// ============================================
// News Filter - Avoid Trading Around High Impact News
// ============================================

// External variables (declared in main file, accessible here)
// g_EnableNewsFilter, g_NewsAvoidBeforeMinutes, g_NewsAvoidAfterMinutes, g_CloseTradesBeforeNews are from main file
// MagicNumber is from main file
// GetCSTHour() is from session.mqh

// News event structure
struct NewsEvent
{
    int dayOfWeek;      // 0=Sunday, 1=Monday, ..., 6=Saturday
    int hour;           // Hour in CST (0-23)
    int minute;         // Minute (0-59)
    string eventName;   // Name of the news event (optional)
};

// Global news events array (can be expanded)
NewsEvent g_NewsEvents[];
int g_NewsCount = 0;

// High-Impact News Events (Hardcoded - Always Active)
// These are locked to 30 minutes before and 30 minutes after (non-negotiable)
// Based on REAL release patterns - not just day-of-week patterns

// FOMC Meeting Dates (2025) - 8 meetings per year, always Wednesday, 2:00 PM ET
// Format: month*100 + day (e.g., 129 = January 29, 319 = March 19)
// IMPORTANT: Update these dates annually based on Federal Reserve calendar
int g_FOMCDates[] = {129, 319, 507, 618, 730, 917, 1105, 1217}; // 2025 dates (UPDATE ANNUALLY)
int g_FOMCDateCount = 8;

// BOJ Meeting Dates (2025) - 8 meetings per year, typically Tue/Wed, late night/early morning CST
// Format: month*100 + day
// IMPORTANT: Update these dates annually based on BOJ calendar
int g_BOJDates[] = {128, 318, 426, 516, 715, 919, 1028, 1219}; // 2025 example dates (UPDATE ANNUALLY)
int g_BOJDateCount = 8;

// Check if current date matches FOMC date
bool IsFOMCDate(datetime currentTime)
{
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    int monthDay = dt.mon * 100 + dt.day;
    
    for(int i = 0; i < g_FOMCDateCount; i++)
    {
        if(g_FOMCDates[i] == monthDay) return true;
    }
    return false;
}

// Check if current date matches BOJ date
bool IsBOJDate(datetime currentTime)
{
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    int monthDay = dt.mon * 100 + dt.day;
    
    for(int i = 0; i < g_BOJDateCount; i++)
    {
        if(g_BOJDates[i] == monthDay) return true;
    }
    return false;
}

// Check if a specific time slot matches high-impact news pattern
// Parameters: currentTime (datetime), dayOfWeek (0=Sun, 1=Mon, ..., 5=Fri, 6=Sat), hour (0-23), minute (0-59)
bool IsHighImpactNewsTimeSlot(datetime currentTime, int dayOfWeek, int hour, int minute)
{
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    int dayOfMonth = dt.day;
    int month = dt.mon;
    
    // 1. NFP (Non-Farm Payrolls) - First Friday of month (Day <= 7)
    // Time: 8:30 AM ET = 7:30 AM CST (standard) or 8:30 AM CST (daylight)
    // Employment Report is same as NFP, so handled here
    if(dayOfWeek == 5 && dayOfMonth <= 7)
    {
        if((hour == 7 && minute == 30) || (hour == 8 && minute == 30)) return true; // NFP
    }
    
    // 2. CPI (Consumer Price Index) - Monthly, 10th-15th, Tuesday/Wednesday
    // Time: 8:30 AM ET = 7:30 AM CST (standard) or 8:30 AM CST (daylight)
    if((dayOfWeek == 2 || dayOfWeek == 3) && dayOfMonth >= 10 && dayOfMonth <= 15)
    {
        if((hour == 7 && minute == 30) || (hour == 8 && minute == 30)) return true; // CPI
    }
    
    // 3. PPI (Producer Price Index) - Monthly, 11th-16th, NOT CPI day
    // Time: 8:30 AM ET = 7:30 AM CST (standard) or 8:30 AM CST (daylight)
    // Released 1-2 days after CPI, avoid overlap with CPI
    bool isCPIDay = ((dayOfWeek == 2 || dayOfWeek == 3) && dayOfMonth >= 10 && dayOfMonth <= 15);
    if(!isCPIDay && dayOfMonth >= 11 && dayOfMonth <= 16)
    {
        // Check if it's Tuesday, Wednesday, or Thursday (typical PPI days)
        if((dayOfWeek == 2 || dayOfWeek == 3 || dayOfWeek == 4))
        {
            if((hour == 7 && minute == 30) || (hour == 8 && minute == 30)) return true; // PPI
        }
    }
    
    // 4. FOMC (Federal Open Market Committee) - 8 fixed dates per year, always Wednesday
    // Time: 2:00 PM ET = 1:00 PM CST (standard) or 2:00 PM CST (daylight)
    // EA Rule: Disable trading entire day (check any time on FOMC date)
    if(dayOfWeek == 3 && IsFOMCDate(currentTime))
    {
        // FOMC is at 2:00 PM ET, but we block entire day
        // Check if it's during trading hours or around announcement time
        if((hour == 13 && minute == 0) || (hour == 14 && minute == 0)) return true; // FOMC announcement time
        // Note: For full day blocking, we'll check this in IsHighImpactNewsTime() function
    }
    
    // 5. GDP (Advance) - Last Thursday of Jan/Apr/Jul/Oct (months 1, 4, 7, 10)
    // Time: 8:30 AM ET = 7:30 AM CST (standard) or 8:30 AM CST (daylight)
    if((month == 1 || month == 4 || month == 7 || month == 10) && dayOfWeek == 4 && dayOfMonth >= 25)
    {
        if((hour == 7 && minute == 30) || (hour == 8 && minute == 30)) return true; // GDP
    }
    
    // 6. Employment Report - Same as NFP (already handled above)
    
    // 7. BOJ Policy - 8 fixed dates per year, typically Tue/Wed, late night/early morning CST
    // Time: ~11:00 PM - 2:00 AM CST
    if(IsBOJDate(currentTime))
    {
        // Check if it's Tuesday or Wednesday, and during Asian session hours
        if((dayOfWeek == 2 || dayOfWeek == 3))
        {
            // Late night (11 PM - midnight) or early morning (midnight - 2 AM)
            if(hour == 23 || hour == 0 || hour == 1 || hour == 2) return true; // BOJ
        }
    }
    
    return false;
}

// Initialize news events (add common high-impact news times)
// Note: Times are in CST timezone
void InitNewsEvents()
{
    // Clear existing events
    ArrayResize(g_NewsEvents, 0);
    g_NewsCount = 0;
    
    // High-impact news events are checked dynamically via IsHighImpactNewsTimeSlot()
    // No need to add them to the array - they're always checked
    
    // User can still add custom news events via input parameters
}

// Add a news event (called from main file during initialization)
void AddNewsEvent(int dayOfWeek, int hour, int minute, string eventName = "")
{
    int newSize = g_NewsCount + 1;
    ArrayResize(g_NewsEvents, newSize);
    
    g_NewsEvents[g_NewsCount].dayOfWeek = dayOfWeek;
    g_NewsEvents[g_NewsCount].hour = hour;
    g_NewsEvents[g_NewsCount].minute = minute;
    g_NewsEvents[g_NewsCount].eventName = eventName;
    
    g_NewsCount++;
}

// Check if current time is within HIGH-IMPACT news avoidance window
// Returns true if we should avoid trading (ALWAYS ACTIVE - regardless of EnableNewsFilter setting)
// High-impact news: NFP, CPI, FOMC, PPI, GDP, Employment, BOJ
bool IsHighImpactNewsTime()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Get current CST hour and day
    int currentCSTHour = GetCSTHour(currentTime);
    int currentCSTMinute = dt.min;
    int currentDayOfWeek = dt.day_of_week; // 0=Sunday, 1=Monday, etc.
    int currentMinutes = (currentCSTHour * 60) + currentCSTMinute;
    
    // SPECIAL CASE: FOMC - Block entire day (not just 30 minutes)
    // FOMC volatility bleeds into Asia/London sessions
    if(IsFOMCDate(currentTime) && currentDayOfWeek == 3)
    {
        return true; // FOMC day - block entire day
    }
    
    // Check hardcoded high-impact news events (NFP, CPI, PPI, GDP, Employment, BOJ)
    // These are LOCKED to 30 minutes before and 30 minutes after (non-negotiable)
    // ALWAYS ACTIVE - regardless of EnableNewsFilter setting
    for(int offset = -30; offset <= 30; offset++) // Check every minute in the 30-minute window
    {
        int checkMinutes = currentMinutes - offset;
        datetime checkTime = currentTime - (offset * 60); // Subtract offset in seconds
        int checkDay = currentDayOfWeek;
        
        // Handle day wrap-around
        if(checkMinutes < 0)
        {
            checkMinutes += (24 * 60);
            checkTime = currentTime - (offset * 60);
            MqlDateTime checkDt;
            TimeToStruct(checkTime, checkDt);
            checkDay = checkDt.day_of_week;
        }
        else if(checkMinutes >= (24 * 60))
        {
            checkMinutes -= (24 * 60);
            checkTime = currentTime - (offset * 60);
            MqlDateTime checkDt;
            TimeToStruct(checkTime, checkDt);
            checkDay = checkDt.day_of_week;
        }
        
        int checkHour = checkMinutes / 60;
        int checkMin = checkMinutes % 60;
        
        // Use checkTime for date-based checks (NFP first Friday, CPI day range, etc.)
        MqlDateTime checkDt;
        TimeToStruct(checkTime, checkDt);
        checkDay = checkDt.day_of_week;
        
        // Check if this time slot is a high-impact news time
        if(IsHighImpactNewsTimeSlot(checkTime, checkDay, checkHour, checkMin))
        {
            return true; // Within 30-minute window of high-impact news - BLOCK TRADING
        }
    }
    
    return false; // No high-impact news nearby
}

// Check if current time is within news avoidance window
// Returns true if we should avoid trading (news is approaching or just passed)
bool IsNewsTime()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Get current CST hour and day
    int currentCSTHour = GetCSTHour(currentTime);
    int currentCSTMinute = dt.min;
    int currentDayOfWeek = dt.day_of_week; // 0=Sunday, 1=Monday, etc.
    int currentMinutes = (currentCSTHour * 60) + currentCSTMinute;
    
    // FIRST: ALWAYS check hardcoded high-impact news events (NFP, CPI, FOMC, PPI, GDP, Employment, BOJ)
    // These are ALWAYS ACTIVE regardless of EnableNewsFilter setting
    // Note: FOMC blocks entire day, others block 30 minutes before/after
    if(IsHighImpactNewsTime())
    {
        return true; // High-impact news - BLOCK TRADING
    }
    
    // SECOND: Check user-configured news events (custom news)
    // These are only active if EnableNewsFilter is true
    if(!g_EnableNewsFilter) return false;
    
    if(g_NewsCount > 0)
    {
        for(int i = 0; i < g_NewsCount; i++)
        {
            int newsDay = g_NewsEvents[i].dayOfWeek;
            int newsHour = g_NewsEvents[i].hour;
            int newsMinute = g_NewsEvents[i].minute;
            
            // Check if today matches the news day
            if(newsDay == currentDayOfWeek)
            {
                int newsMinutes = (newsHour * 60) + newsMinute;
                
                // Calculate time difference in minutes
                int diffMinutes = currentMinutes - newsMinutes;
                
                // User-configured news: Use configurable minutes
                int avoidBefore = (g_NewsAvoidBeforeMinutes > 0) ? g_NewsAvoidBeforeMinutes : 30;
                int avoidAfter = (g_NewsAvoidAfterMinutes > 0) ? g_NewsAvoidAfterMinutes : 60;
                
                if(diffMinutes >= -avoidBefore && diffMinutes <= avoidAfter)
                {
                    return true; // User-configured news window - avoid trading
                }
            }
        }
    }
    
    return false; // No news nearby, trading allowed
}

// Check if HIGH-IMPACT news is approaching (within 30 minutes before)
// Used to close existing trades
// ALWAYS ACTIVE - regardless of EnableNewsFilter setting
bool IsHighImpactNewsApproaching()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    int currentCSTHour = GetCSTHour(currentTime);
    int currentCSTMinute = dt.min;
    int currentDayOfWeek = dt.day_of_week;
    int currentMinutes = (currentCSTHour * 60) + currentCSTMinute;
    
    // FIRST: Check hardcoded high-impact news events (locked to 30 minutes before)
    // SPECIAL CASE: FOMC - Block entire day
    if(IsFOMCDate(currentTime) && currentDayOfWeek == 3)
    {
        return true; // FOMC day - news is approaching (entire day blocked)
    }
    
    for(int offset = 1; offset <= 30; offset++) // Check 1-30 minutes ahead
    {
        int checkMinutes = currentMinutes + offset;
        datetime checkTime = currentTime + (offset * 60); // Add offset in seconds
        int checkDay = currentDayOfWeek;
        
        // Handle day wrap-around
        if(checkMinutes >= (24 * 60))
        {
            checkMinutes -= (24 * 60);
            checkTime = currentTime + (offset * 60);
            MqlDateTime checkDt;
            TimeToStruct(checkTime, checkDt);
            checkDay = checkDt.day_of_week;
        }
        
        int checkHour = checkMinutes / 60;
        int checkMin = checkMinutes % 60;
        
        // Use checkTime for date-based checks
        MqlDateTime checkDt;
        TimeToStruct(checkTime, checkDt);
        checkDay = checkDt.day_of_week;
        
        // Check if this time slot is a high-impact news time
        if(IsHighImpactNewsTimeSlot(checkTime, checkDay, checkHour, checkMin))
        {
            return true; // High-impact news approaching within 30 minutes
        }
    }
    
    return false;
}

// Check if news is approaching (within 30 minutes before)
// Used to close existing trades
bool IsNewsApproaching()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    int currentCSTHour = GetCSTHour(currentTime);
    int currentCSTMinute = dt.min;
    int currentDayOfWeek = dt.day_of_week;
    int currentMinutes = (currentCSTHour * 60) + currentCSTMinute;
    
    // FIRST: ALWAYS check hardcoded high-impact news events (ALWAYS ACTIVE)
    if(IsHighImpactNewsApproaching())
    {
        return true; // High-impact news approaching
    }
    
    // SECOND: Check user-configured news events (only if EnableNewsFilter is true)
    if(!g_EnableNewsFilter) return false;
    
    if(g_NewsCount > 0)
    {
        for(int i = 0; i < g_NewsCount; i++)
        {
            int newsDay = g_NewsEvents[i].dayOfWeek;
            int newsHour = g_NewsEvents[i].hour;
            int newsMinute = g_NewsEvents[i].minute;
            
            if(newsDay == currentDayOfWeek)
            {
                int newsMinutes = (newsHour * 60) + newsMinute;
                int diffMinutes = newsMinutes - currentMinutes;
                
                // User-configured news: Use configurable minutes
                int avoidBefore = (g_NewsAvoidBeforeMinutes > 0) ? g_NewsAvoidBeforeMinutes : 30;
                if(diffMinutes > 0 && diffMinutes <= avoidBefore)
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}

// Close trades before news (at break-even or small profit)
// High-impact news: ALWAYS ACTIVE (closes trades before NFP, CPI, FOMC, etc.)
// User-configured news: Only if EnableNewsFilter is true and CloseTradesBeforeNews is enabled
void CloseTradesBeforeNews()
{
    // Always check high-impact news (regardless of EnableNewsFilter setting)
    // User-configured news only checked if EnableNewsFilter is true and CloseTradesBeforeNews is enabled
    if(!IsNewsApproaching()) return;
    
    int totalOrders = OrdersTotal();
    for(int i = totalOrders - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        
        // Only manage our EA's trades
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
        
        // Only manage market orders (filled positions)
        if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
        
        double openPrice = OrderOpenPrice();
        double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
        double point = Point;
        
        // Calculate profit in pips
        double profitPips = 0;
        if(OrderType() == OP_BUY)
            profitPips = (currentPrice - openPrice) / point / 10;
        else
            profitPips = (openPrice - currentPrice) / point / 10;
        
        // Close if at break-even or in profit (even small profit)
        if(profitPips >= -2.0) // Allow up to 2 pips loss to close
        {
            // Calculate profit in currency (for alert)
            double profit = OrderProfit() + OrderSwap() + OrderCommission();
            string orderType = (OrderType() == OP_BUY) ? "BUY" : "SELL";
            
            if(OrderClose(OrderTicket(), OrderLots(), currentPrice, 3))
            {
                LogTrade("Trade closed before news: Ticket " + IntegerToString(OrderTicket()) + 
                        " Profit: " + DoubleToString(profitPips, 1) + " pips");
                
                // Send alert
                if(g_EnableAlerts && g_AlertTradeClosed)
                {
                    AlertTradeClosed(OrderTicket(), orderType, profit, profitPips, "News approaching");
                }
            }
        }
    }
}

// Get news avoidance window status (for logging)
string GetNewsFilterStatus()
{
    if(IsNewsTime())
    {
        // Check if it's high-impact news (always active) or user-configured news
        bool isHighImpact = IsHighImpactNewsTime();
        
        if(IsNewsApproaching())
        {
            if(isHighImpact)
                return "High-impact news approaching (NFP/CPI/FOMC/PPI/GDP/Employment/BOJ) - Trading blocked (30 min before/after) [ALWAYS ACTIVE]";
            else
                return "News approaching - Trading blocked";
        }
        else
        {
            if(isHighImpact)
                return "High-impact news window (NFP/CPI/FOMC/PPI/GDP/Employment/BOJ) - Trading blocked (30 min before/after) [ALWAYS ACTIVE]";
            else
                return "News window - Trading blocked";
        }
    }
    
    // Show status: high-impact news is always active, user-configured depends on EnableNewsFilter
    if(!g_EnableNewsFilter)
        return "No news nearby - High-impact news filter: ALWAYS ACTIVE | User-configured news: Disabled";
    else
        return "No news nearby - Trading allowed";
}
