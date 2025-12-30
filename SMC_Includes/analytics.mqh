// ============================================
// Enhanced Performance Analytics
// Detailed statistics and reporting
// ============================================

// Analytics structure
struct SessionStats
{
    string sessionName;
    int trades;
    int wins;
    int losses;
    double profit;
    double loss;
    double winRate;
};

struct PairStats
{
    string symbol;
    int trades;
    int wins;
    int losses;
    double profit;
    double loss;
    double winRate;
};

// Global analytics
SessionStats g_SessionAnalytics[10];
int g_SessionStatsCount = 0;

PairStats g_PairAnalytics[10];
int g_PairStatsCount = 0;

// Overall analytics
static double g_TotalProfit = 0;
static double g_TotalLoss = 0;
static int g_TotalTrades = 0;
static int g_TotalWins = 0;
static int g_TotalLosses = 0;
static double g_AverageWin = 0;
static double g_AverageLoss = 0;
static double g_LargestWin = 0;
static double g_LargestLoss = 0;
static double g_BestDay = 0;
static double g_WorstDay = 0;
static datetime g_FirstTradeTime = 0;
static datetime g_LastTradeTime = 0;

// Initialize analytics
void InitAnalytics()
{
    g_SessionStatsCount = 0;
    g_PairStatsCount = 0;
    g_TotalProfit = 0;
    g_TotalLoss = 0;
    g_TotalTrades = 0;
    g_TotalWins = 0;
    g_TotalLosses = 0;
    g_AverageWin = 0;
    g_AverageLoss = 0;
    g_LargestWin = 0;
    g_LargestLoss = 0;
    g_BestDay = 0;
    g_WorstDay = 0;
    g_FirstTradeTime = 0;
    g_LastTradeTime = 0;
}

// Update analytics when trade closes
void UpdateAnalytics(int ticket, string sessionName)
{
    if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) return;
    if(OrderSymbol() != Symbol()) return;
    // MagicNumber is from main file, accessible here
    if(OrderMagicNumber() != MagicNumber) return;
    
    double profit = OrderProfit() + OrderSwap() + OrderCommission();
    string symbol = OrderSymbol();
    
    // Update overall stats
    g_TotalTrades++;
    if(profit > 0)
    {
        g_TotalWins++;
        g_TotalProfit += profit;
        if(profit > g_LargestWin) g_LargestWin = profit;
    }
    else
    {
        g_TotalLosses++;
        g_TotalLoss += MathAbs(profit);
        if(MathAbs(profit) > g_LargestLoss) g_LargestLoss = MathAbs(profit);
    }
    
    // Update averages
    if(g_TotalWins > 0) g_AverageWin = g_TotalProfit / g_TotalWins;
    if(g_TotalLosses > 0) g_AverageLoss = g_TotalLoss / g_TotalLosses;
    
    // Update timestamps
    if(g_FirstTradeTime == 0) g_FirstTradeTime = OrderOpenTime();
    g_LastTradeTime = OrderCloseTime();
    
    // Update session stats
    int sessionIdx = -1;
    for(int sessIdx = 0; sessIdx < g_SessionStatsCount; sessIdx++)
    {
        if(g_SessionAnalytics[sessIdx].sessionName == sessionName)
        {
            sessionIdx = sessIdx;
            break;
        }
    }
    
    if(sessionIdx < 0)
    {
        // New session
        sessionIdx = g_SessionStatsCount;
        g_SessionAnalytics[sessionIdx].sessionName = sessionName;
        g_SessionAnalytics[sessionIdx].trades = 0;
        g_SessionAnalytics[sessionIdx].wins = 0;
        g_SessionAnalytics[sessionIdx].losses = 0;
        g_SessionAnalytics[sessionIdx].profit = 0;
        g_SessionAnalytics[sessionIdx].loss = 0;
        g_SessionStatsCount++;
    }
    
    g_SessionAnalytics[sessionIdx].trades++;
    if(profit > 0)
    {
        g_SessionAnalytics[sessionIdx].wins++;
        g_SessionAnalytics[sessionIdx].profit += profit;
    }
    else
    {
        g_SessionAnalytics[sessionIdx].losses++;
        g_SessionAnalytics[sessionIdx].loss += MathAbs(profit);
    }
    
    int total = g_SessionAnalytics[sessionIdx].wins + g_SessionAnalytics[sessionIdx].losses;
    if(total > 0)
    {
        g_SessionAnalytics[sessionIdx].winRate = 
            (double)g_SessionAnalytics[sessionIdx].wins / (double)total * 100.0;
    }
    
    // Update pair stats
    int pairIdx = -1;
    for(int pairLoopIdx = 0; pairLoopIdx < g_PairStatsCount; pairLoopIdx++)
    {
        if(g_PairAnalytics[pairLoopIdx].symbol == symbol)
        {
            pairIdx = pairLoopIdx;
            break;
        }
    }
    
    if(pairIdx < 0)
    {
        pairIdx = g_PairStatsCount;
        g_PairAnalytics[pairIdx].symbol = symbol;
        g_PairAnalytics[pairIdx].trades = 0;
        g_PairAnalytics[pairIdx].wins = 0;
        g_PairAnalytics[pairIdx].losses = 0;
        g_PairAnalytics[pairIdx].profit = 0;
        g_PairAnalytics[pairIdx].loss = 0;
        g_PairStatsCount++;
    }
    
    g_PairAnalytics[pairIdx].trades++;
    if(profit > 0)
    {
        g_PairAnalytics[pairIdx].wins++;
        g_PairAnalytics[pairIdx].profit += profit;
    }
    else
    {
        g_PairAnalytics[pairIdx].losses++;
        g_PairAnalytics[pairIdx].loss += MathAbs(profit);
    }
    
    total = g_PairAnalytics[pairIdx].wins + g_PairAnalytics[pairIdx].losses;
    if(total > 0)
    {
        g_PairAnalytics[pairIdx].winRate = 
            (double)g_PairAnalytics[pairIdx].wins / (double)total * 100.0;
    }
}

// Print detailed analytics
void PrintDetailedAnalytics()
{
    if(!g_EnableAnalytics) return;
    
    string report = "\n========================================\n";
    report += "=== ENHANCED PERFORMANCE ANALYTICS ===\n";
    report += "========================================\n\n";
    
    // Overall Statistics
    report += "--- OVERALL STATISTICS ---\n";
    report += "Total Trades: " + IntegerToString(g_TotalTrades) + "\n";
    report += "Wins: " + IntegerToString(g_TotalWins) + " | Losses: " + IntegerToString(g_TotalLosses) + "\n";
    
    if(g_TotalTrades > 0)
    {
        double winRate = (double)g_TotalWins / (double)g_TotalTrades * 100.0;
        report += "Win Rate: " + DoubleToString(winRate, 2) + "%\n";
    }
    
    report += "Total Profit: " + DoubleToString(g_TotalProfit, 2) + "\n";
    report += "Total Loss: " + DoubleToString(g_TotalLoss, 2) + "\n";
    report += "Net P/L: " + DoubleToString(g_TotalProfit - g_TotalLoss, 2) + "\n";
    
    double profitFactor = (g_TotalLoss > 0) ? g_TotalProfit / g_TotalLoss : 0;
    report += "Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
    
    if(g_TotalWins > 0)
        report += "Average Win: " + DoubleToString(g_AverageWin, 2) + "\n";
    if(g_TotalLosses > 0)
        report += "Average Loss: " + DoubleToString(g_AverageLoss, 2) + "\n";
    
    if(g_LargestWin > 0)
        report += "Largest Win: " + DoubleToString(g_LargestWin, 2) + "\n";
    if(g_LargestLoss > 0)
        report += "Largest Loss: " + DoubleToString(g_LargestLoss, 2) + "\n";
    
    report += "\n";
    
    // Session Statistics
    if(g_SessionStatsCount > 0)
    {
        report += "--- SESSION STATISTICS ---\n";
        for(int sessStatIdx = 0; sessStatIdx < g_SessionStatsCount; sessStatIdx++)
        {
            report += g_SessionAnalytics[sessStatIdx].sessionName + ":\n";
            report += "  Trades: " + IntegerToString(g_SessionAnalytics[sessStatIdx].trades) + "\n";
            report += "  Wins: " + IntegerToString(g_SessionAnalytics[sessStatIdx].wins) + 
                     " | Losses: " + IntegerToString(g_SessionAnalytics[sessStatIdx].losses) + "\n";
            report += "  Win Rate: " + DoubleToString(g_SessionAnalytics[sessStatIdx].winRate, 2) + "%\n";
            report += "  P/L: " + DoubleToString(g_SessionAnalytics[sessStatIdx].profit - g_SessionAnalytics[sessStatIdx].loss, 2) + "\n";
            report += "\n";
        }
    }
    
    // Pair Statistics
    if(g_PairStatsCount > 0)
    {
        report += "--- PAIR STATISTICS ---\n";
        for(int pairStatIdx = 0; pairStatIdx < g_PairStatsCount; pairStatIdx++)
        {
            report += g_PairAnalytics[pairStatIdx].symbol + ":\n";
            report += "  Trades: " + IntegerToString(g_PairAnalytics[pairStatIdx].trades) + "\n";
            report += "  Wins: " + IntegerToString(g_PairAnalytics[pairStatIdx].wins) + 
                     " | Losses: " + IntegerToString(g_PairAnalytics[pairStatIdx].losses) + "\n";
            report += "  Win Rate: " + DoubleToString(g_PairAnalytics[pairStatIdx].winRate, 2) + "%\n";
            report += "  P/L: " + DoubleToString(g_PairAnalytics[pairStatIdx].profit - g_PairAnalytics[pairStatIdx].loss, 2) + "\n";
            report += "\n";
        }
    }
    
    report += "========================================\n";
    
    Print(report);
}

