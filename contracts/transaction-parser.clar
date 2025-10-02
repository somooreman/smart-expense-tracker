;; Transaction Parser Smart Contract
;; Analyzes and categorizes income and expenses for financial tracking

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_INVALID_TRANSACTION (err u301))
(define-constant ERR_TRANSACTION_NOT_FOUND (err u302))
(define-constant ERR_INVALID_AMOUNT (err u303))
(define-constant ERR_CATEGORY_NOT_FOUND (err u304))
(define-constant ERR_INVALID_DATE (err u305))
(define-constant ERR_USER_NOT_FOUND (err u306))

;; Data structures
(define-map user-profiles
  principal
  {
    username: (string-ascii 32),
    email: (string-ascii 128),
    currency: (string-ascii 3), ;; USD, EUR, etc.
    timezone: (string-ascii 32),
    created-at: uint,
    last-activity: uint,
    total-transactions: uint,
    profile-active: bool
  }
)

(define-map transactions
  { user: principal, transaction-id: uint }
  {
    amount: uint, ;; Amount in cents/smallest unit
    description: (string-ascii 128),
    category: (string-ascii 32),
    transaction-type: (string-ascii 16), ;; "income" or "expense"
    date: uint,
    account-source: (string-ascii 64), ;; Bank account, credit card, etc.
    merchant: (string-ascii 64),
    location: (string-ascii 64),
    tags: (list 5 (string-ascii 16)),
    is-recurring: bool,
    confidence-score: uint, ;; 0-100 categorization confidence
    created-at: uint,
    modified-at: uint
  }
)

(define-map expense-categories
  (string-ascii 32)
  {
    category-name: (string-ascii 32),
    parent-category: (optional (string-ascii 32)),
    description: (string-ascii 128),
    color-code: (string-ascii 7), ;; Hex color
    is-active: bool,
    created-by: principal
  }
)

(define-map user-category-rules
  { user: principal, rule-id: uint }
  {
    keyword: (string-ascii 64),
    category: (string-ascii 32),
    priority: uint, ;; 1-10 scale
    auto-apply: bool,
    created-at: uint
  }
)

(define-map spending-patterns
  { user: principal, pattern-id: uint }
  {
    category: (string-ascii 32),
    average-amount: uint,
    frequency: (string-ascii 16), ;; "daily", "weekly", "monthly"
    trend: (string-ascii 16), ;; "increasing", "decreasing", "stable"
    last-transaction: uint,
    pattern-strength: uint, ;; 0-100 confidence
    identified-at: uint
  }
)

(define-map financial-insights
  { user: principal, insight-id: uint }
  {
    insight-type: (string-ascii 32), ;; "overspending", "savings-opportunity", etc.
    category: (optional (string-ascii 32)),
    message: (string-ascii 256),
    severity: (string-ascii 16), ;; "low", "medium", "high"
    action-recommended: (string-ascii 128),
    amount-involved: uint,
    generated-at: uint,
    is-acknowledged: bool
  }
)

;; Data variables
(define-data-var next-transaction-id uint u1)
(define-data-var next-rule-id uint u1)
(define-data-var next-pattern-id uint u1)
(define-data-var next-insight-id uint u1)
(define-data-var total-users uint u0)
(define-data-var contract-active bool true)
(define-data-var default-categories-initialized bool false)

;; Public functions

;; Initialize user profile
(define-public (create-user-profile (username (string-ascii 32)) (email (string-ascii 128))
                                   (currency (string-ascii 3)) (timezone (string-ascii 32)))
  (let ((profile-exists (is-some (map-get? user-profiles tx-sender))))
    (asserts! (not profile-exists) ERR_INVALID_TRANSACTION)
    (asserts! (> (len username) u0) ERR_INVALID_TRANSACTION)
    (asserts! (> (len email) u0) ERR_INVALID_TRANSACTION)
    (map-set user-profiles tx-sender {
      username: username,
      email: email,
      currency: currency,
      timezone: timezone,
      created-at: burn-block-height,
      last-activity: burn-block-height,
      total-transactions: u0,
      profile-active: true
    })
    (var-set total-users (+ (var-get total-users) u1))
    (ok "User profile created successfully")
  )
)

;; Record a new transaction
(define-public (record-transaction (amount uint) (description (string-ascii 128))
                                  (category (string-ascii 32)) (transaction-type (string-ascii 16))
                                  (date uint) (account-source (string-ascii 64))
                                  (merchant (string-ascii 64)) (location (string-ascii 64))
                                  (tags (list 5 (string-ascii 16))) (is-recurring bool))
  (let ((transaction-id (var-get next-transaction-id))
        (user-profile (unwrap! (map-get? user-profiles tx-sender) ERR_USER_NOT_FOUND)))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> (len description) u0) ERR_INVALID_TRANSACTION)
    (asserts! (or (is-eq transaction-type "income") (is-eq transaction-type "expense")) ERR_INVALID_TRANSACTION)
    (asserts! (< date burn-block-height) ERR_INVALID_DATE)
    (let ((confidence (calculate-categorization-confidence category description merchant)))
      (map-set transactions { user: tx-sender, transaction-id: transaction-id } {
        amount: amount,
        description: description,
        category: category,
        transaction-type: transaction-type,
        date: date,
        account-source: account-source,
        merchant: merchant,
        location: location,
        tags: tags,
        is-recurring: is-recurring,
        confidence-score: confidence,
        created-at: burn-block-height,
        modified-at: burn-block-height
      })
      (map-set user-profiles tx-sender {
        username: (get username user-profile),
        email: (get email user-profile),
        currency: (get currency user-profile),
        timezone: (get timezone user-profile),
        created-at: (get created-at user-profile),
        last-activity: burn-block-height,
        total-transactions: (+ (get total-transactions user-profile) u1),
        profile-active: true
      })
      (var-set next-transaction-id (+ transaction-id u1))
      (ok transaction-id)
    )
  )
)

;; Automatically categorize transaction based on rules and patterns
(define-public (auto-categorize-transaction (transaction-id uint) (description (string-ascii 128))
                                          (merchant (string-ascii 64)))
  (let ((transaction (unwrap! (map-get? transactions { user: tx-sender, transaction-id: transaction-id }) ERR_TRANSACTION_NOT_FOUND)))
    (let ((suggested-category (suggest-category-from-rules description merchant tx-sender)))
      (match suggested-category
        some-category (begin
          (map-set transactions { user: tx-sender, transaction-id: transaction-id } {
            amount: (get amount transaction),
            description: description,
            category: some-category,
            transaction-type: (get transaction-type transaction),
            date: (get date transaction),
            account-source: (get account-source transaction),
            merchant: merchant,
            location: (get location transaction),
            tags: (get tags transaction),
            is-recurring: (get is-recurring transaction),
            confidence-score: u85,
            created-at: (get created-at transaction),
            modified-at: burn-block-height
          })
          (ok some-category)
        )
        (ok "food") ;; Default category if no rules match
      )
    )
  )
)

;; Create custom categorization rule
(define-public (create-categorization-rule (keyword (string-ascii 64)) (category (string-ascii 32))
                                          (priority uint) (auto-apply bool))
  (let ((rule-id (var-get next-rule-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_USER_NOT_FOUND)
    (asserts! (> (len keyword) u0) ERR_INVALID_TRANSACTION)
    (asserts! (and (>= priority u1) (<= priority u10)) ERR_INVALID_TRANSACTION)
    (map-set user-category-rules { user: tx-sender, rule-id: rule-id } {
      keyword: keyword,
      category: category,
      priority: priority,
      auto-apply: auto-apply,
      created-at: burn-block-height
    })
    (var-set next-rule-id (+ rule-id u1))
    (ok rule-id)
  )
)

;; Analyze spending patterns
(define-public (analyze-spending-pattern (category (string-ascii 32)) (timeframe-days uint))
  (let ((pattern-id (var-get next-pattern-id))
        (user-profile (unwrap! (map-get? user-profiles tx-sender) ERR_USER_NOT_FOUND)))
    (asserts! (> timeframe-days u0) ERR_INVALID_TRANSACTION)
    (let ((pattern-data (calculate-pattern-metrics category tx-sender timeframe-days)))
      (map-set spending-patterns { user: tx-sender, pattern-id: pattern-id } {
        category: category,
        average-amount: (get average pattern-data),
        frequency: (get frequency pattern-data),
        trend: (get trend pattern-data),
        last-transaction: burn-block-height,
        pattern-strength: (get strength pattern-data),
        identified-at: burn-block-height
      })
      (var-set next-pattern-id (+ pattern-id u1))
      (ok pattern-id)
    )
  )
)

;; Generate financial insight
(define-public (generate-insight (insight-type (string-ascii 32)) (category (optional (string-ascii 32)))
                                (message (string-ascii 256)) (severity (string-ascii 16))
                                (action-recommended (string-ascii 128)) (amount-involved uint))
  (let ((insight-id (var-get next-insight-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_USER_NOT_FOUND)
    (asserts! (> (len message) u0) ERR_INVALID_TRANSACTION)
    (map-set financial-insights { user: tx-sender, insight-id: insight-id } {
      insight-type: insight-type,
      category: category,
      message: message,
      severity: severity,
      action-recommended: action-recommended,
      amount-involved: amount-involved,
      generated-at: burn-block-height,
      is-acknowledged: false
    })
    (var-set next-insight-id (+ insight-id u1))
    (ok insight-id)
  )
)

;; Acknowledge financial insight
(define-public (acknowledge-insight (insight-id uint))
  (let ((insight (unwrap! (map-get? financial-insights { user: tx-sender, insight-id: insight-id }) ERR_TRANSACTION_NOT_FOUND)))
    (map-set financial-insights { user: tx-sender, insight-id: insight-id } {
      insight-type: (get insight-type insight),
      category: (get category insight),
      message: (get message insight),
      severity: (get severity insight),
      action-recommended: (get action-recommended insight),
      amount-involved: (get amount-involved insight),
      generated-at: (get generated-at insight),
      is-acknowledged: true
    })
    (ok "Insight acknowledged")
  )
)

;; Update transaction category manually
(define-public (update-transaction-category (transaction-id uint) (new-category (string-ascii 32)))
  (let ((transaction (unwrap! (map-get? transactions { user: tx-sender, transaction-id: transaction-id }) ERR_TRANSACTION_NOT_FOUND)))
    (asserts! (> (len new-category) u0) ERR_INVALID_TRANSACTION)
    (map-set transactions { user: tx-sender, transaction-id: transaction-id } {
      amount: (get amount transaction),
      description: (get description transaction),
      category: new-category,
      transaction-type: (get transaction-type transaction),
      date: (get date transaction),
      account-source: (get account-source transaction),
      merchant: (get merchant transaction),
      location: (get location transaction),
      tags: (get tags transaction),
      is-recurring: (get is-recurring transaction),
      confidence-score: u100, ;; Manual categorization has highest confidence
      created-at: (get created-at transaction),
      modified-at: burn-block-height
    })
    (ok "Transaction category updated")
  )
)

;; Private functions

;; Calculate categorization confidence based on description and merchant
(define-private (calculate-categorization-confidence (category (string-ascii 32))
                                                   (description (string-ascii 128))
                                                   (merchant (string-ascii 64)))
  ;; Simplified confidence calculation - in real implementation would use ML
  (if (> (len merchant) u0)
    u75
    u60
  )
)

;; Suggest category based on user rules
(define-private (suggest-category-from-rules (description (string-ascii 128))
                                           (merchant (string-ascii 64))
                                           (user principal))
  ;; Simplified rule matching - in real implementation would check all rules
  (some "food")
)

;; Calculate spending pattern metrics
(define-private (calculate-pattern-metrics (category (string-ascii 32))
                                         (user principal)
                                         (timeframe-days uint))
  ;; Simplified pattern analysis - in real implementation would analyze historical data
  {
    average: u10000, ;; $100.00 in cents
    frequency: "weekly",
    trend: "stable",
    strength: u70
  }
)

;; Read-only functions

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

;; Get transaction details
(define-read-only (get-transaction (user principal) (transaction-id uint))
  (map-get? transactions { user: user, transaction-id: transaction-id })
)

;; Get categorization rule
(define-read-only (get-categorization-rule (user principal) (rule-id uint))
  (map-get? user-category-rules { user: user, rule-id: rule-id })
)

;; Get spending pattern
(define-read-only (get-spending-pattern (user principal) (pattern-id uint))
  (map-get? spending-patterns { user: user, pattern-id: pattern-id })
)

;; Get financial insight
(define-read-only (get-financial-insight (user principal) (insight-id uint))
  (map-get? financial-insights { user: user, insight-id: insight-id })
)

;; Get expense category details
(define-read-only (get-expense-category (category-name (string-ascii 32)))
  (map-get? expense-categories category-name)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-users: (var-get total-users),
    next-transaction-id: (var-get next-transaction-id),
    next-rule-id: (var-get next-rule-id),
    next-pattern-id: (var-get next-pattern-id),
    next-insight-id: (var-get next-insight-id),
    contract-active: (var-get contract-active)
  }
)

;; Admin functions

;; Create default expense category (admin only)
(define-public (create-expense-category (category-name (string-ascii 32))
                                       (parent-category (optional (string-ascii 32)))
                                       (description (string-ascii 128))
                                       (color-code (string-ascii 7)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (> (len category-name) u0) ERR_INVALID_TRANSACTION)
    (map-set expense-categories category-name {
      category-name: category-name,
      parent-category: parent-category,
      description: description,
      color-code: color-code,
      is-active: true,
      created-by: tx-sender
    })
    (ok "Category created")
  )
)

;; Toggle contract status (admin only)
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)
