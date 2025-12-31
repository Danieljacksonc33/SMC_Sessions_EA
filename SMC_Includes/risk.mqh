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
    double point = Point;
    double pipValue = point * 10; // 1 pip in price terms
    
    // Variable for risk distance (used in both manual and automatic modes)
    double riskDistance = 0;
    
    // Check if manual stop loss or take profit override is enabled
    if(g_UseManualStopLoss && g_ManualStopLossPips > 0)
    {
        // Use manual stop loss (simple distance from entry)
        double manualSLDistance = g_ManualStopLossPips * pipValue;
        
        if(bias == BULLISH)
        {
            stopLoss = FVGEntry - manualSLDistance;
            riskDistance = manualSLDistance;
            
            // Use manual TP if enabled, otherwise use 1:2 R:R
            if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
            {
                takeProfit = FVGEntry + (g_ManualTakeProfitPips * pipValue);
            }
            else
            {
                takeProfit = FVGEntry + (riskDistance * 2.0); // 1:2 R:R
            }
        }
        else if(bias == BEARISH)
        {
            stopLoss = FVGEntry + manualSLDistance;
            riskDistance = manualSLDistance;
            
            // Use manual TP if enabled, otherwise use 1:2 R:R
            if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
            {
                takeProfit = FVGEntry - (g_ManualTakeProfitPips * pipValue);
            }
            else
            {
                takeProfit = FVGEntry - (riskDistance * 2.0); // 1:2 R:R
            }
        }
        else
        {
            return false;
        }
        
        // Validate manual SL/TP
        if((bias == BULLISH && (stopLoss >= FVGEntry || takeProfit <= FVGEntry)) ||
           (bias == BEARISH && (stopLoss <= FVGEntry || takeProfit >= FVGEntry)))
        {
            LogTrade("Invalid manual SL/TP: Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5));
            return false;
        }
        
        // Skip Fibonacci calculation, proceed to lot size calculation
    }
    else if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
    {
        // Manual TP only (SL still uses automatic MSS-based calculation)
        // Note: This section should also use MSS-based SL, but keeping old Fibonacci logic as fallback
        // Calculate Asian range for automatic SL (old logic - should be updated to MSS)
        double asiaRange = AsiaHigh - AsiaLow;
        if(asiaRange <= 0) return false;
        
        // Maximum stop loss distance from entry (20 pips) - declare once at function scope
        // (maxSLDistance will be redeclared in else block, but they're in separate blocks)
        double maxSLDistanceTP = 20.0 * pipValue;
        
        // Fibonacci 0.618 level
        double fib618Level = 0;
        double slAtFib = 0;
        double slDistanceFromEntry = 0;
        
        if(bias == BULLISH)
        {
            // For BUY: 0.618 level = AsiaLow + 0.618 * (AsiaHigh - AsiaLow)
            fib618Level = AsiaLow + (0.618 * asiaRange);
            slAtFib = fib618Level - (5.0 * pipValue);
            slDistanceFromEntry = FVGEntry - slAtFib;
            
            if(slDistanceFromEntry > maxSLDistanceTP)
            {
                stopLoss = FVGEntry - maxSLDistanceTP;
            }
            else
            {
                stopLoss = slAtFib;
            }
            
            riskDistance = FVGEntry - stopLoss;
            // Use manual TP
            takeProfit = FVGEntry + (g_ManualTakeProfitPips * pipValue);
        }
        else if(bias == BEARISH)
        {
            // For SELL: 0.618 level = AsiaHigh - 0.618 * (AsiaHigh - AsiaLow)
            fib618Level = AsiaHigh - (0.618 * asiaRange);
            slAtFib = fib618Level + (5.0 * pipValue);
            slDistanceFromEntry = slAtFib - FVGEntry;
            
            if(slDistanceFromEntry > maxSLDistanceTP)
            {
                stopLoss = FVGEntry + maxSLDistanceTP;
            }
            else
            {
                stopLoss = slAtFib;
            }
            
            riskDistance = stopLoss - FVGEntry;
            // Use manual TP
            takeProfit = FVGEntry - (g_ManualTakeProfitPips * pipValue);
        }
        else
        {
            return false;
        }
        
        // Validate automatic SL with manual TP
        if((bias == BULLISH && (stopLoss >= FVGEntry || takeProfit <= FVGEntry)) ||
           (bias == BEARISH && (stopLoss <= FVGEntry || takeProfit >= FVGEntry)))
        {
            LogTrade("Invalid SL/TP (Auto SL + Manual TP): Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5));
            return false;
        }
        
        // Proceed to lot size calculation
    }
    else
    {
        // Automatic calculation using 50% displacement + 5 pips after MSS
        // Displacement = FVG range (FVGBottom to FVGTop)
        // Entry is already at 50% of displacement (FVGEntry = midpoint of FVG)
        // MSS = Market Structure Shift (Lower High for bearish, Higher Low for bullish)
        
        // Validate FVG range
        double displacementRange = FVGTop - FVGBottom;
        if(displacementRange <= 0) return false;
        
        // Find Market Structure Shift (MSS)
        double mssLevel = FindMSS(bias, 20);
        
        // Maximum stop loss distance from entry (20 pips)
        double maxSLDistance = 20.0 * pipValue;
        
        if(bias == BULLISH)
        {
            // For BUY: Find Higher Low (HL) after displacement
            if(mssLevel > 0 && mssLevel < FVGEntry)
            {
                // Stop loss = HL - 5 pips
                stopLoss = mssLevel - (5.0 * pipValue);
                
                // Calculate distance from entry to SL
                riskDistance = FVGEntry - stopLoss;
                
                // Ensure total is 20 pips (cap if more, adjust if less)
                if(riskDistance > maxSLDistance)
                {
                    // If more than 20 pips, cap at 20 pips
                    stopLoss = FVGEntry - maxSLDistance;
                    riskDistance = maxSLDistance;
                }
                else if(riskDistance < (15.0 * pipValue))
                {
                    // If less than 15 pips, adjust to maintain minimum distance
                    // Keep MSS-based SL but log warning
                    LogTrade("Warning: MSS-based SL is less than 15 pips: " + DoubleToString(riskDistance / pipValue, 1) + " pips");
                }
            }
            else
            {
                // Fallback: If MSS not found or invalid, use 20 pips below entry
                stopLoss = FVGEntry - maxSLDistance;
                riskDistance = maxSLDistance;
                LogTrade("MSS not found for BUY, using 20 pips SL");
            }
            
            // Use manual TP if enabled, otherwise use 1:2 R:R
            if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
            {
                takeProfit = FVGEntry + (g_ManualTakeProfitPips * pipValue);
            }
            else
            {
                // First target (TP1): 2x the SL distance (1:2 risk/reward)
                takeProfit = FVGEntry + (riskDistance * 2.0);
            }
            
            // Validate prices
            if(stopLoss >= FVGEntry || takeProfit <= FVGEntry) 
            {
                LogTrade("Invalid SL/TP for BUY: Entry=" + DoubleToString(FVGEntry, 5) + 
                        " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5) +
                        " MSS=" + DoubleToString(mssLevel, 5));
                return false;
            }
        }
        else if(bias == BEARISH)
        {
            // For SELL: Find Lower High (LH) after displacement
            if(mssLevel > 0 && mssLevel > FVGEntry)
            {
                // Stop loss = LH + 5 pips
                stopLoss = mssLevel + (5.0 * pipValue);
                
                // Calculate distance from entry to SL
                riskDistance = stopLoss - FVGEntry;
                
                // Ensure total is 20 pips (cap if more, adjust if less)
                if(riskDistance > maxSLDistance)
                {
                    // If more than 20 pips, cap at 20 pips
                    stopLoss = FVGEntry + maxSLDistance;
                    riskDistance = maxSLDistance;
                }
                else if(riskDistance < (15.0 * pipValue))
                {
                    // If less than 15 pips, adjust to maintain minimum distance
                    // Keep MSS-based SL but log warning
                    LogTrade("Warning: MSS-based SL is less than 15 pips: " + DoubleToString(riskDistance / pipValue, 1) + " pips");
                }
            }
            else
            {
                // Fallback: If MSS not found or invalid, use 20 pips above entry
                stopLoss = FVGEntry + maxSLDistance;
                riskDistance = maxSLDistance;
                LogTrade("MSS not found for SELL, using 20 pips SL");
            }
            
            // Use manual TP if enabled, otherwise use 1:2 R:R
            if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
            {
                takeProfit = FVGEntry - (g_ManualTakeProfitPips * pipValue);
            }
            else
            {
                // First target (TP1): 2x the SL distance (1:2 risk/reward)
                takeProfit = FVGEntry - (riskDistance * 2.0);
            }
            
            // Validate prices
            if(stopLoss <= FVGEntry || takeProfit >= FVGEntry) 
            {
                LogTrade("Invalid SL/TP for SELL: Entry=" + DoubleToString(FVGEntry, 5) + 
                        " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5) +
                        " MSS=" + DoubleToString(mssLevel, 5));
                return false;
            }
        }
        else
        {
            return false;
        }
    } // End of automatic SL calculation
    
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

