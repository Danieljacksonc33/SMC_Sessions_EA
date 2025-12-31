// ============================================
// Active Trade Management
// Break-even, Trailing Stops, Partial Closes
// ============================================

// External variables (declared in main file, accessible here)
// MagicNumber is from main file
// g_EnableTrailingStop is from main file (global variable)
// Additional settings for trade management
bool EnableBreakEven = true;
int BreakEvenPips = 20;  // Move to break-even after X pips profit
int TrailingStopPips = 15;  // Trailing stop distance in pips (not used currently - using 20-pip step logic)
int TrailingStepPips = 5;   // Trailing step in pips (not used currently - using 20-pip step logic)
bool EnablePartialClose = false;
int PartialClosePercent = 50;  // Close X% at first TP
int PartialClosePips = 30;     // Close partial at X pips profit

// Manage all open trades
void ManageTrades()
{
    int totalOrders = OrdersTotal();
    for(int i = totalOrders - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        
        // Only manage our EA's trades
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
        
        // Only manage market orders (filled positions)
        if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
        
        // Get current price (MQL4)
        double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
        
        double openPrice = OrderOpenPrice();
        double currentSL = OrderStopLoss();
        double currentTP = OrderTakeProfit();
        double point = Point;
        int digits = Digits;
        
        // Calculate profit in pips
        double profitPips = 0;
        if(OrderType() == OP_BUY)
            profitPips = (currentPrice - openPrice) / point / 10;
        else
            profitPips = (openPrice - currentPrice) / point / 10;
        
        // 1. Partial Close
        if(EnablePartialClose && profitPips >= PartialClosePips)
        {
            // Check if we haven't already done partial close (by checking if lot size changed)
            // This is a simple check - in production you might want to track this better
            double originalLot = OrderLots();
            double closeLot = NormalizeDouble(originalLot * (PartialClosePercent / 100.0), 2);
            
            double minLot = MarketInfo(Symbol(), MODE_MINLOT);
            if(closeLot >= minLot && closeLot < originalLot)
            {
                if(OrderClose(OrderTicket(), closeLot, currentPrice, 3))
                {
                    LogTrade("Partial close: " + DoubleToString(closeLot, 2) + " lots at " + 
                            DoubleToString(profitPips, 1) + " pips profit");
                }
                continue; // Move to next order
            }
        }
        
        // 2. Trailing Stop (move SL after every 20 pips profit)
        // Move SL up/down by 20 pips for every 20 pips profit
        // Only if trailing stop is enabled (can disable in high volatility sessions)
        if(g_EnableTrailingStop && profitPips >= 20.0)
        {
            double pipValue = point * 10;
            double trailingStepPips = 20.0; // Move SL every 20 pips
            
            // Calculate how many 20-pip steps we've moved
            int steps = (int)(profitPips / trailingStepPips);
            double newSL = 0;
            bool shouldUpdate = false;
            
            if(OrderType() == OP_BUY)
            {
                // New SL = Entry + (steps * 20 pips)
                newSL = openPrice + (steps * trailingStepPips * pipValue);
                
                // Only update if new SL is better (higher) than current SL and below current price
                if(newSL > currentSL && newSL < currentPrice)
                {
                    shouldUpdate = true;
                }
            }
            else if(OrderType() == OP_SELL)
            {
                // New SL = Entry - (steps * 20 pips)
                newSL = openPrice - (steps * trailingStepPips * pipValue);
                
                // Only update if new SL is better (lower) than current SL and above current price
                if(newSL < currentSL && newSL > currentPrice)
                {
                    shouldUpdate = true;
                }
            }
            
            if(shouldUpdate)
            {
                newSL = NormalizeDouble(newSL, digits);
                if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, currentTP, 0, clrBlue))
                {
                    LogTrade("Trailing stop updated: Ticket " + IntegerToString(OrderTicket()) + 
                            " to " + DoubleToString(newSL, 5) + " (moved " + 
                            DoubleToString(steps * trailingStepPips, 1) + " pips from entry)");
                }
            }
        }
        
        // 3. Old trailing stop logic (disabled - using new 20-pip step logic above)
        if(false && EnableTrailingStop && profitPips > BreakEvenPips)
        {
            double trailSL = 0;
            bool shouldTrail = false;
            
            if(OrderType() == OP_BUY)
            {
                trailSL = currentPrice - (TrailingStopPips * point * 10);
                trailSL = NormalizeDouble(trailSL, digits);
                
                // Only trail if new SL is better than current
                if(trailSL > currentSL && trailSL < currentPrice)
                {
                    // Check trailing step
                    if(currentSL == 0 || (trailSL - currentSL) >= (TrailingStepPips * point * 10))
                    {
                        shouldTrail = true;
                    }
                }
            }
            else if(OrderType() == OP_SELL)
            {
                trailSL = currentPrice + (TrailingStopPips * point * 10);
                trailSL = NormalizeDouble(trailSL, digits);
                
                // Only trail if new SL is better than current
                if((currentSL == 0 || trailSL < currentSL) && trailSL > currentPrice)
                {
                    // Check trailing step
                    if(currentSL == 0 || (currentSL - trailSL) >= (TrailingStepPips * point * 10))
                    {
                        shouldTrail = true;
                    }
                }
            }
            
            if(shouldTrail)
            {
                if(OrderModify(OrderTicket(), openPrice, trailSL, currentTP, 0))
                {
                    LogTrade("Trailing stop updated: Ticket " + IntegerToString(OrderTicket()) + 
                            " to " + DoubleToString(trailSL, digits));
                }
            }
        }
    }
}


