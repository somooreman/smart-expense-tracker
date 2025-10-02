;; Budget Planner Smart Contract
;; Generates savings goals and financial plans for users

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u400))
(define-constant ERR_INVALID_BUDGET (err u401))
(define-constant ERR_BUDGET_NOT_FOUND (err u402))
(define-constant ERR_GOAL_NOT_FOUND (err u403))
(define-constant ERR_INVALID_AMOUNT (err u404))
(define-constant ERR_INVALID_DATE (err u405))
(define-constant ERR_USER_NOT_FOUND (err u406))
(define-constant ERR_INSUFFICIENT_FUNDS (err u407))

;; Data structures
(define-map user-budgets
  { user: principal, budget-id: uint }
  {
    budget-name: (string-ascii 64),
    period-type: (string-ascii 16), ;; "monthly", "weekly", "yearly"
    total-income: uint,
    total-allocated: uint,
    start-date: uint,
    end-date: uint,
    is-active: bool,
    created-at: uint,
    last-updated: uint
  }
)

(define-map budget-categories
  { user: principal, budget-id: uint, category: (string-ascii 32) }
  {
    allocated-amount: uint,
    spent-amount: uint,
    remaining-amount: uint,
    percentage-of-income: uint, ;; 0-100
    alert-threshold: uint, ;; 0-100 percentage
    is-essential: bool,
    notes: (string-ascii 128)
  }
)

(define-map savings-goals
  { user: principal, goal-id: uint }
  {
    goal-name: (string-ascii 64),
    target-amount: uint,
    current-amount: uint,
    monthly-contribution: uint,
    target-date: uint,
    goal-type: (string-ascii 32), ;; "emergency", "vacation", "house", "retirement", "other"
    priority: uint, ;; 1-5 scale
    is-achieved: bool,
    created-at: uint,
    last-contribution: uint
  }
)

(define-map investment-recommendations
  { user: principal, recommendation-id: uint }
  {
    investment-type: (string-ascii 32), ;; "stocks", "bonds", "crypto", "real-estate"
    recommended-amount: uint,
    risk-level: (string-ascii 16), ;; "low", "medium", "high"
    expected-return: uint, ;; Annual percentage
    time-horizon: uint, ;; Years
    reasoning: (string-ascii 256),
    confidence-score: uint, ;; 0-100
    generated-at: uint,
    is-accepted: bool
  }
)

(define-map debt-management
  { user: principal, debt-id: uint }
  {
    debt-name: (string-ascii 64),
    total-amount: uint,
    current-balance: uint,
    interest-rate: uint, ;; Annual percentage in basis points (5% = 500)
    minimum-payment: uint,
    recommended-payment: uint,
    debt-type: (string-ascii 32), ;; "credit-card", "loan", "mortgage", "student"
    payoff-strategy: (string-ascii 32), ;; "avalanche", "snowball", "minimum"
    estimated-payoff-date: uint,
    created-at: uint
  }
)

(define-map financial-health-scores
  principal
  {
    overall-score: uint, ;; 0-100
    income-stability: uint,
    expense-control: uint,
    savings-rate: uint,
    debt-ratio: uint,
    emergency-fund-coverage: uint, ;; Months of expenses covered
    last-calculated: uint,
    improvement-suggestions: (list 5 (string-ascii 64))
  }
)

(define-map budget-alerts
  { user: principal, alert-id: uint }
  {
    alert-type: (string-ascii 32), ;; "overspending", "goal-progress", "bill-due"
    category: (optional (string-ascii 32)),
    message: (string-ascii 256),
    severity: (string-ascii 16), ;; "info", "warning", "critical"
    amount: uint,
    triggered-at: uint,
    is-read: bool,
    is-dismissed: bool
  }
)

;; Data variables
(define-data-var next-budget-id uint u1)
(define-data-var next-goal-id uint u1)
(define-data-var next-recommendation-id uint u1)
(define-data-var next-debt-id uint u1)
(define-data-var next-alert-id uint u1)
(define-data-var total-budgets uint u0)
(define-data-var total-goals uint u0)
(define-data-var contract-active bool true)

;; Public functions

;; Create a new budget
(define-public (create-budget (budget-name (string-ascii 64)) (period-type (string-ascii 16))
                             (total-income uint) (start-date uint) (end-date uint))
  (let ((budget-id (var-get next-budget-id)))
    (asserts! (> (len budget-name) u0) ERR_INVALID_BUDGET)
    (asserts! (> total-income u0) ERR_INVALID_AMOUNT)
    (asserts! (< start-date end-date) ERR_INVALID_DATE)
    (asserts! (or (is-eq period-type "monthly") (is-eq period-type "weekly") (is-eq period-type "yearly")) ERR_INVALID_BUDGET)
    (map-set user-budgets { user: tx-sender, budget-id: budget-id } {
      budget-name: budget-name,
      period-type: period-type,
      total-income: total-income,
      total-allocated: u0,
      start-date: start-date,
      end-date: end-date,
      is-active: true,
      created-at: burn-block-height,
      last-updated: burn-block-height
    })
    (var-set next-budget-id (+ budget-id u1))
    (var-set total-budgets (+ (var-get total-budgets) u1))
    (ok budget-id)
  )
)

;; Allocate budget to category
(define-public (allocate-budget-category (budget-id uint) (category (string-ascii 32))
                                        (allocated-amount uint) (alert-threshold uint)
                                        (is-essential bool) (notes (string-ascii 128)))
  (let ((budget (unwrap! (map-get? user-budgets { user: tx-sender, budget-id: budget-id }) ERR_BUDGET_NOT_FOUND)))
    (asserts! (> allocated-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= alert-threshold u100) ERR_INVALID_BUDGET)
    (asserts! (<= (+ (get total-allocated budget) allocated-amount) (get total-income budget)) ERR_INSUFFICIENT_FUNDS)
    (let ((percentage (/ (* allocated-amount u100) (get total-income budget))))
      (map-set budget-categories { user: tx-sender, budget-id: budget-id, category: category } {
        allocated-amount: allocated-amount,
        spent-amount: u0,
        remaining-amount: allocated-amount,
        percentage-of-income: percentage,
        alert-threshold: alert-threshold,
        is-essential: is-essential,
        notes: notes
      })
      (map-set user-budgets { user: tx-sender, budget-id: budget-id } {
        budget-name: (get budget-name budget),
        period-type: (get period-type budget),
        total-income: (get total-income budget),
        total-allocated: (+ (get total-allocated budget) allocated-amount),
        start-date: (get start-date budget),
        end-date: (get end-date budget),
        is-active: (get is-active budget),
        created-at: (get created-at budget),
        last-updated: burn-block-height
      })
      (ok "Budget category allocated")
    )
  )
)

;; Create savings goal
(define-public (create-savings-goal (goal-name (string-ascii 64)) (target-amount uint)
                                   (monthly-contribution uint) (target-date uint)
                                   (goal-type (string-ascii 32)) (priority uint))
  (let ((goal-id (var-get next-goal-id)))
    (asserts! (> (len goal-name) u0) ERR_INVALID_BUDGET)
    (asserts! (> target-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> monthly-contribution u0) ERR_INVALID_AMOUNT)
    (asserts! (> target-date burn-block-height) ERR_INVALID_DATE)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR_INVALID_BUDGET)
    (map-set savings-goals { user: tx-sender, goal-id: goal-id } {
      goal-name: goal-name,
      target-amount: target-amount,
      current-amount: u0,
      monthly-contribution: monthly-contribution,
      target-date: target-date,
      goal-type: goal-type,
      priority: priority,
      is-achieved: false,
      created-at: burn-block-height,
      last-contribution: u0
    })
    (var-set next-goal-id (+ goal-id u1))
    (var-set total-goals (+ (var-get total-goals) u1))
    (ok goal-id)
  )
)

;; Contribute to savings goal
(define-public (contribute-to-goal (goal-id uint) (contribution-amount uint))
  (let ((goal (unwrap! (map-get? savings-goals { user: tx-sender, goal-id: goal-id }) ERR_GOAL_NOT_FOUND)))
    (asserts! (> contribution-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (get is-achieved goal)) ERR_INVALID_BUDGET)
    (let ((new-current-amount (+ (get current-amount goal) contribution-amount))
          (is-now-achieved (>= new-current-amount (get target-amount goal))))
      (map-set savings-goals { user: tx-sender, goal-id: goal-id } {
        goal-name: (get goal-name goal),
        target-amount: (get target-amount goal),
        current-amount: new-current-amount,
        monthly-contribution: (get monthly-contribution goal),
        target-date: (get target-date goal),
        goal-type: (get goal-type goal),
        priority: (get priority goal),
        is-achieved: is-now-achieved,
        created-at: (get created-at goal),
        last-contribution: burn-block-height
      })
      (if is-now-achieved
        (ok "Goal achieved!")
        (ok "Contribution recorded")
      )
    )
  )
)

;; Generate investment recommendation
(define-public (generate-investment-recommendation (investment-type (string-ascii 32))
                                                  (recommended-amount uint) (risk-level (string-ascii 16))
                                                  (expected-return uint) (time-horizon uint)
                                                  (reasoning (string-ascii 256)))
  (let ((recommendation-id (var-get next-recommendation-id))
        (confidence (calculate-recommendation-confidence investment-type risk-level expected-return)))
    (asserts! (> recommended-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> time-horizon u0) ERR_INVALID_BUDGET)
    (asserts! (or (is-eq risk-level "low") (is-eq risk-level "medium") (is-eq risk-level "high")) ERR_INVALID_BUDGET)
    (map-set investment-recommendations { user: tx-sender, recommendation-id: recommendation-id } {
      investment-type: investment-type,
      recommended-amount: recommended-amount,
      risk-level: risk-level,
      expected-return: expected-return,
      time-horizon: time-horizon,
      reasoning: reasoning,
      confidence-score: confidence,
      generated-at: burn-block-height,
      is-accepted: false
    })
    (var-set next-recommendation-id (+ recommendation-id u1))
    (ok recommendation-id)
  )
)

;; Add debt for management
(define-public (add-debt (debt-name (string-ascii 64)) (total-amount uint) (current-balance uint)
                        (interest-rate uint) (minimum-payment uint) (debt-type (string-ascii 32)))
  (let ((debt-id (var-get next-debt-id))
        (recommended-payment (calculate-recommended-payment current-balance interest-rate))
        (estimated-payoff (calculate-payoff-date current-balance recommended-payment interest-rate)))
    (asserts! (> (len debt-name) u0) ERR_INVALID_BUDGET)
    (asserts! (> current-balance u0) ERR_INVALID_AMOUNT)
    (asserts! (> minimum-payment u0) ERR_INVALID_AMOUNT)
    (asserts! (<= current-balance total-amount) ERR_INVALID_AMOUNT)
    (map-set debt-management { user: tx-sender, debt-id: debt-id } {
      debt-name: debt-name,
      total-amount: total-amount,
      current-balance: current-balance,
      interest-rate: interest-rate,
      minimum-payment: minimum-payment,
      recommended-payment: recommended-payment,
      debt-type: debt-type,
      payoff-strategy: "avalanche",
      estimated-payoff-date: estimated-payoff,
      created-at: burn-block-height
    })
    (var-set next-debt-id (+ debt-id u1))
    (ok debt-id)
  )
)

;; Update spending in budget category
(define-public (update-category-spending (budget-id uint) (category (string-ascii 32)) (spent-amount uint))
  (let ((budget-category (unwrap! (map-get? budget-categories { user: tx-sender, budget-id: budget-id, category: category }) ERR_BUDGET_NOT_FOUND)))
    (asserts! (> spent-amount u0) ERR_INVALID_AMOUNT)
    (let ((new-spent (+ (get spent-amount budget-category) spent-amount))
          (new-remaining (if (>= new-spent (get allocated-amount budget-category))
                           u0
                           (- (get allocated-amount budget-category) new-spent))))
      (map-set budget-categories { user: tx-sender, budget-id: budget-id, category: category } {
        allocated-amount: (get allocated-amount budget-category),
        spent-amount: new-spent,
        remaining-amount: new-remaining,
        percentage-of-income: (get percentage-of-income budget-category),
        alert-threshold: (get alert-threshold budget-category),
        is-essential: (get is-essential budget-category),
        notes: (get notes budget-category)
      })
      ;; Check if alert threshold is exceeded
      (let ((spending-percentage (/ (* new-spent u100) (get allocated-amount budget-category))))
        (if (>= spending-percentage (get alert-threshold budget-category))
          (begin
            (try! (create-budget-alert "overspending" (some category) 
                                     "Budget threshold exceeded" "warning" new-spent))
            (ok "Spending updated with alert")
          )
          (ok "Spending updated")
        )
      )
    )
  )
)

;; Calculate financial health score
(define-public (calculate-financial-health (monthly-income uint) (monthly-expenses uint)
                                          (total-savings uint) (total-debt uint)
                                          (emergency-fund uint))
  (let ((savings-rate (if (> monthly-income u0) (/ (* (- monthly-income monthly-expenses) u100) monthly-income) u0))
        (debt-ratio (if (> monthly-income u0) (/ (* total-debt u100) (* monthly-income u12)) u0))
        (emergency-coverage (if (> monthly-expenses u0) (/ emergency-fund monthly-expenses) u0))
        (expense-control (if (<= monthly-expenses (* monthly-income u80)) u100 u50)))
    (let ((capped-emergency (if (<= emergency-coverage u100) emergency-coverage u100))
          (debt-adjustment (if (>= debt-ratio u100) u0 (- u100 debt-ratio)))
          (overall-score (/ (+ savings-rate expense-control capped-emergency debt-adjustment) u4)))
      (map-set financial-health-scores tx-sender {
        overall-score: overall-score,
        income-stability: u75, ;; Simplified - would analyze income history
        expense-control: expense-control,
        savings-rate: savings-rate,
        debt-ratio: debt-ratio,
        emergency-fund-coverage: emergency-coverage,
        last-calculated: burn-block-height,
        improvement-suggestions: (list "increase-savings" "reduce-expenses" "pay-debt" "build-emergency" "invest")
      })
      (ok overall-score)
    )
  )
)

;; Create budget alert
(define-public (create-budget-alert (alert-type (string-ascii 32)) (category (optional (string-ascii 32)))
                                   (message (string-ascii 256)) (severity (string-ascii 16)) (amount uint))
  (let ((alert-id (var-get next-alert-id)))
    (asserts! (> (len message) u0) ERR_INVALID_BUDGET)
    (map-set budget-alerts { user: tx-sender, alert-id: alert-id } {
      alert-type: alert-type,
      category: category,
      message: message,
      severity: severity,
      amount: amount,
      triggered-at: burn-block-height,
      is-read: false,
      is-dismissed: false
    })
    (var-set next-alert-id (+ alert-id u1))
    (ok alert-id)
  )
)

;; Mark alert as read
(define-public (mark-alert-read (alert-id uint))
  (let ((alert (unwrap! (map-get? budget-alerts { user: tx-sender, alert-id: alert-id }) ERR_BUDGET_NOT_FOUND)))
    (map-set budget-alerts { user: tx-sender, alert-id: alert-id } {
      alert-type: (get alert-type alert),
      category: (get category alert),
      message: (get message alert),
      severity: (get severity alert),
      amount: (get amount alert),
      triggered-at: (get triggered-at alert),
      is-read: true,
      is-dismissed: (get is-dismissed alert)
    })
    (ok "Alert marked as read")
  )
)

;; Private functions

;; Calculate investment recommendation confidence
(define-private (calculate-recommendation-confidence (investment-type (string-ascii 32))
                                                   (risk-level (string-ascii 16))
                                                   (expected-return uint))
  ;; Simplified confidence calculation
  (if (is-eq risk-level "low")
    u85
    (if (is-eq risk-level "medium")
      u70
      u55
    )
  )
)

;; Calculate recommended debt payment
(define-private (calculate-recommended-payment (balance uint) (interest-rate uint))
  ;; Simplified calculation - recommend paying more than minimum
  (+ (/ balance u60) (/ (* balance interest-rate) u1200)) ;; Rough monthly payment calculation
)

;; Calculate debt payoff date
(define-private (calculate-payoff-date (balance uint) (monthly-payment uint) (interest-rate uint))
  ;; Simplified calculation - would use proper amortization formula
  (+ burn-block-height (/ balance monthly-payment))
)

;; Read-only functions

;; Get user budget
(define-read-only (get-budget (user principal) (budget-id uint))
  (map-get? user-budgets { user: user, budget-id: budget-id })
)

;; Get budget category allocation
(define-read-only (get-budget-category (user principal) (budget-id uint) (category (string-ascii 32)))
  (map-get? budget-categories { user: user, budget-id: budget-id, category: category })
)

;; Get savings goal
(define-read-only (get-savings-goal (user principal) (goal-id uint))
  (map-get? savings-goals { user: user, goal-id: goal-id })
)

;; Get investment recommendation
(define-read-only (get-investment-recommendation (user principal) (recommendation-id uint))
  (map-get? investment-recommendations { user: user, recommendation-id: recommendation-id })
)

;; Get debt information
(define-read-only (get-debt-info (user principal) (debt-id uint))
  (map-get? debt-management { user: user, debt-id: debt-id })
)

;; Get financial health score
(define-read-only (get-financial-health (user principal))
  (map-get? financial-health-scores user)
)

;; Get budget alert
(define-read-only (get-budget-alert (user principal) (alert-id uint))
  (map-get? budget-alerts { user: user, alert-id: alert-id })
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-budgets: (var-get total-budgets),
    total-goals: (var-get total-goals),
    next-budget-id: (var-get next-budget-id),
    next-goal-id: (var-get next-goal-id),
    next-recommendation-id: (var-get next-recommendation-id),
    next-debt-id: (var-get next-debt-id),
    next-alert-id: (var-get next-alert-id),
    contract-active: (var-get contract-active)
  }
)

;; Admin functions

;; Toggle contract status (admin only)
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)
