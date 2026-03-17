export const MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack'] as const;
export type MealType = (typeof MEAL_TYPES)[number];

export const WEIGHT_SOURCES = ['manual', 'apple_health'] as const;
export type WeightSource = (typeof WEIGHT_SOURCES)[number];

export const ANALYTICS_RANGES = ['week', 'month', '3months'] as const;
export type AnalyticsRange = (typeof ANALYTICS_RANGES)[number];

export function rangeToDays(range: string): number {
  return range === 'week' ? 7 : range === 'month' ? 30 : 90;
}
