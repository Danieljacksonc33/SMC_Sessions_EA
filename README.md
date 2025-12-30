# SMC Sessions Expert Advisor (EA)

A sophisticated MetaTrader 4 Expert Advisor implementing Smart Money Concepts (SMC) trading strategy with session-based analysis, liquidity sweeps, change of character (CHOCH) detection, and Fair Value Gap (FVG) entries.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Strategy Logic](#strategy-logic)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [File Structure](#file-structure)
- [Requirements](#requirements)
- [Performance Features](#performance-features)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## 🎯 Overview

The SMC Sessions EA is an automated trading system that combines Smart Money Concepts with session-based analysis. It identifies high-probability trading opportunities by:

1. **Session Analysis**: Calculates Asian session range (7 PM - 12 AM CST)
2. **Higher Timeframe Bias**: Determines market direction using H4 and D1 timeframes
3. **Liquidity Sweeps**: Detects when price breaks Asian session highs/lows
4. **Change of Character (CHOCH)**: Identifies structural breaks in market direction
5. **Fair Value Gap (FVG)**: Finds price inefficiencies for optimal entry points

## ✨ Features

### Core Trading Features
- ✅ **Session-Based Trading**: Trades only during specified hours (default: 2-5 AM CST)
- ✅ **Multi-Timeframe Analysis**: Uses M5, H1, H4, and D1 for comprehensive market analysis
- ✅ **Smart Entry System**: FVG-based entries at 50% retracement
- ✅ **Risk Management**: Dynamic lot sizing based on account risk percentage
- ✅ **Limit Orders**: Places limit orders at calculated FVG entry points

### Advanced Features
- ✅ **Active Trade Management**: Break-even moves, trailing stops, partial closes
- ✅ **Performance Statistics**: Real-time tracking of win rate, profit factor, drawdown
- ✅ **Safety Features**: Daily loss limits, max drawdown protection, max trades per day
- ✅ **Symbol Validation**: Checks if symbol is tradeable before trading
- ✅ **Magic Number System**: Unique trade identification for multiple EA instances

### Technical Features
- ✅ **Cached Calculations**: Efficient Asian range calculation (once per day)
- ✅ **Swing Point Detection**: Advanced CHOCH detection using actual swing highs/lows
- ✅ **MQL4 Compatible**: Fully optimized for MetaTrader 4
- ✅ **Modular Code**: Clean, organized codebase with separate modules

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

6. Place Limit Order
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

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MagicNumber` | 123456 | Unique identifier for EA trades |
| `RiskPercent` | 0.5 | Risk per trade (% of account balance) |
| `SessionStartHour` | 2 | Trading session start (CST hour, 0-23) |
| `SessionEndHour` | 5 | Trading session end (CST hour, 0-23) |
| `StopBufferPips` | 5 | Stop loss buffer in pips |
| `MaxTradesPerDay` | 1 | Maximum trades per day per symbol |
| `EnableTradeManagement` | true | Enable break-even & trailing stops |
| `EnableStatistics` | true | Enable performance statistics |
| `EnableSafetyChecks` | true | Enable safety features |
| `MaxDailyLossPercent` | 5.0 | Stop trading if daily loss > X% |
| `MaxDrawdownPercent` | 10.0 | Stop trading if drawdown > X% |
| `TimezoneOffset` | -8 | Timezone offset (CST = -8) |

### Recommended Settings

**Conservative:**
- Risk: 0.5%
- Max Trades/Day: 1
- Max Daily Loss: 3%

**Moderate:**
- Risk: 1.0%
- Max Trades/Day: 2
- Max Daily Loss: 5%

**Aggressive:**
- Risk: 1.5%
- Max Trades/Day: 3
- Max Daily Loss: 7%

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

### Multiple Pairs

The EA can run on multiple pairs simultaneously:

1. Attach EA to each chart (EURUSD, GBPUSD, etc.)
2. Use same Magic Number to group trades
3. Or use different Magic Numbers to track separately
4. Each pair has independent trade limits

### Trade Management Settings

**Break-Even:**
- Moves stop loss to entry + 5 pips after 20 pips profit
- Enabled by default

**Trailing Stop:**
- Activates after break-even
- Trails by 15 pips with 5 pip step
- Enabled by default

**Partial Close:**
- Closes 50% of position at 30 pips profit
- Disabled by default (can be enabled in code)

### Timezone Configuration

The EA uses CST (Central Standard Time) by default. To adjust:

1. Find your timezone offset from UTC
2. Set `TimezoneOffset` parameter:
   - EST: -5
   - CST: -8 (default)
   - PST: -8
   - GMT: 0
   - For other timezones, calculate: `(Your UTC offset) - (CST offset)`

## 📁 File Structure

```
SMC_Sessions_EA/
├── SMC_Session_EA.mq4          # Main EA file
├── SMC_Includes/               # Include files folder
│   ├── session.mqh             # Session management & Asian range
│   ├── bias.mqh                # Higher timeframe bias detection
│   ├── liquidity.mqh           # Liquidity sweep detection
│   ├── structure.mqh           # CHOCH detection
│   ├── entry.mqh                # FVG calculation
│   ├── risk.mqh                 # Risk management & trade placement
│   ├── logger.mqh               # Logging functions
│   ├── trade_management.mqh    # Break-even, trailing stops
│   ├── statistics.mqh           # Performance statistics
│   └── safety.mqh               # Safety features
├── README.md                    # This file
└── USAGE_GUIDE.md              # Detailed usage guide
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

Statistics are printed:
- On initialization
- After each trade
- At end of day
- On EA removal

### Safety Features

1. **Daily Loss Limit**: Stops trading if daily loss exceeds threshold
2. **Max Drawdown**: Stops trading if account drawdown exceeds limit
3. **Max Trades Per Day**: Limits number of trades per symbol per day
4. **Symbol Validation**: Checks if symbol is tradeable before trading
5. **Spread Warning**: Alerts if spread is unusually high

## 🐛 Troubleshooting

### EA Not Trading

**Check:**
- [ ] AutoTrading button is enabled (green)
- [ ] EA is attached to chart (smiley face visible)
- [ ] Within trading session hours (2-5 AM CST by default)
- [ ] Max trades per day not reached
- [ ] Safety checks not blocking (check Experts tab)
- [ ] Market conditions meet all entry criteria

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

The EA is designed to wait for quality setups, not force trades.

### EA Stops Working

**Check:**
- Computer is on (or use VPS)
- MetaTrader 4 is running
- Internet connection is active
- AutoTrading is still enabled
- Check Experts/Journal tabs for errors

## 📝 Notes

- **Trading Hours**: EA trades during specified session (default: 2-5 AM CST)
- **Trade Frequency**: Expect 0-3 trades per week (quality over quantity)
- **Timeframe**: EA uses multiple timeframes but can be attached to any chart
- **24/7 Operation**: Requires computer/VPS to be on 24/7 for continuous operation

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

