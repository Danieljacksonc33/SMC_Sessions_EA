// ============================================
// Multiple Session Support
// Allows trading during multiple time windows
// ============================================

// Session structure
struct TradingSession
{
    int startHour;
    int endHour;
    bool enabled;
};

// Global sessions array (up to 5 sessions)
TradingSession g_Sessions[5];
int g_SessionCount = 0;

// Initialize multiple sessions
void InitMultipleSessions()
{
    g_SessionCount = 0;
    
    // Session 1 (default: 2-5 AM CST)
    if(g_MultiSession1_Enabled)
    {
        g_Sessions[g_SessionCount].startHour = g_MultiSession1_Start;
        g_Sessions[g_SessionCount].endHour = g_MultiSession1_End;
        g_Sessions[g_SessionCount].enabled = true;
        g_SessionCount++;
    }
    
    // Session 2 (optional: 8-11 AM CST - London)
    if(g_MultiSession2_Enabled)
    {
        g_Sessions[g_SessionCount].startHour = g_MultiSession2_Start;
        g_Sessions[g_SessionCount].endHour = g_MultiSession2_End;
        g_Sessions[g_SessionCount].enabled = true;
        g_SessionCount++;
    }
    
    // Session 3 (optional: 2-5 PM CST - New York)
    if(g_MultiSession3_Enabled)
    {
        g_Sessions[g_SessionCount].startHour = g_MultiSession3_Start;
        g_Sessions[g_SessionCount].endHour = g_MultiSession3_End;
        g_Sessions[g_SessionCount].enabled = true;
        g_SessionCount++;
    }
    
    // Session 4 (optional)
    if(g_MultiSession4_Enabled)
    {
        g_Sessions[g_SessionCount].startHour = g_MultiSession4_Start;
        g_Sessions[g_SessionCount].endHour = g_MultiSession4_End;
        g_Sessions[g_SessionCount].enabled = true;
        g_SessionCount++;
    }
    
    // Session 5 (optional)
    if(g_MultiSession5_Enabled)
    {
        g_Sessions[g_SessionCount].startHour = g_MultiSession5_Start;
        g_Sessions[g_SessionCount].endHour = g_MultiSession5_End;
        g_Sessions[g_SessionCount].enabled = true;
        g_SessionCount++;
    }
    
    // If no multi-sessions enabled, use default single session
    if(g_SessionCount == 0)
    {
        g_Sessions[0].startHour = g_SessionStartHour;
        g_Sessions[0].endHour = g_SessionEndHour;
        g_Sessions[0].enabled = true;
        g_SessionCount = 1;
    }
}

// Check if current time is within any trading session
bool IsAnyTradingSession()
{
    int hour = GetCSTHour(TimeCurrent());
    
    for(int i = 0; i < g_SessionCount; i++)
    {
        if(!g_Sessions[i].enabled) continue;
        
        int start = g_Sessions[i].startHour;
        int end = g_Sessions[i].endHour;
        
        // Handle sessions that cross midnight
        if(start < end)
        {
            if(hour >= start && hour < end)
                return true;
        }
        else // Session crosses midnight (e.g., 22-2)
        {
            if(hour >= start || hour < end)
                return true;
        }
    }
    
    return false;
}

// Get current session name (for logging/analytics)
string GetCurrentSessionName()
{
    int hour = GetCSTHour(TimeCurrent());
    
    for(int i = 0; i < g_SessionCount; i++)
    {
        if(!g_Sessions[i].enabled) continue;
        
        int start = g_Sessions[i].startHour;
        int end = g_Sessions[i].endHour;
        
        bool inSession = false;
        if(start < end)
        {
            inSession = (hour >= start && hour < end);
        }
        else
        {
            inSession = (hour >= start || hour < end);
        }
        
        if(inSession)
        {
            return "Session" + IntegerToString(i + 1) + "_" + 
                   IntegerToString(start) + "-" + IntegerToString(end);
        }
    }
    
    return "None";
}

