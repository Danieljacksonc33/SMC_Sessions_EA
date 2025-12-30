// ============================================
// Visual Indicator
// Simple blinking star to show EA is running
// ============================================

// Indicator settings (using globals from main file)
// g_EnableVisualIndicator is set in main file

// Indicator object name
#define INDICATOR_NAME "SMC_EA_Heartbeat"

// Indicator settings
#define INDICATOR_DURATION 20        // Show for 20 seconds
#define INDICATOR_INTERVAL 300       // Show every 5 minutes (300 seconds)
#define INDICATOR_SIZE 20            // Size of the star

// Colors for blinking effect
color IndicatorColors[] = {clrLimeGreen, clrYellow, clrAqua, clrMagenta, clrOrange};

// Track indicator state
static datetime LastIndicatorTime = 0;
static datetime IndicatorStartTime = 0;
static bool IndicatorActive = false;
static int ColorIndex = 0;

// Initialize visual indicator
void InitVisualIndicator()
{
    if(!g_EnableVisualIndicator) return;
    
    // Create the indicator object (star symbol)
    if(ObjectFind(INDICATOR_NAME) < 0)
    {
        ObjectCreate(INDICATOR_NAME, OBJ_ARROW, 0, 0, 0);
        ObjectSet(INDICATOR_NAME, OBJPROP_ARROWCODE, 159); // Star symbol
        ObjectSet(INDICATOR_NAME, OBJPROP_COLOR, IndicatorColors[0]);
        ObjectSet(INDICATOR_NAME, OBJPROP_WIDTH, INDICATOR_SIZE);
        ObjectSet(INDICATOR_NAME, OBJPROP_ANCHOR, ANCHOR_CENTER);
        ObjectSet(INDICATOR_NAME, OBJPROP_BACK, false);
        ObjectSet(INDICATOR_NAME, OBJPROP_SELECTABLE, false);
        ObjectSet(INDICATOR_NAME, OBJPROP_HIDDEN, true);
    }
    
    LastIndicatorTime = 0;
    IndicatorStartTime = 0;
    IndicatorActive = false;
    ColorIndex = 0;
}

// Update visual indicator
void UpdateVisualIndicator()
{
    if(!g_EnableVisualIndicator) return;
    
    datetime currentTime = TimeCurrent();
    
    // Check if it's time to show the indicator (every 5 minutes)
    if(currentTime - LastIndicatorTime >= INDICATOR_INTERVAL)
    {
        // Start showing the indicator
        IndicatorActive = true;
        IndicatorStartTime = currentTime;
        LastIndicatorTime = currentTime;
        ColorIndex = 0;
        
        // Position the star in the top-right area of the chart
        double indHigh = iHigh(Symbol(), PERIOD_CURRENT, 0);
        double indLow = iLow(Symbol(), PERIOD_CURRENT, 0);
        double indRange = indHigh - indLow;
        double indPrice = indHigh + indRange * 0.15; // Position above current price
        datetime indTime = TimeCurrent();
        
        // Move the object to the current position
        ObjectMove(INDICATOR_NAME, 0, indTime, indPrice);
        ObjectSet(INDICATOR_NAME, OBJPROP_COLOR, IndicatorColors[ColorIndex]);
        ObjectSet(INDICATOR_NAME, OBJPROP_TIME1, indTime);
        ObjectSet(INDICATOR_NAME, OBJPROP_PRICE1, indPrice);
    }
    
    // If indicator is active, update it
    if(IndicatorActive)
    {
        // Check if 20 seconds have passed
        if(currentTime - IndicatorStartTime >= INDICATOR_DURATION)
        {
            // Hide the indicator
            IndicatorActive = false;
            ObjectSet(INDICATOR_NAME, OBJPROP_TIME1, 0);
            ObjectSet(INDICATOR_NAME, OBJPROP_PRICE1, 0);
        }
        else
        {
            // Blink effect - change color every second
            int secondsElapsed = (int)(currentTime - IndicatorStartTime);
            int newColorIndex = secondsElapsed % ArraySize(IndicatorColors);
            
            if(newColorIndex != ColorIndex)
            {
                ColorIndex = newColorIndex;
                ObjectSet(INDICATOR_NAME, OBJPROP_COLOR, IndicatorColors[ColorIndex]);
            }
            
            // Ensure the indicator is visible (update position to stay visible)
            datetime indTime2 = TimeCurrent();
            double indHigh2 = iHigh(Symbol(), PERIOD_CURRENT, 0);
            double indLow2 = iLow(Symbol(), PERIOD_CURRENT, 0);
            double indRange2 = indHigh2 - indLow2;
            double indPrice2 = indHigh2 + indRange2 * 0.15; // Position above current price
            
            ObjectMove(INDICATOR_NAME, 0, indTime2, indPrice2);
            ObjectSet(INDICATOR_NAME, OBJPROP_TIME1, indTime2);
            ObjectSet(INDICATOR_NAME, OBJPROP_PRICE1, indPrice2);
        }
    }
}

// Clean up visual indicator
void CleanupVisualIndicator()
{
    if(ObjectFind(INDICATOR_NAME) >= 0)
    {
        ObjectDelete(INDICATOR_NAME);
    }
}

