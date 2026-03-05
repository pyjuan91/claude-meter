import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock chrome APIs
const storageData = {};
const chrome = {
  storage: {
    local: {
      get: vi.fn((key, cb) => {
        cb({ [key]: storageData[key] ?? undefined });
      }),
      set: vi.fn((obj, cb) => {
        Object.assign(storageData, obj);
        cb?.();
      }),
      remove: vi.fn((key, cb) => {
        delete storageData[key];
        cb?.();
      }),
    },
  },
  runtime: {
    onMessage: {
      addListener: vi.fn(),
    },
  },
  notifications: {
    create: vi.fn(),
  },
};
globalThis.chrome = chrome;

let messageHandler;

beforeEach(() => {
  // Clear storage
  for (const k of Object.keys(storageData)) delete storageData[k];
  vi.clearAllMocks();

  // Re-require background.js to register the listener
  vi.resetModules();

  // Capture the listener
  chrome.runtime.onMessage.addListener.mockImplementation((handler) => {
    messageHandler = handler;
  });

  // Load background.js by evaluating it
  const fs = require('fs');
  const path = require('path');
  const code = fs.readFileSync(path.join(__dirname, '..', 'src', 'background.js'), 'utf-8');
  // eslint-disable-next-line no-eval
  const fn = new Function('chrome', code);
  fn(chrome);
});

function sendMessage(message) {
  return new Promise((resolve) => {
    const result = messageHandler(message, {}, resolve);
    // If handler doesn't return true, resolve immediately
    if (result !== true) resolve(undefined);
  });
}

describe('background message handler', () => {
  it('handles GET_CACHED_ORG with no cached value', async () => {
    const response = await sendMessage({ type: 'GET_CACHED_ORG' });
    expect(response).toEqual({ orgId: null });
  });

  it('handles SET_ORG_ID', async () => {
    const response = await sendMessage({ type: 'SET_ORG_ID', orgId: 'test-org-123' });
    expect(response).toEqual({ ok: true });
    expect(storageData['claude_usage_org_id']).toBe('test-org-123');
  });

  it('handles GET_CACHED_ORG after SET_ORG_ID', async () => {
    await sendMessage({ type: 'SET_ORG_ID', orgId: 'test-org-456' });
    const response = await sendMessage({ type: 'GET_CACHED_ORG' });
    expect(response).toEqual({ orgId: 'test-org-456' });
  });

  it('handles INVALIDATE_ORG', async () => {
    storageData['claude_usage_org_id'] = 'some-org';
    const response = await sendMessage({ type: 'INVALIDATE_ORG' });
    expect(response).toEqual({ ok: true });
    expect(storageData['claude_usage_org_id']).toBeUndefined();
  });

  it('handles CACHE_USAGE', async () => {
    const usageData = { five_hour: { utilization: 42 } };
    const response = await sendMessage({ type: 'CACHE_USAGE', data: usageData });
    expect(response).toEqual({ ok: true });
    const cached = storageData['claude_usage_data'];
    expect(cached.data).toEqual(usageData);
    expect(cached.timestamp).toBeTypeOf('number');
  });

  it('handles GET_CACHED_USAGE', async () => {
    const usageData = { five_hour: { utilization: 55 } };
    await sendMessage({ type: 'CACHE_USAGE', data: usageData });
    const response = await sendMessage({ type: 'GET_CACHED_USAGE' });
    expect(response.data).toEqual(usageData);
    expect(response.timestamp).toBeTypeOf('number');
  });

  it('handles GET_CACHED_USAGE with no data', async () => {
    const response = await sendMessage({ type: 'GET_CACHED_USAGE' });
    expect(response).toBeNull();
  });

  it('handles USAGE_THRESHOLD', async () => {
    const response = await sendMessage({
      type: 'USAGE_THRESHOLD',
      message: '5-hour usage at 85%'
    });
    expect(response).toEqual({ ok: true });
    expect(chrome.notifications.create).toHaveBeenCalledWith(
      'usage-warning',
      expect.objectContaining({
        type: 'basic',
        title: 'Claude Usage Warning',
        message: '5-hour usage at 85%',
      })
    );
  });
});
