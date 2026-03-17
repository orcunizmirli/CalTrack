import { z } from 'zod';
import { t, Locale } from '../i18n';

export function getUpdateProfileSchema(locale: Locale = 'tr') {
  return z.object({
    name: z.string().min(1, t('validation.name_required', locale)).max(100).optional(),
    gender: z.enum(['male', 'female']).optional(),
    birthDate: z.string().datetime().optional(),
    heightCm: z.number().min(50).max(300).optional(),
    weightKg: z.number().min(20).max(300).optional(),
    bodyFatPct: z.number().min(1).max(70).nullable().optional(),
    activityLevel: z.enum(['sedentary', 'light', 'moderate', 'active', 'very_active']).optional(),
    unitSystem: z.enum(['metric', 'imperial']).optional(),
    language: z.enum(['tr', 'en']).optional(),
  });
}

// Static schemas for type inference
export const updateProfileSchema = getUpdateProfileSchema('tr');

export const updateGoalsSchema = z.object({
  goalType: z.enum(['lose_weight', 'gain_muscle', 'burn_fat', 'maintain']),
  targetWeight: z.number().min(30).max(250).optional(),
  weeklyChange: z.number().min(0).max(1.5).optional(),
  dailyCalories: z.number().min(800).max(6000),
  proteinG: z.number().min(0).max(500).optional(),
  carbsG: z.number().min(0).max(800).optional(),
  fatG: z.number().min(0).max(300).optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type UpdateGoalsInput = z.infer<typeof updateGoalsSchema>;
