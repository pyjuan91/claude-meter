# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Usage Monitor is a browser extension (Chrome MV3 + Firefox) that displays Claude.ai usage limits as a floating widget. It shows real-time 5-hour and 7-day utilization with progress bars, model breakdowns (Opus/Sonnet/Cowork), and optional extra usage tracking. Published on the Chrome Web Store.

## Commands

```bash
npm test              # Run tests once with vitest
npm run test:ci       # Run tests with verbose reporter (used in CI)
npm run test:watch    # Run tests in watch mode
npm run zip           # Package extension into zip for distribution
```

To run a single test file: `npx vitest tests/utils.test.js`

## Tech Stack

- **Pure vanilla JavaScript** — no frameworks, no bundler, no transpilation
- **Vitest** for testing (only dev dependency)
- **Chrome Extension Manifest V3** with Firefox gecko compatibility
- Node.js 20 for development

## Architecture

### Source Files (`src/`)

- **`content.js`** (~1245 lines) — Main widget injected into claude.ai. Handles org detection (5 fallback strategies), usage polling (60s interval), Shadow DOM rendering, theme detection, sidebar integration, drag handling, and the onboarding tutorial with confetti. This is the largest and most complex file.
- **`background.js`** — Service worker handling storage (org ID, usage cache) and desktop notifications (80% threshold).
- **`popup.js` + `popup.html`** — Fallback popup showing cached usage data when the extension icon is clicked.
- **`utils.js`** — Pure utility functions (color selection by utilization %, time formatting, org extraction, SVG donut icon). Exported as UMD module shared by content, popup, and tests.
- **`i18n.js`** — Custom i18n system with 12 languages. Key functions: `detectLang()`, `setLang()`, `t(key, ...placeholders)`.
- **`browser-polyfill.js`** — Firefox/Chrome API shim.
- **`manifest.json`** — MV3 manifest. Content scripts inject on `https://claude.ai/*` at `document_idle`.

### Tests (`tests/`)

Tests mock `chrome.*` APIs using `vi.stubGlobal`. Each test file corresponds to a source module (`utils.test.js`, `i18n.test.js`, `background.test.js`, `popup.test.js`).

### Key Patterns

- **Shadow DOM isolation**: Widget uses a closed Shadow DOM to prevent page style interference. Host element at max z-index with `pointer-events: none`.
- **Org ID detection** has 5 ordered fallbacks: cached storage → `lastActiveOrg` cookie → `/api/organizations` fetch → `__NEXT_DATA__` parsing → fetch URL interception.
- **Usage endpoint**: `GET https://claude.ai/api/organizations/{orgId}/usage` using browser session cookies (same-origin, no token).
- **Visibility-based polling**: Only fetches when tab is visible (`document.visibilitychange`).
- **Sidebar detection**: Uses `nav[aria-label]` selector (language-agnostic) + `ResizeObserver` for responsive repositioning.
- **Storage keys** are prefixed with `claude_usage_` (e.g., `claude_usage_org_id`, `claude_usage_collapsed`).
- **Color thresholds**: ≤50% terracotta, 50-80% amber, >80% red (with dark/light variants in `getUtilColor`).

### CI/CD (`.github/workflows/`)

- **ci.yml**: Runs tests + validates manifest.json on push/PR.
- **release.yml**: On `v*` tags, runs CI then creates GitHub Release with packaged zip.
