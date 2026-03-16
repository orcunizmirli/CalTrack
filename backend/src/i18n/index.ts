import { Request } from 'express';
import translations, { Locale } from './translations';

const DEFAULT_LOCALE: Locale = 'tr';
const SUPPORTED_LOCALES: Locale[] = ['tr', 'en'];

/**
 * Get translated message by key and locale.
 */
export function t(key: string, locale: Locale = DEFAULT_LOCALE): string {
  const entry = translations[key];
  if (!entry) return key;
  return entry[locale] || entry[DEFAULT_LOCALE] || key;
}

/**
 * Extract locale from request.
 * Priority: 1) query param ?lang= 2) Accept-Language header 3) default 'tr'
 */
export function getLocale(req: Request): Locale {
  // Check query parameter
  const queryLang = req.query.lang as string;
  if (queryLang && SUPPORTED_LOCALES.includes(queryLang as Locale)) {
    return queryLang as Locale;
  }

  // Check Accept-Language header
  const acceptLang = req.headers['accept-language'];
  if (acceptLang) {
    for (const locale of SUPPORTED_LOCALES) {
      if (acceptLang.toLowerCase().includes(locale)) {
        return locale;
      }
    }
  }

  return DEFAULT_LOCALE;
}

export type { Locale };
