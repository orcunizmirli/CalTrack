import { z } from 'zod';

const syncMealSchema = z.object({
  clientId: z.string().optional(),
  serverId: z.string().uuid().optional(),
  clientUpdatedAt: z.string().datetime().optional(),
  foodId: z.string().uuid().nullable().optional(),
  foodName: z.string().min(1).max(255),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  date: z.string(),
  quantity: z.number().min(1).max(5000),
  calories: z.number().min(0),
  proteinG: z.number().min(0).optional(),
  carbsG: z.number().min(0).optional(),
  fatG: z.number().min(0).optional(),
  photoUrl: z.string().url().nullable().optional(),
  notes: z.string().max(500).nullable().optional(),
});

const syncWaterSchema = z.object({
  serverId: z.string().uuid().optional(),
  amountMl: z.number().min(1).max(5000),
  date: z.string(),
});

const syncWeightSchema = z.object({
  serverId: z.string().uuid().optional(),
  weightKg: z.number().min(20).max(300),
  bodyFatPct: z.number().min(1).max(70).nullable().optional(),
  date: z.string(),
  source: z.enum(['manual', 'apple_health']).optional(),
});

export const syncPushSchema = z.object({
  meals: z.array(syncMealSchema).optional(),
  waterEntries: z.array(syncWaterSchema).optional(),
  weightLogs: z.array(syncWeightSchema).optional(),
}).refine(
  (data) => data.meals || data.waterEntries || data.weightLogs,
  { message: 'At least one data type must be provided' }
);

export const syncPullSchema = z.object({
  lastSyncedAt: z.string().datetime().optional(),
});

export const healthImportWeightSchema = z.object({
  weightKg: z.number().min(20).max(300),
  bodyFatPct: z.number().min(1).max(70).nullable().optional(),
  date: z.string(),
});

export const healthImportWaterSchema = z.object({
  amountMl: z.number().min(1).max(50000),
  date: z.string(),
});

export const healthImportSchema = z.object({
  weightEntries: z.array(healthImportWeightSchema).optional(),
  waterEntries: z.array(healthImportWaterSchema).optional(),
  activeCalories: z.any().optional(),
  steps: z.any().optional(),
});

export const healthExportSchema = z.object({
  startDate: z.string(),
  endDate: z.string().optional(),
});

export type SyncPushInput = z.infer<typeof syncPushSchema>;
export type SyncPullInput = z.infer<typeof syncPullSchema>;
export type HealthImportInput = z.infer<typeof healthImportSchema>;
export type HealthExportInput = z.infer<typeof healthExportSchema>;
