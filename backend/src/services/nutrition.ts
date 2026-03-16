/**
 * Nutrition calculation service
 * BMR: Mifflin-St Jeor equation
 * TDEE: BMR × activity multiplier
 * Macro distribution based on goal type
 */

interface UserMetrics {
  gender: string;
  weightKg: number;
  heightCm: number;
  birthDate: Date;
  activityLevel: string;
}

interface GoalParams {
  goalType: 'lose_weight' | 'gain_muscle' | 'burn_fat' | 'maintain';
  weeklyChange?: number; // kg per week
}

interface NutritionPlan {
  bmr: number;
  tdee: number;
  dailyCalories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

const ACTIVITY_MULTIPLIERS: Record<string, number> = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

function calculateAge(birthDate: Date): number {
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const m = today.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return age;
}

/**
 * Mifflin-St Jeor BMR
 * Male:   10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161 + 166
 * Female: 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
 */
export function calculateBMR(metrics: UserMetrics): number {
  const age = calculateAge(metrics.birthDate);
  const base = 10 * metrics.weightKg + 6.25 * metrics.heightCm - 5 * age;

  if (metrics.gender === 'male') {
    return Math.round(base + 5);
  }
  return Math.round(base - 161);
}

export function calculateTDEE(metrics: UserMetrics): number {
  const bmr = calculateBMR(metrics);
  const multiplier = ACTIVITY_MULTIPLIERS[metrics.activityLevel] || 1.55;
  return Math.round(bmr * multiplier);
}

export function calculateNutritionPlan(
  metrics: UserMetrics,
  goal: GoalParams,
): NutritionPlan {
  const bmr = calculateBMR(metrics);
  const tdee = calculateTDEE(metrics);

  // Calculate calorie adjustment based on goal
  let dailyCalories: number;
  const weeklyChange = goal.weeklyChange || 0.5;
  // 1 kg fat ≈ 7700 kcal
  const dailyDeficitSurplus = Math.round((weeklyChange * 7700) / 7);

  switch (goal.goalType) {
    case 'lose_weight':
    case 'burn_fat':
      dailyCalories = Math.max(1200, tdee - dailyDeficitSurplus);
      break;
    case 'gain_muscle':
      dailyCalories = tdee + dailyDeficitSurplus;
      break;
    default: // maintain
      dailyCalories = tdee;
  }

  // Macro distribution based on goal
  let proteinRatio: number;
  let fatRatio: number;
  let carbRatio: number;

  switch (goal.goalType) {
    case 'gain_muscle':
      // High protein: 30% protein, 45% carbs, 25% fat
      proteinRatio = 0.30;
      carbRatio = 0.45;
      fatRatio = 0.25;
      break;
    case 'burn_fat':
      // Higher protein, lower carb: 35% protein, 30% carbs, 35% fat
      proteinRatio = 0.35;
      carbRatio = 0.30;
      fatRatio = 0.35;
      break;
    case 'lose_weight':
      // Moderate high protein: 30% protein, 40% carbs, 30% fat
      proteinRatio = 0.30;
      carbRatio = 0.40;
      fatRatio = 0.30;
      break;
    default: // maintain
      // Balanced: 25% protein, 50% carbs, 25% fat
      proteinRatio = 0.25;
      carbRatio = 0.50;
      fatRatio = 0.25;
  }

  // 1g protein = 4 kcal, 1g carb = 4 kcal, 1g fat = 9 kcal
  const proteinG = Math.round((dailyCalories * proteinRatio) / 4);
  const carbsG = Math.round((dailyCalories * carbRatio) / 4);
  const fatG = Math.round((dailyCalories * fatRatio) / 9);

  return { bmr, tdee, dailyCalories, proteinG, carbsG, fatG };
}
