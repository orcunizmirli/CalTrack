import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Geçerli bir email giriniz'),
  password: z.string().min(8, 'Şifre en az 8 karakter olmalı'),
  name: z.string().min(1, 'İsim gerekli').max(100),
});

export const loginSchema = z.object({
  email: z.string().email('Geçerli bir email giriniz'),
  password: z.string().min(1, 'Şifre gerekli'),
});

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
