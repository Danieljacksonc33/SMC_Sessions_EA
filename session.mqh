// ============================================
// Session Management
// ============================================

// Session filter for trading time
#define SESSION_START 2   // 2:00 AM CST
#define SESSION_END   5   // 5:00 AM CST

// Timezone offset (CST = UTC-8, adjust for your broker)
#define TIMEZONE_OFFSET -8

// Asian session range: 7:00 PM CST → 12:00 AM CST
#define ASIA_START 19
#define ASIA_END   24

// Cache for Asian range calculation
static datetime LastAsianCalcDate = 0;

// ============================================
// Helper Functions
// ============================================

// Convert broker time to CST hour
int GetCSTHour(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    int hour = dt.hour + TIMEZONE_OFFSET;
    if(hour < 0) hour += 24;
    else if(hour >= 24) hour -= 24;
    return hour;
}

// Get current date (midnight)
datetime GetCurrentDate()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    return StructToTime(dt);
}

// ============================================
// Trading Session Functions
// ============================================

// Function to check if it's the trading session
bool IsTradingSession()
{
    int hour = GetCSTHour(TimeCurrent());
    return (hour >= SESSION_START && hour < SESSION_END);
}

// Check if a trade can be taken today
bool CanTrade()
{
    return IsTradingSession() && !TradeTakenToday;
}

// ============================================
// Asian Range Calculation (Cached)
// ============================================

// Function to calculate the Asian High and Low (cached per day)
void CalculateAsianRange()
{
    datetime currentDate = GetCurrentDate();
    
    // Only recalculate if new day or not calculated yet
    if(currentDate == LastAsianCalcDate && AsiaHigh > 0 && AsiaLow > 0)
        return;
    
    // Reset values
    AsiaHigh = -1;
    AsiaLow = DBL_MAX;
    
    // Get today's date for Asian session
    MqlDateTime today;
    TimeToStruct(currentDate, today);
    
    // Calculate Asian session start/end for today
    datetime asiaStart = currentDate + (ASIA_START * 3600);
    datetime asiaEnd = currentDate + (ASIA_END * 3600);
    if(ASIA_END == 24) asiaEnd = currentDate + 86400; // Next day midnight
    
    // Get bars efficiently - only check recent bars (last 48 hours max)
    int maxBars = 48; // 48 hours = max bars to check
    int totalBars = iBars(NULL, PERIOD_H1);
    int barsToCheck = (totalBars < maxBars) ? totalBars : maxBars;
    
    bool foundAny = false;
    for(int i = 0; i < barsToCheck; i++)
    {
        datetime barTime = iTime(NULL, PERIOD_H1, i);
        
        // Check if bar is within Asian session
        if(barTime >= asiaStart && barTime < asiaEnd)
        {
            double high = iHigh(NULL, PERIOD_H1, i);
            double low  = iLow(NULL, PERIOD_H1, i);
            
            if(high > 0 && low > 0) // Validate prices
            {
                if(AsiaHigh < 0 || high > AsiaHigh) AsiaHigh = high;
                if(AsiaLow == DBL_MAX || low < AsiaLow) AsiaLow = low;
                foundAny = true;
            }
        }
    }
    
    // If no Asian session bars found, set invalid values
    if(!foundAny)
    {
        AsiaHigh = -1;
        AsiaLow = -1;
    }
    
    // Cache the calculation date
    LastAsianCalcDate = currentDate;
}

