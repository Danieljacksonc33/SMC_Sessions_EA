// ============================================
// Backtesting Enhancements
// Improved Strategy Tester compatibility and reporting
// ============================================

// Check if running in Strategy Tester
bool IsBacktesting()
{
    return (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE));
}

// Enhanced logging for backtesting
void LogBacktestInfo(string message)
{
    if(IsBacktesting())
    {
        Print("[BACKTEST] " + message);
    }
    else
    {
        LogTrade(message);
    }
}

// Print backtest summary
void PrintBacktestSummary()
{
    if(!IsBacktesting()) return;
    
    string summary = "\n========================================\n";
    summary += "=== BACKTEST SUMMARY ===\n";
    summary += "========================================\n";
    summary += "Symbol: " + Symbol() + "\n";
    summary += "Period: " + PeriodToString(Period()) + "\n";
    summary += "Magic Number: " + IntegerToString(MagicNumber) + "\n";
    summary += "Risk Per Trade: " + DoubleToString(RiskPercent, 2) + "%\n";
    
    if(EnableMultiSessions)
    {
        summary += "Sessions: " + IntegerToString(g_SessionCount) + " enabled\n";
    }
    else
    {
        summary += "Session: " + IntegerToString(SessionStartHour) + ":00 - " + 
                   IntegerToString(SessionEndHour) + ":00 CST\n";
    }
    
    summary += "Market Filter: " + (EnableMarketFilter ? "ON" : "OFF") + "\n";
    summary += "Entry Filters: Volume=" + (EnableVolumeFilter ? "ON" : "OFF") + 
               " Momentum=" + (EnableMomentumFilter ? "ON" : "OFF") + 
               " S/R=" + (EnableSRFilter ? "ON" : "OFF") + "\n";
    summary += "========================================\n";
    
    Print(summary);
}

// Convert period to string
string PeriodToString(int period)
{
    switch(period)
    {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        default: return "Unknown";
    }
}

// Optimization note: Use the main EA parameters for Strategy Tester optimization
// The main parameters (SessionStartHour, SessionEndHour, RiskPercent, ADX_Level, etc.)
// can all be optimized directly in Strategy Tester - no separate Opt_ parameters needed

