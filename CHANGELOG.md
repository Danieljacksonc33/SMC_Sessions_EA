# Changelog

All notable changes to SMC Sessions EA will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-30

### Fixed
- Fixed CST date calculation for Asian session (was using broker date instead of CST date)
- Fixed Asian range lines not appearing on chart
- Fixed variable name conflicts in session.mqh (lastLog variables)

### Changed
- Changed Asian range lines from full-width horizontal lines (OBJ_HLINE) to segments (OBJ_TREND)
- Lines now start from first Asian session candle and extend to current candle
- Improved debug logging for Asian range calculation
- Enhanced timezone handling with GetCSTDate() function

### Added
- Added comprehensive testing settings guide to README (Phase 1-3: Testing to Industrial)
- Added GetCSTDate() function for proper CST timezone date calculation
- Added GetFirstAsianCandleTime() function to find first Asian session candle
- Added UpdateAsianRangeLines() function for continuous line updates
- Added detailed debug logging for troubleshooting Asian range issues

## [1.0.0] - 2025-12-15

### Initial Release
- Core SMC strategy implementation
- Session-based trading (default: 2-5 AM CST)
- Multiple session support (up to 5 sessions)
- Asian session range calculation (6 PM - 12 AM CST)
- Higher timeframe bias detection (H4 + D1)
- Liquidity sweep detection
- Change of Character (CHOCH) detection
- Fair Value Gap (FVG) entry system
- Market condition filters (ADX, ATR)
- Entry confirmation filters (Volume, Momentum, S/R)
- Active trade management (break-even, trailing stops)
- Performance statistics tracking
- Enhanced analytics (session-based, pair-based)
- Safety features (max daily loss, max drawdown, max trades)
- Alert system (popup, email, push notifications)
- Visual indicator (blinking star every 5 minutes)
- Asian session range visual lines (yellow segments)
- Comprehensive documentation (README, USAGE_GUIDE, INSTALLATION, etc.)

