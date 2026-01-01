# Recommended Folder Structure

## Current Structure
```
Trading/all bots/
├── SMC_Sessions_EA/
└── SMC_Dashboard/
```

## Recommended Structure (Future)
```
Trading/all bots/
├── SMC_Trading/                    # All SMC strategies together
│   ├── SMC_Sessions_EA/          # Current strategy
│   │   ├── SMC_Session_EA.mq4
│   │   ├── SMC_Includes/
│   │   └── [documentation]
│   │
│   ├── SMC_OrderBlocks_EA/       # Future strategy
│   │   ├── SMC_OrderBlocks_EA.mq4
│   │   ├── SMC_Includes/
│   │   └── [documentation]
│   │
│   └── README.md                 # Overview of all SMC strategies
│
└── SMC_Dashboard/                 # Shared dashboard for all strategies
    ├── dashboard.html             # Single strategy (original)
    ├── dashboard_modular.html     # Multi-strategy (new)
    └── [automation scripts]
```

## Benefits

1. **Organization:** All SMC strategies in one place
2. **Scalability:** Easy to add new strategies
3. **Shared Dashboard:** One dashboard monitors all strategies
4. **Maintainability:** Clear structure, easy to navigate

## Migration Steps

### Step 1: Create SMC_Trading Folder
```powershell
cd "C:\Users\test\OneDrive\Desktop\Trading\all bots"
mkdir SMC_Trading
```

### Step 2: Move SMC_Sessions_EA
```powershell
# Close any programs using the folder first
Move-Item -Path "SMC_Sessions_EA" -Destination "SMC_Trading\SMC_Sessions_EA"
```

### Step 3: Update Git (if using)
```powershell
cd SMC_Trading\SMC_Sessions_EA
git remote set-url origin https://github.com/Danieljacksonc33/SMC_Sessions_EA.git
# Or keep as is - Git doesn't care about folder location
```

### Step 4: Update Dashboard References
- Dashboard already uses relative paths, so no changes needed
- JSON files are in MT4 folders, not affected by this move

## Important Notes

- **EA files don't need changes** - They're in MT4, not affected
- **Dashboard scripts** - May need path updates if they reference SMC_Sessions_EA folder
- **Git repositories** - Can stay as separate repos or combine

## Alternative: Keep Current Structure

If you prefer to keep strategies separate:
- Current structure works fine
- Dashboard can still monitor multiple strategies
- Just add new strategies to dashboard_modular.html

**Both approaches work!** Choose what's easier for you.
