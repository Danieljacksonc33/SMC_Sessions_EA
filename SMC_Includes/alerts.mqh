// ============================================
// Alert System
// Popup, Email, and Push Notifications
// ============================================

// Alert settings (using globals from main file)
// g_EnableAlerts, g_AlertSweep, g_AlertTradePlaced, g_AlertBreakEven, g_AlertTradeClosed
// g_AlertPopup, g_AlertEmail, g_AlertPush are set in main file

// Alert types
enum AlertType
{
    ALERT_SWEEP,
    ALERT_TRADE_PLACED,
    ALERT_BREAKEVEN,
    ALERT_TRADE_CLOSED
};

// Send alert based on settings
void SendAlert(AlertType type, string message)
{
    if(!g_EnableAlerts) return;
    
    // Check if this alert type is enabled
    bool alertEnabled = false;
    switch(type)
    {
        case ALERT_SWEEP: alertEnabled = g_AlertSweep; break;
        case ALERT_TRADE_PLACED: alertEnabled = g_AlertTradePlaced; break;
        case ALERT_BREAKEVEN: alertEnabled = g_AlertBreakEven; break;
        case ALERT_TRADE_CLOSED: alertEnabled = g_AlertTradeClosed; break;
    }
    
    if(!alertEnabled) return;
    
    // Format message with symbol and time
    string fullMessage = "SMC EA [" + Symbol() + "] " + message;
    string timeStr = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
    fullMessage = timeStr + " | " + fullMessage;
    
    // Send popup alert
    if(g_AlertPopup)
    {
        Alert(fullMessage);
    }
    
    // Send email alert
    if(g_AlertEmail)
    {
        string subject = "SMC EA Alert: ";
        switch(type)
        {
            case ALERT_SWEEP: subject += "Liquidity Sweep"; break;
            case ALERT_TRADE_PLACED: subject += "Trade Opened"; break;
            case ALERT_BREAKEVEN: subject += "Break-Even Hit"; break;
            case ALERT_TRADE_CLOSED: subject += "Trade Closed"; break;
        }
        SendMail(subject, fullMessage);
    }
    
    // Send push notification (to MT4 mobile app)
    if(g_AlertPush)
    {
        SendNotification(fullMessage);
    }
}

// Alert: Liquidity Sweep Detected
void AlertSweep(string sweepType, double price)
{
    string message = "Liquidity Sweep: " + sweepType + " at " + DoubleToString(price, Digits);
    SendAlert(ALERT_SWEEP, message);
}

// Alert: Trade Placed
void AlertTradePlaced(string orderType, double lotSize, double entryPrice, double sl, double tp)
{
    string message = "Trade Opened: " + orderType + 
                    " | Lot: " + DoubleToString(lotSize, 2) +
                    " | Entry: " + DoubleToString(entryPrice, Digits) +
                    " | SL: " + DoubleToString(sl, Digits) +
                    " | TP: " + DoubleToString(tp, Digits);
    SendAlert(ALERT_TRADE_PLACED, message);
}

// Alert: Break-Even Hit
void AlertBreakEven(int ticket, double profitPips)
{
    string message = "Break-Even: Ticket #" + IntegerToString(ticket) + 
                    " | Profit: " + DoubleToString(profitPips, 1) + " pips";
    SendAlert(ALERT_BREAKEVEN, message);
}

// Alert: Trade Closed
void AlertTradeClosed(int ticket, string orderType, double profit, double profitPips, string reason)
{
    string profitStr = (profit >= 0) ? "+" + DoubleToString(profit, 2) : DoubleToString(profit, 2);
    string message = "Trade Closed: " + orderType + 
                    " | Ticket #" + IntegerToString(ticket) +
                    " | P/L: " + profitStr + " (" + DoubleToString(profitPips, 1) + " pips)" +
                    " | Reason: " + reason;
    SendAlert(ALERT_TRADE_CLOSED, message);
}

