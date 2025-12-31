// ============================================
// Liquidity Sweep Detection
// ============================================

// Helper function to convert M5 sweep time to H1 candle time
datetime GetH1CandleTime(datetime m5Time)
{
    MqlDateTime dt;
    TimeToStruct(m5Time, dt);
    dt.min = 0;
    dt.sec = 0;
    return StructToTime(dt); // H1 candle start time
}

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
    
    // Get M5 sweep time once (used for both high and low sweeps)
    datetime m5SweepTime = iTime(NULL, PERIOD_M5, 1);
    
    // High sweep: price broke above Asian high
    if(!SweepHighOccurred && prevHigh > AsiaHigh)
    {
        SweepHighOccurred = true;
        // Store the H1 candle time that contains the sweep (round down to nearest hour)
        SweepCandleTime = GetH1CandleTime(m5SweepTime);
        AlertSweep("HIGH", prevHigh);
    }
    
    // Low sweep: price broke below Asian low
    if(!SweepLowOccurred && prevLow < AsiaLow)
    {
        SweepLowOccurred = true;
        // Store the H1 candle time that contains the sweep (round down to nearest hour)
        SweepCandleTime = GetH1CandleTime(m5SweepTime);
        AlertSweep("LOW", prevLow);
    }
}

