// ============================================
// Performance Statistics Tracking
// ============================================

#define USE_STATISTICS  // Enable statistics tracking

// Statistics structure
struct DailyStats
{
    int tradesToday;
    int winsToday;
    int lossesToday;
    double profitToday;
    double lossToday;
    datetime date;
};

static DailyStats todayStats;
static double totalProfit = 0;
static double totalLoss = 0;
static int totalWins = 0;
static int totalLosses = 0;
static double maxDrawdown = 0;
static double peakBalance = 0;

// Initialize statistics
void InitStatistics()
{
    todayStats.tradesToday = 0;
    todayStats.winsToday = 0;
    todayStats.lossesToday = 0;
    todayStats.profitToday = 0;
    todayStats.lossToday = 0;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    todayStats.date = StructToTime(dt);
    
    peakBalance = AccountBalance();
}

// Update statistics when trade closes
void UpdateStatistics(int ticket)
{
    if(!OrderSelect(ticket, SELECT_BY_POS, MODE_HISTORY)) return;
    if(OrderSymbol() != Symbol()) return;
    
    double profit = OrderProfit() + OrderSwap() + OrderCommission();
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime today = StructToTime(dt);
    
    // Reset daily stats if new day
    if(todayStats.date != today)
    {
        todayStats.tradesToday = 0;
        todayStats.winsToday = 0;
        todayStats.lossesToday = 0;
        todayStats.profitToday = 0;
        todayStats.lossToday = 0;
        todayStats.date = today;
    }
    
    todayStats.tradesToday++;
    
    if(profit > 0)
    {
        todayStats.winsToday++;
        todayStats.profitToday += profit;
        totalWins++;
        totalProfit += profit;
    }
    else if(profit < 0)
    {
        todayStats.lossesToday++;
        todayStats.lossToday += MathAbs(profit);
        totalLosses++;
        totalLoss += MathAbs(profit);
    }
    
    // Update drawdown
    double currentBalance = AccountBalance();
    if(currentBalance > peakBalance)
        peakBalance = currentBalance;
    
    double currentDrawdown = ((peakBalance - currentBalance) / peakBalance) * 100.0;
    if(currentDrawdown > maxDrawdown)
        maxDrawdown = currentDrawdown;
}

// Get win rate
double GetWinRate()
{
    int totalTrades = totalWins + totalLosses;
    if(totalTrades == 0) return 0;
    return (double(totalWins) / double(totalTrades)) * 100.0;
}

// Get profit factor
double GetProfitFactor()
{
    if(totalLoss == 0) return (totalProfit > 0) ? 999.0 : 0.0;
    return totalProfit / totalLoss;
}

// Get daily win rate
double GetDailyWinRate()
{
    int total = todayStats.winsToday + todayStats.lossesToday;
    if(total == 0) return 0;
    return (double(todayStats.winsToday) / double(total)) * 100.0;
}

// Print statistics
void PrintStatistics()
{
    string stats = "\n=== SMC EA Statistics ===\n";
    stats += "Today: " + IntegerToString(todayStats.tradesToday) + " trades | ";
    stats += "Wins: " + IntegerToString(todayStats.winsToday) + " | ";
    stats += "Losses: " + IntegerToString(todayStats.lossesToday) + "\n";
    stats += "Today P/L: " + DoubleToString(todayStats.profitToday - todayStats.lossToday, 2) + "\n";
    stats += "Win Rate: " + DoubleToString(GetDailyWinRate(), 1) + "%\n\n";
    
    stats += "Overall: " + IntegerToString(totalWins + totalLosses) + " trades | ";
    stats += "Wins: " + IntegerToString(totalWins) + " | ";
    stats += "Losses: " + IntegerToString(totalLosses) + "\n";
    stats += "Win Rate: " + DoubleToString(GetWinRate(), 1) + "%\n";
    stats += "Profit Factor: " + DoubleToString(GetProfitFactor(), 2) + "\n";
    stats += "Max Drawdown: " + DoubleToString(maxDrawdown, 2) + "%\n";
    stats += "========================\n";
    
    Print(stats);
}

// Check if we should stop trading (safety)
bool CheckDailyLossLimit(double maxDailyLossPercent)
{
    if(maxDailyLossPercent <= 0) return false; // Disabled
    
    double dailyLoss = todayStats.lossToday - todayStats.profitToday;
    double accountBalance = AccountBalance();
    double lossPercent = (dailyLoss / accountBalance) * 100.0;
    
    if(lossPercent >= maxDailyLossPercent)
    {
        LogTrade("Daily loss limit reached: " + DoubleToString(lossPercent, 2) + "%");
        return true;
    }
    
    return false;
}


