# SMC Sessions EA - Complete System Flow Diagram

This document provides a detailed explanation of how the EA works, including timing, filters, entry logic, and trade management.

---

## 📊 Complete Flow Diagram

```
┌─────────────────────────────────────────────────┐
│           EVERY TICK (OnTick Function)          │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 0️⃣ Manage Existing Trades                        │
│    - Break-even moves                            │
│    - Trailing stops                              │
│    - Partial closes                              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 0.5️⃣ Check Closed Trades                         │
│    - Update statistics                           │
│    - Update analytics                            │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 1️⃣ Daily Reset Check                            │
│    - New day? Reset all flags                   │
│    - Recalculate Asian range                     │
│    - Reset statistics                            │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 2️⃣ Safety Checks                                │
│    ❌ Daily loss limit? → STOP                   │
│    ❌ Max drawdown? → STOP                       │
│    ❌ Max trades reached? → STOP                  │
│    ❌ Symbol invalid? → STOP                     │
│    ✅ All checks pass? → Continue                │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 3️⃣ Trading Session Check                        │
│    ❌ Not in trading hours? → STOP               │
│    ✅ In session? → Continue                     │
│    (Default: 2-5 AM CST, or multiple sessions)    │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 3.5️⃣ Market Condition Filter                    │
│    - Check ADX (trend strength)                  │
│    ❌ Market choppy (ADX < 25)? → STOP           │
│    ✅ Market trending? → Continue                │
│    (Configurable: TradeOnlyTrending)             │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 3.6️⃣ Volatility Filter                          │
│    - Check ATR (Average True Range)             │
│    ❌ ATR too low (< MinPips)? → STOP            │
│    ❌ ATR too high (> MaxPips)? → STOP            │
│    ✅ ATR acceptable? → Continue                 │
│    (Configurable: ATR_MinPips, ATR_MaxPips)       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 4️⃣ Calculate Asian Range                        │
│    - Scan H1 bars from 7 PM - 12 AM CST         │
│    - Find highest high (AsiaHigh)                │
│    - Find lowest low (AsiaLow)                   │
│    - Cache result (calculated once per day)      │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 5️⃣ Validate Asian Range                          │
│    ❌ No valid range? → STOP                     │
│    ❌ Range invalid (High <= Low)? → STOP        │
│    ✅ Range valid? → Continue                    │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 6️⃣ Higher Timeframe Bias                        │
│    - Analyze H4 structure (last 2 candles)        │
│    - Analyze D1 structure (context)                │
│    ❌ Sideways (no clear trend)? → STOP           │
│    ✅ Bullish (higher close + higher low)? → Continue
│    ✅ Bearish (lower close + lower high)? → Continue
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 7️⃣ Liquidity Sweep Check                        │
│    - Check M5 previous closed candle             │
│    - Compare high/low to Asian range             │
│    ✅ Price broke above AsiaHigh? → HIGH SWEEP    │
│    ✅ Price broke below AsiaLow? → LOW SWEEP      │
│    ❌ No sweep? → WAIT                           │
│    (Alert sent when sweep detected)               │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 8️⃣ Change of Character (CHOCH)                  │
│    - Find swing points on H1 timeframe          │
│    - Check if price breaks swing structure       │
│    ✅ Price broke above swing high? → Bullish CHOCH
│    ✅ Price broke below swing low? → Bearish CHOCH
│    ❌ No CHOCH? → WAIT                           │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 9️⃣ Fair Value Gap (FVG) Calculation             │
│    - Analyze 3 M5 candles for price gap          │
│    - Bullish FVG: Candle 0 low > Candle 2 high  │
│    - Bearish FVG: Candle 0 high < Candle 2 low   │
│    - Entry Price = 50% of FVG (middle of gap)    │
│    ❌ No FVG? → WAIT                             │
│    ✅ FVG found? → Continue                      │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 9.5️⃣ Entry Confirmation Filters                 │
│    ┌─────────────────────────────────────────┐   │
│    │ Filter 1: Volume Confirmation           │   │
│    │ ❌ Volume < (Avg × Multiplier)? → STOP │   │
│    │ ✅ Volume sufficient? → Continue        │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ┌─────────────────────────────────────────┐   │
│    │ Filter 2: Momentum (RSI)                 │   │
│    │ ❌ RSI doesn't align with bias? → STOP   │   │
│    │ ✅ RSI confirms momentum? → Continue     │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ┌─────────────────────────────────────────┐   │
│    │ Filter 3: Support/Resistance               │   │
│    │ ❌ Too close to S/R level? → STOP        │   │
│    │ ✅ Safe distance from S/R? → Continue     │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ✅ ALL FILTERS PASS → Continue                 │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 🔟 Risk Management & Trade Placement             │
│    ┌─────────────────────────────────────────┐   │
│    │ Step 1: Calculate Lot Size              │   │
│    │ - Risk Amount = Balance × Risk%         │   │
│    │ - Stop Distance = |Entry - Stop Loss|    │   │
│    │ - Lot Size = Risk / Distance            │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ┌─────────────────────────────────────────┐   │
│    │ Step 2: Calculate Stop Loss              │   │
│    │ - Bullish: AsiaLow - Buffer (5 pips)    │   │
│    │ - Bearish: AsiaHigh + Buffer (5 pips)    │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ┌─────────────────────────────────────────┐   │
│    │ Step 3: Calculate Take Profit             │   │
│    │ - TP = Asian Range + (Range × 1.0)       │   │
│    │ - 1:1 extension from Asian range         │   │
│    └─────────────────────────────────────────┘   │
│                    │                              │
│                    ▼                              │
│    ┌─────────────────────────────────────────┐   │
│    │ Step 4: Place Limit Order                 │   │
│    │ - Buy Limit: Entry below current price   │   │
│    │ - Sell Limit: Entry above current price  │   │
│    │ - Validate prices and lot size          │   │
│    │ ✅ Order placed? → DONE                   │   │
│    │ ❌ Order failed? → Log error              │   │
│    └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ ✅ Trade Placed Successfully                     │
│    - Set TradeTakenToday = true                 │
│    - Send alert (popup/email/push)               │
│    - Log trade details                           │
│    - Update statistics                           │
└─────────────────────────────────────────────────┘
```

---

## 🔄 Continuous Trade Management (Every Tick)

While the EA searches for new trades, it also actively manages existing open positions:

```
┌─────────────────────────────────────────────────┐
│         ManageTrades() - Every Tick              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ For Each Open Trade (EA's Magic Number)         │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 1️⃣ Partial Close Check (Optional)                │
│    - Profit >= PartialClosePips (30 pips)?      │
│    ✅ Yes → Close 50% of position                │
│    ❌ No → Continue                              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 2️⃣ Break-Even Move                               │
│    - Profit >= BreakEvenPips (20 pips)?          │
│    ✅ Yes → Move SL to Entry + 5 pips            │
│    - Send break-even alert                       │
│    ❌ No → Continue                              │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ 3️⃣ Trailing Stop                                 │
│    - Profit > BreakEvenPips?                     │
│    ✅ Yes → Trail SL by 15 pips                  │
│    - Only move if profit increases by 5 pips     │
│    - Update SL as price moves favorably          │
│    ❌ No → Continue                              │
└─────────────────────────────────────────────────┘
```

---

## ⏰ Timing System

### Daily Cycle

```
00:00 AM (Midnight)
├─ Daily Reset
│  ├─ Reset all flags
│  ├─ Reset statistics
│  └─ Prepare for new day
│
07:00 PM - 12:00 AM (Asian Session)
├─ Calculate Asian Range
│  ├─ Scan H1 bars
│  ├─ Find highest high
│  └─ Find lowest low
│
02:00 AM - 05:00 AM (Trading Session - Default)
├─ EA Actively Searching
│  ├─ Check all filters
│  ├─ Monitor for sweeps
│  ├─ Wait for CHOCH
│  └─ Place trades when ready
│
05:00 AM - 02:00 AM (Next Day)
├─ EA Inactive (No New Trades)
│  └─ Only manages existing trades
```

### Multiple Sessions (If Enabled)

```
Session 1: 1:00 AM - 6:00 AM (Asian/London Overlap)
Session 2: 8:00 AM - 11:00 AM (London Session)
Session 3: 2:00 PM - 5:00 PM (New York Session)
Session 4: 8:00 PM - 11:00 PM (Custom)
Session 5: 12:00 AM - 2:00 AM (Custom)
```

---

## 🎯 Filter System (All Must Pass)

### Safety Filters (Always Active)
1. **Daily Loss Limit**: Stops if daily loss > 5%
2. **Max Drawdown**: Stops if drawdown > 10%
3. **Max Trades**: Limits trades per day (default: 1)
4. **Symbol Validation**: Ensures symbol is tradeable

### Market Condition Filters
5. **ADX Trend Filter**: Only trades in trending markets (ADX >= 25)
6. **ATR Volatility Filter**: ATR must be between MinPips and MaxPips

### Entry Confirmation Filters
7. **Volume Filter**: Current volume must be above average
8. **Momentum Filter**: RSI must align with bias direction
9. **S/R Filter**: Entry must be safe distance from support/resistance

### SMC Strategy Filters
10. **HTF Bias**: Must have clear bullish or bearish structure
11. **Liquidity Sweep**: Price must break Asian high/low
12. **CHOCH**: Structural break must occur
13. **FVG**: Valid price gap must exist

**Total: 13 filters - ALL must pass for a trade!**

---

## 📈 Entry Logic (SMC Concepts)

### 1. Higher Timeframe Bias
- **Timeframes**: H4 (primary) + D1 (context)
- **Bullish**: Higher close + Higher low (uptrend structure)
- **Bearish**: Lower close + Lower high (downtrend structure)
- **Sideways**: No clear structure → Skip day

### 2. Liquidity Sweep
- **What**: Price breaks Asian session high or low
- **Why**: Institutional traders trigger stops (liquidity)
- **Detection**: M5 previous closed candle vs Asian range
- **Result**: Sweep flag set (High or Low)

### 3. Change of Character (CHOCH)
- **What**: Structural break in market direction
- **How**: Price breaks previous swing high (bullish) or low (bearish)
- **Timeframe**: H1 for swing detection, M5 for confirmation
- **Purpose**: Confirms trend reversal after sweep

### 4. Fair Value Gap (FVG)
- **What**: Price gap (inefficiency) between 3 candles
- **Bullish FVG**: Candle 0 low > Candle 2 high (gap up)
- **Bearish FVG**: Candle 0 high < Candle 2 low (gap down)
- **Entry**: 50% of FVG (middle of gap)
- **Why**: Price tends to fill gaps (inefficiency)

---

## 💰 Risk Management

### Lot Size Calculation
```
Step 1: Calculate Risk Amount
Risk Amount = Account Balance × (RiskPercent / 100)
Example: $10,000 × 0.5% = $50

Step 2: Calculate Stop Distance
Stop Distance = |Entry Price - Stop Loss|
Example: |1.0835 - 1.0820| = 0.0015 (15 pips)

Step 3: Calculate Lot Size
Lot Size = (Risk Amount / Stop Distance) × (Tick Size / Tick Value)
Result: Lot size that risks exactly $50
```

### Stop Loss Placement
- **Bullish Trades**: `Stop Loss = AsiaLow - StopBufferPips`
- **Bearish Trades**: `Stop Loss = AsiaHigh + StopBufferPips`
- **Buffer**: Default 5 pips (configurable)
- **Purpose**: Places stop below/above liquidity zone

### Take Profit Placement
- **Formula**: `TP = Asian Range + (Asian Range Size × 1.0)`
- **Example**: If Asian range is 30 pips, TP is 30 pips beyond range
- **Purpose**: Targets 1:1 extension (risk:reward = 1:1)

---

## 🛡️ Trade Management

### Break-Even Move
- **Trigger**: Profit reaches `BreakEvenPips` (default: 20 pips)
- **Action**: 
  - Buy orders: Move SL to Entry + 5 pips
  - Sell orders: Move SL to Entry - 5 pips
- **Purpose**: Locks in small profit, eliminates risk
- **Alert**: Sends break-even alert when triggered

### Trailing Stop
- **Trigger**: After break-even is moved
- **Distance**: Trails by `TrailingStopPips` (default: 15 pips)
- **Step**: Only moves if profit increases by `TrailingStepPips` (default: 5 pips)
- **Purpose**: Locks in profits as trade moves favorably
- **Example**: 
  - Entry: 1.0835
  - Break-even: 1.0840 (at 20 pips profit)
  - Trailing: SL moves to 1.0845 (at 25 pips profit)
  - Continues trailing as price moves up

### Partial Close (Optional)
- **Trigger**: Profit reaches `PartialClosePips` (default: 30 pips)
- **Action**: Closes `PartialClosePercent` (default: 50%) of position
- **Purpose**: Secures profit while letting winners run
- **Status**: Disabled by default (can be enabled in code)

---

## 📊 Statistics & Analytics

### Real-Time Tracking
- **Daily Statistics**: Trades, wins, losses, P/L for current day
- **Overall Statistics**: Total trades, win rate, profit factor
- **Session Analytics**: Performance breakdown by trading session
- **Pair Analytics**: Performance breakdown by currency pair

### Updates
- **On Trade Close**: Statistics updated automatically
- **Daily Reset**: Statistics reset at midnight
- **On EA Removal**: Final statistics printed

---

## 🔔 Alert System

### Alert Types
1. **Sweep Alert**: When liquidity sweep occurs
2. **Trade Placed**: When limit order is placed
3. **Break-Even**: When stop loss moves to break-even
4. **Trade Closed**: When trade closes (with P/L and reason)

### Alert Methods
- **Popup**: Desktop notification with sound (default: ON)
- **Email**: Email notification (requires SMTP setup)
- **Push**: Mobile app notification (requires MT4 mobile app)

---

## 🎛️ Configuration Parameters

### Timing
- `SessionStartHour`: Trading session start (default: 2 AM CST)
- `SessionEndHour`: Trading session end (default: 5 AM CST)
- `TimezoneOffset`: Timezone offset (default: -8 for CST)
- `EnableMultiSessions`: Enable multiple sessions (default: false)

### Risk Management
- `RiskPercent`: Risk per trade % (default: 0.5%)
- `StopBufferPips`: Stop loss buffer (default: 5 pips)
- `MaxTradesPerDay`: Maximum trades per day (default: 1)

### Market Filters
- `EnableMarketFilter`: Enable market condition filter (default: true)
- `TradeOnlyTrending`: Only trade in trending markets (default: true)
- `ADX_Level`: ADX threshold for trending (default: 25)
- `ATR_MinPips`: Minimum ATR in pips (default: 10.0)
- `ATR_MaxPips`: Maximum ATR in pips (default: 100.0)

### Entry Filters
- `EnableVolumeFilter`: Enable volume confirmation (default: true)
- `EnableMomentumFilter`: Enable RSI momentum filter (default: true)
- `EnableSRFilter`: Enable S/R distance filter (default: true)

### Trade Management
- `EnableTradeManagement`: Enable break-even & trailing (default: true)
- `BreakEvenPips`: Move to break-even at X pips (default: 20)
- `TrailingStopPips`: Trailing stop distance (default: 15 pips)

### Safety
- `MaxDailyLossPercent`: Stop if daily loss > X% (default: 5.0%)
- `MaxDrawdownPercent`: Stop if drawdown > X% (default: 10.0%)
- `EnableSafetyChecks`: Enable all safety features (default: true)

---

## 🔍 Decision Points Summary

### Must Pass (All Required)
✅ Safety checks passed  
✅ Within trading session hours  
✅ Market is trending (if filter enabled)  
✅ Volatility is acceptable (ATR in range)  
✅ Asian range calculated and valid  
✅ Clear HTF bias (bullish or bearish)  
✅ Liquidity sweep occurred  
✅ CHOCH detected  
✅ FVG identified  
✅ Volume confirmation passed  
✅ Momentum confirmation passed  
✅ S/R distance acceptable  
✅ Max trades not reached  

### If Any Fails
❌ EA waits for next tick or next day  
❌ No trade placed  
❌ Logs reason (if applicable)  

---

## 📝 Key Concepts Explained

### Why Asian Session Range?
- Asian session (7 PM - 12 AM CST) is when liquidity builds
- Institutional traders place orders at session highs/lows
- These become "liquidity zones" that get swept later

### Why Liquidity Sweep?
- When price breaks Asian high/low, it triggers stops
- This creates a "sweep" of liquidity
- After sweep, price often reverses (smart money enters)

### Why CHOCH?
- Change of Character confirms structural break
- Shows market direction has changed
- Validates that reversal is genuine, not just a pullback

### Why FVG?
- Fair Value Gap is a price inefficiency (gap)
- Price tends to fill gaps
- Entry at 50% of gap provides good risk/reward

### Why So Many Filters?
- Quality over quantity
- Each filter reduces false signals
- Combined filters ensure only high-probability setups trade
- Better win rate = better profitability

---

## 🎯 Expected Behavior

### Normal Operation
- **Trade Frequency**: 0-5 trades per week (by design)
- **Filter Messages**: Normal (shows EA is working)
- **Waiting Periods**: Common (waiting for all conditions)
- **Selectivity**: High (only best setups trade)

### What to Expect
- Days with no trades: **Normal** (filters are working)
- Multiple filter rejections: **Normal** (quality control)
- Trades only when all align: **Expected** (by design)

---

**This EA is designed to be selective and wait for high-probability setups. The multiple filters ensure quality over quantity.**

