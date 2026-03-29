/* background.js — Service worker for Claude Meter */

const STORAGE_KEY_ORG = 'claude_usage_org_id';
const STORAGE_KEY_USAGE = 'claude_usage_data';

// Listen for messages from content script or popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'GET_CACHED_ORG') {
    chrome.storage.local.get(STORAGE_KEY_ORG, (result) => {
      sendResponse({ orgId: result[STORAGE_KEY_ORG] || null });
    });
    return true; // async response
  }

  if (message.type === 'SET_ORG_ID') {
    chrome.storage.local.set({ [STORAGE_KEY_ORG]: message.orgId }, () => {
      sendResponse({ ok: true });
    });
    return true;
  }

  if (message.type === 'INVALIDATE_ORG') {
    chrome.storage.local.remove(STORAGE_KEY_ORG, () => {
      sendResponse({ ok: true });
    });
    return true;
  }

  if (message.type === 'CACHE_USAGE') {
    chrome.storage.local.set({
      [STORAGE_KEY_USAGE]: {
        data: message.data,
        timestamp: Date.now()
      }
    }, () => {
      sendResponse({ ok: true });
    });
    return true;
  }

  if (message.type === 'GET_CACHED_USAGE') {
    chrome.storage.local.get(STORAGE_KEY_USAGE, (result) => {
      sendResponse(result[STORAGE_KEY_USAGE] || null);
    });
    return true;
  }

  // Notification trigger from content script
  if (message.type === 'USAGE_THRESHOLD') {
    chrome.notifications?.create?.('usage-warning', {
      type: 'basic',
      iconUrl: 'icons/icon-128.png',
      title: 'Claude Usage Warning',
      message: message.message || 'Your 5-hour usage is above 80%.'
    });
    sendResponse({ ok: true });
    return true;
  }
});
