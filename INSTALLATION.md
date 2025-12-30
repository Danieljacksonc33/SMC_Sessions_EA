# Installation Guide

## Quick Installation

### Step 1: Download the EA

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/SMC_Sessions_EA.git
   ```
   
   Or download as ZIP and extract.

### Step 2: Locate MetaTrader 4 Data Folder

1. Open MetaTrader 4
2. Go to: **File → Open Data Folder**
3. Navigate to: `MQL4 → Experts`

### Step 3: Copy Files

Copy the following files/folders to the `Experts` folder:

```
From Repository:
├── SMC_Session_EA.mq4          → Copy to: MT4/MQL4/Experts/
└── SMC_Includes/               → Copy to: MT4/MQL4/Experts/
    ├── session.mqh
    ├── bias.mqh
    ├── liquidity.mqh
    ├── structure.mqh
    ├── entry.mqh
    ├── risk.mqh
    ├── logger.mqh
    ├── trade_management.mqh
    ├── statistics.mqh
    └── safety.mqh
```

### Step 4: Compile the EA

1. Open **MetaEditor** (Press F4 in MT4, or Tools → MetaQuotes Language Editor)
2. In Navigator, find `SMC_Session_EA.mq4`
3. Double-click to open
4. Press **F7** (or click Compile button)
5. Check bottom panel for errors
6. Should show: **0 error(s), 0 warning(s)**

### Step 5: Verify Installation

1. Close MetaEditor
2. In MT4 Navigator, expand **Expert Advisors**
3. You should see **SMC_Session_EA**
4. If you see it, installation is complete! ✅

## Troubleshooting

### EA Not Appearing in Navigator

**Problem:** EA doesn't show in Navigator after copying files.

**Solutions:**
- Refresh Navigator (right-click → Refresh)
- Restart MetaTrader 4
- Check files are in correct location: `MT4/MQL4/Experts/`
- Verify file extensions are correct (.mq4, .mqh)

### Compilation Errors

**Error: "Cannot open include file"**

**Solution:**
- Ensure `SMC_Includes` folder is in `Experts` folder
- Check folder name is exactly `SMC_Includes` (case-sensitive)
- Verify all .mqh files are in the `SMC_Includes` folder

**Error: "Undeclared identifier"**

**Solution:**
- Recompile all files
- Check for missing includes
- Verify file paths in main file are correct

**Error: "Function not defined"**

**Solution:**
- Ensure all include files are present
- Check include paths use backslash: `SMC_Includes\filename.mqh`

### Files Not Found

**Problem:** Can't find MT4 data folder.

**Solution:**
1. In MT4, go to: **File → Open Data Folder**
2. This opens the correct folder
3. Navigate to: `MQL4 → Experts`

## File Structure After Installation

Your MT4 folder should look like this:

```
MT4/
└── MQL4/
    └── Experts/
        ├── SMC_Session_EA.mq4
        └── SMC_Includes/
            ├── session.mqh
            ├── bias.mqh
            ├── liquidity.mqh
            ├── structure.mqh
            ├── entry.mqh
            ├── risk.mqh
            ├── logger.mqh
            ├── trade_management.mqh
            ├── statistics.mqh
            └── safety.mqh
```

## Next Steps

After installation:

1. ✅ Read [README.md](README.md) for overview
2. ✅ Read [USAGE_GUIDE.md](USAGE_GUIDE.md) for detailed usage
3. ✅ Attach EA to chart and configure
4. ✅ Test on demo account first!

## Verification Checklist

- [ ] Files copied to correct location
- [ ] EA compiles without errors
- [ ] EA appears in Navigator
- [ ] Can attach EA to chart
- [ ] EA initializes without errors

---

**Installation complete!** 🎉

Now proceed to [USAGE_GUIDE.md](USAGE_GUIDE.md) to learn how to use the EA.

