// ============================================
// CSV Export - Daily Trade Report
// ============================================

// MagicNumber is from main file, accessible here

// Export today's trades to CSV file
// Called at end of day (before resetting daily flags)
void ExportDailyTradesToCSV()
{
    // Determine if we're in tester or live mode
    bool isTester = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE));
    string modeStr = isTester ? "Tester" : "Live";
    
    // Get yesterday's date for filename (trades from previous day)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime todayStart = StructToTime(dt);
    datetime yesterdayStart = todayStart - 86400; // Previous day
    
    // Create filename with date: SMC_Trades_YYYYMMDD_Tester.csv or SMC_Trades_YYYYMMDD_Live.csv
    MqlDateTime fileDt;
    TimeToStruct(yesterdayStart, fileDt);
    string dateStr = IntegerToString(fileDt.year) + 
                     StringFormat("%02d", fileDt.mon) + 
                     StringFormat("%02d", fileDt.day);
    string filename = "SMC_Trades_" + dateStr + "_" + modeStr + ".csv";
    
    // Open file for writing
    int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI);
    if(handle == INVALID_HANDLE)
    {
        int error = GetLastError();
        Print("CSV Export Error (" + modeStr + "): Cannot create CSV file: " + filename + ". Error code: " + IntegerToString(error));
        return;
    }
    
    // Write CSV header
    FileWrite(handle, "Date", "Pair", "Direction", "Win/Lost", "Ticket", "OpenTime", "CloseTime", 
              "OpenPrice", "ClosePrice", "LotSize", "StopLoss", "TakeProfit", "Profit", "ProfitPips", 
              "Swap", "Commission", "CloseReason", "MagicNumber");
    
    // Get yesterday's trades (closed trades from previous day)
    int historyTotal = OrdersHistoryTotal();
    int tradesExported = 0;
    
    for(int i = historyTotal - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
        {
            // Only include trades for this magic number
            if(OrderMagicNumber() != MagicNumber) continue;
            
            // Only include trades closed yesterday
            if(OrderCloseTime() < yesterdayStart || OrderCloseTime() >= todayStart) continue;
            
            // Get trade details
            string pair = OrderSymbol();
            string direction = (OrderType() == OP_BUY) ? "Long" : "Short";
            double profit = OrderProfit() + OrderSwap() + OrderCommission();
            string winLost = (profit > 0) ? "Win" : "Lost";
            
            // Calculate profit in pips
            double profitPips = 0;
            double point = Point;
            if(OrderType() == OP_BUY)
                profitPips = (OrderClosePrice() - OrderOpenPrice()) / point / 10;
            else if(OrderType() == OP_SELL)
                profitPips = (OrderOpenPrice() - OrderClosePrice()) / point / 10;
            
            // Determine close reason
            string closeReason = "Unknown";
            if(OrderClosePrice() == OrderTakeProfit())
                closeReason = "Take Profit";
            else if(OrderClosePrice() == OrderStopLoss())
                closeReason = "Stop Loss";
            else
                closeReason = "Manual/Other";
            
            // Format dates
            string openTimeStr = TimeToString(OrderOpenTime(), TIME_DATE|TIME_MINUTES);
            string closeTimeStr = TimeToString(OrderCloseTime(), TIME_DATE|TIME_MINUTES);
            string closeDateStr = TimeToString(OrderCloseTime(), TIME_DATE);
            
            // Write trade row
            FileWrite(handle, 
                closeDateStr,                                    // Date
                pair,                                       // Pair
                direction,                                  // Direction (Long/Short)
                winLost,                                   // Win/Lost
                IntegerToString(OrderTicket()),            // Ticket
                openTimeStr,                               // OpenTime
                closeTimeStr,                              // CloseTime
                DoubleToString(OrderOpenPrice(), 5),       // OpenPrice
                DoubleToString(OrderClosePrice(), 5),      // ClosePrice
                DoubleToString(OrderLots(), 2),           // LotSize
                DoubleToString(OrderStopLoss(), 5),       // StopLoss
                DoubleToString(OrderTakeProfit(), 5),      // TakeProfit
                DoubleToString(profit, 2),                // Profit
                DoubleToString(profitPips, 1),            // ProfitPips
                DoubleToString(OrderSwap(), 2),          // Swap
                DoubleToString(OrderCommission(), 2),      // Commission
                closeReason,                               // CloseReason
                IntegerToString(OrderMagicNumber())       // MagicNumber
            );
            
            tradesExported++;
        }
    }
    
    FileClose(handle);
    
    if(tradesExported > 0)
    {
        Print("CSV Export (" + modeStr + "): Exported " + IntegerToString(tradesExported) + " trades to " + filename);
    }
    else
    {
        Print("CSV Export (" + modeStr + "): No trades to export for " + dateStr + " (file not created)");
    }
}
