// ============================================
// Liquidity Sweep Detection
// ============================================

void CheckLiquiditySweep()
{
    // Validate Asian range is calculated
    if(AsiaHigh <= 0 || AsiaLow <= 0 || AsiaHigh <= AsiaLow) return;
    
    // Only check after session start
    int hour = GetCSTHour(TimeCurrent());
    if(hour < SESSION_START) return;
    
    // Check previous closed candle (index 1) to avoid false signals from unclosed candle
    if(iBars(NULL, PERIOD_M5) < 2) return;
    
    double prevHigh = iHigh(NULL, PERIOD_M5, 1); // Previous closed candle
    double prevLow  = iLow(NULL, PERIOD_M5, 1);
    
    // Validate prices
    if(prevHigh <= 0 || prevLow <= 0) return;
    
    // High sweep: price broke above Asian high
    if(!SweepHighOccurred && prevHigh > AsiaHigh)
    {
        SweepHighOccurred = true;
        AlertSweep("HIGH", prevHigh);
    }
    
    // Low sweep: price broke below Asian low
    if(!SweepLowOccurred && prevLow < AsiaLow)
    {
        SweepLowOccurred = true;
        AlertSweep("LOW", prevLow);
    }
}

