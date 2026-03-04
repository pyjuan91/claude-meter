# Claude Usage Monitor

Browser extension that displays claude.ai usage limits as a floating widget on the chat page.

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

## Install

**Chrome:** `chrome://extensions` → Developer mode → Load unpacked → select this folder

**Firefox:** `about:debugging#/runtime/this-firefox` → Load Temporary Add-on → select `manifest.json`

## Structure

```
├── manifest.json         # MV3 manifest with Firefox gecko settings
├── background.js         # Service worker: caching, notifications
├── content.js            # Widget: Shadow DOM, polling, theme detection
├── styles.css            # Host-level styles
├── popup.html/js         # Fallback popup
├── browser-polyfill.js   # Minimal browser/chrome API shim
└── icons/                # Terracotta clock icons (16/48/128px)
```

## License

MIT
