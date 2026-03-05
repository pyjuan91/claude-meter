import { describe, it, expect } from 'vitest';
const utils = require('../src/utils.js');

describe('getUtilColor', () => {
  it('returns green/orange for <=50% (dark)', () => {
    expect(utils.getUtilColor(30, true)).toBe('#D4835E');
  });

  it('returns green/orange for <=50% (light)', () => {
    expect(utils.getUtilColor(50, false)).toBe('#C15F3C');
  });

  it('returns yellow for 50-80% (dark)', () => {
    expect(utils.getUtilColor(51, true)).toBe('#E0A020');
  });

  it('returns yellow for 50-80% (light)', () => {
    expect(utils.getUtilColor(80, false)).toBe('#D4940A');
  });

  it('returns red for >80% (dark)', () => {
    expect(utils.getUtilColor(81, true)).toBe('#E5524A');
  });

  it('returns red for >80% (light)', () => {
    expect(utils.getUtilColor(100, false)).toBe('#D03E3E');
  });

  it('returns base color at 0%', () => {
    expect(utils.getUtilColor(0, true)).toBe('#D4835E');
  });
});

describe('formatTimeUntil', () => {
  it('returns empty string for null', () => {
    expect(utils.formatTimeUntil(null)).toBe('');
  });

  it('returns empty string for undefined', () => {
    expect(utils.formatTimeUntil(undefined)).toBe('');
  });

  it('returns "Resetting soon" for past time', () => {
    const past = new Date(Date.now() - 60_000).toISOString();
    expect(utils.formatTimeUntil(past, Date.now())).toBe('Resetting soon');
  });

  it('returns minutes only when <1h', () => {
    const now = Date.now();
    const future = new Date(now + 45 * 60_000).toISOString();
    expect(utils.formatTimeUntil(future, now)).toBe('Resets in 45m');
  });

  it('returns hours+mins when 1-24h', () => {
    const now = Date.now();
    const future = new Date(now + 3 * 3_600_000 + 30 * 60_000).toISOString();
    expect(utils.formatTimeUntil(future, now)).toBe('Resets in 3h 30m');
  });

  it('returns date string when >=24h', () => {
    const now = Date.now();
    const future = new Date(now + 25 * 3_600_000).toISOString();
    const result = utils.formatTimeUntil(future, now);
    expect(result).toMatch(/^Resets \w{3}/);
  });

  it('returns "Resetting soon" at exact boundary (diff=0)', () => {
    const now = Date.now();
    const exact = new Date(now).toISOString();
    expect(utils.formatTimeUntil(exact, now)).toBe('Resetting soon');
  });
});

describe('extractOrgFromUrl', () => {
  it('extracts UUID from valid API URL', () => {
    const url = 'https://claude.ai/api/organizations/12345678-1234-1234-1234-123456789abc/usage';
    expect(utils.extractOrgFromUrl(url)).toBe('12345678-1234-1234-1234-123456789abc');
  });

  it('returns null for non-matching URL', () => {
    expect(utils.extractOrgFromUrl('https://claude.ai/chat')).toBeNull();
  });

  it('returns null for null input', () => {
    expect(utils.extractOrgFromUrl(null)).toBeNull();
  });

  it('returns null for empty string', () => {
    expect(utils.extractOrgFromUrl('')).toBeNull();
  });
});

describe('getOrgFromCookies', () => {
  const uuid = 'abcdef01-2345-6789-abcd-ef0123456789';

  it('extracts UUID from lastActiveOrg cookie', () => {
    const cookieStr = `other=value; lastActiveOrg=${uuid}; another=thing`;
    expect(utils.getOrgFromCookies(cookieStr)).toBe(uuid);
  });

  it('returns null when no lastActiveOrg cookie', () => {
    expect(utils.getOrgFromCookies('session=abc; theme=dark')).toBeNull();
  });

  it('handles URL-encoded cookie value', () => {
    const encoded = encodeURIComponent(`"${uuid}"`);
    const cookieStr = `lastActiveOrg=${encoded}`;
    expect(utils.getOrgFromCookies(cookieStr)).toBe(uuid);
  });

  it('returns null for null input', () => {
    expect(utils.getOrgFromCookies(null)).toBeNull();
  });

  it('returns null for empty string', () => {
    expect(utils.getOrgFromCookies('')).toBeNull();
  });

  it('handles multiple cookies with spaces', () => {
    const cookieStr = `  foo=bar ;  lastActiveOrg=${uuid} ; baz=qux  `;
    expect(utils.getOrgFromCookies(cookieStr)).toBe(uuid);
  });
});

describe('buildDonutIcon', () => {
  it('returns valid SVG string', () => {
    const svg = utils.buildDonutIcon(50, '#E0A020', '#444444', '#ECECEC');
    expect(svg).toContain('<svg');
    expect(svg).toContain('</svg>');
  });

  it('includes the percentage text', () => {
    const svg = utils.buildDonutIcon(75, '#E0A020', '#444444', '#ECECEC');
    expect(svg).toContain('>75</text>');
  });

  it('uses provided colors', () => {
    const svg = utils.buildDonutIcon(30, '#D4835E', '#444444', '#ECECEC');
    expect(svg).toContain('stroke="#D4835E"');
    expect(svg).toContain('stroke="#444444"');
    expect(svg).toContain('fill="#ECECEC"');
  });

  it('rounds percentage', () => {
    const svg = utils.buildDonutIcon(33.7, '#D4835E', '#444444', '#ECECEC');
    expect(svg).toContain('>34</text>');
  });
});
