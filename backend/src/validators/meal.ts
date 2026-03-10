import { z } from 'zod';

export const createMealSchema = z.object({
  foodId: z.string().uuid().optional(),
  foodName: z.string().min(1).max(255),
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  date: z.string(), // ISO date string
  quantity: z.number().min(1).max(5000),
  calories: z.number().min(0),
  proteinG: z.number().min(0).optional(),
  carbsG: z.number().min(0).optional(),
  fatG: z.number().min(0).optional(),
  aiScanId: z.string().uuid().optional(),
  photoUrl: z.string().url().optional(),
  notes: z.string().max(500).optional(),
});

export const updateMealSchema = createMealSchema.partial();

export const createCustomFoodSchema = z.object({
  name: z.string().min(1).max(255),
  nameTr: z.string().max(255).optional(),
  brand: z.string().max(255).optional(),
  barcode: z.string().max(50).optional(),
  servingSizeG: z.number().min(1).max(5000),
  servingLabel: z.string().max(50).optional(),
  calories: z.number().min(0),
  proteinG: z.number().min(0),
  carbsG: z.number().min(0),
  fatG: z.number().min(0),
  fiberG: z.number().min(0).optional(),
  sugarG: z.number().min(0).optional(),
});

export const recipeRequestSchema = z.object({
  mealType: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  targetCalories: z.number().min(50).max(3000),
  ingredients: z.array(z.string()).optional(),
  dietaryRestrictions: z.array(z.string()).optional(),
  proteinTarget: z.number().min(0).optional(),
  carbsTarget: z.number().min(0).optional(),
  fatTarget: z.number().min(0).optional(),
});

export type CreateMealInput = z.infer<typeof createMealSchema>;
export type CreateCustomFoodInput = z.infer<typeof createCustomFoodSchema>;
export type RecipeRequestInput = z.infer<typeof recipeRequestSchema>;
