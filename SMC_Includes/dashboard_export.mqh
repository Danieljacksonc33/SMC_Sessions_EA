// ============================================
// Dashboard Export - File-based Web Dashboard
// ============================================

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
    
    // Current time
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    json += "  \"currentTime\": \"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\",\n";
    
    // Session info
    int hour = GetCSTHour(TimeCurrent());
    bool inSession = IsTradingSession();
    json += "  \"session\": {\n";
    json += "    \"inSession\": " + (inSession ? "true" : "false") + ",\n";
    json += "    \"currentHour\": " + IntegerToString(hour) + ",\n";
    json += "    \"sessionStart\": " + IntegerToString(g_SessionStartHour) + ",\n";
    json += "    \"sessionEnd\": " + IntegerToString(g_SessionEndHour) + "\n";
    json += "  },\n";
    
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
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
                openCount++;
                double profit = OrderProfit() + OrderSwap() + OrderCommission();
                openProfit += profit;
                
                // Calculate profit in pips
                double point = Point;
                if(OrderType() == OP_BUY)
                    openProfitPips += (Bid - OrderOpenPrice()) / point / 10;
                else if(OrderType() == OP_SELL)
                    openProfitPips += (OrderOpenPrice() - Ask) / point / 10;
            }
        }
    }
    json += "    \"openTrades\": " + IntegerToString(openCount) + ",\n";
    json += "    \"openProfit\": " + DoubleToString(openProfit, 2) + ",\n";
    json += "    \"openProfitPips\": " + DoubleToString(openProfitPips, 1) + "\n";
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
    
    // Current price
    json += "  \"price\": {\n";
    json += "    \"bid\": " + DoubleToString(Bid, 5) + ",\n";
    json += "    \"ask\": " + DoubleToString(Ask, 5) + ",\n";
    json += "    \"spread\": " + DoubleToString((Ask - Bid) / Point / 10, 1) + "\n";
    json += "  }\n";
    
    json += "}\n";
    
    // Write to file (in MT4 data folder, Files subdirectory)
    int handle = FileOpen("SMC_Dashboard.json", FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileWriteString(handle, json);
        FileClose(handle);
    }
    else
    {
        // Log error for debugging
        int error = GetLastError();
        Print("Dashboard Export Error: Cannot open SMC_Dashboard.json file. Error code: ", error);
    }
}
