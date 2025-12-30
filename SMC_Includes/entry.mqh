
// ============================================
// Fair Value Gap (FVG) Calculation
// ============================================

void CalculateFVG()
{
    FVGReady = false;
    
    // Only after valid CHOCH
    CHOCHType choch = CheckCHOCH();
    if(choch == CHOCH_NONE) return;
    
    // Need at least 3 candles for FVG
    if(iBars(NULL, PERIOD_M5) < 3) return;
    
    // Get 3 candles: candle 2 (oldest), candle 1 (middle), candle 0 (newest)
    double high2 = iHigh(NULL, PERIOD_M5, 2);
    double low2  = iLow(NULL, PERIOD_M5, 2);
    double high1 = iHigh(NULL, PERIOD_M5, 1);
    double low1  = iLow(NULL, PERIOD_M5, 1);
    double high0 = iHigh(NULL, PERIOD_M5, 0);
    double low0  = iLow(NULL, PERIOD_M5, 0);
    
    // Validate prices
    if(high2 <= 0 || low2 <= 0 || high1 <= 0 || low1 <= 0 || high0 <= 0 || low0 <= 0)
        return;
    
    // Bullish FVG: gap between candle 2 high and candle 0 low
    // Candle 0's low should be above candle 2's high (gap up)
    if(choch == CHOCH_BULL)
    {
        if(low0 > high2) // Valid gap exists
        {
            FVGBottom = high2;  // Bottom of gap
            FVGTop = low0;      // Top of gap
            
            // Validate FVG
            if(FVGTop > FVGBottom)
            {
                // Check FVG quality (size filter) - optional enhancement
                #ifdef USE_FVG_QUALITY_FILTER
                double fvgSize = (FVGTop - FVGBottom) / _Point / 10; // Convert to pips
                if(fvgSize < 5 || fvgSize > 100) // Min 5 pips, max 100 pips
                {
                    FVGReady = false;
                    return;
                }
                #endif
                
                // Entry at 50% of FVG
                FVGEntry = (FVGTop + FVGBottom) / 2.0;
                FVGReady = true;
            }
        }
    }
    // Bearish FVG: gap between candle 2 low and candle 0 high
    // Candle 0's high should be below candle 2's low (gap down)
    else if(choch == CHOCH_BEAR)
    {
        if(high0 < low2) // Valid gap exists
        {
            FVGTop = low2;      // Top of gap
            FVGBottom = high0;  // Bottom of gap
            
            // Validate FVG
            if(FVGTop > FVGBottom)
            {
                // Check FVG quality (size filter) - optional enhancement
                #ifdef USE_FVG_QUALITY_FILTER
                double fvgSize = (FVGTop - FVGBottom) / _Point / 10; // Convert to pips
                if(fvgSize < 5 || fvgSize > 100) // Min 5 pips, max 100 pips
                {
                    FVGReady = false;
                    return;
                }
                #endif
                
                // Entry at 50% of FVG
                FVGEntry = (FVGTop + FVGBottom) / 2.0;
                FVGReady = true;
            }
        }
    }
}


