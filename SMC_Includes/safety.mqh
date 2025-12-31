// ============================================
// Safety Features & Risk Management
// ============================================

// External variables (defined in main file, declared here for access)
// These will be available from main file's extern declarations

// Check if we can trade (safety checks)
bool CanTradeSafely()
{
    if(!g_EnableSafetyChecks) return true;
    
    // Check max trades per day
    int tradeCount = 0;
    datetime todayStart = GetCurrentDate();
    
    // Count open orders
    int totalOpen = OrdersTotal();
    for(int j = totalOpen - 1; j >= 0; j--)
    {
        if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && 
               StringFind(OrderComment(), "SMC") >= 0 &&
               OrderOpenTime() >= todayStart)
            {
                tradeCount++;
            }
        }
    }
    
    // Count closed trades today
    int totalHistory = OrdersHistoryTotal();
    for(int k = totalHistory - 1; k >= 0; k--)
    {
        if(OrderSelect(k, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && 
               StringFind(OrderComment(), "SMC") >= 0 &&
               OrderCloseTime() >= todayStart)
            {
                tradeCount++;
            }
        }
    }
    
    int maxTrades = (g_MaxTradesPerDay > 0) ? g_MaxTradesPerDay : 3;
    if(tradeCount >= maxTrades)
    {
        // Only log once per hour to avoid spam
        static datetime lastMaxTradesLog = 0;
        if(TimeCurrent() - lastMaxTradesLog > 3600) // Log once per hour
        {
            LogTrade("Max trades per day reached: " + IntegerToString(tradeCount) + "/" + IntegerToString(maxTrades));
            lastMaxTradesLog = TimeCurrent();
        }
        return false;
    }
    
    // Check daily loss limit (if statistics available)
    #ifdef USE_STATISTICS
    if(CheckDailyLossLimit(g_MaxDailyLossPercent))
        return false;
    #endif
    
    // Check drawdown (MQL4)
    double currentBalance = AccountBalance();
    double equity = AccountEquity();
    double peakBal = AccountBalance(); // Use current balance as peak (simplified)
    
    // Use equity for drawdown calculation
    // Use global variable from main file
    double maxDrawdownPct = g_MaxDrawdownPercent;
    if(maxDrawdownPct <= 0) maxDrawdownPct = 10.0; // Default if not set
    if(peakBal > 0 && maxDrawdownPct > 0)
    {
        double drawdown = ((peakBal - equity) / peakBal) * 100.0;
        if(drawdown >= maxDrawdownPct)
        {
            // Only log once per hour to avoid spam
            static datetime lastDrawdownLog = 0;
            if(TimeCurrent() - lastDrawdownLog > 3600) // Log once per hour
            {
                LogTrade("Max drawdown reached: " + DoubleToString(drawdown, 2) + "%");
                lastDrawdownLog = TimeCurrent();
            }
            return false;
        }
    }
    
    return true;
}

// Validate symbol before trading (MQL4)
bool ValidateSymbol()
{
    // Check if symbol is tradeable (MQL4)
    if(MarketInfo(Symbol(), MODE_TRADEALLOWED) == 0)
    {
        LogTrade("Symbol not tradeable: " + Symbol());
        return false;
    }
    
    // Check spread (MQL4)
    double spread = (Ask - Bid) / Point;
    
    // Log if spread is unusually high (warning only)
    if(spread > 30) // 3 pips for 5-digit broker
    {
        LogTrade("Warning: High spread detected: " + DoubleToString(spread/10, 1) + " pips");
    }
    
    return true;
}


