// ============================================
// Enhanced Risk Management & Trade Placement
// Includes: Multiple TP levels, Better stops, Partial closes
// ============================================

// Include enhancements
#include "enhancements.mqh"

// Track TP levels for partial closes
struct TPTracking
{
    int ticket;
    double tp1;
    double tp2;
    double tp3;
    bool tp1Hit;
    bool tp2Hit;
    bool tp3Hit;
    double originalLot;
    double remainingLot;
};

TPTracking activeTrades[];

// Manage partial closes on TP hits
void ManagePartialCloses()
{
    int size = ArraySize(activeTrades);
    
    for(int i = size - 1; i >= 0; i--)
    {
        if(!OrderSelect(activeTrades[i].ticket, SELECT_BY_TICKET))
        {
            // Order closed, remove from tracking
            ArrayRemove(activeTrades, i, 1);
            continue;
        }
        
        double currentPrice = (OrderType() == OP_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double currentLot = OrderLots();
        
        // Check TP1
        if(!activeTrades[i].tp1Hit)
        {
            bool tp1Reached = false;
            if(OrderType() == OP_BUY && currentPrice >= activeTrades[i].tp1)
                tp1Reached = true;
            else if(OrderType() == OP_SELL && currentPrice <= activeTrades[i].tp1)
                tp1Reached = true;
            
            if(tp1Reached)
            {
                // Close 50% at TP1
                double closeLot = NormalizeDouble(currentLot * (TP1_PERCENT / 100.0), 2);
                if(closeLot >= SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                {
                    if(OrderClose(activeTrades[i].ticket, closeLot, currentPrice, 3))
                    {
                        activeTrades[i].tp1Hit = true;
                        activeTrades[i].remainingLot = currentLot - closeLot;
                        LogTrade("TP1 hit: Closed " + DoubleToString(closeLot, 2) + " lots");
                    }
                }
            }
        }
        
        // Check TP2 (only if TP1 hit)
        if(activeTrades[i].tp1Hit && !activeTrades[i].tp2Hit)
        {
            bool tp2Reached = false;
            if(OrderType() == OP_BUY && currentPrice >= activeTrades[i].tp2)
                tp2Reached = true;
            else if(OrderType() == OP_SELL && currentPrice <= activeTrades[i].tp2)
                tp2Reached = true;
            
            if(tp2Reached)
            {
                // Close 25% at TP2 (of original position)
                double closeLot = NormalizeDouble(activeTrades[i].originalLot * (TP2_PERCENT / 100.0), 2);
                double currentLotAfterTP1 = OrderLots();
                
                if(closeLot > currentLotAfterTP1) closeLot = currentLotAfterTP1;
                
                if(closeLot >= SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
                {
                    if(OrderClose(activeTrades[i].ticket, closeLot, currentPrice, 3))
                    {
                        activeTrades[i].tp2Hit = true;
                        activeTrades[i].remainingLot = currentLotAfterTP1 - closeLot;
                        LogTrade("TP2 hit: Closed " + DoubleToString(closeLot, 2) + " lots");
                        
                        // Move stop to breakeven after TP2
                        if(OrderModify(activeTrades[i].ticket, OrderOpenPrice(), OrderOpenPrice(), activeTrades[i].tp3, 0))
                        {
                            LogTrade("Stop moved to breakeven after TP2");
                        }
                    }
                }
            }
        }
        
        // TP3: Trailing stop (only if TP2 hit)
        if(activeTrades[i].tp2Hit && !activeTrades[i].tp3Hit)
        {
            double atr = GetATR(14, PERIOD_H1);
            double trailDistance = (atr > 0) ? atr * 0.5 : (20 * _Point * 10); // 0.5 ATR or 20 pips
            
            double newStop = 0;
            if(OrderType() == OP_BUY)
            {
                newStop = currentPrice - trailDistance;
                if(newStop > OrderStopLoss() && newStop < currentPrice)
                {
                    if(OrderModify(activeTrades[i].ticket, OrderOpenPrice(), newStop, activeTrades[i].tp3, 0))
                    {
                        LogTrade("Trailing stop updated to " + DoubleToString(newStop, _Digits));
                    }
                }
            }
            else if(OrderType() == OP_SELL)
            {
                newStop = currentPrice + trailDistance;
                if((OrderStopLoss() == 0 || newStop < OrderStopLoss()) && newStop > currentPrice)
                {
                    if(OrderModify(activeTrades[i].ticket, OrderOpenPrice(), newStop, activeTrades[i].tp3, 0))
                    {
                        LogTrade("Trailing stop updated to " + DoubleToString(newStop, _Digits));
                    }
                }
            }
        }
    }
}

// Enhanced PlaceTrade with multiple TPs
bool PlaceTradeEnhanced(BiasType bias)
{
    if(!FVGReady) return false;
    
    // Validate FVG quality
    if(!IsFVGValid())
    {
        LogTrade("FVG quality check failed - size out of range");
        return false;
    }
    
    // Validate Asian range
    if(AsiaHigh <= 0 || AsiaLow <= 0 || AsiaHigh <= AsiaLow) return false;
    
    // Validate FVG
    if(FVGTop <= FVGBottom || FVGEntry <= 0) return false;
    
    // Check if we can take another trade
    if(!CanTakeAnotherTrade())
    {
        LogTrade("Max trades per day reached");
        return false;
    }
    
    // Calculate improved stop loss
    double stopLoss = CalculateImprovedStopLoss(bias);
    
    // Calculate multiple TP levels
    double tp1, tp2, tp3;
    CalculateMultipleTPs(bias, stopLoss, tp1, tp2, tp3);
    
    // Validate prices
    if(bias == BULLISH)
    {
        if(stopLoss >= FVGEntry || tp1 <= FVGEntry) return false;
    }
    else if(bias == BEARISH)
    {
        if(stopLoss <= FVGEntry || tp1 >= FVGEntry) return false;
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
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    
    // Round prices to proper digits
    FVGEntry = NormalizeDouble(FVGEntry, digits);
    stopLoss = NormalizeDouble(stopLoss, digits);
    tp1 = NormalizeDouble(tp1, digits);
    tp2 = NormalizeDouble(tp2, digits);
    tp3 = NormalizeDouble(tp3, digits);
    
    // Place Limit order at FVGEntry (use TP3 as initial TP, we'll manage partial closes)
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
                             stopLoss, tp3, comment, 0, 0, orderColor);
        }
    }
    else if(bias == BEARISH)
    {
        // Sell limit: entry must be above current price
        if(FVGEntry > bid)
        {
            ticket = OrderSend(Symbol(), OP_SELLLIMIT, lotSize, FVGEntry, slippage, 
                             stopLoss, tp3, comment, 0, 0, orderColor);
        }
    }
    
    // Check result and track for partial closes
    if(ticket > 0)
    {
        // Add to tracking array
        int size = ArraySize(activeTrades);
        ArrayResize(activeTrades, size + 1);
        activeTrades[size].ticket = ticket;
        activeTrades[size].tp1 = tp1;
        activeTrades[size].tp2 = tp2;
        activeTrades[size].tp3 = tp3;
        activeTrades[size].tp1Hit = false;
        activeTrades[size].tp2Hit = false;
        activeTrades[size].tp3Hit = false;
        activeTrades[size].originalLot = lotSize;
        activeTrades[size].remainingLot = lotSize;
        
        LogTrade("Trade placed: Ticket " + IntegerToString(ticket) + 
                 " | TP1: " + DoubleToString(tp1, digits) + 
                 " | TP2: " + DoubleToString(tp2, digits) + 
                 " | TP3: " + DoubleToString(tp3, digits));
        
        return true;
    }
    else
    {
        int error = GetLastError();
        LogTrade("Order failed: Error " + IntegerToString(error));
        return false;
    }
}

