/*
 * Minimal browser API polyfill.
 * Ensures `chrome.*` is available in both Chrome and Firefox.
 * Firefox MV3 exposes `browser.*` natively; Chrome uses `chrome.*`.
 * This shim makes the content script use `chrome.*` uniformly,
 * aliasing from `browser` if needed.
 */
if (typeof globalThis.chrome === 'undefined' && typeof globalThis.browser !== 'undefined') {
  globalThis.chrome = globalThis.browser;
}
