-- Mortgage Simulator Extension for MoneyMoney
-- Step 1: Enter principal amount in username field (format: principal:245700)
-- Step 2: Configure mortgage details in Notes tab user-defined fields
-- Step 3: Refresh account to calculate transactions

WebBanking {
  version = 1.08,
  country = "de",
  url = "https://mortgage-simulator.local",
  services = { "Mortgage Account" },
  description = "Step 1: Enter 'principal:245700' in username. Step 2: Configure mortgage in Notes tab. Step 3: Refresh to calculate."
}

-- Global variable to store parsed principal
local userPrincipal = nil

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Mortgage Account"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  print("Mortgage Simulator: Session initialized")
  print("Parsing principal amount from username field...")
  
  if username and username ~= "" then
    userPrincipal = parsePrincipal(username)
    if userPrincipal then
      print("Successfully parsed principal: €" .. userPrincipal)
    else
      print("Failed to parse principal, using fallback: €250000")
      userPrincipal = 250000
    end
  else
    print("No username provided, using fallback: €250000")
    userPrincipal = 250000
  end
  
  return nil
end

function parsePrincipal(configString)
  local principal = string.match(configString, "^%s*principal%s*:%s*(%d+)%s*$")
  if principal then
    return tonumber(principal)
  end
  
  local number = tonumber(configString)
  if number then
    return number
  end
  
  return nil
end

function ListAccounts(knownAccounts)
  local principal = userPrincipal or 250000
  
  print("Creating mortgage account with principal: €" .. principal)
  print("Account created with negative balance (debt): €" .. (-principal))
  print("Configure mortgage details in Notes tab, then refresh to generate transactions")
  
  local account = {
    name = "Mortgage Loan (€" .. string.format("%.0f", principal / 1000) .. "k)",
    accountNumber = "MORT" .. string.format("%.0f", principal),
    currency = "EUR",
    type = AccountTypeLoan
  }
  
  return {account}
end

function RefreshAccount(account, since)
  print("RefreshAccount called - GENERATING TRANSACTIONS")
  
  local config = readConfigFromAccount(account)
  
  print("RefreshAccount called with configuration:")
  printMortgageConfig(config)
  
  if not isConfigurationComplete(config) then
    print("Configuration incomplete - returning setup instructions")
    
    local setupTransaction = {
      bookingDate = MM.time(),
      valueDate = MM.time(),
      amount = 0,
      currency = "EUR",
      name = "Setup Required",
      purpose = "Configure mortgage in Notes tab:\n• interestRate (e.g., 3.5)\n• termYears (e.g., 25)\n• startDate (e.g., 2023-01-01)\n• monthlyPayment (e.g., auto or 1200)\n• frequency (monthly or weekly)\n• paymentDate (optional, 1-31 for day of month)\nThen refresh again.",
      bookingText = "Setup",
      bookingKey = "MSC",
      transactionCode = 999,
      textKeyExtension = 0,
      booked = true,
      checkmark = false
    }
    
    return {
      balance = -config.principal,
      transactions = {setupTransaction}
    }
  end
  
  local startTimestamp = parseDate(config.startDate)
  if not startTimestamp then
    return "Invalid start date format. Use YYYY-MM-DD (e.g., 2023-01-01)"
  end
  
  local currentTime = MM.time()
  local paymentsElapsed = calculatePaymentsElapsed(startTimestamp, currentTime, config.frequency)
  
  local transactions, currentBalance, paymentAmount = generateAllTransactions(
    config, startTimestamp, paymentsElapsed)
  
  local summaryText = string.format("Mortgage Configuration\n€%.0f at %.1f%% for %d years\nPayment: €%.2f %s", 
           config.principal, config.interestRate, config.termYears, paymentAmount, config.frequency)
  
  table.insert(transactions, 1, {
    bookingDate = startTimestamp,
    valueDate = startTimestamp,
    amount = 0,
    currency = "EUR",
    name = "Mortgage Configuration",
    purpose = summaryText,
    bookingText = "Mortgage Configuration",
    bookingKey = "MSC",
    transactionCode = 999,
    textKeyExtension = 0,
    booked = true,
    checkmark = false
  })
  
  print("Generated " .. #transactions .. " transactions (including " .. paymentsElapsed .. " payments)")
  print("Current balance: €" .. string.format("%.2f", currentBalance))
  
  return {
    balance = -currentBalance,
    transactions = transactions
  }
end

function EndSession()
  print("Mortgage Simulator: Session ended")
end

function readConfigFromAccount(account)
  local config = {
    principal = userPrincipal or 250000
  }
  
  if account.attributes then
    print("Reading configuration from Notes tab...")
    for key, value in pairs(account.attributes) do
      if key == "interestRate" then
        config.interestRate = tonumber(value)
      elseif key == "termYears" then
        config.termYears = tonumber(value)
      elseif key == "startDate" then
        config.startDate = value
      elseif key == "monthlyPayment" then
        config.monthlyPayment = value
      elseif key == "frequency" then
        config.frequency = value
      elseif key == "paymentDate" then
        config.paymentDate = tonumber(value)
      end
    end
  else
    print("No user-defined fields found in Notes tab")
  end
  
  return config
end

function isConfigurationComplete(config)
  return config.interestRate and config.interestRate > 0 and
         config.termYears and config.termYears > 0 and
         config.startDate and config.startDate ~= "" and
         config.monthlyPayment and config.monthlyPayment ~= "" and
         config.frequency and (config.frequency == "monthly" or config.frequency == "weekly")
end

function printMortgageConfig(config)
  print("  Principal: €" .. (config.principal or "NOT SET"))
  print("  Interest Rate: " .. (config.interestRate or "NOT SET") .. "%")
  print("  Term: " .. (config.termYears or "NOT SET") .. " years")
  print("  Start Date: " .. (config.startDate or "NOT SET"))
  print("  Monthly Payment: " .. (config.monthlyPayment or "NOT SET"))
  print("  Frequency: " .. (config.frequency or "NOT SET"))
  print("  Payment Date: " .. (config.paymentDate or "auto") .. " (day of month)")
end

function parseDate(dateStr)
  local year, month, day = string.match(dateStr, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if year and month and day then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = 10
    })
  end
  return nil
end

function calculateMonthlyPayment(principal, annualRate, termYears)
  local monthlyRate = (annualRate / 100) / 12
  local numPayments = termYears * 12
  
  if monthlyRate > 0 then
    local factor = (1 + monthlyRate) ^ numPayments
    return principal * (monthlyRate * factor) / (factor - 1)
  else
    return principal / numPayments
  end
end

function calculatePaymentsElapsed(startDate, currentDate, frequency)
  local secondsElapsed = currentDate - startDate
  local daysElapsed = secondsElapsed / (24 * 60 * 60)
  
  if frequency == "weekly" then
    return math.max(0, math.floor(daysElapsed / 7))
  else
    return math.max(0, math.floor(daysElapsed / 30.44))
  end
end

function generateAllTransactions(config, startTimestamp, paymentsElapsed)
  local transactions = {}
  local currentBalance = config.principal
  
  local paymentAmount = calculatePaymentAmount(config)
  
  for payment = 1, paymentsElapsed do
    local paymentDate = getPaymentDate(startTimestamp, payment, config.frequency, config.paymentDate)
    
    local periodRate = calculatePeriodRate(config.interestRate, config.frequency)
    local interestPayment = currentBalance * periodRate
    local principalPayment = paymentAmount - interestPayment
    
    if principalPayment > currentBalance then
      principalPayment = currentBalance
      interestPayment = paymentAmount - principalPayment
      paymentAmount = principalPayment + interestPayment
    end
    
    currentBalance = currentBalance - principalPayment
    
    table.insert(transactions, {
      bookingDate = paymentDate,
      valueDate = paymentDate,
      amount = paymentAmount,
      currency = "EUR",
      name = "Mortgage Payment Received",
      purpose = string.format("Payment #%d (%s)\nPrincipal: €%.2f, Interest: €%.2f\nRemaining: €%.2f", 
               payment, config.frequency, principalPayment, interestPayment, currentBalance),
      bookingText = "Payment Received",
      bookingKey = "MSC",
      transactionCode = 999,
      textKeyExtension = 0,
      booked = true,
      checkmark = false
    })
    
    table.insert(transactions, {
      bookingDate = paymentDate,
      valueDate = paymentDate,
      amount = -interestPayment,
      currency = "EUR",
      name = "Interest Charged",
      purpose = string.format("Payment #%d (%s) - Interest\nRate: %.2f%% per year\nAmount: €%.2f", 
               payment, config.frequency, config.interestRate, interestPayment),
      bookingText = "Interest Charged",
      bookingKey = "MSC",
      transactionCode = 999,
      textKeyExtension = 0,
      booked = true,
      checkmark = false
    })
  end
  
  table.sort(transactions, function(a, b) return a.bookingDate > b.bookingDate end)
  
  return transactions, currentBalance, paymentAmount
end

function calculatePaymentAmount(config)
  local monthlyPayment
  
  if config.monthlyPayment == "auto" then
    monthlyPayment = calculateMonthlyPayment(config.principal, config.interestRate, config.termYears)
  else
    monthlyPayment = tonumber(config.monthlyPayment)
  end
  
  if config.frequency == "weekly" then
    return monthlyPayment / 4.33
  else
    return monthlyPayment
  end
end

function calculatePeriodRate(annualRate, frequency)
  if frequency == "weekly" then
    return (annualRate / 100) / 52
  else
    return (annualRate / 100) / 12
  end
end

function getPaymentDate(startTimestamp, paymentNumber, frequency, paymentDate)
  local startYear = tonumber(os.date("%Y", startTimestamp))
  local startMonth = tonumber(os.date("%m", startTimestamp))
  local startDay = tonumber(os.date("%d", startTimestamp))
  
  if frequency == "weekly" then
    local weeksToAdd = paymentNumber - 1
    local secondsToAdd = weeksToAdd * 7 * 24 * 60 * 60
    return startTimestamp + secondsToAdd
  else
    -- Monthly payments
    local totalMonths = startMonth + paymentNumber - 1
    local year = startYear + math.floor(totalMonths / 12)
    local month = (totalMonths % 12) + 1
    
    if month == 0 then
      month = 12
      year = year - 1
    end
    
    -- Use custom payment date if specified, otherwise use start day
    local targetDay = paymentDate or startDay
    
    -- Get the last day of the target month
    local lastDayOfMonth = getLastDayOfMonth(year, month)
    
    -- Use the smaller of target day or last day of month
    local actualDay = math.min(targetDay, lastDayOfMonth)
    
    return os.time({
      year = year,
      month = month,
      day = actualDay,
      hour = 10
    })
  end
end

function getLastDayOfMonth(year, month)
  -- Days in each month (non-leap year)
  local daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  
  -- Check for leap year
  if month == 2 and isLeapYear(year) then
    return 29
  else
    return daysInMonth[month]
  end
end

function isLeapYear(year)
  return (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
end

-- SIGNATURE: MC0CFQCMortgageSimulatorClean=