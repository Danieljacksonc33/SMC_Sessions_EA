// ============================================
// Change of Character (CHOCH) Detection
// ============================================

enum CHOCHType { CHOCH_BULL, CHOCH_BEAR, CHOCH_NONE };

// Find swing high (looks for local maximum)
double FindSwingHigh(int timeframe, int lookback = 5)
{
    if(iBars(NULL, timeframe) < lookback + 1) return 0;
    
    double centerHigh = iHigh(NULL, timeframe, 1);
    
    // Check if center bar is higher than surrounding bars
    bool isSwing = true;
    for(int i = 2; i <= lookback && i < iBars(NULL, timeframe); i++)
    {
        if(iHigh(NULL, timeframe, i) >= centerHigh)
        {
            isSwing = false;
            break;
        }
    }
    
    return isSwing ? centerHigh : 0;
}

// Find swing low (looks for local minimum)
double FindSwingLow(int timeframe, int lookback = 5)
{
    if(iBars(NULL, timeframe) < lookback + 1) return 0;
    
    double centerLow = iLow(NULL, timeframe, 1);
    
    // Check if center bar is lower than surrounding bars
    bool isSwing = true;
    for(int i = 2; i <= lookback && i < iBars(NULL, timeframe); i++)
    {
        if(iLow(NULL, timeframe, i) <= centerLow)
        {
            isSwing = false;
            break;
        }
    }
    
    return isSwing ? centerLow : 0;
}

CHOCHType CheckCHOCH()
{
    // Preconditions: sweep must have occurred
    if(!(SweepHighOccurred || SweepLowOccurred)) return CHOCH_NONE;
    
    // Need enough bars (using completed candles only - index 1+)
    if(iBars(NULL, PERIOD_H1) < 3) return CHOCH_NONE;
    if(iBars(NULL, PERIOD_M5) < 2) return CHOCH_NONE;
    
    // Find swing points on H1 (using closes for structure, not wicks)
    // Use previous completed H1 candles (index 1, 2, etc.)
    double lastHHClose = 0;
    double lastHLClose = 0;
    
    // Look for swing highs using CLOSES (candle-close based, not wick-based)
    int i; // Declare loop variable once at function scope
    double centerClose; // Declare variable once at function scope
    int j, k; // Declare nested loop variables once at function scope
    
    for(i = 1; i < 10 && i < iBars(NULL, PERIOD_H1); i++)
    {
        centerClose = iClose(NULL, PERIOD_H1, i);
        bool isSwingHigh = true;
        
        // Check if this close is higher than surrounding closes (completed candles)
        for(j = 1; j <= 2 && (i + j) < iBars(NULL, PERIOD_H1); j++)
        {
            if(iClose(NULL, PERIOD_H1, i + j) >= centerClose)
            {
                isSwingHigh = false;
                break;
            }
        }
        for(k = 1; k <= 2 && (i - k) >= 0; k++)
        {
            if(iClose(NULL, PERIOD_H1, i - k) >= centerClose)
            {
                isSwingHigh = false;
                break;
            }
        }
        
        if(isSwingHigh && centerClose > 0)
        {
            lastHHClose = centerClose;
            break; // Found most recent swing high close
        }
    }
    
    // Look for swing lows using CLOSES (candle-close based, not wick-based)
    for(i = 1; i < 10 && i < iBars(NULL, PERIOD_H1); i++)
    {
        centerClose = iClose(NULL, PERIOD_H1, i);
        bool isSwingLow = true;
        
        // Check if this close is lower than surrounding closes (completed candles)
        for(j = 1; j <= 2 && (i + j) < iBars(NULL, PERIOD_H1); j++)
        {
            if(iClose(NULL, PERIOD_H1, i + j) <= centerClose)
            {
                isSwingLow = false;
                break;
            }
        }
        for(k = 1; k <= 2 && (i - k) >= 0; k++)
        {
            if(iClose(NULL, PERIOD_H1, i - k) <= centerClose)
            {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingLow && centerClose > 0)
        {
            lastHLClose = centerClose;
            break; // Found most recent swing low close
        }
    }
    
    // Fallback: if no swing found, use previous H1 close
    if(lastHHClose <= 0) lastHHClose = iClose(NULL, PERIOD_H1, 1);
    if(lastHLClose <= 0) lastHLClose = iClose(NULL, PERIOD_H1, 1);
    
    // Use previous CLOSED M5 candle CLOSE (candle-close based, completed candle only - index 1)
    double m5Close = iClose(NULL, PERIOD_M5, 1);
    
    // Validate prices
    if(m5Close <= 0 || lastHHClose <= 0 || lastHLClose <= 0) return CHOCH_NONE;
    
    // Bullish CHOCH: M5 close breaks above last H1 swing high CLOSE (structure break up)
    // Candle-close based comparison
    if(m5Close > lastHHClose) return CHOCH_BULL;
    
    // Bearish CHOCH: M5 close breaks below last H1 swing low CLOSE (structure break down)
    // Candle-close based comparison
    if(m5Close < lastHLClose) return CHOCH_BEAR;
    
    // No valid CHOCH yet
    return CHOCH_NONE;
}

// Find Market Structure Shift (MSS)
// For bearish: Find Lower High (LH) - swing high after CHOCH that is lower than previous highs
// For bullish: Find Higher Low (HL) - swing low after CHOCH that is higher than previous lows
// Returns the price level of the MSS, or 0 if not found
double FindMSS(BiasType bias, int lookbackBars = 20)
{
    if(iBars(NULL, PERIOD_M5) < lookbackBars + 1) return 0;
    
    double mssLevel = 0;
    
    if(bias == BEARISH)
    {
        // Find Lower High (LH) - look for swing highs on M5 after CHOCH
        // A LH is a swing high that is lower than the previous swing high
        double previousHigh = 0;
        double currentHigh = 0;
        
        // Declare loop variables for this function scope
        int i1, j1, k1;
        
        // Look for swing highs (using wicks for structure points)
        for(i1 = 1; i1 < lookbackBars && i1 < iBars(NULL, PERIOD_M5); i1++)
        {
            double centerHigh = iHigh(NULL, PERIOD_M5, i1);
            bool isSwingHigh = true;
            
            // Check if this is a swing high (higher than 2 candles on each side)
            for(j1 = 1; j1 <= 2 && (i1 + j1) < iBars(NULL, PERIOD_M5); j1++)
            {
                if(iHigh(NULL, PERIOD_M5, i1 + j1) >= centerHigh)
                {
                    isSwingHigh = false;
                    break;
                }
            }
            for(k1 = 1; k1 <= 2 && (i1 - k1) >= 0; k1++)
            {
                if(iHigh(NULL, PERIOD_M5, i1 - k1) >= centerHigh)
                {
                    isSwingHigh = false;
                    break;
                }
            }
            
            if(isSwingHigh && centerHigh > 0)
            {
                if(previousHigh > 0)
                {
                    // Found a swing high, check if it's lower than previous
                    if(centerHigh < previousHigh)
                    {
                        // This is a Lower High (LH)
                        mssLevel = centerHigh;
                        break;
                    }
                }
                previousHigh = centerHigh;
                if(currentHigh == 0) currentHigh = centerHigh;
            }
        }
        
        // If no LH found but we have a swing high, use the most recent one as fallback
        if(mssLevel == 0 && currentHigh > 0)
        {
            mssLevel = currentHigh;
        }
    }
    else if(bias == BULLISH)
    {
        // Find Higher Low (HL) - look for swing lows on M5 after CHOCH
        // A HL is a swing low that is higher than the previous swing low
        double previousLow = DBL_MAX;
        double currentLow = 0;
        
        // Declare loop variables for this function scope
        int i2, j2, k2;
        
        // Look for swing lows (using wicks for structure points)
        for(i2 = 1; i2 < lookbackBars && i2 < iBars(NULL, PERIOD_M5); i2++)
        {
            double centerLow = iLow(NULL, PERIOD_M5, i2);
            bool isSwingLow = true;
            
            // Check if this is a swing low (lower than 2 candles on each side)
            for(j2 = 1; j2 <= 2 && (i2 + j2) < iBars(NULL, PERIOD_M5); j2++)
            {
                if(iLow(NULL, PERIOD_M5, i2 + j2) <= centerLow)
                {
                    isSwingLow = false;
                    break;
                }
            }
            for(k2 = 1; k2 <= 2 && (i2 - k2) >= 0; k2++)
            {
                if(iLow(NULL, PERIOD_M5, i2 - k2) <= centerLow)
                {
                    isSwingLow = false;
                    break;
                }
            }
            
            if(isSwingLow && centerLow > 0)
            {
                if(previousLow < DBL_MAX)
                {
                    // Found a swing low, check if it's higher than previous
                    if(centerLow > previousLow)
                    {
                        // This is a Higher Low (HL)
                        mssLevel = centerLow;
                        break;
                    }
                }
                previousLow = centerLow;
                if(currentLow == 0) currentLow = centerLow;
            }
        }
        
        // If no HL found but we have a swing low, use the most recent one as fallback
        if(mssLevel == 0 && currentLow > 0)
        {
            mssLevel = currentLow;
        }
    }
    
    return mssLevel;
}
