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

// ============================================
// Corrected Hybrid Stop Loss Calculation
// ============================================
// Calculates optimal stop loss using MSS (primary invalidation) and Asian range (context/safety)
// Returns true if SL calculated successfully, false if trade should be invalidated
// stopLoss and riskDistance are output parameters
bool CalculateHybridStopLoss(BiasType bias, double entryPrice, double& stopLoss, double& riskDistance, string& slReason)
{
    double point = Point;
    double pipValue = point * 10; // 1 pip in price terms
    
    // Constants
    double minSLDistance = 15.0 * pipValue; // Minimum 15 pips
    double maxSLDistance = 20.0 * pipValue; // Maximum 20 pips
    double asiaBuffer = 5.0 * pipValue;     // 5 pips buffer for Asian range
    
    // Validate Asian range is available
    if(AsiaHigh <= 0 || AsiaLow <= 0 || AsiaHigh <= AsiaLow)
    {
        // No Asian range - use fallback 20 pips
        if(bias == BULLISH)
        {
            stopLoss = entryPrice - maxSLDistance;
            riskDistance = maxSLDistance;
        }
        else
        {
            stopLoss = entryPrice + maxSLDistance;
            riskDistance = maxSLDistance;
        }
        slReason = "Asian range invalid, using 20 pips fallback";
        return true;
    }
    
    // Step 1: Calculate MSS-based SL
    double mssLevel = FindMSS(bias, 20);
    double mssSL = 0;
    double mssDistance = 0;
    bool mssValid = false;
    
    if(mssLevel > 0)
    {
        if(bias == BULLISH && mssLevel < entryPrice)
        {
            // MSS-based SL = HL - 5 pips
            mssSL = mssLevel - asiaBuffer;
            mssDistance = entryPrice - mssSL;
            
            // Validate MSS SL: must be 15-20 pips (priority rule)
            if(mssDistance >= minSLDistance && mssDistance <= maxSLDistance)
            {
                mssValid = true; // MSS is valid and in ideal range
            }
            else if(mssDistance > maxSLDistance)
            {
                // MSS too wide - will cap to 20 pips
                mssSL = entryPrice - maxSLDistance;
                mssDistance = maxSLDistance;
                mssValid = true; // Use capped version
            }
            // If MSS too tight (<15), mark as invalid - will use Asian SL instead
        }
        else if(bias == BEARISH && mssLevel > entryPrice)
        {
            // MSS-based SL = LH + 5 pips
            mssSL = mssLevel + asiaBuffer;
            mssDistance = mssSL - entryPrice;
            
            // Validate MSS SL: must be 15-20 pips (priority rule)
            if(mssDistance >= minSLDistance && mssDistance <= maxSLDistance)
            {
                mssValid = true; // MSS is valid and in ideal range
            }
            else if(mssDistance > maxSLDistance)
            {
                // MSS too wide - will cap to 20 pips
                mssSL = entryPrice + maxSLDistance;
                mssDistance = maxSLDistance;
                mssValid = true; // Use capped version
            }
            // If MSS too tight (<15), mark as invalid - will use Asian SL instead
        }
    }
    
    // Step 2: Calculate Asian-based SL
    double asiaSL = 0;
    double asiaDistance = 0;
    
    if(bias == BULLISH)
    {
        // Asian SL = Asian Low - 5 pips
        asiaSL = AsiaLow - asiaBuffer;
        asiaDistance = entryPrice - asiaSL;
    }
    else // BEARISH
    {
        // Asian SL = Asian High + 5 pips
        asiaSL = AsiaHigh + asiaBuffer;
        asiaDistance = asiaSL - entryPrice;
    }
    
    // Step 3: Select stop by priority (MSS is PRIMARY invalidation)
    if(mssValid)
    {
        // MSS is valid and in 15-20 pips range (or capped to 20)
        stopLoss = mssSL;
        riskDistance = mssDistance;
        slReason = "MSS-based SL (" + DoubleToString(riskDistance / pipValue, 1) + " pips)";
    }
    else if(mssLevel > 0 && mssDistance < minSLDistance)
    {
        // MSS too tight (<15 pips) - use Asian SL instead
        stopLoss = asiaSL;
        riskDistance = asiaDistance;
        slReason = "MSS too tight (" + DoubleToString(mssDistance / pipValue, 1) + " pips), using Asian SL (" + DoubleToString(riskDistance / pipValue, 1) + " pips)";
    }
    else
    {
        // No valid MSS found - use Asian SL (or 20 pips fallback if Asian is too wide)
        if(asiaDistance > maxSLDistance)
        {
            // Asian SL too wide - cap to 20 pips
            if(bias == BULLISH)
            {
                stopLoss = entryPrice - maxSLDistance;
                riskDistance = maxSLDistance;
            }
            else
            {
                stopLoss = entryPrice + maxSLDistance;
                riskDistance = maxSLDistance;
            }
            slReason = "No MSS, Asian SL too wide (" + DoubleToString(asiaDistance / pipValue, 1) + " pips), using 20 pips cap";
        }
        else
        {
            // Use Asian SL
            stopLoss = asiaSL;
            riskDistance = asiaDistance;
            slReason = "No MSS found, using Asian SL (" + DoubleToString(riskDistance / pipValue, 1) + " pips)";
        }
    }
    
    // Step 4: Safety check - validate SL position relative to Asian range
    if(bias == BULLISH)
    {
        // For bullish: SL must be below Asian Low
        if(stopLoss > AsiaLow)
        {
            // SL is above Asian Low - this is a bad setup (too tight Asian range)
            LogTrade("SAFETY CHECK FAILED (BULLISH): SL above Asian Low - invalidating trade. SL=" + 
                    DoubleToString(stopLoss, 5) + " AsiaLow=" + DoubleToString(AsiaLow, 5));
            return false; // Invalidate trade
        }
        else if(stopLoss >= AsiaLow - asiaBuffer && stopLoss <= AsiaLow)
        {
            // SL is inside/very close to Asian range - log warning but allow
            LogTrade("WARNING: SL is inside Asian range (BULLISH). SL=" + DoubleToString(stopLoss, 5) + 
                    " AsiaLow=" + DoubleToString(AsiaLow, 5) + " - trade allowed but risky");
        }
    }
    else // BEARISH
    {
        // For bearish: SL must be above Asian High
        if(stopLoss < AsiaHigh)
        {
            // SL is below Asian High - this is a bad setup (too tight Asian range)
            LogTrade("SAFETY CHECK FAILED (BEARISH): SL below Asian High - invalidating trade. SL=" + 
                    DoubleToString(stopLoss, 5) + " AsiaHigh=" + DoubleToString(AsiaHigh, 5));
            return false; // Invalidate trade
        }
        else if(stopLoss <= AsiaHigh + asiaBuffer && stopLoss >= AsiaHigh)
        {
            // SL is inside/very close to Asian range - log warning but allow
            LogTrade("WARNING: SL is inside Asian range (BEARISH). SL=" + DoubleToString(stopLoss, 5) + 
                    " AsiaHigh=" + DoubleToString(AsiaHigh, 5) + " - trade allowed but risky");
        }
    }
    
    // Validate final SL is on correct side of entry
    if((bias == BULLISH && stopLoss >= entryPrice) || (bias == BEARISH && stopLoss <= entryPrice))
    {
        LogTrade("ERROR: Calculated SL is on wrong side of entry. Entry=" + DoubleToString(entryPrice, 5) + 
                " SL=" + DoubleToString(stopLoss, 5) + " Bias=" + (bias == BULLISH ? "BULLISH" : "BEARISH"));
        return false;
    }
    
    return true; // SL calculated successfully
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
        // Manual TP only - use hybrid SL calculation (MSS + Asian range)
        string slReason = "";
        if(!CalculateHybridStopLoss(bias, FVGEntry, stopLoss, riskDistance, slReason))
        {
            // Trade invalidated by safety check
            LogTrade("Trade invalidated (Manual TP mode): " + slReason);
            return false;
        }
        
        // Log which SL was chosen
        LogTrade("Stop Loss Calculation (Manual TP mode): " + slReason);
        
        // Use manual TP
        if(bias == BULLISH)
            takeProfit = FVGEntry + (g_ManualTakeProfitPips * pipValue);
        else
            takeProfit = FVGEntry - (g_ManualTakeProfitPips * pipValue);
        
        // Validate SL/TP
        if((bias == BULLISH && (stopLoss >= FVGEntry || takeProfit <= FVGEntry)) ||
           (bias == BEARISH && (stopLoss <= FVGEntry || takeProfit >= FVGEntry)))
        {
            LogTrade("Invalid SL/TP (Hybrid SL + Manual TP): Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5));
            return false;
        }
        
        // Proceed to lot size calculation
    }
    else
    {
        // CORRECTED HYBRID STOP LOSS: MSS (primary invalidation) + Asian range (context/safety)
        // MSS defines invalidation, Asian range defines context (not stop placement)
        
        // Validate FVG range
        double displacementRange = FVGTop - FVGBottom;
        if(displacementRange <= 0) return false;
        
        // Calculate optimal stop loss using hybrid logic
        string slReason2 = "";
        if(!CalculateHybridStopLoss(bias, FVGEntry, stopLoss, riskDistance, slReason2))
        {
            // Trade invalidated by safety check (SL in wrong position relative to Asian range)
            LogTrade("Trade invalidated: " + slReason2);
            return false;
        }
        
        // Log which SL was chosen and why
        LogTrade("Stop Loss Calculation: " + slReason2);
        
        // Use manual TP if enabled, otherwise use 1:2 R:R
        if(g_UseManualTakeProfit && g_ManualTakeProfitPips > 0)
        {
            if(bias == BULLISH)
                takeProfit = FVGEntry + (g_ManualTakeProfitPips * pipValue);
            else
                takeProfit = FVGEntry - (g_ManualTakeProfitPips * pipValue);
        }
        else
        {
            // First target (TP1): 2x the SL distance (1:2 risk/reward)
            if(bias == BULLISH)
                takeProfit = FVGEntry + (riskDistance * 2.0);
            else
                takeProfit = FVGEntry - (riskDistance * 2.0);
        }
        
        // Final validation of prices
        if((bias == BULLISH && (stopLoss >= FVGEntry || takeProfit <= FVGEntry)) ||
           (bias == BEARISH && (stopLoss <= FVGEntry || takeProfit >= FVGEntry)))
        {
            LogTrade("Invalid SL/TP after calculation: Entry=" + DoubleToString(FVGEntry, 5) + 
                    " SL=" + DoubleToString(stopLoss, 5) + " TP=" + DoubleToString(takeProfit, 5));
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

