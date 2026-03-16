import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { updateProfileSchema, updateGoalsSchema } from '../validators/user';
import { AppError } from '../middleware/errorHandler';
import { calculateBMR, calculateTDEE, calculateNutritionPlan } from '../services/nutrition';
import { t, getLocale } from '../i18n';

const router = Router();
const prisma = new PrismaClient();

// All routes require authentication
router.use(authenticate);

// GET /users/me
router.get('/me', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: { goals: { where: { isActive: true }, take: 1 } },
    });

    if (!user) throw new AppError(t('user.not_found', locale), 404);

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      gender: user.gender,
      birthDate: user.birthDate,
      heightCm: user.heightCm,
      weightKg: user.weightKg,
      bodyFatPct: user.bodyFatPct,
      activityLevel: user.activityLevel,
      unitSystem: user.unitSystem,
      language: user.language,
      activeGoal: user.goals[0] || null,
    });
  } catch (error) {
    next(error);
  }
});

// PUT /users/me
router.put('/me', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = updateProfileSchema.parse(req.body);

    const user = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...data,
        birthDate: data.birthDate ? new Date(data.birthDate) : undefined,
        updatedAt: new Date(),
      },
    });

    res.json({
      id: user.id,
      name: user.name,
      gender: user.gender,
      heightCm: user.heightCm,
      weightKg: user.weightKg,
      bodyFatPct: user.bodyFatPct,
      activityLevel: user.activityLevel,
    });
  } catch (error) {
    next(error);
  }
});

// PUT /users/me/goals
router.put('/me/goals', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = updateGoalsSchema.parse(req.body);

    // Deactivate existing goals
    await prisma.userGoal.updateMany({
      where: { userId: req.userId!, isActive: true },
      data: { isActive: false },
    });

    // Create new goal
    const goal = await prisma.userGoal.create({
      data: {
        userId: req.userId!,
        goalType: data.goalType,
        targetWeight: data.targetWeight,
        weeklyChange: data.weeklyChange,
        dailyCalories: data.dailyCalories,
        proteinG: data.proteinG,
        carbsG: data.carbsG,
        fatG: data.fatG,
        isActive: true,
      },
    });

    res.json(goal);
  } catch (error) {
    next(error);
  }
});

// GET /users/me/stats
router.get('/me/stats', async (req: AuthRequest, res: Response, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const mealCount = await prisma.mealEntry.count({
      where: { userId: req.userId!, date: { gte: today } },
    });

    const totalDays = await prisma.mealEntry.groupBy({
      by: ['date'],
      where: { userId: req.userId! },
    });

    res.json({
      todayMeals: mealCount,
      totalDaysLogged: totalDays.length,
    });
  } catch (error) {
    next(error);
  }
});

// GET /users/me/nutrition-plan?goalType=lose_weight&weeklyChange=0.5
router.get('/me/nutrition-plan', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) throw new AppError(t('user.not_found', locale), 404);

    if (!user.gender || !user.heightCm || !user.weightKg || !user.birthDate) {
      throw new AppError(t('user.profile_incomplete', locale), 400);
    }

    const metrics = {
      gender: user.gender,
      weightKg: Number(user.weightKg),
      heightCm: Number(user.heightCm),
      birthDate: user.birthDate,
      activityLevel: user.activityLevel || 'moderate',
    };

    const goalType = (req.query.goalType as string) || 'maintain';
    const weeklyChange = req.query.weeklyChange ? parseFloat(req.query.weeklyChange as string) : 0.5;

    const plan = calculateNutritionPlan(metrics, {
      goalType: goalType as 'lose_weight' | 'gain_muscle' | 'burn_fat' | 'maintain',
      weeklyChange,
    });

    res.json(plan);
  } catch (error) {
    next(error);
  }
});

// DELETE /users/me
router.delete('/me', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    await prisma.user.delete({ where: { id: req.userId } });
    res.json({ message: t('user.account_deleted', locale) });
  } catch (error) {
    next(error);
  }
});

export { router as userRouter };
