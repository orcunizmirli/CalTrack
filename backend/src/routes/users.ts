import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { updateProfileSchema, updateGoalsSchema } from '../validators/user';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

// All routes require authentication
router.use(authenticate);

// GET /users/me
router.get('/me', async (req: AuthRequest, res: Response, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: { goals: { where: { isActive: true }, take: 1 } },
    });

    if (!user) throw new AppError('Kullanıcı bulunamadı', 404);

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

// DELETE /users/me
router.delete('/me', async (req: AuthRequest, res: Response, next) => {
  try {
    await prisma.user.delete({ where: { id: req.userId } });
    res.json({ message: 'Hesap silindi' });
  } catch (error) {
    next(error);
  }
});

export { router as userRouter };
