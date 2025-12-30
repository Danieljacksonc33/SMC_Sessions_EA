// ============================================
// Market Condition Filter
// Detects trending vs choppy markets
// ============================================

enum MarketCondition { MARKET_TRENDING, MARKET_CHOPPY, MARKET_UNKNOWN };

// ADX parameters for trend detection (using globals from main file)
// g_ADX_Period, g_ADX_Level, g_ATR_Period are set in main file
// g_EnableMarketFilter, g_TradeOnlyTrending are set in main file

// Check market condition using ADX
MarketCondition CheckMarketCondition()
{
    if(!g_EnableMarketFilter) return MARKET_UNKNOWN;
    
    // Get ADX value (trend strength indicator) - MQL4 syntax
    // iADX(symbol, timeframe, period, applied_price, mode, shift)
    // For ADX, we use MODE_MAIN (the ADX line itself)
    double adx = iADX(Symbol(), PERIOD_H1, g_ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    
    if(adx <= 0) return MARKET_UNKNOWN; // Not enough data
    
    // ADX above threshold = trending market
    if(adx >= g_ADX_Level)
    {
        return MARKET_TRENDING;
    }
    else
    {
        return MARKET_CHOPPY;
    }
}

// Check if market is suitable for trading
bool IsMarketSuitable()
{
    if(!g_EnableMarketFilter) return true;
    
    MarketCondition condition = CheckMarketCondition();
    
    if(g_TradeOnlyTrending)
    {
        // Only trade in trending markets
        return (condition == MARKET_TRENDING);
    }
    else
    {
        // Trade in both conditions (but skip unknown)
        return (condition != MARKET_UNKNOWN);
    }
}

// Get ATR value for volatility check
double GetATR(int period = 14)
{
    return iATR(Symbol(), PERIOD_H1, period, 0);
}

// Check if volatility is acceptable (not too low, not too high)
bool IsVolatilityAcceptable()
{
    double atr = GetATR(g_ATR_Period);
    double point = Point;
    
    // Convert ATR to pips
    double atrPips = atr / point / 10;
    
    // Acceptable range: 10-100 pips (adjustable)
    if(atrPips < 10) return false; // Too low volatility
    if(atrPips > 100) return false; // Too high volatility
    
    return true;
}

// Get market condition string (for logging)
string GetMarketConditionString()
{
    MarketCondition condition = CheckMarketCondition();
    
    switch(condition)
    {
        case MARKET_TRENDING: return "TRENDING";
        case MARKET_CHOPPY: return "CHOPPY";
        default: return "UNKNOWN";
    }
}

