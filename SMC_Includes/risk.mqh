// ============================================
// Risk Management & Trade Placement
// ============================================

// Risk parameters (now using extern variables from main file)
// Default values if not set
#ifndef STOP_BUFFER_PIPS
#define STOP_BUFFER_PIPS 5  // Buffer for stop loss in pips
#endif

// Calculate lot size based on risk percentage
double CalculateLotSize(double entryPrice, double stopLoss, double riskPercent)
{
    double accountBalance = AccountBalance();
    if(accountBalance <= 0) return 0.01; // Minimum lot
    
    double riskAmount = accountBalance * (riskPercent / 100.0);
    double stopDistance = MathAbs(entryPrice - stopLoss);
    
    if(stopDistance <= 0) return 0.01; // Safety check
    
    // Get tick value (MQL4)
    double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
    
    if(tickSize <= 0 || tickValue <= 0) return 0.01;
    
    // Calculate lot size
    double lots = (riskAmount / stopDistance) * (tickSize / tickValue);
    
    // Normalize lot size (MQL4)
    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
    double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
    double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
    
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
               OrderMagicNumber() == MagicNumber &&
               (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT))
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
    int stopBufferPips = (StopBufferPips > 0) ? StopBufferPips : STOP_BUFFER_PIPS;
    double stopBuffer = stopBufferPips * _Point * 10; // Convert pips to price
    
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
    
    // Calculate lot size based on risk (use extern variable)
    double riskPct = (RiskPercent > 0) ? RiskPercent : 0.5;
    double lotSize = CalculateLotSize(FVGEntry, stopLoss, riskPct);
    
    if(lotSize <= 0) return false;
    
    // Normalize prices (MQL4)
    double ask = Ask;
    double bid = Bid;
    double point = Point;
    int digits = Digits;
    
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
                             stopLoss, takeProfit, comment, MagicNumber, 0, orderColor);
        }
    }
    else if(bias == BEARISH)
    {
        // Sell limit: entry must be above current price
        if(FVGEntry > bid)
        {
            ticket = OrderSend(Symbol(), OP_SELLLIMIT, lotSize, FVGEntry, slippage, 
                             stopLoss, takeProfit, comment, MagicNumber, 0, orderColor);
        }
    }
    
    // Check result
    if(ticket > 0)
    {
        // Send alert with order details
        string orderTypeStr = (bias == BULLISH) ? "BUY LIMIT" : "SELL LIMIT";
        AlertTradePlaced(orderTypeStr, lotSize, FVGEntry, stopLoss, takeProfit);
        return true;
    }
    else
    {
        int error = GetLastError();
        LogTrade("Order failed: Error " + IntegerToString(error));
        return false;
    }
}

