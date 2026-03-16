import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { prisma } from '../utils/prisma';
import { getCache, setCache } from '../utils/redis';

const router = Router();

router.use(authenticate);

// GET /analytics/calories?range=week|month|3months
router.get('/calories', async (req: AuthRequest, res: Response, next) => {
  try {
    const range = req.query.range as string || 'week';
    const days = range === 'week' ? 7 : range === 'month' ? 30 : 90;

    const cacheKey = `analytics:calories:${req.userId}:${range}`;
    const cached = await getCache<unknown[]>(cacheKey);
    if (cached) { res.json(cached); return; }

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const meals = await prisma.mealEntry.groupBy({
      by: ['date'],
      where: {
        userId: req.userId!,
        date: { gte: startDate },
      },
      _sum: { calories: true },
      orderBy: { date: 'asc' },
    });

    const result = meals.map(m => ({
      date: m.date,
      calories: m._sum.calories || 0,
    }));

    await setCache(cacheKey, result, 60);

    res.json(result);
  } catch (error) {
    next(error);
  }
});

// GET /analytics/macros?range=
router.get('/macros', async (req: AuthRequest, res: Response, next) => {
  try {
    const range = req.query.range as string || 'week';
    const days = range === 'week' ? 7 : range === 'month' ? 30 : 90;

    const cacheKey = `analytics:macros:${req.userId}:${range}`;
    const cached = await getCache<unknown[]>(cacheKey);
    if (cached) { res.json(cached); return; }

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const meals = await prisma.mealEntry.groupBy({
      by: ['date'],
      where: {
        userId: req.userId!,
        date: { gte: startDate },
      },
      _sum: {
        proteinG: true,
        carbsG: true,
        fatG: true,
      },
      orderBy: { date: 'asc' },
    });

    const result = meals.map(m => ({
      date: m.date,
      proteinG: m._sum.proteinG || 0,
      carbsG: m._sum.carbsG || 0,
      fatG: m._sum.fatG || 0,
    }));

    await setCache(cacheKey, result, 60);

    res.json(result);
  } catch (error) {
    next(error);
  }
});

// GET /analytics/weight?range=
router.get('/weight', async (req: AuthRequest, res: Response, next) => {
  try {
    const range = req.query.range as string || 'month';
    const days = range === 'week' ? 7 : range === 'month' ? 30 : 90;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const weights = await prisma.weightLog.findMany({
      where: {
        userId: req.userId!,
        date: { gte: startDate },
      },
      orderBy: { date: 'asc' },
    });

    res.json(weights);
  } catch (error) {
    next(error);
  }
});

// GET /analytics/streak
router.get('/streak', async (req: AuthRequest, res: Response, next) => {
  try {
    const meals = await prisma.mealEntry.groupBy({
      by: ['date'],
      where: { userId: req.userId! },
      orderBy: { date: 'desc' },
    });

    let currentStreak = 0;
    let longestStreak = 0;
    let tempStreak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dates = meals.map(m => {
      const d = new Date(m.date);
      d.setHours(0, 0, 0, 0);
      return d.getTime();
    });

    // Calculate current streak
    let checkDate = today.getTime();
    for (const date of dates) {
      if (date === checkDate) {
        currentStreak++;
        checkDate -= 86400000; // -1 day
      } else {
        break;
      }
    }

    // Calculate longest streak
    for (let i = 0; i < dates.length; i++) {
      if (i === 0 || dates[i] === dates[i - 1] - 86400000) {
        tempStreak++;
      } else {
        longestStreak = Math.max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    longestStreak = Math.max(longestStreak, tempStreak);

    res.json({ currentStreak, longestStreak });
  } catch (error) {
    next(error);
  }
});

// GET /analytics/micronutrients?date=
router.get('/micronutrients', async (req: AuthRequest, res: Response, next) => {
  try {
    const dateStr = req.query.date as string || new Date().toISOString().split('T')[0];
    const date = new Date(dateStr);
    date.setHours(0, 0, 0, 0);
    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);

    const meals = await prisma.mealEntry.findMany({
      where: {
        userId: req.userId!,
        date: { gte: date, lt: nextDay },
      },
      include: { food: true },
    });

    // Aggregate micro nutrients from foods
    const totals: Record<string, number> = {};
    for (const meal of meals) {
      if (!meal.food) continue;
      const ratio = Number(meal.quantity || 0) / Number(meal.food.servingSizeG || 100);
      const fields = [
        'vitaminAMcg', 'vitaminCMg', 'vitaminDMcg', 'vitaminEMg', 'vitaminKMcg',
        'vitaminB1Mg', 'vitaminB2Mg', 'vitaminB3Mg', 'vitaminB6Mg',
        'vitaminB9Mcg', 'vitaminB12Mcg',
        'calciumMg', 'ironMg', 'magnesiumMg', 'potassiumMg', 'zincMg', 'phosphorusMg'
      ];
      for (const field of fields) {
        const value = (meal.food as any)[field];
        if (value) {
          totals[field] = (totals[field] || 0) + value * ratio;
        }
      }
    }

    res.json(totals);
  } catch (error) {
    next(error);
  }
});

export { router as analyticsRouter };
