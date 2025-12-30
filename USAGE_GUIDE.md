# SMC Sessions EA - Complete Usage Guide

## 📚 Table of Contents

1. [Getting Started](#getting-started)
2. [Initial Setup](#initial-setup)
3. [Daily Operation](#daily-operation)
4. [Monitoring & Analysis](#monitoring--analysis)
5. [Advanced Configuration](#advanced-configuration)
6. [Multiple Pairs Setup](#multiple-pairs-setup)
7. [VPS Setup](#vps-setup)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## 🚀 Getting Started

### Prerequisites

Before using the EA, ensure you have:

- ✅ MetaTrader 4 installed
- ✅ Active broker account (demo or live)
- ✅ Stable internet connection
- ✅ Basic understanding of forex trading

### First-Time Setup

1. **Install the EA**
   ```
   Copy SMC_Session_EA.mq4 → MT4/Experts folder
   Copy SMC_Includes folder → MT4/Experts folder
   ```

2. **Compile the EA**
   - Open MetaEditor (F4)
   - Open SMC_Session_EA.mq4
   - Press F7 to compile
   - Verify: 0 errors, 0 warnings

3. **Test on Demo Account**
   - Always test on demo first!
   - Run for at least 1 week
   - Monitor all trades
   - Review statistics

---

## ⚙️ Initial Setup

### Step 1: Attach EA to Chart

1. Open MetaTrader 4
2. Open a chart (e.g., EURUSD)
3. Press **Ctrl+N** to open Navigator
4. Expand "Expert Advisors"
5. Find "SMC_Session_EA"
6. **Drag and drop** onto chart

### Step 2: Configure Settings

When the settings window opens:

#### **Basic Settings:**
- **Magic Number**: 123456 (or unique number)
- **Risk Percent**: 0.5% (start conservative)
- **Session Start Hour**: 2 (2:00 AM CST)
- **Session End Hour**: 5 (5:00 AM CST)

#### **Risk Management:**
- **Stop Buffer Pips**: 5
- **Max Trades Per Day**: 1
- **Max Daily Loss Percent**: 5.0%
- **Max Drawdown Percent**: 10.0%

#### **Features:**
- **Enable Trade Management**: ✓ (checked)
- **Enable Statistics**: ✓ (checked)
- **Enable Safety Checks**: ✓ (checked)

#### **Timezone:**
- **Timezone Offset**: -8 (CST)

### Step 3: Enable AutoTrading

1. Look at the top toolbar
2. Find the **AutoTrading** button
3. Click to enable (should turn **green**)
4. Verify EA shows **smiley face** on chart

### Step 4: Verify Initialization

1. Open **Experts** tab (bottom panel)
2. Look for initialization message:
   ```
   === SMC Sessions EA Initialized ===
   Magic Number: 123456
   Risk Per Trade: 0.5%
   Session: 2:00 - 5:00 CST
   ...
   ```
3. If you see errors, check [Troubleshooting](#troubleshooting)

---

## 📅 Daily Operation

### What Happens Each Day

#### **Morning (Before Session)**
- EA calculates Asian session range (7 PM - 12 AM CST previous day)
- Monitors market conditions
- Waits for trading session

#### **During Trading Session (2-5 AM CST)**
- Checks for entry conditions:
  1. HTF bias (bullish/bearish)
  2. Liquidity sweep
  3. CHOCH
  4. FVG
- Places limit order if all conditions met
- Manages existing trades

#### **After Session**
- Continues managing open trades
- Updates statistics
- Waits for next day

### What to Monitor Daily

1. **Experts Tab**
   - Check for initialization
   - Review log messages
   - Look for errors

2. **Terminal Tab**
   - Check for new trades
   - Monitor open positions
   - Review trade history

3. **Statistics**
   - Daily win rate
   - Profit/loss
   - Trade count

---

## 📊 Monitoring & Analysis

### Understanding Log Messages

#### **Initialization:**
```
=== SMC Sessions EA Initialized ===
```
✅ EA started successfully

#### **Asian Range:**
```
Asian range calculated: High 1.1050, Low 1.1020
```
✅ Asian session range found

#### **Liquidity Sweep:**
```
Liquidity sweep detected (High)
```
✅ Price broke Asian high/low

#### **CHOCH:**
```
CHOCH detected (Bullish)
```
✅ Market structure changed

#### **FVG:**
```
FVG calculated, entry at 1.1035
```
✅ Entry point identified

#### **Trade Placed:**
```
Trade placed successfully at 1.1035
```
✅ Limit order placed

#### **Trade Management:**
```
Break-even moved: Ticket 12345 at 20.0 pips
Trailing stop updated: Ticket 12345 to 1.1045
```
✅ Trade being managed

### Statistics Interpretation

#### **Daily Statistics:**
```
=== SMC EA Statistics ===
Today: 1 trades | Wins: 1 | Losses: 0
Today P/L: +$50.00
Win Rate: 100.0%
```

#### **Overall Statistics:**
```
Overall: 10 trades | Wins: 7 | Losses: 3
Win Rate: 70.0%
Profit Factor: 2.33
Max Drawdown: 3.5%
```

**Key Metrics:**
- **Win Rate**: % of winning trades (aim for >50%)
- **Profit Factor**: Total profit / Total loss (aim for >1.5)
- **Max Drawdown**: Largest equity drop (keep <10%)

---

## 🔧 Advanced Configuration

### Timezone Setup

The EA uses CST by default. To change:

1. **Find Your Timezone Offset:**
   - EST: UTC-5 → Offset: -5
   - CST: UTC-6 → Offset: -8 (default)
   - PST: UTC-8 → Offset: -8
   - GMT: UTC+0 → Offset: 0

2. **Set TimezoneOffset Parameter:**
   - Open EA settings
   - Change `TimezoneOffset` to your offset
   - Click OK

### Session Hours Adjustment

To trade different hours:

1. **Calculate CST Hours:**
   - Example: Want to trade 8-11 AM EST
   - EST is UTC-5, CST is UTC-6
   - 8 AM EST = 7 AM CST
   - Set: SessionStartHour = 7, SessionEndHour = 10

2. **24-Hour Format:**
   - 0 = midnight
   - 12 = noon
   - 23 = 11 PM

### Risk Management Tuning

#### **Conservative:**
```
RiskPercent: 0.5%
MaxTradesPerDay: 1
MaxDailyLossPercent: 3.0%
MaxDrawdownPercent: 8.0%
```

#### **Moderate:**
```
RiskPercent: 1.0%
MaxTradesPerDay: 2
MaxDailyLossPercent: 5.0%
MaxDrawdownPercent: 10.0%
```

#### **Aggressive:**
```
RiskPercent: 1.5%
MaxTradesPerDay: 3
MaxDailyLossPercent: 7.0%
MaxDrawdownPercent: 15.0%
```

### Trade Management Customization

To modify break-even/trailing stop settings, edit `SMC_Includes/trade_management.mqh`:

```mq4
bool EnableBreakEven = true;
int BreakEvenPips = 20;  // Change this
bool EnableTrailingStop = true;
int TrailingStopPips = 15;  // Change this
int TrailingStepPips = 5;   // Change this
```

Then recompile the EA.

---

## 🔄 Multiple Pairs Setup

### Running on Multiple Pairs

1. **Open Multiple Charts:**
   - EURUSD
   - GBPUSD
   - USDJPY
   - etc.

2. **Attach EA to Each:**
   - Drag EA to each chart
   - Configure settings (can be different per pair)
   - Use same Magic Number to group, or different to track separately

3. **Independent Operation:**
   - Each pair trades independently
   - Each has its own daily trade limit
   - Statistics tracked per symbol

### Magic Number Strategy

#### **Option 1: Same Magic Number**
- All pairs share same Magic Number
- Unified tracking
- Shared daily loss limit
- Easier overall monitoring

#### **Option 2: Different Magic Numbers**
- Each pair has unique Magic Number
- Separate tracking per pair
- Individual daily loss limits
- More granular control

**Example:**
```
EURUSD: MagicNumber = 111111
GBPUSD: MagicNumber = 222222
USDJPY: MagicNumber = 333333
```

---

## 💻 VPS Setup

### Why Use a VPS?

- ✅ 24/7 operation
- ✅ Low latency
- ✅ Stable connection
- ✅ No impact on your PC

### VPS Setup Steps

1. **Choose VPS Provider:**
   - FXVM.net (trading-focused)
   - Amazon AWS
   - DigitalOcean
   - Vultr

2. **Install MetaTrader 4:**
   - Download MT4 installer
   - Install on VPS
   - Connect to your broker

3. **Transfer EA Files:**
   - Use Remote Desktop
   - Copy `SMC_Session_EA.mq4` to VPS
   - Copy `SMC_Includes` folder to VPS
   - Place in `MT4/MQL4/Experts/`

4. **Compile on VPS:**
   - Open MetaEditor on VPS
   - Open `SMC_Session_EA.mq4`
   - Press F7 to compile

5. **Configure EA:**
   - Attach to chart
   - Configure settings
   - Enable AutoTrading

6. **Monitor Remotely:**
   - Use Remote Desktop
   - Or MT4 mobile app
   - Check trades from anywhere

### VPS Requirements

- **RAM**: 1-2 GB (minimum)
- **CPU**: 1-2 cores
- **Storage**: 20-40 GB
- **OS**: Windows Server
- **Location**: Close to broker server

---

## 🐛 Troubleshooting

### EA Not Trading

**Checklist:**
- [ ] AutoTrading enabled (green button)
- [ ] EA attached (smiley face visible)
- [ ] Within trading session hours
- [ ] Max trades per day not reached
- [ ] Safety checks passed
- [ ] Market conditions met

**Solution:**
- Check Experts tab for messages
- Verify all conditions are met
- Wait for next trading session

### Compilation Errors

**Error: "Cannot open include file"**
- Solution: Ensure `SMC_Includes` folder is in `Experts` folder
- Check include paths in main file

**Error: "Undeclared identifier"**
- Solution: Recompile all files
- Check for missing includes

### No Trades After Days

**This is Normal:**
- EA waits for quality setups
- Not all days have valid conditions
- 0-3 trades per week is typical

**If Concerned:**
- Check Asian range is calculating
- Verify timezone is correct
- Review log messages
- Check if all conditions are being met

### EA Stops Working

**Check:**
- Computer is on (or VPS running)
- MT4 is running
- Internet connected
- AutoTrading still enabled
- No errors in Experts/Journal tabs

**Solution:**
- Restart MT4
- Reattach EA
- Check for error messages

### Performance Issues

**EA Running Slow:**
- Close other programs
- Reduce number of charts
- Use VPS for better performance

**High CPU Usage:**
- Normal during trading session
- Should be minimal outside session
- Check for infinite loops (shouldn't happen)

---

## 💡 Best Practices

### Risk Management

1. **Start Small:**
   - Use 0.5% risk initially
   - Increase gradually if comfortable

2. **Set Limits:**
   - Max daily loss: 3-5%
   - Max drawdown: 8-10%
   - Max trades per day: 1-2

3. **Monitor Regularly:**
   - Check daily
   - Review weekly statistics
   - Adjust if needed

### Testing

1. **Demo First:**
   - Test for at least 1 week
   - Monitor all trades
   - Understand behavior

2. **Small Live:**
   - Start with minimum lot size
   - Gradually increase
   - Never risk more than you can afford

3. **Continuous Monitoring:**
   - Review performance weekly
   - Adjust settings as needed
   - Keep learning

### Maintenance

1. **Daily:**
   - Check Experts tab
   - Verify EA is running
   - Review any errors

2. **Weekly:**
   - Review statistics
   - Analyze performance
   - Adjust if needed

3. **Monthly:**
   - Full performance review
   - Strategy evaluation
   - Settings optimization

### Computer Setup

1. **Keep Computer On:**
   - Or use VPS
   - Screen can sleep (computer must stay on)
   - Set sleep to "Never"

2. **Stable Internet:**
   - Use wired connection if possible
   - Ensure reliable connection
   - Consider backup connection

3. **System Maintenance:**
   - Keep Windows updated
   - Keep MT4 updated
   - Regular system maintenance

---

## 📞 Support

### Getting Help

1. **Check Documentation:**
   - README.md
   - This guide
   - Code comments

2. **Check Logs:**
   - Experts tab
   - Journal tab
   - Error messages

3. **GitHub Issues:**
   - Open an issue
   - Provide error messages
   - Include MT4 version

### Common Questions

**Q: How many trades per week?**
A: Typically 0-3 trades per week. Quality over quantity.

**Q: Can I change trading hours?**
A: Yes, adjust SessionStartHour and SessionEndHour parameters.

**Q: Does it work on all pairs?**
A: Yes, works on any currency pair. Some pairs may have more opportunities.

**Q: Can I run multiple instances?**
A: Yes, attach to multiple charts. Each runs independently.

**Q: Do I need VPS?**
A: Not required, but recommended for 24/7 operation.

---

**Remember:** Trading involves risk. Always test thoroughly and never risk more than you can afford to lose.

**Happy Trading! 📈**

