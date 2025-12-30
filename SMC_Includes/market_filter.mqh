// ============================================
// Market Condition Filter
// Detects trending vs choppy markets
// ============================================

enum MarketCondition { MARKET_TRENDING, MARKET_CHOPPY, MARKET_UNKNOWN };

// ADX parameters for trend detection
int g_ADX_Period = 14;
int g_ADX_Level = 25; // Above this = trending

// ATR parameters for volatility
int g_ATR_Period = 14;

// Market condition filter
bool g_EnableMarketFilter = true;
bool g_TradeOnlyTrending = true; // If true, only trade in trending markets

// Check market condition using ADX
MarketCondition CheckMarketCondition()
{
    if(!g_EnableMarketFilter) return MARKET_UNKNOWN;
    
    // Get ADX value (trend strength indicator)
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

