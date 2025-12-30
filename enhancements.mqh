// ============================================
// ENHANCEMENTS FOR WIN RATE & MORE TRADES
// Include this file to add improvements
// ============================================

// ============================================
// Configuration Constants
// ============================================

// FVG Quality Filters
#define MIN_FVG_SIZE_PIPS 5      // Minimum FVG size in pips
#define MAX_FVG_SIZE_PIPS 100    // Maximum FVG size in pips

// Multiple TP Levels
#define TP1_PERCENT 50           // Close 50% at TP1
#define TP2_PERCENT 25           // Close 25% at TP2  
#define TP3_PERCENT 25           // Close 25% at TP3 (trailing)

// TP Multipliers (based on Asian range)
#define TP1_MULTIPLIER 1.0       // 1:1 R:R at Asian High/Low
#define TP2_MULTIPLIER 1.5       // 1.5x extension
#define TP3_MULTIPLIER 2.0       // 2x extension

// Stop Loss Improvement
#define USE_SWING_STOP true      // Use swing-based stop instead of Asian range
#define ATR_STOP_MULTIPLIER 0.5  // Use 0.5x ATR for stop buffer

// Multiple Sessions
#define ENABLE_LONDON_SESSION true
#define ENABLE_NY_SESSION true
#define MAX_TRADES_PER_DAY 3     // Allow multiple trades per day

// ============================================
// Enhanced Functions
// ============================================

// Check FVG quality (size filter)
bool IsFVGValid()
{
    if(!FVGReady) return false;
    if(FVGTop <= FVGBottom) return false;
    
    // Calculate FVG size in pips
    double fvgSize = (FVGTop - FVGBottom) / _Point / 10; // Convert to pips
    
    // Check minimum and maximum size
    if(fvgSize < MIN_FVG_SIZE_PIPS) return false;
    if(fvgSize > MAX_FVG_SIZE_PIPS) return false;
    
    return true;
}

// Get ATR value for volatility-based stops
double GetATR(int period = 14, int timeframe = PERIOD_H1)
{
    int handle = iATR(Symbol(), timeframe, period);
    if(handle == INVALID_HANDLE) return 0;
    
    double atr[1];
    if(CopyBuffer(handle, 0, 0, 1, atr) <= 0)
    {
        IndicatorRelease(handle);
        return 0;
    }
    
    IndicatorRelease(handle);
    return atr[0];
}

// Find swing low (for better stop placement)
double FindSwingLowForStop(int lookback = 10)
{
    if(iBars(NULL, PERIOD_H1) < lookback + 1) return 0;
    
    double lowest = DBL_MAX;
    int lowestIndex = -1;
    
    // Find lowest point in lookback period
    for(int i = 1; i <= lookback && i < iBars(NULL, PERIOD_H1); i++)
    {
        double low = iLow(NULL, PERIOD_H1, i);
        if(low < lowest)
        {
            lowest = low;
            lowestIndex = i;
        }
    }
    
    // Validate it's a swing (lower than surrounding bars)
    if(lowestIndex > 0 && lowestIndex < lookback)
    {
        double prevLow = iLow(NULL, PERIOD_H1, lowestIndex + 1);
        double nextLow = iLow(NULL, PERIOD_H1, lowestIndex - 1);
        
        if(lowest < prevLow && lowest < nextLow)
        {
            return lowest;
        }
    }
    
    return 0;
}

// Find swing high (for better stop placement)
double FindSwingHighForStop(int lookback = 10)
{
    if(iBars(NULL, PERIOD_H1) < lookback + 1) return 0;
    
    double highest = 0;
    int highestIndex = -1;
    
    // Find highest point in lookback period
    for(int i = 1; i <= lookback && i < iBars(NULL, PERIOD_H1); i++)
    {
        double high = iHigh(NULL, PERIOD_H1, i);
        if(high > highest)
        {
            highest = high;
            highestIndex = i;
        }
    }
    
    // Validate it's a swing (higher than surrounding bars)
    if(highestIndex > 0 && highestIndex < lookback)
    {
        double prevHigh = iHigh(NULL, PERIOD_H1, highestIndex + 1);
        double nextHigh = iHigh(NULL, PERIOD_H1, highestIndex - 1);
        
        if(highest > prevHigh && highest > nextHigh)
        {
            return highest;
        }
    }
    
    return 0;
}

// Calculate improved stop loss (swing-based or ATR-based)
double CalculateImprovedStopLoss(BiasType bias)
{
    double stopLoss = 0;
    
    if(USE_SWING_STOP)
    {
        if(bias == BULLISH)
        {
            double swingLow = FindSwingLowForStop(10);
            if(swingLow > 0 && swingLow < FVGEntry)
            {
                // Use swing low with ATR buffer
                double atr = GetATR(14, PERIOD_H1);
                double buffer = (atr > 0) ? atr * ATR_STOP_MULTIPLIER : (STOP_BUFFER_PIPS * _Point * 10);
                stopLoss = swingLow - buffer;
            }
            else
            {
                // Fallback to Asian low
                stopLoss = AsiaLow - (STOP_BUFFER_PIPS * _Point * 10);
            }
        }
        else if(bias == BEARISH)
        {
            double swingHigh = FindSwingHighForStop(10);
            if(swingHigh > 0 && swingHigh > FVGEntry)
            {
                // Use swing high with ATR buffer
                double atr = GetATR(14, PERIOD_H1);
                double buffer = (atr > 0) ? atr * ATR_STOP_MULTIPLIER : (STOP_BUFFER_PIPS * _Point * 10);
                stopLoss = swingHigh + buffer;
            }
            else
            {
                // Fallback to Asian high
                stopLoss = AsiaHigh + (STOP_BUFFER_PIPS * _Point * 10);
            }
        }
    }
    else
    {
        // Original method
        double stopBuffer = STOP_BUFFER_PIPS * _Point * 10;
        if(bias == BULLISH)
            stopLoss = AsiaLow - stopBuffer;
        else
            stopLoss = AsiaHigh + stopBuffer;
    }
    
    return stopLoss;
}

// Calculate multiple TP levels
void CalculateMultipleTPs(BiasType bias, double stopLoss, double &tp1, double &tp2, double &tp3)
{
    double asiaRange = AsiaHigh - AsiaLow;
    
    if(bias == BULLISH)
    {
        tp1 = AsiaHigh; // 1:1 at Asian high
        tp2 = AsiaHigh + (asiaRange * (TP2_MULTIPLIER - 1.0)); // 1.5x extension
        tp3 = AsiaHigh + (asiaRange * (TP3_MULTIPLIER - 1.0)); // 2x extension
    }
    else if(bias == BEARISH)
    {
        tp1 = AsiaLow; // 1:1 at Asian low
        tp2 = AsiaLow - (asiaRange * (TP2_MULTIPLIER - 1.0)); // 1.5x extension
        tp3 = AsiaLow - (asiaRange * (TP3_MULTIPLIER - 1.0)); // 2x extension
    }
}

// Check if we can take another trade today (multiple trades per day)
bool CanTakeAnotherTrade()
{
    if(!ENABLE_LONDON_SESSION && !ENABLE_NY_SESSION)
    {
        // Original: only 1 trade per day
        return !TradeTakenToday;
    }
    
    // Count existing SMC trades today
    int tradeCount = 0;
    datetime todayStart = GetCurrentDate();
    
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && 
               StringFind(OrderComment(), "SMC") >= 0 &&
               OrderOpenTime() >= todayStart)
            {
                tradeCount++;
            }
        }
    }
    
    // Also check history for today
    for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            if(OrderSymbol() == Symbol() && 
               StringFind(OrderComment(), "SMC") >= 0 &&
               OrderCloseTime() >= todayStart)
            {
                tradeCount++;
            }
        }
    }
    
    return (tradeCount < MAX_TRADES_PER_DAY);
}

// Check if current session is active (for multiple sessions)
bool IsCurrentSessionActive()
{
    int hour = GetCSTHour(TimeCurrent());
    
    // Asian session (original)
    if(hour >= SESSION_START && hour < SESSION_END)
        return true;
    
    // London session
    if(ENABLE_LONDON_SESSION)
    {
        if(hour >= 8 && hour < 12) // 8 AM - 12 PM CST
            return true;
    }
    
    // New York session
    if(ENABLE_NY_SESSION)
    {
        if(hour >= 14 && hour < 18) // 2 PM - 6 PM CST
            return true;
    }
    
    return false;
}

// Enhanced CanTrade function (supports multiple sessions)
bool CanTradeEnhanced()
{
    if(!IsCurrentSessionActive()) return false;
    if(!CanTakeAnotherTrade()) return false;
    return true;
}

