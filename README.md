# SMC Sessions Expert Advisor (EA) - Enhanced Edition

A sophisticated MetaTrader 4 Expert Advisor implementing Smart Money Concepts (SMC) trading strategy with session-based analysis, liquidity sweeps, change of character (CHOCH) detection, Fair Value Gap (FVG) entries, and comprehensive alert system.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Strategy Logic](#strategy-logic)
- [Installation](#installation)
- [Configuration](#configuration)
- [Alert System](#alert-system)
- [Usage Guide](#usage-guide)
- [File Structure](#file-structure)
- [Requirements](#requirements)
- [Performance Features](#performance-features)
- [Future Improvements](#future-improvements)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 🎯 Overview

The SMC Sessions EA is an automated trading system that combines Smart Money Concepts with session-based analysis. It identifies high-probability trading opportunities by:

1. **Session Analysis**: Calculates Asian session range (7 PM - 12 AM CST)
2. **Higher Timeframe Bias**: Determines market direction using H4 and D1 timeframes
3. **Liquidity Sweeps**: Detects when price breaks Asian session highs/lows
4. **Change of Character (CHOCH)**: Identifies structural breaks in market direction
5. **Fair Value Gap (FVG)**: Finds price inefficiencies for optimal entry points
6. **Market Condition Filters**: ADX-based trend detection and volatility filters
7. **Entry Confirmations**: Volume, momentum (RSI), and support/resistance filters
8. **Comprehensive Alerts**: Popup, email, and push notifications

## ✨ Features

### Core Trading Features
- ✅ **Session-Based Trading**: Trades only during specified hours (default: 2-5 AM CST)
- ✅ **Multiple Session Support**: Trade during multiple time windows (Asian, London, NY sessions)
- ✅ **Multi-Timeframe Analysis**: Uses M5, H1, H4, and D1 for comprehensive market analysis
- ✅ **Smart Entry System**: FVG-based entries at 50% retracement
- ✅ **Risk Management**: Dynamic lot sizing based on account risk percentage
- ✅ **Limit Orders**: Places limit orders at calculated FVG entry points

### Advanced Features
- ✅ **Active Trade Management**: Break-even moves, trailing stops, partial closes
- ✅ **Performance Statistics**: Real-time tracking of win rate, profit factor, drawdown
- ✅ **Enhanced Analytics**: Session-based and pair-based performance tracking
- ✅ **Safety Features**: Daily loss limits, max drawdown protection, max trades per day
- ✅ **Symbol Validation**: Checks if symbol is tradeable before trading
- ✅ **Magic Number System**: Unique trade identification for multiple EA instances

### Market Condition Filters
- ✅ **Trend Detection**: ADX-based filter to trade only in trending markets
- ✅ **Volatility Filter**: ATR-based filter to avoid low/high volatility conditions
- ✅ **Volume Confirmation**: Ensures sufficient volume before entry
- ✅ **Momentum Filter**: RSI-based confirmation aligned with bias
- ✅ **Support/Resistance Filter**: Avoids entries too close to key S/R levels

### Alert System
- ✅ **Popup Alerts**: Desktop notifications with sound
- ✅ **Email Alerts**: Configurable email notifications
- ✅ **Push Notifications**: Mobile app push notifications
- ✅ **Event Types**: Sweep alerts, trade placement, break-even, trade closure

### Technical Features
- ✅ **Cached Calculations**: Efficient Asian range calculation (once per day)
- ✅ **Swing Point Detection**: Advanced CHOCH detection using actual swing highs/lows
- ✅ **MQL4 Compatible**: Fully optimized for MetaTrader 4
- ✅ **Modular Code**: Clean, organized codebase with separate modules
- ✅ **Backtesting Support**: Enhanced Strategy Tester compatibility

## 🧠 Strategy Logic

### Trading Flow

```
1. Calculate Asian Session Range (7 PM - 12 AM CST)
   └─> High and Low of Asian session

2. Determine Higher Timeframe Bias (H4 + D1)
   └─> BULLISH, BEARISH, or SIDEWAYS

3. Wait for Liquidity Sweep
   └─> Price breaks above Asian High OR below Asian Low

4. Detect Change of Character (CHOCH)
   └─> Price breaks previous swing high (bullish) or low (bearish)

5. Calculate Fair Value Gap (FVG)
   └─> Identify price gap between 3 candles

6. Market Condition Filters
   └─> Check ADX (trending market)
   └─> Check ATR (acceptable volatility)
   └─> Check Volume (above average)
   └─> Check RSI (momentum confirmation)
   └─> Check S/R levels (not too close)

7. Place Limit Order
   └─> Entry at 50% of FVG
   └─> Stop Loss: Asian range ± buffer
   └─> Take Profit: 1:1 extension from Asian range
```

### Entry Conditions (ALL must be met)

- ✅ Clear HTF bias (not sideways)
- ✅ Liquidity sweep occurred (high or low)
- ✅ Valid CHOCH detected
- ✅ FVG identified and validated
- ✅ Within trading session hours
- ✅ Market is trending (if filter enabled)
- ✅ Volatility is acceptable (if filter enabled)
- ✅ Volume confirmation passed (if filter enabled)
- ✅ Momentum confirmation passed (if filter enabled)
- ✅ Not too close to S/R levels (if filter enabled)
- ✅ Max trades per day not reached
- ✅ Safety checks passed

## 📦 Installation

### Step 1: Download Files

1. Clone this repository or download as ZIP
2. Extract files to your computer

### Step 2: Copy to MetaTrader

1. Open MetaTrader 4
2. Navigate to: `File → Open Data Folder`
3. Go to: `MQL4 → Experts`
4. Copy the following:
   - `SMC_Session_EA.mq4` → `Experts` folder
   - `SMC_Includes` folder → `Experts` folder

### Step 3: Compile

1. Open MetaEditor (F4 in MT4)
2. Open `SMC_Session_EA.mq4`
3. Press **F7** to compile
4. Verify: **0 errors, 0 warnings**

### Step 4: Attach to Chart

1. Open a chart (any timeframe)
2. Open Navigator (Ctrl+N)
3. Drag `SMC_Session_EA` onto chart
4. Configure settings (see [Configuration](#configuration))
5. Enable AutoTrading (green button in toolbar)

## ⚙️ Configuration

### Input Parameters

#### Basic Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `MagicNumber` | 123456 | Unique identifier for EA trades |
| `RiskPercent` | 0.5 | Risk per trade (% of account balance) |
| `SessionStartHour` | 2 | Trading session start (CST hour, 0-23) |
| `SessionEndHour` | 5 | Trading session end (CST hour, 0-23) |
| `StopBufferPips` | 5 | Stop loss buffer in pips |
| `MaxTradesPerDay` | 1 | Maximum trades per day per symbol |
| `TimezoneOffset` | -8 | Timezone offset (CST = -8) |

#### Multiple Sessions
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableMultiSessions` | false | Enable multiple trading sessions |
| `MultiSession1_Enabled` | true | Session 1 (default: 2-5 AM) |
| `MultiSession2_Enabled` | false | Session 2 (London: 8-11 AM) |
| `MultiSession3_Enabled` | false | Session 3 (NY: 2-5 PM) |
| `MultiSession4_Enabled` | false | Session 4 (custom) |
| `MultiSession5_Enabled` | false | Session 5 (custom) |

#### Market Filters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableMarketFilter` | true | Enable market condition filter |
| `TradeOnlyTrending` | true | Only trade in trending markets |
| `ADX_Period` | 14 | ADX period for trend detection |
| `ADX_Level` | 25 | ADX level (above = trending) |
| `ATR_Period` | 14 | ATR period for volatility |

#### Entry Filters
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableVolumeFilter` | true | Enable volume confirmation |
| `VolumePeriod` | 20 | Period for average volume |
| `VolumeMultiplier` | 1.2 | Volume must be X times average |
| `EnableMomentumFilter` | true | Enable momentum (RSI) filter |
| `MomentumPeriod` | 14 | RSI period |
| `MomentumLevel` | 50 | RSI level threshold |
| `EnableSRFilter` | true | Enable support/resistance filter |
| `SRLookback` | 50 | Bars to look back for S/R |
| `SRBufferPips` | 20 | Buffer in pips to avoid S/R |

#### Trade Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableTradeManagement` | true | Enable break-even & trailing stops |
| `EnableStatistics` | true | Enable performance statistics |
| `EnableAnalytics` | true | Enable enhanced analytics |
| `EnableSafetyChecks` | true | Enable safety features |
| `MaxDailyLossPercent` | 5.0 | Stop trading if daily loss > X% |
| `MaxDrawdownPercent` | 10.0 | Stop trading if drawdown > X% |

#### Alert System
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableAlerts` | true | Enable alert system |
| `AlertSweep` | true | Alert on liquidity sweep |
| `AlertTradePlaced` | true | Alert when trade is placed |
| `AlertBreakEven` | true | Alert when break-even is hit |
| `AlertTradeClosed` | true | Alert when trade is closed |
| `AlertPopup` | true | Show popup alerts |
| `AlertEmail` | false | Send email alerts (requires setup) |
| `AlertPush` | false | Send push notifications (requires mobile app) |

### Recommended Settings

**Conservative:**
- Risk: 0.5%
- Max Trades/Day: 1
- Max Daily Loss: 3%
- Market Filter: Enabled
- All Entry Filters: Enabled

**Moderate:**
- Risk: 1.0%
- Max Trades/Day: 2
- Max Daily Loss: 5%
- Market Filter: Enabled
- Entry Filters: Volume + Momentum

**Aggressive:**
- Risk: 1.5%
- Max Trades/Day: 3
- Max Daily Loss: 7%
- Market Filter: Optional
- Entry Filters: Volume only

## 🔔 Alert System

### Setup Email Alerts

1. In MT4: `Tools → Options → Email`
2. Configure SMTP settings:
   - **Gmail**: smtp.gmail.com, Port 587
   - **Outlook**: smtp-mail.outlook.com, Port 587
   - **Yahoo**: smtp.mail.yahoo.com, Port 587
3. Test email connection
4. Set `AlertEmail = true` in EA settings

### Setup Push Notifications

1. Install MetaTrader 4 mobile app (iOS/Android)
2. Log in with your broker account
3. Enable push notifications in app settings
4. In MT4 desktop: `Tools → Options → Notifications → Enable push`
5. Set `AlertPush = true` in EA settings

### Alert Types

- **Sweep Alert**: When liquidity sweep occurs (HIGH/LOW)
- **Trade Placed**: When limit order is placed (with entry, SL, TP)
- **Break-Even**: When stop loss moves to break-even
- **Trade Closed**: When trade closes (with P/L and reason)

## 📖 Usage Guide

### Basic Usage

1. **Attach EA to Chart**
   - Open any currency pair chart
   - Drag EA from Navigator to chart
   - Configure settings in Inputs tab
   - Click OK

2. **Verify EA is Running**
   - Check for smiley face in top-right corner
   - Check Experts tab for initialization message

3. **Monitor Performance**
   - Watch Experts tab for log messages
   - Check Terminal for open trades
   - Review statistics (printed daily)
   - Receive alerts for key events

### Multiple Sessions Setup

To trade during multiple sessions:

1. Set `EnableMultiSessions = true`
2. Enable desired sessions (Session 1, 2, 3, etc.)
3. Set start/end hours for each session
4. EA will trade during any enabled session

Example:
- Session 1: 2-5 AM (Asian)
- Session 2: 8-11 AM (London)
- Session 3: 2-5 PM (New York)

### Multiple Pairs

The EA can run on multiple pairs simultaneously:

1. Attach EA to each chart (EURUSD, GBPUSD, etc.)
2. Use same Magic Number to group trades
3. Or use different Magic Numbers to track separately
4. Each pair has independent trade limits

## 📁 File Structure

```
SMC_Sessions_EA/
├── SMC_Session_EA.mq4          # Main EA file
├── SMC_Includes/               # Include files folder
│   ├── session.mqh             # Session management & Asian range
│   ├── multi_session.mqh        # Multiple session support
│   ├── bias.mqh                # Higher timeframe bias detection
│   ├── liquidity.mqh           # Liquidity sweep detection
│   ├── structure.mqh           # CHOCH detection
│   ├── entry.mqh                # FVG calculation
│   ├── risk.mqh                 # Risk management & trade placement
│   ├── logger.mqh               # Logging functions
│   ├── trade_management.mqh    # Break-even, trailing stops
│   ├── statistics.mqh           # Performance statistics
│   ├── safety.mqh               # Safety features
│   ├── market_filter.mqh       # Market condition filters
│   ├── entry_filters.mqh       # Entry confirmation filters
│   ├── analytics.mqh            # Enhanced analytics
│   ├── backtesting.mqh         # Backtesting enhancements
│   └── alerts.mqh               # Alert system
├── README.md                    # This file
├── USAGE_GUIDE.md              # Detailed usage guide
└── INSTALLATION.md             # Installation instructions
```

## 🔧 Requirements

- **MetaTrader 4**: Version 4.0 or higher
- **Broker**: Any MT4 broker (demo or live)
- **Account**: Standard, ECN, or any account type
- **Symbols**: Works with any currency pair
- **Computer**: Windows (for MT4) or VPS for 24/7 operation

## 📊 Performance Features

### Statistics Tracking

The EA tracks and displays:
- Total trades (wins/losses)
- Win rate (%)
- Profit factor
- Max drawdown (%)
- Daily performance
- Session-based performance
- Pair-based performance

Statistics are printed:
- On initialization
- After each trade
- At end of day
- On EA removal

### Enhanced Analytics

- **Session Analytics**: Performance breakdown by trading session
- **Pair Analytics**: Performance breakdown by currency pair
- **Overall Metrics**: Comprehensive statistics across all trades
- **Backtesting Reports**: Detailed reports for Strategy Tester

### Safety Features

1. **Daily Loss Limit**: Stops trading if daily loss exceeds threshold
2. **Max Drawdown**: Stops trading if account drawdown exceeds limit
3. **Max Trades Per Day**: Limits number of trades per symbol per day
4. **Symbol Validation**: Checks if symbol is tradeable before trading
5. **Spread Warning**: Alerts if spread is unusually high

## 🔄 System Flow

For a detailed explanation of how the EA works, including complete flow diagrams, filter explanations, and trade management logic, see:

**[SYSTEM_FLOW.md](SYSTEM_FLOW.md)** - Complete system flow diagram and detailed explanations

This document covers:
- Complete flow diagram from tick to trade placement
- All 13 filters explained in detail
- Timing system and session management
- SMC entry logic (Bias, Sweep, CHOCH, FVG)
- Risk management calculations
- Trade management (break-even, trailing stops)
- Configuration parameters

## 🚀 Future Improvements

The following enhancements are planned for future versions:

### Trading Strategy Enhancements
- [ ] **Order Block Detection**: Identify institutional order blocks for entries
- [ ] **Imbalance Detection**: Enhanced FVG detection with quality scoring
- [ ] **Market Structure Analysis**: Advanced structure break detection
- [ ] **Liquidity Pool Identification**: Automatic liquidity zone detection
- [ ] **Multi-Pair Correlation**: Trade based on currency correlation
- [ ] **News Filter**: Avoid trading during high-impact news events
- [ ] **Session Strength Indicator**: Weight trades by session strength

### Risk Management
- [ ] **Dynamic Position Sizing**: Kelly Criterion or volatility-based sizing
- [ ] **Correlation-Based Risk**: Adjust risk for correlated pairs
- [ ] **Time-Based Risk**: Adjust risk based on time of day/week
- [ ] **Drawdown Recovery**: Automatic risk reduction during drawdown
- [ ] **Profit Target Scaling**: Multiple take profit levels

### Trade Management
- [ ] **Partial Profit Taking**: Multiple TP levels with partial closes
- [ ] **Trailing Stop Optimization**: Adaptive trailing stop based on volatility
- [ ] **Break-Even Optimization**: Dynamic break-even based on ATR
- [ ] **Trade Correlation Management**: Close correlated trades together
- [ ] **Time-Based Exits**: Exit trades at specific times

### Analytics & Reporting
- [ ] **Web Dashboard**: Real-time web-based performance dashboard
- [ ] **Trade Journal Export**: Export trades to CSV/Excel
- [ ] **Performance Attribution**: Analyze which filters contribute most
- [ ] **Optimization Reports**: Detailed optimization analysis
- [ ] **Risk Metrics**: Sharpe ratio, Sortino ratio, maximum adverse excursion

### User Interface
- [ ] **On-Chart Display**: Visual indicators on chart (FVG, sweeps, etc.)
- [ ] **Settings Panel**: GUI for easy configuration
- [ ] **Trade History Panel**: Visual trade history display
- [ ] **Performance Dashboard**: Real-time performance metrics on chart

### Technical Improvements
- [ ] **MQL5 Version**: Full MQL5 port with object-oriented design
- [ ] **Multi-Threading**: Parallel processing for multiple pairs
- [ ] **Database Integration**: Store trades in external database
- [ ] **API Integration**: Connect to external services (Telegram, Discord)
- [ ] **Machine Learning**: ML-based entry/exit optimization

### Alert Enhancements
- [ ] **Telegram Bot**: Send alerts via Telegram
- [ ] **Discord Webhooks**: Send alerts to Discord channels
- [ ] **SMS Integration**: SMS alerts via third-party service
- [ ] **Custom Alert Templates**: User-defined alert formats
- [ ] **Alert Scheduling**: Quiet hours for alerts

### Backtesting
- [ ] **Monte Carlo Simulation**: Risk analysis with Monte Carlo
- [ ] **Walk-Forward Analysis**: Automated walk-forward optimization
- [ ] **Out-of-Sample Testing**: Automatic OOS validation
- [ ] **Multi-Currency Backtesting**: Test across multiple pairs simultaneously

### Integration
- [ ] **MyFXBook Integration**: Automatic trade upload
- [ ] **TradingView Integration**: Sync with TradingView signals
- [ ] **cTrader Support**: Port to cTrader platform
- [ ] **Broker API Integration**: Direct broker API connection

## 🐛 Troubleshooting

### EA Not Trading

**Check:**
- [ ] AutoTrading button is enabled (green)
- [ ] EA is attached to chart (smiley face visible)
- [ ] Within trading session hours (2-5 AM CST by default)
- [ ] Max trades per day not reached
- [ ] Safety checks not blocking (check Experts tab)
- [ ] Market conditions meet all entry criteria
- [ ] Market filters not blocking (check ADX, ATR, etc.)

### Compilation Errors

**Common Issues:**
- Missing include files → Ensure `SMC_Includes` folder is in `Experts` folder
- MQL4 version → Ensure using MT4, not MT5
- File paths → Check include paths in main file

### No Trades After Several Days

**This is Normal If:**
- Market conditions don't meet all criteria
- No liquidity sweeps occurred
- No valid CHOCH detected
- No FVG formed
- Market filters are blocking trades

The EA is designed to wait for quality setups, not force trades.

### Alerts Not Working

**Email Alerts:**
- Check SMTP settings in MT4 Options
- Test email connection
- Check spam folder
- Verify firewall settings

**Push Notifications:**
- Ensure MT4 mobile app is installed and logged in
- Check phone notifications are enabled
- Verify MT4 desktop push notifications are enabled

### EA Stops Working

**Check:**
- Computer is on (or use VPS)
- MetaTrader 4 is running
- Internet connection is active
- AutoTrading is still enabled
- Check Experts/Journal tabs for errors

## 📝 Notes

- **Trading Hours**: EA trades during specified session(s) (default: 2-5 AM CST)
- **Trade Frequency**: Expect 0-5 trades per week (quality over quantity)
- **Timeframe**: EA uses multiple timeframes but can be attached to any chart
- **24/7 Operation**: Requires computer/VPS to be on 24/7 for continuous operation
- **Alert Frequency**: Alerts can be frequent during active trading; adjust settings as needed

## 🔒 Risk Warning

**Trading involves substantial risk of loss. This EA is provided for educational purposes. Always:**
- Test on demo account first
- Start with small risk (0.5% or less)
- Monitor performance regularly
- Never risk more than you can afford to lose
- Past performance does not guarantee future results

## 📄 License

This project is provided as-is for educational and personal use. Use at your own risk.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## 📧 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the Experts tab in MT4 for error messages
- Review the USAGE_GUIDE.md for detailed instructions

---

**Happy Trading! 📈**

*Remember: The best trading system is one that fits your risk tolerance and trading style. Always test thoroughly before live trading.*

---

## 📝 Credits

**Developed by:** @DPC Capital By DeeJay

*This Expert Advisor is created and maintained by DPC Capital. For support, questions, or collaboration opportunities, please reach out through GitHub issues or contact DPC Capital directly.*

---

**© 2024 DPC Capital | All Rights Reserved**
