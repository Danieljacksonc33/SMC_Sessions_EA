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
    
    // Calculate stop loss and take profit using Fibonacci 0.618 level
    double stopLoss = 0;
    double takeProfit = 0;
    double point = Point;
    double pipValue = point * 10; // 1 pip in price terms
    
    // Calculate Asian range
    double asiaRange = AsiaHigh - AsiaLow;
    if(asiaRange <= 0) return false;
    
    // Maximum stop loss distance from entry (20 pips)
    double maxSLDistance = 20.0 * pipValue;
    
    // Fibonacci 0.618 level
    double fib618Level = 0;
    
    // Variables used in both BULLISH and BEARISH sections
    double slAtFib = 0;
    double slDistanceFromEntry = 0;
    double riskDistance = 0;
    
    if(bias == BULLISH)
    {
        // For BUY: 0.618 level = AsiaLow + 0.618 * (AsiaHigh - AsiaLow)
        fib618Level = AsiaLow + (0.618 * asiaRange);
        
        // Stop loss: 5 pips below 0.618 level
        slAtFib = fib618Level - (5.0 * pipValue);
        
        // Calculate distance from entry to SL at Fibonacci
        slDistanceFromEntry = FVGEntry - slAtFib;
        
        // Cap SL distance at maximum 20 pips from entry
        if(slDistanceFromEntry > maxSLDistance)
        {
            // If Fibonacci SL is more than 20 pips, use entry - 20 pips
            stopLoss = FVGEntry - maxSLDistance;
        }
        else
        {
            // Use Fibonacci level - 5 pips
            stopLoss = slAtFib;
        }
        
        // Calculate actual risk distance (entry to stop loss)
        riskDistance = FVGEntry - stopLoss;
        
        // First target (TP1): 2x the SL distance (1:2 risk/reward)
        takeProfit = FVGEntry + (riskDistance * 2.0);
        
        // Validate prices
        if(stopLoss >= FVGEntry || takeProfit <= FVGEntry) 
        {
            LogTrade("Invalid SL/TP for BUY: Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5) +
                    " Fib618=" + DoubleToString(fib618Level, 5));
            return false;
        }
    }
    else if(bias == BEARISH)
    {
        // For SELL: 0.618 level = AsiaHigh - 0.618 * (AsiaHigh - AsiaLow)
        fib618Level = AsiaHigh - (0.618 * asiaRange);
        
        // Stop loss: 5 pips above 0.618 level
        slAtFib = fib618Level + (5.0 * pipValue);
        
        // Calculate distance from entry to SL at Fibonacci
        slDistanceFromEntry = slAtFib - FVGEntry;
        
        // Cap SL distance at maximum 20 pips from entry
        if(slDistanceFromEntry > maxSLDistance)
        {
            // If Fibonacci SL is more than 20 pips, use entry + 20 pips
            stopLoss = FVGEntry + maxSLDistance;
        }
        else
        {
            // Use Fibonacci level + 5 pips
            stopLoss = slAtFib;
        }
        
        // Calculate actual risk distance (stop loss to entry)
        riskDistance = stopLoss - FVGEntry;
        
        // First target (TP1): 2x the SL distance (1:2 risk/reward)
        takeProfit = FVGEntry - (riskDistance * 2.0);
        
        // Validate prices
        if(stopLoss <= FVGEntry || takeProfit >= FVGEntry) 
        {
            LogTrade("Invalid SL/TP for SELL: Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5) +
                    " Fib618=" + DoubleToString(fib618Level, 5));
            return false;
        }
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
    // point already declared above
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

