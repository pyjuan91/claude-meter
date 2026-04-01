# Claude Meter

Browser extension that displays claude.ai usage limits as a floating widget on the chat page. Also ships a **macOS menu bar app** (`menubar/`) that reads session data from the Claude Desktop app — no browser needed.


<p float="middle">
  <img width="45%" alt="Light Theme" src="https://github.com/user-attachments/assets/694bf3fe-9115-4007-a80b-4f08583a8e84" />
  <img width="45%" alt="Dark Theme" src="https://github.com/user-attachments/assets/66bb0fb0-4453-4c44-8ecb-d22ba7ea1139" />
</p>

## Chrome Extension Store

[Link](https://chromewebstore.google.com/detail/claude-meter/ijefjecdkjhhghkpngakollggloipnlg)

## Features

- **Real-time usage tracking** — 5-hour and 7-day utilization with progress bars
- **Color-coded limits** — terracotta (<50%), amber (50–80%), red (>80%)
- **Expand/collapse widget** — persisted across sessions; collapsed shows a donut ring icon
- **Theme-aware** — auto-detects light/dark mode via MutationObserver
- **Extra usage display** — shows spent credits vs monthly limit when enabled
- **Opus/Sonnet/Cowork breakdowns** — shown when data is available
- **Fallback popup** — view cached data from the extension icon
- **80% threshold notification** — optional desktop alert
- **Cross-browser** — Chrome (MV3) + Firefox compatible

## How It Works

The extension fetches `GET /api/organizations/{org_id}/usage` using the browser's session cookies (same-origin, no token needed). Org ID is extracted from cookies, the organizations API, `__NEXT_DATA__`, or URL interception — cached and auto-invalidated on auth errors. Polls every 60s while the tab is visible.

## Testing

**Chrome:** `chrome://extensions` → Developer mode → Load unpacked → select this folder

**Firefox:** `about:debugging#/runtime/this-firefox` → Load Temporary Add-on → select `manifest.json`

## Menu Bar App (macOS)

Native Swift app that sits in your menu bar. Reads session cookies directly from the Claude Desktop app via Keychain + SQLite — just `make run` and go.

```bash
cd menubar
make run          # build + launch
make install      # copy to /Applications
```

Requires macOS 13+ and the Claude Desktop app to be logged in.

## Structure

```
├── src/                  # Browser extension
│   ├── manifest.json     # MV3 manifest with Firefox gecko settings
│   ├── background.js     # Service worker: caching, notifications
│   ├── content.js        # Widget: Shadow DOM, polling, theme detection
│   ├── styles.css        # Host-level styles
│   ├── popup.html/js     # Fallback popup
│   ├── browser-polyfill.js # Minimal browser/chrome API shim
│   └── icons/            # Terracotta clock icons (16/48/128px)
└── menubar/              # macOS menu bar app (Swift, SPM)
```

## License

MIT
