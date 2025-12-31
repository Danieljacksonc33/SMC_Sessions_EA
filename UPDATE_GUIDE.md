# Update & Patch Distribution Guide

## 🔄 How to Distribute Updates to Users

### Method 1: GitHub Releases (Recommended)

**Best for:** Professional distribution, version tracking, easy downloads

#### Steps:

1. **Update Version Number**
   - Edit `SMC_Session_EA.mq4`
   - Change `#property version "1.0"` to new version (e.g., "1.1.0")
   - Commit and push to GitHub

2. **Create a Release on GitHub**
   ```
   GitHub → Your Repository → Releases → "Create a new release"
   ```
   - **Tag version:** v1.1.0 (follows semantic versioning)
   - **Release title:** SMC Sessions EA v1.1.0 - [Brief Description]
   - **Description:** List all changes, fixes, and improvements
   - **Attach files:** (Optional) Create a ZIP with all files

3. **Notify Users**
   - Send email/announcement with release link
   - Update README with latest version
   - Post in your community/forum

#### User Update Process:
```bash
# Option 1: Download ZIP from GitHub Releases
1. Go to Releases page
2. Download latest release ZIP
3. Extract and replace files in MT4/Experts folder
4. Recompile EA (F7)

# Option 2: Git Pull (for advanced users)
cd SMC_Sessions_EA
git pull origin main
# Then recompile in MetaEditor
```

---

### Method 2: Direct File Sharing

**Best for:** Small user base, quick fixes

#### Steps:

1. **Create Update Package**
   - ZIP all changed files
   - Include `CHANGELOG.md` with what changed
   - Name: `SMC_Sessions_EA_v1.1.0_Update.zip`

2. **Distribution Channels**
   - Email to users
   - Google Drive / Dropbox link
   - Telegram / Discord channel
   - Your website

3. **User Instructions**
   ```
   1. Download update ZIP
   2. Extract files
   3. Replace old files in MT4/Experts folder
   4. Recompile EA (F7 in MetaEditor)
   5. Restart MT4 or re-attach EA to chart
   ```

---

### Method 3: Automated Update Check (Advanced)

**Best for:** Large user base, professional distribution

You can add an update checker to the EA that:
- Checks GitHub for new versions
- Alerts users when update is available
- Provides download link

*(This requires additional coding - can be added as future enhancement)*

---

## 📝 Version Numbering System

Use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes, major rewrites
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, small improvements

### Examples:
- `1.0.0` → `1.0.1`: Fixed Asian session calculation bug
- `1.0.1` → `1.1.0`: Added new filter option
- `1.1.0` → `2.0.0`: Complete rewrite, breaking changes

---

## 📋 Creating a CHANGELOG

Create a `CHANGELOG.md` file to track all changes:

```markdown
# Changelog

All notable changes to SMC Sessions EA will be documented in this file.

## [1.1.0] - 2025-12-30

### Fixed
- Fixed CST date calculation for Asian session (was using broker date)
- Fixed Asian range lines not appearing on chart

### Changed
- Changed Asian range lines from full-width to segments (first candle to current)
- Improved debug logging for troubleshooting

### Added
- Added comprehensive testing settings guide to README
- Added GetCSTDate() function for proper timezone handling

## [1.0.0] - 2025-12-15

### Initial Release
- Core SMC strategy implementation
- Session-based trading
- Multiple filters and safety features
```

---

## 🔔 Notifying Users About Updates

### Email Template:
```
Subject: SMC Sessions EA Update Available - v1.1.0

Hi [User Name],

A new update is available for SMC Sessions EA!

Version: 1.1.0
Release Date: December 30, 2025

What's New:
- Fixed Asian session calculation bug
- Improved visual lines display
- Enhanced debug logging

Download: [GitHub Release Link]

Update Instructions:
1. Download latest release
2. Replace files in MT4/Experts folder
3. Recompile EA (F7)
4. Re-attach to chart

Full Changelog: [Link to CHANGELOG.md]

Thank you for using SMC Sessions EA!

Best regards,
BluePips University By Deejay
```

---

## ✅ Pre-Release Checklist

Before releasing an update:

- [ ] Update version number in `SMC_Session_EA.mq4`
- [ ] Test all changes thoroughly
- [ ] Update `CHANGELOG.md`
- [ ] Update README if needed
- [ ] Commit all changes to GitHub
- [ ] Create GitHub release
- [ ] Notify users via email/announcement
- [ ] Update documentation

---

## 🚀 Quick Update Workflow

1. **Make Changes**
   ```bash
   # Edit files
   # Test changes
   ```

2. **Update Version**
   ```mq4
   # In SMC_Session_EA.mq4
   #property version "1.1.0"
   ```

3. **Commit & Push**
   ```bash
   git add -A
   git commit -m "Release v1.1.0 - Fixed Asian session calculation"
   git push origin main
   ```

4. **Create Release**
   - GitHub → Releases → New Release
   - Tag: v1.1.0
   - Title: SMC Sessions EA v1.1.0
   - Description: Copy from CHANGELOG.md

5. **Notify Users**
   - Send update email
   - Post in community

---

## 📞 User Support

When users ask about updates:

1. **Check Current Version**
   - Users can see version in EA's "About" tab
   - Or in Experts log on initialization

2. **Provide Update Link**
   - Direct link to latest GitHub release
   - Or download instructions

3. **Troubleshooting**
   - If update fails, check file permissions
   - Ensure all files are replaced
   - Recompile is required after update

---

## 🔐 Security & Distribution

- **Private Repository:** Keep code private, share compiled .ex4 files
- **Public Repository:** Open source, users compile themselves
- **Licensed Distribution:** Use GitHub releases with license file

---

## 📊 Tracking Updates

Keep a spreadsheet or database of:
- User emails
- Version they're using
- Last update notification sent
- User feedback on updates

This helps you:
- Know who needs updates
- Track adoption rate
- Gather feedback for improvements

