import { z } from 'zod';
import { t, Locale } from '../i18n';

export function getRegisterSchema(locale: Locale = 'tr') {
  return z.object({
    email: z.string().email(t('validation.email_invalid', locale)),
    password: z.string().min(8, t('validation.password_min', locale)),
    name: z.string().min(1, t('validation.name_required', locale)).max(100),
  });
}

export function getLoginSchema(locale: Locale = 'tr') {
  return z.object({
    email: z.string().email(t('validation.email_invalid', locale)),
    password: z.string().min(1, t('validation.password_required', locale)),
  });
}

// Static schemas for type inference and non-localized contexts
export const registerSchema = getRegisterSchema('tr');
export const loginSchema = getLoginSchema('tr');

export const appleAuthSchema = z.object({
  identityToken: z.string(),
  authorizationCode: z.string(),
  fullName: z.object({
    givenName: z.string().optional(),
    familyName: z.string().optional(),
  }).optional(),
  email: z.string().email().optional(),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string(),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type AppleAuthInput = z.infer<typeof appleAuthSchema>;
