// ============================================
// Logging Functions
// ============================================

void LogTrade(string message)
{
    string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
    Print(timestamp + " : " + message);
}

