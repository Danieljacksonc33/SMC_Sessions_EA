# Code Review - Critical Issues & Improvements

## 🔴 CRITICAL BUGS

### 1. **Missing Daily Reset Logic**
**File:** `SMC_Session_EA.mqh`
**Issue:** `TradeTakenToday` never resets, so EA will only trade once in its lifetime
**Fix:** Add daily reset in `OnTick()`:
```mql
static int lastDay = -1;
int currentDay = Day();
if(currentDay != lastDay) {
    TradeTakenToday = false;
    SweepHighOccurred = false;
    SweepLowOccurred = false;
    FVGReady = false;
    lastDay = currentDay;
}
```

### 2. **Performance Issue - CalculateAsianRange()**
**File:** `sessionpy.mqh`
**Issue:** Loops through ALL H1 bars every tick (could be thousands of bars)
**Fix:** Only calculate once per day or cache results:
```mql
static datetime lastCalcDate = 0;
datetime currentDate = GetCurrentDate();
if(currentDate != lastCalcDate) {
    // Only recalculate when new day
    // ... calculation code ...
    lastCalcDate = currentDate;
}
```

### 3. **Invalid FVG Calculation**
**File:** `entrypy.mqh`
**Issue:** Uses candles 2 and 0, missing candle 1 (middle candle)
**Fix:** Proper FVG requires 3 candles with gap:
```mql
// Bullish FVG: gap between candle 2 and candle 0
double high2 = iHigh(NULL, PERIOD_M5, 2);
double low2  = iLow(NULL, PERIOD_M5, 2);
double high0 = iHigh(NULL, PERIOD_M5, 0);
double low0  = iLow(NULL, PERIOD_M5, 0);

if(choch == CHOCH_BULL && low0 > high2) { // Valid gap
    FVGBottom = high2;
    FVGTop = low0;
}
```

### 4. **No Error Handling for OrderSend**
**File:** `riskpy.mqh`
**Issue:** Order might fail but code continues
**Fix:**
```mql
int ticket = OrderSend(...);
if(ticket <= 0) {
    int error = GetLastError();
    LogTrade("Order failed: " + IntegerToString(error));
    return;
}
TradeTakenToday = true;
```

### 5. **Invalid Price Initialization**
**File:** `sessionpy.mqh`
**Issue:** `AsiaLow = 999999` is arbitrary, should use proper constant
**Fix:**
```mql
AsiaLow = DBL_MAX; // or use -1 and check for validity
```

## ⚠️ LOGIC ISSUES

### 6. **CHOCH Detection Too Simplistic**
**File:** `structurepy.mqh`
**Issue:** Uses previous bar's high/low, not actual swing points
**Current:** `iHigh(NULL, PERIOD_H1, 1)` - just previous bar
**Should:** Find actual swing high/low using multiple bars

### 7. **Bias Logic Mismatch**
**File:** `biaspy.mqh`
**Issue:** Compares D1 low with H4 low - different timeframes
**Line 11:** `prevLow <= iLow(NULL, PERIOD_H4, 1)` - doesn't make sense
**Fix:** Compare same timeframe or clarify logic

### 8. **Liquidity Sweep on Unclosed Candle**
**File:** `liquiditypy.mqh`
**Issue:** Checks current candle (index 0) which might not be closed
**Fix:** Check previous closed candle or wait for candle close

### 9. **Timezone Hardcoding**
**File:** `sessionpy.mqh`
**Issue:** Hardcoded -8 offset, won't work for all brokers
**Fix:** Use proper timezone conversion or make it configurable

## 📝 CODE QUALITY

### 10. **Deprecated Functions**
- `DoubleToStr()` → `DoubleToString()`
- `TimeToStr()` → `TimeToString()`

### 11. **Magic Numbers**
- `5*Point` → Define as constant `#define STOP_BUFFER 5`
- `0.1` lot size → Calculate from `RiskPercent`

### 12. **Missing Validations**
- Check if `AsiaHigh/AsiaLow` are valid before use
- Check if enough bars exist before accessing
- Check if order already exists before placing new one

### 13. **Unused Risk Management**
**File:** `riskpy.mqh`
**Issue:** `RiskPercent` defined but lot size is hardcoded
**Fix:** Calculate lot size based on risk percentage

### 14. **Redundant Trade Flag Logic**
**Issue:** `TradeTakenToday` set in `PlaceTrade()` but also checked in `CanTrade()`
**Fix:** Keep logic in one place (prefer in main OnTick)

## 🎯 RECOMMENDED IMPROVEMENTS

1. **Add OnInit()/OnDeinit()** for proper initialization
2. **Add input parameters** for configurable values (timezone, risk %, etc.)
3. **Add validation functions** for price/bars before use
4. **Implement proper swing detection** for CHOCH
5. **Cache Asian range** calculation to avoid recalculation every tick
6. **Add order management** (check existing orders, modify, close)
7. **Improve logging** with error codes and detailed info
8. **Add symbol validation** (check if symbol is valid for trading)

