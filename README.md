# Mortgage-MoneyMoney
MoneyMoney Mortgage Account - Create realistic mortgage loan accounts in MoneyMoney with configurable payment frequencies, variable interest rates, custom payment dates, and automatic transaction generation. Features accurate amortization calculations, split principal/interest transactions, and support for rate changes during the mortgage term.

# MoneyMoney Mortgage Account Extension

A comprehensive mortgage simulation extension for [MoneyMoney](https://moneymoney-app.com) that creates realistic mortgage accounts with payment tracking, interest calculations, and rate change support.

## Features

- ✅ **Realistic Mortgage Simulation** - Creates loan accounts with negative balances representing debt
- ✅ **Flexible Payment Frequencies** - Support for monthly and weekly payments  
- ✅ **Custom Payment Dates** - Set specific day of month for payments (handles month-end edge cases)
- ✅ **Variable Interest Rates** - Support for rate changes during mortgage term
- ✅ **Accurate Amortization** - Proper principal/interest calculations using standard mortgage formulas
- ✅ **Split Transactions** - Separate positive (payment received) and negative (interest charged) transactions
- ✅ **Auto-calculation** - Automatically calculates payment amounts or accepts fixed amounts
- ✅ **Smart Date Handling** - Handles leap years and months with different day counts

## Installation

1. Download `MortgageAccount.lua` from this repository
2. Copy to your MoneyMoney Extensions folder:
   ```
   ~/Library/Containers/com.moneymoney-app.retail/Data/Library/Application Support/MoneyMoney/Extensions/
   ```
3. Disable digital signature verification in MoneyMoney preferences:
   - `MoneyMoney` → `Preferences` → `Extensions` → Uncheck "Check digital signature of extensions"
4. Restart MoneyMoney

## Usage

### Step 1: Create Account
1. In MoneyMoney, add a new account
2. Select **"Mortgage Account"** as the service
3. Enter your mortgage principal in the username field:
   - Format: `principal:245700` or just `245700`
   - Example: `principal:250000` for a €250,000 mortgage
4. Enter any dummy password
5. Account is created with negative balance (representing debt)

### Step 2: Configure Mortgage Details
Add these user-defined fields in the account's **Notes tab**:

| Field | Required | Example | Description |
|-------|----------|---------|-------------|
| `interestRate` | ✅ | `3.5` | Annual interest rate (%) |
| `termYears` | ✅ | `25` | Mortgage term in years |
| `startDate` | ✅ | `2023-01-01` | Mortgage start date (YYYY-MM-DD) |
| `monthlyPayment` | ✅ | `auto` | Payment amount (`auto` or fixed amount) |
| `frequency` | ✅ | `monthly` | Payment frequency (`monthly` or `weekly`) |
| `paymentDate` | ⭕ | `15` | Day of month for payments (1-31) |
| `newRate` | ⭕ | `4.2` | New interest rate for rate changes (%) |
| `newRateDate` | ⭕ | `2025-06-01` | Date when rate changes (YYYY-MM-DD) |

### Step 3: Generate Transactions
1. Right-click the account and select "Refresh Account"
2. Extension generates complete payment history from start date to current date
3. Each payment creates two transactions:
   - **Positive**: "Mortgage Payment Received" (reduces debt)
   - **Negative**: "Interest Charged" (adds interest cost)

## Configuration Examples

### Basic Fixed-Rate Mortgage
```
interestRate = 3.25
termYears = 20
startDate = 2023-01-01
monthlyPayment = 1393.60
frequency = monthly
paymentDate = 1
```

### Variable Rate Mortgage
```
interestRate = 3.25
termYears = 20
startDate = 2023-01-01
monthlyPayment = 1393.60
frequency = monthly
paymentDate = 15
newRate = 4.0
newRateDate = 2025-06-01
```

### Weekly Payment Mortgage
```
interestRate = 3.5
termYears = 25
startDate = 2023-01-01
monthlyPayment = auto
frequency = weekly
```

## Transaction Structure

The extension creates realistic mortgage transactions:

### Payment Received (+€1,200)
```
Mortgage Payment Received
Payment #24 (monthly)
Principal: €623.45, Interest: €576.55
Remaining: €234,567.89
```

### Interest Charged (-€576.55)
```
Interest Charged  
Payment #24 (monthly) - Interest
Rate: 3.5% per year
Amount: €576.55
```

### Rate Change Notification
```
Interest Rate Change
From 3.5% to 4.0%
Effective from this payment period
```

## How It Works

1. **Account Balance**: Shows current remaining mortgage debt (negative number)
2. **Payment Calculation**: Uses standard mortgage amortization formulas
3. **Interest Calculation**: Applied to remaining balance each payment period
4. **Rate Changes**: New rate applied from specified date using existing balance
5. **Smart Dates**: Handles month-end payments (e.g., day 31 becomes day 30 in April)

## Technical Details

- **Language**: Lua 5.3+
- **Platform**: macOS (MoneyMoney requirement)
- **Account Type**: Loan account with negative balance
- **Date Handling**: Proper leap year and month-end calculations
- **Formula**: Standard mortgage amortization: `M = P[r(1+r)^n]/[(1+r)^n-1]`

## Troubleshooting

### Extension Not Showing
- Ensure digital signature verification is disabled
- Restart MoneyMoney after copying the file
- Check the Protocol Window for error messages

### No Transactions Generated
- Verify all required fields are configured in Notes tab
- Check that `frequency` is set to `monthly` or `weekly`
- Ensure `startDate` is in YYYY-MM-DD format

### Rate Change Not Working
- Both `newRate` and `newRateDate` must be set
- `newRateDate` must be after `startDate`
- Rate change applies from the first payment on/after the change date

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with MoneyMoney
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Disclaimer

This extension is for simulation purposes only. It does not connect to real financial institutions. Always verify calculations with your actual mortgage provider.

## Support

- 📫 Create an issue for bugs or feature requests
- 💡 Check the MoneyMoney [API documentation](https://moneymoney.app/api/webbanking/) for extension development
- 🎯 Ensure you're using a compatible version of MoneyMoney (2.4+)
