# Dashboard Timezone Fields Reference

## Available JSON Fields (All in 12-Hour Format)

The `SMC_Dashboard.json` file contains timezone information in multiple formats for maximum compatibility:

### Top-Level Fields (Simplest - Use These First)

```json
{
  "broker": "11:45 AM",           // Broker time in 12-hour format
  "cst": "3:45 AM",              // CST time in 12-hour format
  "brokerTime": "11:45 AM",      // Alternative name for broker time
  "cstTime": "3:45 AM",          // Alternative name for CST time
  "brokerTime12hr": "11:45 AM",  // Explicit 12-hour format
  "cstTime12hr": "3:45 AM"       // Explicit 12-hour format
}
```

### Nested Timezone Object (More Detailed)

```json
{
  "timezone": {
    "brokerTime12hr": "11:45 AM",
    "cstTime12hr": "3:45 AM",
    "displayTime": "11:45 AM (Broker) / 3:45 AM (CST)",
    "brokerHour": 11,
    "cstHour": 3,
    "timezoneOffset": -8,
    "timezoneOffsetDescription": "CST UTC-6 - Broker UTC+2 = -8"
  }
}
```

### Session Object (Also in 12-Hour Format)

```json
{
  "session": {
    "currentTime12hr": "3:45 AM",
    "sessionStart12hr": "2:00 AM",
    "sessionEnd12hr": "5:00 AM",
    "sessionDisplay": "2:00 AM - 5:00 AM CST"
  }
}
```

## Dashboard JavaScript Examples

### Example 1: Simple Display (Recommended)

```javascript
// Read JSON file
fetch('SMC_Dashboard.json')
  .then(response => response.json())
  .then(data => {
    // Update Broker time
    document.getElementById('broker-time').textContent = data.broker || data.brokerTime12hr || 'Loading...';
    
    // Update CST time
    document.getElementById('cst-time').textContent = data.cst || data.cstTime12hr || 'Loading...';
  })
  .catch(error => {
    console.error('Error loading dashboard:', error);
    document.getElementById('broker-time').textContent = 'Error';
    document.getElementById('cst-time').textContent = 'Error';
  });
```

### Example 2: Using Nested Object

```javascript
fetch('SMC_Dashboard.json')
  .then(response => response.json())
  .then(data => {
    if (data.timezone) {
      document.getElementById('broker-time').textContent = data.timezone.brokerTime12hr || 'Loading...';
      document.getElementById('cst-time').textContent = data.timezone.cstTime12hr || 'Loading...';
    }
  });
```

### Example 3: With Fallback Chain

```javascript
fetch('SMC_Dashboard.json')
  .then(response => response.json())
  .then(data => {
    // Try multiple field names for maximum compatibility
    const brokerTime = data.broker || 
                      data.brokerTime || 
                      data.brokerTime12hr || 
                      (data.timezone && data.timezone.brokerTime12hr) || 
                      'Loading...';
    
    const cstTime = data.cst || 
                   data.cstTime || 
                   data.cstTime12hr || 
                   (data.timezone && data.timezone.cstTime12hr) || 
                   'Loading...';
    
    document.getElementById('broker-time').textContent = brokerTime;
    document.getElementById('cst-time').textContent = cstTime;
  });
```

## Troubleshooting

### If Times Show "Loading..."

1. **Check JSON File Location:**
   - Live: `MT4/MQL4/Files/SMC_Dashboard.json`
   - Backtest: `MT4/tester/files/SMC_Dashboard.json`

2. **Verify JSON File Exists:**
   - Open the file in a text editor
   - Check that it contains `"broker"` and `"cst"` fields
   - Verify the file is being updated (check timestamp)

3. **Check JavaScript Console:**
   - Open browser Developer Tools (F12)
   - Look for JavaScript errors
   - Check Network tab to see if JSON file is loading

4. **Verify Field Names:**
   - Open `SMC_Dashboard.json` in a text editor
   - Search for `"broker"` and `"cst"`
   - Make sure your JavaScript is using the exact same field names

5. **Check EA Logs:**
   - Look in MT4 Experts tab
   - Should see "Timezone Verification" logs every 60 seconds
   - Verify times are being calculated correctly

## Field Name Priority (Use in This Order)

1. **`data.broker`** - Simplest, top-level broker time
2. **`data.cst`** - Simplest, top-level CST time
3. **`data.brokerTime12hr`** - Explicit 12-hour format
4. **`data.cstTime12hr`** - Explicit 12-hour format
5. **`data.timezone.brokerTime12hr`** - Nested object
6. **`data.timezone.cstTime12hr`** - Nested object

## Example HTML Structure

```html
<div class="timezone-display">
  <div>
    <span class="clock-icon">🕐</span>
    <span class="label">Broker:</span>
    <span id="broker-time" class="time-value">Loading...</span>
  </div>
  <div>
    <span class="clock-icon">🕐</span>
    <span class="label">CST:</span>
    <span id="cst-time" class="time-value">Loading...</span>
  </div>
</div>
```

## Verification

After updating your dashboard code:

1. **Recompile the EA** (F7 in MetaEditor)
2. **Restart the EA** on your chart
3. **Check Experts tab** for timezone verification logs
4. **Open JSON file** and verify fields exist
5. **Refresh dashboard** and check browser console for errors
