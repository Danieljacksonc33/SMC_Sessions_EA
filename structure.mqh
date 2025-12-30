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
    
    // Need enough bars
    if(iBars(NULL, PERIOD_H1) < 3) return CHOCH_NONE;
    if(iBars(NULL, PERIOD_M5) < 2) return CHOCH_NONE;
    
    // Find actual swing points on H1
    double lastHH = FindSwingHigh(PERIOD_H1, 3);
    double lastHL = FindSwingLow(PERIOD_H1, 3);
    
    // Fallback to previous bar if no swing found
    if(lastHH <= 0) lastHH = iHigh(NULL, PERIOD_H1, 1);
    if(lastHL <= 0) lastHL = iLow(NULL, PERIOD_H1, 1);
    
    // Use previous closed M5 candle
    double currentClose = iClose(NULL, PERIOD_M5, 1);
    
    // Validate prices
    if(currentClose <= 0 || lastHH <= 0 || lastHL <= 0) return CHOCH_NONE;
    
    // Bullish CHOCH: breaks last swing high (structure break up)
    if(currentClose > lastHH) return CHOCH_BULL;
    
    // Bearish CHOCH: breaks last swing low (structure break down)
    if(currentClose < lastHL) return CHOCH_BEAR;
    
    // No valid CHOCH yet
    return CHOCH_NONE;
}

