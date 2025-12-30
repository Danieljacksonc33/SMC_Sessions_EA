// ============================================
// SMC Sessions EA - Main File
// ============================================

// Session / Trade Control
bool TradeTakenToday = false;

// Asian Session High / Low
double AsiaHigh = -1;
double AsiaLow  = -1;

// Liquidity Sweep Flags
bool SweepHighOccurred = false;
bool SweepLowOccurred  = false;

// FVG Entry
double FVGTop = 0;
double FVGBottom = 0;
double FVGEntry = 0;
bool FVGReady = false;

// Includes
#include "session.mqh"
#include "bias.mqh"
#include "liquidity.mqh"
#include "structure.mqh"
#include "entry.mqh"
#include "risk.mqh"
#include "logger.mqh"

// Daily reset tracking
static datetime LastResetDate = 0;

// ============================================
// Helper Functions
// ============================================

// Reset all daily flags
void ResetDailyFlags()
{
    TradeTakenToday = false;
    SweepHighOccurred = false;
    SweepLowOccurred = false;
    FVGReady = false;
    AsiaHigh = -1;
    AsiaLow = -1;
    FVGTop = 0;
    FVGBottom = 0;
    FVGEntry = 0;
}

// ============================================
// Event Handlers
// ============================================

int OnInit()
{
    // Initialize last reset date
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    LastResetDate = StructToTime(dt);
    
    // Reset flags on initialization
    ResetDailyFlags();
    
    Print("SMC Sessions EA initialized successfully");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    Print("SMC Sessions EA deinitialized");
}

void OnTick()
{
    // 0️⃣ Reset daily flags if new day
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime currentDate = StructToTime(dt);
    
    if(currentDate != LastResetDate)
    {
        ResetDailyFlags();
        LastResetDate = currentDate;
    }
    
    // 1️⃣ Check if we can trade
    if(!CanTrade()) return;

    // 2️⃣ Update session info (cached internally)
    CalculateAsianRange();

    // 3️⃣ Validate Asian range before proceeding
    if(AsiaHigh <= 0 || AsiaLow <= 0 || AsiaHigh <= AsiaLow) return;

    // 4️⃣ Get HTF bias
    BiasType bias = HTFBias();
    if(bias == SIDEWAYS) return; // skip the day if no clear bias

    // 5️⃣ Check liquidity sweeps
    CheckLiquiditySweep();
    if(!(SweepHighOccurred || SweepLowOccurred)) return; // wait for sweep

    // 6️⃣ Check CHOCH
    CHOCHType choch = CheckCHOCH();
    if(choch == CHOCH_NONE) return; // wait for valid CHOCH

    // 7️⃣ FVG entry calculation
    CalculateFVG();
    if(!FVGReady) return;
    
    // Validate FVG
    if(FVGTop <= FVGBottom) return;

    // 8️⃣ Risk & order placement
    bool tradeResult = PlaceTrade(bias);
    if(tradeResult)
    {
        TradeTakenToday = true; // Only set if trade succeeded
        LogTrade("Trade placed successfully at " + DoubleToString(FVGEntry, _Digits));
    }
}
