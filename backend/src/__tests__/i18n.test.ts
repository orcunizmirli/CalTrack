import { describe, it, expect } from 'vitest';
import { t, getLocale } from '../i18n';
import translations from '../i18n/translations';

describe('i18n', () => {
  describe('t()', () => {
    it('returns Turkish translation by default', () => {
      expect(t('auth.required')).toBe('Yetkilendirme gerekli');
    });

    it('returns English translation when locale is en', () => {
      expect(t('auth.required', 'en')).toBe('Authorization required');
    });

    it('returns key when translation key does not exist', () => {
      expect(t('nonexistent.key', 'en')).toBe('nonexistent.key');
    });

    it('falls back to Turkish when requested locale entry missing', () => {
      const result = t('auth.email_exists', 'tr');
      expect(result).toBe('Bu email zaten kayıtlı');
    });
  });

  describe('translation completeness', () => {
    const keys = Object.keys(translations);

    it('has translations defined', () => {
      expect(keys.length).toBeGreaterThan(0);
    });

    it('every key has both tr and en translations', () => {
      const missing: string[] = [];
      for (const key of keys) {
        const entry = translations[key];
        if (!entry.tr) missing.push(`${key} missing tr`);
        if (!entry.en) missing.push(`${key} missing en`);
      }
      expect(missing).toEqual([]);
    });

    it('no translation value is empty string', () => {
      const empty: string[] = [];
      for (const key of keys) {
        const entry = translations[key];
        if (entry.tr === '') empty.push(`${key}.tr`);
        if (entry.en === '') empty.push(`${key}.en`);
      }
      expect(empty).toEqual([]);
    });
  });

  describe('getLocale()', () => {
    function mockReq(query: Record<string, string> = {}, headers: Record<string, string> = {}) {
      return { query, headers } as any;
    }

    it('returns tr by default', () => {
      expect(getLocale(mockReq())).toBe('tr');
    });

    it('returns en from query param', () => {
      expect(getLocale(mockReq({ lang: 'en' }))).toBe('en');
    });

    it('returns en from Accept-Language header', () => {
      expect(getLocale(mockReq({}, { 'accept-language': 'en-US,en;q=0.9' }))).toBe('en');
    });

    it('query param takes priority over Accept-Language', () => {
      expect(getLocale(mockReq({ lang: 'tr' }, { 'accept-language': 'en-US' }))).toBe('tr');
    });

    it('ignores unsupported locale in query param', () => {
      expect(getLocale(mockReq({ lang: 'fr' }))).toBe('tr');
    });
  });
});
