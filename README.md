# Claude Usage Tracker

A macOS menu bar plugin that displays your Claude Code API usage limits in real-time using [SwiftBar](https://github.com/swiftbar/SwiftBar).

<img width="260" height="366" alt="image" src="https://github.com/user-attachments/assets/0186fef5-9857-48dc-a213-1ff46225f9fc" />


## Features

- **Live usage tracking** - See your Claude Code limits at a glance
- **Smart status indicators** - Color-coded alerts based on your usage patterns
- **Two key metrics**:
  - **Weekly** (7-day) - Main usage limit (includes Opus)
  - **Session** (5-hour) - Rolling window limit
- **Separate Sonnet tracking** - Sonnet has its own usage bucket
- **Auto-refresh** - Updates every 5 minutes

## Status Indicators

The menu bar shows two emoji indicators: `🟢31% 🟢3%`

| Indicator | What it measures | Green | Yellow | Red |
|-----------|------------------|-------|--------|-----|
| **Weekly** | 7-day usage vs ideal pace | On track for 15%/weekday | Up to 10% over target | >10% over target |
| **Session** | 5-hour window burndown | Usage matches time elapsed | 20%+ ahead of time | 80%+ used & ahead of curve |

### Weekly Pacing Strategy

The weekly indicator is designed around a sustainable pacing strategy:
- **Weekdays**: Use ~15% per day (75% total for Mon-Fri)
- **Weekends**: Reserve 25% for weekend projects
- Green means you're on or below this pace

## Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - Menu bar customization tool
- [Bun](https://bun.sh) - Fast JavaScript runtime
- [Claude Code](https://claude.ai/code) - Must be authenticated

## Installation

### Quick Install

```bash
git clone https://github.com/philberryman/claude-usage-tracker.git
cd claude-usage-tracker
./install.sh
```

### Manual Install

1. **Install dependencies**:
   ```bash
   # Install Bun
   brew install oven-sh/bun/bun

   # Install SwiftBar
   brew install swiftbar
   ```

2. **Copy the plugin**:
   ```bash
   mkdir -p "$HOME/Library/Application Support/SwiftBar/plugins"
   cp claude-usage.5m.sh "$HOME/Library/Application Support/SwiftBar/plugins/"
   chmod +x "$HOME/Library/Application Support/SwiftBar/plugins/claude-usage.5m.sh"
   ```

3. **Configure SwiftBar**:
   - Open SwiftBar from Applications
   - When prompted, select: `~/Library/Application Support/SwiftBar/plugins`

4. **Authenticate Claude Code** (if not already):
   ```bash
   claude
   ```

## Usage

Once installed, you'll see the usage indicator in your menu bar. Click it to see detailed information:

```
🟢31% 🟢3%
---
Weekly: 31% (resets 4d 20h)
  Target: 15%/weekday, 25% for weekends
Sonnet: 7% (resets 4d 20h)
---
Session: 3% (resets 4h 44m)
  Time elapsed: 5%
---
Open Claude
Usage Settings
---
Refresh
```

## API Response

The plugin reads from Anthropic's OAuth usage API. Current response structure:

```json
{
  "five_hour": { "utilization": 3, "resets_at": "2025-11-27T02:59:59Z" },
  "seven_day": { "utilization": 31, "resets_at": "2025-12-01T18:59:59Z" },
  "seven_day_sonnet": { "utilization": 7, "resets_at": "2025-12-01T18:59:59Z" },
  "seven_day_opus": null,
  "extra_usage": { "is_enabled": false, ... }
}
```

Note: `seven_day_opus` is now null as Opus is included in the main `seven_day` limit. Sonnet has a separate bucket.

## Troubleshooting

### Plugin not showing
1. Make sure SwiftBar is running
2. Right-click SwiftBar icon → Refresh All
3. Check Plugin Browser to ensure the plugin is enabled

### "No token" error
Run `claude` in your terminal to authenticate with Claude Code.

### "API 403" error
Your OAuth token may have expired. Run `/logout` in Claude Code, then restart it to re-authenticate.

### Checking plugin output manually
```bash
bash "$HOME/Library/Application Support/SwiftBar/plugins/claude-usage.5m.sh"
```

## Customization

### Refresh interval
The filename `claude-usage.5m.sh` sets the refresh interval. Rename to change:
- `claude-usage.1m.sh` - Every minute
- `claude-usage.10m.sh` - Every 10 minutes
- `claude-usage.30s.sh` - Every 30 seconds

### Modifying thresholds
Edit the plugin file and adjust the threshold functions:
- `getWeeklyStatus()` - Weekly pacing thresholds
- `getSessionStatus()` - Session burndown thresholds

## License

MIT License - See [LICENSE](LICENSE)

## Credits

- Built for use with [Claude Code](https://claude.ai/code) by Anthropic
- Uses [SwiftBar](https://github.com/swiftbar/SwiftBar) for menu bar integration
- Inspired by [this blog post](https://codelynx.dev/posts/claude-code-usage-limits-statusline)
