// ============================================
// Additional Entry Confirmation Filters
// Volume, Momentum, Support/Resistance
// ============================================

// Filter settings (using globals from main file)
// g_EnableVolumeFilter, g_EnableMomentumFilter, g_EnableSRFilter are set in main file
// g_VolumePeriod, g_VolumeMultiplier, g_MomentumPeriod, g_MomentumLevel
// g_SRLookback, g_SRBufferPips are set in main file

// Check volume confirmation
bool CheckVolumeConfirmation()
{
    if(!g_EnableVolumeFilter) return true;
    
    // Get current volume (tick volume)
    long currentVolume = iVolume(Symbol(), PERIOD_M5, 0);
    
    // Calculate average volume
    long totalVolume = 0;
    for(int i = 1; i <= g_VolumePeriod; i++)
    {
        totalVolume += iVolume(Symbol(), PERIOD_M5, i);
    }
    double avgVolume = (double)totalVolume / (double)g_VolumePeriod;
    
    // Check if current volume is above threshold
    if(avgVolume <= 0) return true; // Can't calculate, allow trade
    
    double volumeRatio = (double)currentVolume / avgVolume;
    
    return (volumeRatio >= g_VolumeMultiplier);
}

// Check momentum confirmation using RSI
bool CheckMomentumConfirmation(BiasType bias)
{
    if(!g_EnableMomentumFilter) return true;
    
    // Get RSI value - MQL4 syntax
    double rsi = iRSI(Symbol(), PERIOD_M5, g_MomentumPeriod, PRICE_CLOSE, 0);
    
    if(rsi <= 0) return true; // Can't calculate, allow trade
    
    // For bullish bias, RSI should be above level (showing upward momentum)
    if(bias == BULLISH)
    {
        return (rsi >= g_MomentumLevel);
    }
    // For bearish bias, RSI should be below (100 - level) (showing downward momentum)
    else if(bias == BEARISH)
    {
        return (rsi <= (100 - g_MomentumLevel));
    }
    
    return true;
}

// Find nearest support/resistance level
double FindNearestSR(bool findSupport, int lookback)
{
    double currentPrice = (Ask + Bid) / 2.0;
    double nearestLevel = 0;
    double minDistance = DBL_MAX;
    
    // Look for swing highs (resistance) or swing lows (support)
    for(int i = 1; i < lookback && i < iBars(Symbol(), PERIOD_H1); i++)
    {
        double level = 0;
        
        if(findSupport)
        {
            // Find support (swing low)
            level = iLow(Symbol(), PERIOD_H1, i);
            
            // Check if it's a swing low (lower than surrounding bars)
            bool isSwingLow = true;
            for(int j1 = 1; j1 <= 3 && (i + j1) < iBars(Symbol(), PERIOD_H1); j1++)
            {
                if(iLow(Symbol(), PERIOD_H1, i + j1) < level)
                {
                    isSwingLow = false;
                    break;
                }
            }
            for(int j2 = 1; j2 <= 3 && (i - j2) >= 0; j2++)
            {
                if(iLow(Symbol(), PERIOD_H1, i - j2) < level)
                {
                    isSwingLow = false;
                    break;
                }
            }
            
            if(!isSwingLow) continue;
        }
        else
        {
            // Find resistance (swing high)
            level = iHigh(Symbol(), PERIOD_H1, i);
            
            // Check if it's a swing high
            bool isSwingHigh = true;
            for(int j3 = 1; j3 <= 3 && (i + j3) < iBars(Symbol(), PERIOD_H1); j3++)
            {
                if(iHigh(Symbol(), PERIOD_H1, i + j3) > level)
                {
                    isSwingHigh = false;
                    break;
                }
            }
            for(int j4 = 1; j4 <= 3 && (i - j4) >= 0; j4++)
            {
                if(iHigh(Symbol(), PERIOD_H1, i - j4) > level)
                {
                    isSwingHigh = false;
                    break;
                }
            }
            
            if(!isSwingHigh) continue;
        }
        
        // Calculate distance
        double distance = MathAbs(currentPrice - level);
        if(distance < minDistance)
        {
            minDistance = distance;
            nearestLevel = level;
        }
    }
    
    return nearestLevel;
}

// Check if price is too close to support/resistance
bool CheckSRLevels(double entryPrice, BiasType bias)
{
    if(!g_EnableSRFilter) return true;
    
    double point = Point;
    double buffer = g_SRBufferPips * point * 10;
    
    if(bias == BULLISH)
    {
        // For buy trades, check if entry is too close to resistance above
        double resistance = FindNearestSR(false, g_SRLookback);
        if(resistance > 0 && (resistance - entryPrice) < buffer)
        {
            return false; // Too close to resistance
        }
    }
    else if(bias == BEARISH)
    {
        // For sell trades, check if entry is too close to support below
        double support = FindNearestSR(true, g_SRLookback);
        if(support > 0 && (entryPrice - support) < buffer)
        {
            return false; // Too close to support
        }
    }
    
    return true;
}

// Check all entry confirmations
bool CheckAllEntryConfirmations(BiasType bias, double entryPrice)
{
    // Volume confirmation
    if(!CheckVolumeConfirmation())
    {
        LogTrade("Entry filter: Volume confirmation failed");
        return false;
    }
    
    // Momentum confirmation
    if(!CheckMomentumConfirmation(bias))
    {
        LogTrade("Entry filter: Momentum confirmation failed");
        return false;
    }
    
    // Support/Resistance check
    if(!CheckSRLevels(entryPrice, bias))
    {
        LogTrade("Entry filter: Too close to S/R level");
        return false;
    }
    
    return true;
}

