// ============================================
// Risk Management & Trade Placement
// ============================================

// Risk parameters
double RiskPercent = 0.5; // Max 0.5% per trade
#define STOP_BUFFER_PIPS 5  // Buffer for stop loss in pips

// Calculate lot size based on risk percentage
double CalculateLotSize(double entryPrice, double stopLoss, double riskPercent)
{
    double accountBalance = AccountBalance();
    if(accountBalance <= 0) return 0.01; // Minimum lot
    
    double riskAmount = accountBalance * (riskPercent / 100.0);
    double stopDistance = MathAbs(entryPrice - stopLoss);
    
    if(stopDistance <= 0) return 0.01; // Safety check
    
    // Get tick value
    double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    
    if(tickSize <= 0 || tickValue <= 0) return 0.01;
    
    // Calculate lot size
    double lots = (riskAmount / stopDistance) * (tickSize / tickValue);
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
    if(lots < minLot) lots = minLot;
    if(lots > maxLot) lots = maxLot;
    
    // Round to lot step
    lots = MathFloor(lots / lotStep) * lotStep;
    
    return lots;
}

// Check if order already exists
bool OrderExists()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && 
               (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT) &&
               StringFind(OrderComment(), "SMC") >= 0)
            {
                return true;
            }
        }
    }
    return false;
}

bool PlaceTrade(BiasType bias)
{
    if(!FVGReady) return false;
    
    // Validate Asian range
    if(AsiaHigh <= 0 || AsiaLow <= 0 || AsiaHigh <= AsiaLow) return false;
    
    // Validate FVG
    if(FVGTop <= FVGBottom || FVGEntry <= 0) return false;
    
    // Check if order already exists
    if(OrderExists())
    {
        LogTrade("Order already exists, skipping");
        return false;
    }
    
    // Calculate stop loss and take profit
    double stopLoss = 0;
    double takeProfit = 0;
    double stopBuffer = STOP_BUFFER_PIPS * _Point * 10; // Convert pips to price
    
    if(bias == BULLISH)
    {
        stopLoss = AsiaLow - stopBuffer;
        takeProfit = AsiaHigh + (AsiaHigh - AsiaLow); // HTF target (1:1 extension)
        
        // Validate prices
        if(stopLoss >= FVGEntry || takeProfit <= FVGEntry) return false;
    }
    else if(bias == BEARISH)
    {
        stopLoss = AsiaHigh + stopBuffer;
        takeProfit = AsiaLow - (AsiaHigh - AsiaLow); // HTF target (1:1 extension)
        
        // Validate prices
        if(stopLoss <= FVGEntry || takeProfit >= FVGEntry) return false;
    }
    else
    {
        return false;
    }
    
    // Calculate lot size based on risk
    double lotSize = CalculateLotSize(FVGEntry, stopLoss, RiskPercent);
    
    if(lotSize <= 0) return false;
    
    // Normalize prices
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    
    // Round prices to proper digits
    FVGEntry = NormalizeDouble(FVGEntry, digits);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    // Place Limit order at FVGEntry
    int ticket = 0;
    int slippage = 3;
    color orderColor = (bias == BULLISH) ? clrGreen : clrRed;
    string comment = (bias == BULLISH) ? "SMC Buy" : "SMC Sell";
    
    if(bias == BULLISH)
    {
        // Buy limit: entry must be below current price
        if(FVGEntry < ask)
        {
            ticket = OrderSend(Symbol(), OP_BUYLIMIT, lotSize, FVGEntry, slippage, 
                             stopLoss, takeProfit, comment, 0, 0, orderColor);
        }
    }
    else if(bias == BEARISH)
    {
        // Sell limit: entry must be above current price
        if(FVGEntry > bid)
        {
            ticket = OrderSend(Symbol(), OP_SELLLIMIT, lotSize, FVGEntry, slippage, 
                             stopLoss, takeProfit, comment, 0, 0, orderColor);
        }
    }
    
    // Check result
    if(ticket > 0)
    {
        return true;
    }
    else
    {
        int error = GetLastError();
        LogTrade("Order failed: Error " + IntegerToString(error));
        return false;
    }
}
