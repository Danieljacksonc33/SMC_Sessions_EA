// ============================================
// Active Trade Management
// Break-even, Trailing Stops, Partial Closes
// ============================================

// External variables (declared in main file, accessible here)
// MagicNumber is from main file
// Additional settings for trade management
bool EnableBreakEven = true;
int BreakEvenPips = 20;  // Move to break-even after X pips profit
bool EnableTrailingStop = true;
int TrailingStopPips = 15;  // Trailing stop distance in pips
int TrailingStepPips = 5;   // Trailing step in pips
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
        
        // 2. Break-Even Move
        if(EnableBreakEven && profitPips >= BreakEvenPips)
        {
            double beSL = 0;
            bool shouldMove = false;
            
            if(OrderType() == OP_BUY)
            {
                // For buy orders, move SL to break-even or better
                beSL = openPrice + (5 * point * 10); // Slightly above entry (5 pips)
                if(currentSL < beSL || currentSL == 0)
                {
                    shouldMove = true;
                }
            }
            else if(OrderType() == OP_SELL)
            {
                // For sell orders, move SL to break-even or better
                beSL = openPrice - (5 * point * 10); // Slightly below entry (5 pips)
                if(currentSL > beSL || currentSL == 0)
                {
                    shouldMove = true;
                }
            }
            
            if(shouldMove)
            {
                beSL = NormalizeDouble(beSL, digits);
                if(OrderModify(OrderTicket(), openPrice, beSL, currentTP, 0))
                {
                    LogTrade("Break-even moved: Ticket " + IntegerToString(OrderTicket()) + 
                            " at " + DoubleToString(profitPips, 1) + " pips");
                }
            }
        }
        
        // 3. Trailing Stop (only if break-even already moved or profit is good)
        if(EnableTrailingStop && profitPips > BreakEvenPips)
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


