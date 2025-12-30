// ============================================
// Higher Timeframe Bias Detection
// ============================================

enum BiasType { BULLISH, BEARISH, SIDEWAYS };

BiasType HTFBias()
{
    // Validate we have enough bars
    if(iBars(NULL, PERIOD_H4) < 2) return SIDEWAYS;
    if(iBars(NULL, PERIOD_D1) < 2) return SIDEWAYS;
    
    // H4 data
    double lastClose = iClose(NULL, PERIOD_H4, 0);
    double prevClose = iClose(NULL, PERIOD_H4, 1);
    double lastHigh = iHigh(NULL, PERIOD_H4, 0);
    double lastLow = iLow(NULL, PERIOD_H4, 0);
    double prevHigh = iHigh(NULL, PERIOD_H4, 1);
    double prevLow = iLow(NULL, PERIOD_H4, 1);
    
    // D1 data for context
    double d1PrevLow = iLow(NULL, PERIOD_D1, 1);
    double d1PrevHigh = iHigh(NULL, PERIOD_D1, 1);
    
    // Validate prices
    if(lastClose <= 0 || prevClose <= 0) return SIDEWAYS;
    
    // Bullish: Higher close AND higher low (uptrend structure)
    if(lastClose > prevClose && lastLow >= prevLow && lastLow >= d1PrevLow)
        return BULLISH;

    // Bearish: Lower close AND lower high (downtrend structure)
    if(lastClose < prevClose && lastHigh <= prevHigh && lastHigh <= d1PrevHigh)
        return BEARISH;

    // Sideways / unclear
    return SIDEWAYS;
}
