# Multi-Pair Trading Limit Feature

## Overview

This feature limits the EA to trade on a maximum number of pairs simultaneously. Once the limit is reached, all EA instances stop searching for new setups, but continue managing existing trades.

## How It Works

### Logic Flow

1. **EA runs on multiple pairs** (e.g., EURUSD, GBPUSD, USDJPY)
2. **Each EA checks** how many unique pairs currently have open trades
3. **If limit reached** (default: 2 pairs):
   - All EAs stop searching for new setups
   - EAs with existing trades continue managing them (break-even, trailing stops, etc.)
   - Dashboard shows limit status

### Key Features

- ✅ **Global Limit**: Works across all EA instances using the same Magic Number
- ✅ **Smart Detection**: Counts unique pairs, not total trades
- ✅ **Existing Trade Management**: EAs with open trades continue managing them
- ✅ **Dashboard Display**: Shows current pairs and limit status
- ✅ **Configurable**: Set `MaxPairsTrading` to adjust limit (0 = no limit)

## Configuration

### Parameter

```
MaxPairsTrading = 2  // Maximum pairs that can trade simultaneously
                    // 0 = no limit (unlimited pairs)
                    // 1 = only one pair at a time
                    // 2 = two pairs maximum (default)
                    // etc.
```

### Example Scenarios

**Scenario 1: Limit = 2**
- EURUSD has 1 open trade → ✅ Can search for setups
- GBPUSD has 1 open trade → ✅ Can search for setups
- USDJPY tries to trade → ❌ Blocked (2 pairs already trading)
- EURUSD trade closes → ✅ USDJPY can now search for setups

**Scenario 2: Limit = 0 (Disabled)**
- All pairs can trade simultaneously
- No restrictions

**Scenario 3: Limit = 1**
- Only one pair can trade at a time
- Very conservative approach

## Dashboard Display

The dashboard now shows a **Multi-Pair Limit** card with:

- **Enabled**: Yes/No (whether limit is active)
- **Current Pairs**: X / Y (how many pairs are trading vs limit)
- **Limit Status**: 
  - ✅ "OK - Searching for Setups" (green) when under limit
  - ❌ "REACHED - Setup Search Stopped" (red) when at limit
- **Trading Pairs**: List of pairs currently trading (e.g., "EURUSD, GBPUSD")

## Technical Details

### Functions Added

1. **`CountTradingPairs(int magicNumber)`**
   - Counts unique pairs with open trades
   - Uses Magic Number to identify EA trades
   - Returns count of unique symbols

2. **`CanTradeMultiPair(int magicNumber)`**
   - Checks if new trade can be placed
   - Returns `false` if limit reached
   - Returns `true` if current pair already has trade (allows management)

3. **`GetTradingPairsList(int magicNumber)`**
   - Returns comma-separated list of trading pairs
   - Used for dashboard display

### Integration Points

- **Check Location**: After safety checks, before setup search
- **Magic Number**: Uses same Magic Number across all instances
- **Dashboard Export**: Added to JSON export every 5 seconds

## Usage

### Setup

1. **Attach EA to multiple charts** (e.g., EURUSD, GBPUSD, USDJPY)
2. **Use same Magic Number** for all instances (e.g., 123456)
3. **Set MaxPairsTrading** to desired limit (default: 2)
4. **Enable Dashboard Export** to see status

### Behavior

- **Under Limit**: EAs search for setups normally
- **At Limit**: EAs stop searching, show message in Experts tab
- **After Trade Closes**: EAs resume searching when limit allows

### Logging

When limit is reached, EA logs:
```
Multi-pair limit reached: 2/2 pairs trading. Pairs: EURUSD, GBPUSD. Stopping setup search.
```

(Logged once per hour to avoid spam)

## Benefits

1. **Risk Management**: Limits exposure across pairs
2. **Focus**: Concentrates on fewer, higher-quality setups
3. **Account Protection**: Prevents over-trading
4. **Visibility**: Dashboard shows exactly which pairs are trading

## Example Use Cases

### Conservative Trading
```
MaxPairsTrading = 1
```
- Only one pair trades at a time
- Maximum focus and risk control

### Balanced Trading (Recommended)
```
MaxPairsTrading = 2
```
- Two pairs can trade simultaneously
- Good balance of opportunity and risk

### Aggressive Trading
```
MaxPairsTrading = 0  // No limit
```
- All pairs can trade simultaneously
- Maximum opportunity (higher risk)

## Important Notes

- **Magic Number Must Match**: All EA instances must use the same Magic Number for the limit to work across them
- **Existing Trades Continue**: When limit is reached, EAs with open trades continue managing them normally
- **Limit Resets Automatically**: When a trade closes, the limit check allows new setups again
- **Dashboard Updates**: Status updates every 5 seconds in dashboard

## Files Modified

- ✅ `SMC_Session_EA.mq4` - Added parameter and check
- ✅ `SMC_Includes/multi_pair_limit.mqh` - New module with logic
- ✅ `SMC_Includes/dashboard_export.mqh` - Added multi-pair status
- ✅ `SMC_Dashboard/dashboard.html` - Added multi-pair limit card
- ✅ `SMC_Dashboard/dashboard_modular.html` - Added multi-pair limit card

---

**Feature Status**: ✅ **IMPLEMENTED AND READY**

**Default Setting**: `MaxPairsTrading = 2` (two pairs maximum)
