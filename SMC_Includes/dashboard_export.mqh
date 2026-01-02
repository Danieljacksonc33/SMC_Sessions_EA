// ============================================
// Dashboard Export - File-based Web Dashboard
// ============================================

// Helper function to format time in 12-hour format (AM/PM)
string FormatTime12Hour(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    int hour12 = dt.hour;
    string ampm = "AM";
    
    if(hour12 == 0)
        hour12 = 12; // Midnight
    else if(hour12 == 12)
        ampm = "PM"; // Noon
    else if(hour12 > 12)
    {
        hour12 -= 12;
        ampm = "PM";
    }
    
    string timeStr = StringFormat("%d:%02d %s", hour12, dt.min, ampm);
    return timeStr;
}

// Helper function to get CST time from broker time
datetime GetCSTTime(datetime brokerTime)
{
    // Use global variable from main file (g_TimezoneOffset) or default
    int tzOffset = TIMEZONE_OFFSET; // Default
    if(g_TimezoneOffset >= -12 && g_TimezoneOffset <= 14)
        tzOffset = g_TimezoneOffset;
    
    // Convert timezone offset from hours to seconds
    // CST = UTC-6, so if broker is UTC+2, offset = -8 to get CST
    // To convert broker time to CST: brokerTime + (offset * 3600 seconds)
    datetime cstTime = brokerTime + (tzOffset * 3600);
    
    return cstTime;
}

// Launch dashboard automatically (called once on init if autotrading enabled)
// Uses file-based trigger system since MQL4 cannot execute external programs directly
void LaunchDashboard()
{
    Print("LaunchDashboard() called - checking conditions...");
    
    // Check if autotrading is enabled
    bool autotradingEnabled = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
    bool isTesterMode = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE));
    
    Print("Autotrading enabled: ", autotradingEnabled ? "YES" : "NO");
    Print("IsTester mode: ", isTesterMode ? "YES" : "NO");
    
    // In Strategy Tester, TERMINAL_TRADE_ALLOWED may be false even when tester is running
    // So we allow trigger creation in tester mode regardless of TERMINAL_TRADE_ALLOWED
    if(!autotradingEnabled && !isTesterMode)
    {
        Print("LaunchDashboard: Autotrading not enabled and not in tester - skipping trigger creation");
        return; // Autotrading not enabled and not in tester, don't launch dashboard
    }
    
    if(isTesterMode)
    {
        Print("LaunchDashboard: Strategy Tester mode - will create trigger file");
    }
    
    // Get MT4 data folder path
    string mt4Path = TerminalInfoString(TERMINAL_PATH);
    if(StringLen(mt4Path) == 0)
    {
        return; // Can't get path
    }
    
    // Determine if we're in tester or live mode
    bool isTester = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE));
    Print("IsTester: ", isTester ? "YES" : "NO");
    
    string triggerFile = "";
    
    if(isTester)
    {
        // Strategy Tester: FileOpen() automatically writes to tester\files folder
        triggerFile = "LAUNCH_DASHBOARD_TESTER.trigger";
        Print("Strategy Tester mode detected - will create: " + triggerFile);
    }
    else
    {
        // Live trading: FileOpen() automatically writes to MQL4\Files folder
        triggerFile = "LAUNCH_DASHBOARD_LIVE.trigger";
        Print("Live trading mode detected - will create: " + triggerFile);
    }
    
    // Write trigger file to signal dashboard should be launched
    // Note: In Strategy Tester, FileOpen() automatically uses tester\files
    //       In Live trading, FileOpen() automatically uses MQL4\Files
    Print("Attempting to create trigger file: " + triggerFile);
    int handle = FileOpen(triggerFile, FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileWriteString(handle, "AUTO_LAUNCH_DASHBOARD");
        FileClose(handle);
        Print("SUCCESS: Dashboard launch trigger created: " + triggerFile);
        Print("Monitor script will detect this and launch dashboard automatically.");
    }
    else
    {
        int error = GetLastError();
        Print("ERROR: Could not create dashboard launch trigger file!");
        Print("Error code: ", error);
        Print("Tried to create: " + triggerFile);
        Print("IsTester: " + (isTester ? "true" : "false"));
        Print("MT4 Path: " + TerminalInfoString(TERMINAL_PATH));
    }
}

// Export EA status to JSON file for web dashboard
void ExportDashboardData()
{
    string json = "";
    json += "{\n";
    
    // Basic info
    json += "  \"timestamp\": " + IntegerToString(TimeCurrent()) + ",\n";
    json += "  \"symbol\": \"" + Symbol() + "\",\n";
    json += "  \"account\": " + IntegerToString(AccountNumber()) + ",\n";
    json += "  \"balance\": " + DoubleToString(AccountBalance(), 2) + ",\n";
    json += "  \"equity\": " + DoubleToString(AccountEquity(), 2) + ",\n";
    json += "  \"magicNumber\": " + IntegerToString(MagicNumber) + ",\n";
    
    // Current time (broker time)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    json += "  \"currentTime\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\",\n";
    
    // Calculate CST time
    datetime cstTime = GetCSTTime(TimeCurrent());
    MqlDateTime cstDt;
    TimeToStruct(cstTime, cstDt);
    
    // Format times in 12-hour format
    string brokerTime12hr = FormatTime12Hour(TimeCurrent());
    string cstTime12hr = FormatTime12Hour(cstTime);
    
    // Get CST hour for session checking
    int hour = GetCSTHour(TimeCurrent());
    
    // Timezone information section (all in 12-hour format for display)
    json += "  \"timezone\": {\n";
    json += "    \"brokerTime12hr\": \"" + brokerTime12hr + "\",\n";
    json += "    \"cstTime12hr\": \"" + cstTime12hr + "\",\n";
    json += "    \"displayTime\": \"" + brokerTime12hr + " (Broker) / " + cstTime12hr + " (CST)\",\n";
    json += "    \"brokerHour\": " + IntegerToString(dt.hour) + ",\n";
    json += "    \"cstHour\": " + IntegerToString(hour) + ",\n";
    json += "    \"timezoneOffset\": " + IntegerToString(g_TimezoneOffset) + ",\n";
    int brokerUTC = g_TimezoneOffset + 6; // CST is UTC-6, so broker UTC = offset + 6
    string offsetDesc = "CST UTC-6 - Broker UTC" + (brokerUTC >= 0 ? "+" : "") + IntegerToString(brokerUTC) + " = " + IntegerToString(g_TimezoneOffset);
    json += "    \"timezoneOffsetDescription\": \"" + offsetDesc + "\"\n";
    json += "  },\n";
    
    // Legacy fields for backward compatibility (12-hour format)
    json += "  \"brokerTime12hr\": \"" + brokerTime12hr + "\",\n";
    json += "  \"cstTime12hr\": \"" + cstTime12hr + "\",\n";
    
    // Simple top-level fields for dashboard compatibility (12-hour format)
    json += "  \"broker\": \"" + brokerTime12hr + "\",\n";
    json += "  \"cst\": \"" + cstTime12hr + "\",\n";
    json += "  \"brokerTime\": \"" + brokerTime12hr + "\",\n";
    json += "  \"cstTime\": \"" + cstTime12hr + "\",\n";
    
    // Session info (with 12-hour format display)
    bool inSession = IsTradingSession();
    
    // Format session times in 12-hour format
    string sessionStart12hr = "";
    string sessionEnd12hr = "";
    if(g_SessionStartHour == 0) sessionStart12hr = "12:00 AM";
    else if(g_SessionStartHour == 12) sessionStart12hr = "12:00 PM";
    else if(g_SessionStartHour < 12) sessionStart12hr = IntegerToString(g_SessionStartHour) + ":00 AM";
    else sessionStart12hr = IntegerToString(g_SessionStartHour - 12) + ":00 PM";
    
    if(g_SessionEndHour == 0) sessionEnd12hr = "12:00 AM";
    else if(g_SessionEndHour == 12) sessionEnd12hr = "12:00 PM";
    else if(g_SessionEndHour < 12) sessionEnd12hr = IntegerToString(g_SessionEndHour) + ":00 AM";
    else sessionEnd12hr = IntegerToString(g_SessionEndHour - 12) + ":00 PM";
    
    json += "  \"session\": {\n";
    json += "    \"inSession\": " + (inSession ? "true" : "false") + ",\n";
    json += "    \"currentHour\": " + IntegerToString(hour) + ",\n";
    json += "    \"currentTime12hr\": \"" + cstTime12hr + "\",\n";
    json += "    \"sessionStart\": " + IntegerToString(g_SessionStartHour) + ",\n";
    json += "    \"sessionStart12hr\": \"" + sessionStart12hr + "\",\n";
    json += "    \"sessionEnd\": " + IntegerToString(g_SessionEndHour) + ",\n";
    json += "    \"sessionEnd12hr\": \"" + sessionEnd12hr + "\",\n";
    json += "    \"sessionDisplay\": \"" + sessionStart12hr + " - " + sessionEnd12hr + " CST\"\n";
    json += "  },\n";
    
    // Log times to Experts tab (every 60 seconds when dashboard exports)
    static datetime lastTimeLog = 0;
    if(TimeCurrent() - lastTimeLog >= 60) // Log every 60 seconds to avoid spam
    {
        Print("=== Timezone Verification ===");
        Print("Broker Time (12hr): " + brokerTime12hr);
        Print("CST Time (12hr): " + cstTime12hr);
        Print("CST Hour: " + IntegerToString(hour));
        Print("Timezone Offset: " + IntegerToString(g_TimezoneOffset));
        Print("Session: " + sessionStart12hr + " - " + sessionEnd12hr + " CST");
        Print("In Session: " + (inSession ? "YES" : "NO"));
        Print("===========================");
        lastTimeLog = TimeCurrent();
    }
    
    // Asian range
    json += "  \"asianRange\": {\n";
    json += "    \"high\": " + (AsiaHigh > 0 ? DoubleToString(AsiaHigh, 5) : "null") + ",\n";
    json += "    \"low\": " + (AsiaLow > 0 ? DoubleToString(AsiaLow, 5) : "null") + ",\n";
    json += "    \"range\": " + (AsiaHigh > 0 && AsiaLow > 0 ? DoubleToString((AsiaHigh - AsiaLow) / Point / 10, 1) : "null") + ",\n";
    json += "    \"valid\": " + (AsiaHigh > 0 && AsiaLow > 0 && AsiaHigh > AsiaLow ? "true" : "false") + "\n";
    json += "  },\n";
    
    // Sweep status
    json += "  \"sweep\": {\n";
    json += "    \"highOccurred\": " + (SweepHighOccurred ? "true" : "false") + ",\n";
    json += "    \"lowOccurred\": " + (SweepLowOccurred ? "true" : "false") + ",\n";
    json += "    \"sweepTime\": " + (SweepCandleTime > 0 ? "\"" + TimeToString(SweepCandleTime, TIME_DATE|TIME_MINUTES) + "\"" : "null") + "\n";
    json += "  },\n";
    
    // Bias
    BiasType currentBias = HTFBias();
    string biasStr = "SIDEWAYS";
    if(currentBias == BULLISH) biasStr = "BULLISH";
    else if(currentBias == BEARISH) biasStr = "BEARISH";
    json += "  \"bias\": \"" + biasStr + "\",\n";
    
    // CHOCH
    CHOCHType choch = CheckCHOCH();
    string chochStr = "NONE";
    if(choch == CHOCH_BULL) chochStr = "BULLISH";
    else if(choch == CHOCH_BEAR) chochStr = "BEARISH";
    json += "  \"choch\": \"" + chochStr + "\",\n";
    
    // FVG
    json += "  \"fvg\": {\n";
    json += "    \"ready\": " + (FVGReady ? "true" : "false") + ",\n";
    json += "    \"top\": " + (FVGTop > 0 ? DoubleToString(FVGTop, 5) : "null") + ",\n";
    json += "    \"bottom\": " + (FVGBottom > 0 ? DoubleToString(FVGBottom, 5) : "null") + ",\n";
    json += "    \"entry\": " + (FVGEntry > 0 ? DoubleToString(FVGEntry, 5) : "null") + ",\n";
    json += "    \"size\": " + (FVGTop > 0 && FVGBottom > 0 ? DoubleToString((FVGTop - FVGBottom) / Point / 10, 1) : "null") + "\n";
    json += "  },\n";
    
    // Trade status
    json += "  \"tradeStatus\": {\n";
    json += "    \"takenToday\": " + (TradeTakenToday ? "true" : "false") + ",\n";
    json += "    \"maxTradesPerDay\": " + IntegerToString(g_MaxTradesPerDay) + ",\n";
    
    // Count open trades
    int openCount = 0;
    double openProfit = 0;
    double openProfitPips = 0;
    for(int oi = 0; oi < OrdersTotal(); oi++)
    {
        if(OrderSelect(oi, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                openCount++;
                double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
                openProfit += orderProfit;
                
                // Calculate profit in pips
                double orderPoint = Point;
                if(OrderType() == OP_BUY)
                    openProfitPips += (Bid - OrderOpenPrice()) / orderPoint / 10;
                else if(OrderType() == OP_SELL)
                    openProfitPips += (OrderOpenPrice() - Ask) / orderPoint / 10;
            }
        }
    }
    json += "    \"openTrades\": " + IntegerToString(openCount) + ",\n";
    json += "    \"openProfit\": " + DoubleToString(openProfit, 2) + ",\n";
    json += "    \"openProfitPips\": " + DoubleToString(openProfitPips, 1) + "\n";
    json += "  },\n";
    
    // Daily Trade Statistics (for current day)
    datetime todayStart = GetCurrentDate();
    int dailyTrades = 0;
    int dailyWins = 0;
    int dailyLosses = 0;
    double dailyProfit = 0;
    
    // Count today's closed trades
    int historyTotal1 = OrdersHistoryTotal();
    for(int h = historyTotal1 - 1; h >= 0; h--)
    {
        if(OrderSelect(h, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderCloseTime() >= todayStart)
            {
                dailyTrades++;
                double dailyOrderProfit = OrderProfit() + OrderSwap() + OrderCommission();
                dailyProfit += dailyOrderProfit;
                if(dailyOrderProfit > 0) dailyWins++;
                else if(dailyOrderProfit < 0) dailyLosses++;
            }
        }
    }
    
    // Add today's open trades to count (taken today)
    for(int o = 0; o < OrdersTotal(); o++)
    {
        if(OrderSelect(o, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderOpenTime() >= todayStart)
            {
                dailyTrades++;
            }
        }
    }
    
    json += "  \"dailyStats\": {\n";
    json += "    \"tradesToday\": " + IntegerToString(dailyTrades) + ",\n";
    json += "    \"winsToday\": " + IntegerToString(dailyWins) + ",\n";
    json += "    \"lossesToday\": " + IntegerToString(dailyLosses) + ",\n";
    json += "    \"profitToday\": " + DoubleToString(dailyProfit, 2) + ",\n";
    json += "    \"winRateToday\": " + (dailyTrades > 0 ? DoubleToString((double(dailyWins) / double(dailyTrades)) * 100.0, 1) : "0.0") + "\n";
    json += "  },\n";
    
    // Multi-pair limit status
    int currentPairs = CountTradingPairs(MagicNumber);
    string pairsList = GetTradingPairsList(MagicNumber);
    bool pairLimitReached = (g_MaxPairsTrading > 0 && currentPairs >= g_MaxPairsTrading);
    json += "  \"multiPairLimit\": {\n";
    json += "    \"enabled\": " + (g_MaxPairsTrading > 0 ? "true" : "false") + ",\n";
    json += "    \"maxPairs\": " + IntegerToString(g_MaxPairsTrading) + ",\n";
    json += "    \"currentPairs\": " + IntegerToString(currentPairs) + ",\n";
    json += "    \"limitReached\": " + (pairLimitReached ? "true" : "false") + ",\n";
    json += "    \"tradingPairs\": \"" + pairsList + "\"\n";
    json += "  },\n";
    
    // Statistics (using available functions only)
    json += "  \"statistics\": {\n";
    json += "    \"dailyWinRate\": " + DoubleToString(GetDailyWinRate(), 1) + ",\n";
    json += "    \"overallWinRate\": " + DoubleToString(GetWinRate(), 1) + ",\n";
    json += "    \"profitFactor\": " + DoubleToString(GetProfitFactor(), 2) + "\n";
    json += "  },\n";
    
    // News filter
    json += "  \"newsFilter\": {\n";
    json += "    \"enabled\": " + (g_EnableNewsFilter ? "true" : "false") + ",\n";
    bool newsBlocking = IsNewsTime();
    json += "    \"blocking\": " + (newsBlocking ? "true" : "false") + "\n";
    json += "  },\n";
    
    // Trade History - Recent closed trades
    json += "  \"tradeHistory\": [\n";
    int historyTotal2 = OrdersHistoryTotal();
    int tradeCount = 0;
    int maxTradesToShow = 20; // Show last 20 trades
    int bullishWins = 0, bullishLosses = 0;
    int bearishWins = 0, bearishLosses = 0;
    
    // Loop through history from most recent to oldest
    for(int hi = historyTotal2 - 1; hi >= 0 && tradeCount < maxTradesToShow; hi--)
    {
        if(OrderSelect(hi, SELECT_BY_POS, MODE_HISTORY))
        {
            // Only include trades for this symbol and magic number
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                if(tradeCount > 0) json += ",\n";
                
                string orderType = (OrderType() == OP_BUY) ? "BULLISH" : "BEARISH";
                double historyProfit = OrderProfit() + OrderSwap() + OrderCommission();
                bool isWin = (historyProfit > 0);
                
                // Count wins/losses by type
                if(OrderType() == OP_BUY)
                {
                    if(isWin) bullishWins++;
                    else bullishLosses++;
                }
                else
                {
                    if(isWin) bearishWins++;
                    else bearishLosses++;
                }
                
                // Calculate profit in pips
                double profitPips = 0;
                double historyPoint = Point;
                if(OrderType() == OP_BUY)
                    profitPips = (OrderClosePrice() - OrderOpenPrice()) / historyPoint / 10;
                else if(OrderType() == OP_SELL)
                    profitPips = (OrderOpenPrice() - OrderClosePrice()) / historyPoint / 10;
                
                json += "    {\n";
                json += "      \"ticket\": " + IntegerToString(OrderTicket()) + ",\n";
                json += "      \"type\": \"" + orderType + "\",\n";
                json += "      \"openTime\": \"" + TimeToString(OrderOpenTime(), TIME_DATE|TIME_MINUTES) + "\",\n";
                json += "      \"closeTime\": \"" + TimeToString(OrderCloseTime(), TIME_DATE|TIME_MINUTES) + "\",\n";
                json += "      \"openPrice\": " + DoubleToString(OrderOpenPrice(), 5) + ",\n";
                json += "      \"closePrice\": " + DoubleToString(OrderClosePrice(), 5) + ",\n";
                json += "      \"profit\": " + DoubleToString(historyProfit, 2) + ",\n";
                json += "      \"profitPips\": " + DoubleToString(profitPips, 1) + ",\n";
                json += "      \"isWin\": " + (isWin ? "true" : "false") + "\n";
                json += "    }";
                
                tradeCount++;
            }
        }
    }
    json += "\n  ],\n";
    
    // Trade History Summary
    json += "  \"tradeHistorySummary\": {\n";
    json += "    \"totalTrades\": " + IntegerToString(tradeCount) + ",\n";
    json += "    \"bullishWins\": " + IntegerToString(bullishWins) + ",\n";
    json += "    \"bullishLosses\": " + IntegerToString(bullishLosses) + ",\n";
    json += "    \"bearishWins\": " + IntegerToString(bearishWins) + ",\n";
    json += "    \"bearishLosses\": " + IntegerToString(bearishLosses) + ",\n";
    int historyTotalWins = bullishWins + bearishWins;
    int historyTotalLosses = bullishLosses + bearishLosses;
    json += "    \"totalWins\": " + IntegerToString(historyTotalWins) + ",\n";
    json += "    \"totalLosses\": " + IntegerToString(historyTotalLosses) + "\n";
    json += "  },\n";
    
    // Current price
    json += "  \"price\": {\n";
    json += "    \"bid\": " + DoubleToString(Bid, 5) + ",\n";
    json += "    \"ask\": " + DoubleToString(Ask, 5) + ",\n";
    json += "    \"spread\": " + DoubleToString((Ask - Bid) / Point / 10, 1) + "\n";
    json += "  }\n";
    
    json += "}\n";
    
    // Determine if we're in tester or live mode
    bool isTester = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE));
    string modeStr = isTester ? "Strategy Tester" : "Live Trading";
    
    // Write to file (in MT4 data folder, Files subdirectory)
    // Note: In Strategy Tester, FileOpen() automatically uses tester\files folder
    //       In Live trading, FileOpen() automatically uses MQL4\Files folder
    int handle = FileOpen("SMC_Dashboard.json", FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileWriteString(handle, json);
        FileClose(handle);
    }
    else
    {
        // Log error for debugging with mode information
        int error = GetLastError();
        
        // Create clear error message indicating which mode is being used
        string modeInfo = "";
        if(isTester)
        {
            modeInfo = "Dashboard being used by tester";
        }
        else
        {
            modeInfo = "Dashboard being used by live account";
        }
        
        string errorMsg = "Dashboard Export Error: Cannot open SMC_Dashboard.json file. Error code: " + IntegerToString(error) + ". " + modeInfo;
        
        Print(errorMsg);
    }
}
