// ============================================
// Multi-Pair Trading Limit
// ============================================
// Limits trading to a maximum number of pairs simultaneously
// Once limit is reached, all EAs stop searching for new setups
//
// Note: MaxPairsTrading and g_MaxPairsTrading are defined in main file

// Count how many unique pairs currently have open trades (using Magic Number)
int CountTradingPairs(int magicNumber)
{
    string tradingPairs[];
    int pairCount = 0;
    
    // Count open trades across all symbols with this Magic Number
    int totalOrders = OrdersTotal();
    for(int i = totalOrders - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            // Check if this order belongs to our EA (same Magic Number)
            if(OrderMagicNumber() == magicNumber)
            {
                string orderSymbol = OrderSymbol();
                
                // Check if we've already counted this pair
                bool found = false;
                for(int j = 0; j < pairCount; j++)
                {
                    if(tradingPairs[j] == orderSymbol)
                    {
                        found = true;
                        break;
                    }
                }
                
                // If not found, add to our list
                if(!found)
                {
                    ArrayResize(tradingPairs, pairCount + 1);
                    tradingPairs[pairCount] = orderSymbol;
                    pairCount++;
                }
            }
        }
    }
    
    return pairCount;
}

// Check if we can trade (considering multi-pair limit)
bool CanTradeMultiPair(int magicNumber)
{
    if(g_MaxPairsTrading <= 0) return true; // No limit if set to 0 or negative
    
    int currentPairs = CountTradingPairs(magicNumber);
    string currentSymbol = Symbol();
    
    // Check if current symbol already has a trade
    bool currentPairHasTrade = false;
    int totalOrders = OrdersTotal();
    for(int i = totalOrders - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == currentSymbol && OrderMagicNumber() == magicNumber)
            {
                currentPairHasTrade = true;
                break;
            }
        }
    }
    
    // If current pair already has a trade, allow it (managing existing trade)
    if(currentPairHasTrade)
    {
        return true;
    }
    
    // If we're at the limit and current pair doesn't have a trade, block new trades
    if(currentPairs >= g_MaxPairsTrading)
    {
        // Log once per hour to avoid spam
        static datetime lastLog = 0;
        if(TimeCurrent() - lastLog > 3600)
        {
            string pairsList = "";
            for(int i = 0; i < currentPairs; i++)
            {
                // Get first trade for each pair to show which pairs are trading
                for(int j = OrdersTotal() - 1; j >= 0; j--)
                {
                    if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
                    {
                        if(OrderMagicNumber() == magicNumber)
                        {
                            pairsList += OrderSymbol() + " ";
                            break;
                        }
                    }
                }
            }
            LogTrade("Multi-pair limit reached: " + IntegerToString(currentPairs) + "/" + 
                    IntegerToString(g_MaxPairsTrading) + " pairs trading. Pairs: " + pairsList + 
                    ". Stopping new setup searches.");
            lastLog = TimeCurrent();
        }
        return false;
    }
    
    return true;
}

// Get list of pairs currently trading (for dashboard)
string GetTradingPairsList(int magicNumber)
{
    string pairsList = "";
    string tradingPairs[];
    int pairCount = 0;
    
    int totalOrders = OrdersTotal();
    for(int i = totalOrders - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == magicNumber)
            {
                string orderSymbol = OrderSymbol();
                
                bool found = false;
                for(int j = 0; j < pairCount; j++)
                {
                    if(tradingPairs[j] == orderSymbol)
                    {
                        found = true;
                        break;
                    }
                }
                
                if(!found)
                {
                    ArrayResize(tradingPairs, pairCount + 1);
                    tradingPairs[pairCount] = orderSymbol;
                    pairCount++;
                }
            }
        }
    }
    
    // Build comma-separated list
    for(int i = 0; i < pairCount; i++)
    {
        if(i > 0) pairsList += ", ";
        pairsList += tradingPairs[i];
    }
    
    if(pairsList == "") pairsList = "None";
    
    return pairsList;
}
