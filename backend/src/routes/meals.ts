import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { createMealSchema, updateMealSchema } from '../validators/meal';
import { AppError } from '../middleware/errorHandler';
import { t, getLocale } from '../i18n';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

// GET /meals/daily?date=
router.get('/daily', async (req: AuthRequest, res: Response, next) => {
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
      orderBy: { createdAt: 'asc' },
    });

    res.json(meals);
  } catch (error) {
    next(error);
  }
});

// GET /meals/summary?date=
router.get('/summary', async (req: AuthRequest, res: Response, next) => {
  try {
    const dateStr = req.query.date as string || new Date().toISOString().split('T')[0];
    const date = new Date(dateStr);
    date.setHours(0, 0, 0, 0);
    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);

    const result = await prisma.mealEntry.aggregate({
      where: {
        userId: req.userId!,
        date: { gte: date, lt: nextDay },
      },
      _sum: {
        calories: true,
        proteinG: true,
        carbsG: true,
        fatG: true,
      },
      _count: true,
    });

    res.json({
      date: dateStr,
      totalCalories: result._sum.calories || 0,
      totalProteinG: result._sum.proteinG || 0,
      totalCarbsG: result._sum.carbsG || 0,
      totalFatG: result._sum.fatG || 0,
      mealCount: result._count,
    });
  } catch (error) {
    next(error);
  }
});

// POST /meals
router.post('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = createMealSchema.parse(req.body);

    const meal = await prisma.mealEntry.create({
      data: {
        userId: req.userId!,
        foodId: data.foodId,
        foodName: data.foodName,
        mealType: data.mealType,
        date: new Date(data.date),
        quantity: data.quantity,
        calories: data.calories,
        proteinG: data.proteinG,
        carbsG: data.carbsG,
        fatG: data.fatG,
        aiScanId: data.aiScanId,
        photoUrl: data.photoUrl,
        notes: data.notes,
      },
    });

    res.status(201).json(meal);
  } catch (error) {
    next(error);
  }
});

// PUT /meals/:id
router.put('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const data = updateMealSchema.parse(req.body);

    const existing = await prisma.mealEntry.findFirst({
      where: { id: req.params.id, userId: req.userId! },
    });

    if (!existing) throw new AppError(t('meal.not_found', locale), 404);

    const meal = await prisma.mealEntry.update({
      where: { id: req.params.id },
      data: {
        ...data,
        date: data.date ? new Date(data.date) : undefined,
      },
    });

    res.json(meal);
  } catch (error) {
    next(error);
  }
});

// DELETE /meals/:id
router.delete('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const existing = await prisma.mealEntry.findFirst({
      where: { id: req.params.id, userId: req.userId! },
    });

    if (!existing) throw new AppError(t('meal.not_found', locale), 404);

    await prisma.mealEntry.delete({ where: { id: req.params.id } });
    res.json({ message: t('meal.deleted', locale) });
  } catch (error) {
    next(error);
  }
});

export { router as mealRouter };
