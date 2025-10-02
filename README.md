# Smart Expense Tracker

A personal finance app that automatically categorizes spending and gives savings insights using blockchain technology on the Stacks network.

## Overview

The Smart Expense Tracker is a decentralized financial management application that leverages smart contracts to provide transparent, secure, and private expense tracking. The system automatically categorizes transactions, analyzes spending patterns, and generates personalized savings recommendations while ensuring complete user control over financial data.

## Key Features

### Automated Transaction Analysis
- **Smart Categorization**: AI-powered automatic categorization of income and expenses
- **Pattern Recognition**: Identify recurring transactions and spending habits
- **Real-time Processing**: Instant transaction analysis and categorization
- **Multi-source Integration**: Support for various payment methods and accounts

### Intelligent Budget Planning
- **Dynamic Budget Creation**: Generate personalized budgets based on spending history
- **Goal-oriented Savings**: Set and track specific financial objectives
- **Spending Alerts**: Real-time notifications for budget overruns
- **Investment Recommendations**: Suggest optimal savings and investment strategies

## Smart Contract Architecture

### Transaction Parser Contract
The transaction parser contract handles:
- Transaction recording and categorization
- Spending pattern analysis and insights
- Income tracking and trend analysis
- Financial health scoring and recommendations

### Budget Planner Contract
The budget planner contract manages:
- Personal budget creation and management
- Savings goal setting and tracking
- Financial planning recommendations
- Investment opportunity analysis

## Technology Stack

- **Blockchain**: Stacks Network
- **Smart Contract Language**: Clarity
- **Development Framework**: Clarinet
- **Testing**: Clarinet integrated testing suite

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for interaction
- Node.js for local development

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/somooreman/smart-expense-tracker.git
   cd smart-expense-tracker
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run tests:
   ```bash
   clarinet test
   ```

4. Check contracts:
   ```bash
   clarinet check
   ```

## Contract Deployment

### Local Development
```bash
clarinet console
```

### Testnet Deployment
```bash
clarinet deploy --testnet
```

## Usage

### For Personal Users
1. Connect your Stacks wallet to the application
2. Set up your financial profile and preferences
3. Import transactions from various sources
4. Receive automated categorization and insights
5. Create and manage personalized budgets
6. Track progress toward savings goals

### Financial Data Management
1. **Transaction Import**: Securely import transaction data
2. **Category Management**: Customize expense categories
3. **Budget Allocation**: Set spending limits per category
4. **Goal Tracking**: Monitor progress toward financial objectives
5. **Insight Generation**: Receive personalized financial advice

## Smart Contract Functions

### Transaction Parser
- `record-transaction`: Add new income or expense transactions
- `categorize-spending`: Automatically classify expenses
- `analyze-patterns`: Identify spending trends and habits
- `generate-insights`: Create personalized financial recommendations

### Budget Planner
- `create-budget`: Establish monthly or annual budgets
- `set-savings-goal`: Define specific financial objectives
- `track-progress`: Monitor spending against budget limits
- `recommend-adjustments`: Suggest budget optimizations

## Financial Categories

### Expense Categories
- **Housing**: Rent, mortgage, utilities, maintenance
- **Food**: Groceries, restaurants, delivery services
- **Transportation**: Gas, public transit, ride-sharing, vehicle maintenance
- **Healthcare**: Insurance, medical bills, prescriptions
- **Entertainment**: Movies, streaming services, hobbies
- **Shopping**: Clothing, electronics, personal items
- **Bills**: Phone, internet, subscriptions, insurance

### Income Categories
- **Salary**: Primary employment income
- **Freelance**: Contract and gig work earnings
- **Investments**: Dividends, capital gains, interest
- **Side Business**: Entrepreneurial income
- **Other**: Gifts, refunds, miscellaneous income

## Privacy & Security

- **Encrypted Storage**: All financial data encrypted on-chain
- **User-controlled Access**: Complete ownership of personal financial information
- **Transparent Algorithms**: Open-source categorization and recommendation logic
- **No Third-party Access**: Financial institutions cannot access user data directly

## Budget Planning Features

### Automated Budget Creation
- Analyze historical spending to suggest realistic budgets
- Account for seasonal variations and irregular expenses
- Provide buffer recommendations for unexpected costs
- Integrate income forecasting with expense planning

### Savings Optimization
- **Emergency Fund Planning**: Build recommended emergency savings
- **Goal-based Saving**: Allocate funds for specific objectives
- **Investment Recommendations**: Suggest low-risk investment options
- **Debt Reduction Plans**: Optimize debt payoff strategies

### Financial Health Metrics
- **Spending Ratio Analysis**: Income vs. expense ratios
- **Category Balance Scoring**: Optimal spending distribution
- **Savings Rate Tracking**: Progress toward financial independence
- **Debt-to-Income Monitoring**: Financial stability indicators

## Roadmap

- [ ] Core smart contract development
- [ ] Transaction parsing and categorization
- [ ] Budget planning algorithm implementation
- [ ] Web interface development
- [ ] Mobile application
- [ ] Bank integration APIs
- [ ] Advanced AI/ML categorization
- [ ] Investment portfolio tracking
- [ ] Tax preparation assistance

## Contributing

We welcome contributions to the Smart Expense Tracker project. Please read our contributing guidelines and code of conduct before submitting pull requests.

### Development Process
1. Fork the repository
2. Create a feature branch
3. Implement changes with comprehensive tests
4. Submit pull request for review

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Join our community discussions

## Data Import Support

### Supported Formats
- **CSV Files**: Bank statements and transaction exports
- **OFX Files**: Standard financial data exchange format
- **QIF Files**: Quicken interchange format
- **Manual Entry**: Direct transaction input interface

### Integration Partners
- **Bank APIs**: Secure connection to financial institutions
- **Credit Card Companies**: Direct transaction feed integration
- **Payment Processors**: PayPal, Stripe, Square connections
- **Cryptocurrency Exchanges**: Digital asset transaction tracking

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Hiro for Clarinet development tools
- Open source community for contributions and feedback
- Financial data standards organizations for integration protocols

---

*Taking control of your financial future, one smart contract at a time.*