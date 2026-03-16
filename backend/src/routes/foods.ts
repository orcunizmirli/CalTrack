import { Router, Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { createCustomFoodSchema } from '../validators/meal';
import { AppError } from '../middleware/errorHandler';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';
import { withCache } from '../utils/redis';

const router = Router();

router.use(authenticate);

// GET /foods/search?q=
router.get('/search', async (req: Request, res: Response, next) => {
  try {
    const query = req.query.q as string;
    if (!query || query.length < 2) {
      res.json([]);
      return;
    }

    const cacheKey = `food_search:${query.toLowerCase().trim()}`;

    const foods = await withCache(cacheKey, 300, () =>
      prisma.food.findMany({
        where: {
          OR: [
            { name: { contains: query, mode: 'insensitive' } },
            { nameTr: { contains: query, mode: 'insensitive' } },
            { brand: { contains: query, mode: 'insensitive' } },
          ],
        },
        take: 30,
        orderBy: [
          { isVerified: 'desc' },
          { name: 'asc' },
        ],
      })
    );

    res.json(foods);
  } catch (error) {
    next(error);
  }
});

// GET /foods/barcode/:code
router.get('/barcode/:code', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { code } = req.params;

    let food = await prisma.food.findFirst({
      where: { barcode: code },
    });

    if (!food) {
      // Try Open Food Facts API
      try {
        const response = await fetch(`https://world.openfoodfacts.org/api/v2/product/${code}.json`);
        const data = await response.json() as Record<string, any>;

        if (data.status === 1 && data.product) {
          const p = data.product as Record<string, any>;
          const nutrients = p.nutriments || {};

          food = await prisma.food.create({
            data: {
              name: p.product_name_en || p.product_name || 'Unknown',
              nameTr: p.product_name || undefined,
              brand: p.brands || undefined,
              barcode: code,
              servingSizeG: parseFloat(p.serving_quantity) || 100,
              servingLabel: p.serving_size || '100g',
              calories: nutrients['energy-kcal_100g'] || 0,
              proteinG: nutrients.proteins_100g || 0,
              carbsG: nutrients.carbohydrates_100g || 0,
              fatG: nutrients.fat_100g || 0,
              fiberG: nutrients.fiber_100g || undefined,
              sugarG: nutrients.sugars_100g || undefined,
              source: 'openfoodfacts',
              isVerified: false,
            },
          });
        }
      } catch {
        // Open Food Facts API error - ignore
      }
    }

    if (!food) {
      throw new AppError(t('food.product_not_found', locale), 404);
    }

    res.json(food);
  } catch (error) {
    next(error);
  }
});

// GET /foods/:id
router.get('/:id', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const food = await prisma.food.findUnique({
      where: { id: req.params.id },
    });

    if (!food) throw new AppError(t('food.not_found', locale), 404);
    res.json(food);
  } catch (error) {
    next(error);
  }
});

// POST /foods/custom
router.post('/custom', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = createCustomFoodSchema.parse(req.body);

    const food = await prisma.food.create({
      data: {
        ...data,
        source: 'custom',
        isVerified: false,
        createdBy: req.userId,
      },
    });

    res.status(201).json(food);
  } catch (error) {
    next(error);
  }
});

// GET /foods/recent
router.get('/recent', async (req: AuthRequest, res: Response, next) => {
  try {
    const recentMeals = await prisma.mealEntry.findMany({
      where: { userId: req.userId! },
      distinct: ['foodId'],
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { food: true },
    });

    const foods = recentMeals
      .filter(m => m.food)
      .map(m => m.food);

    res.json(foods);
  } catch (error) {
    next(error);
  }
});

// GET /foods/frequent
router.get('/frequent', async (req: AuthRequest, res: Response, next) => {
  try {
    const frequent = await prisma.mealEntry.groupBy({
      by: ['foodId'],
      where: { userId: req.userId!, foodId: { not: null } },
      _count: { foodId: true },
      orderBy: { _count: { foodId: 'desc' } },
      take: 20,
    });

    const foodIds = frequent.map(f => f.foodId).filter(Boolean) as string[];
    const foods = await prisma.food.findMany({
      where: { id: { in: foodIds } },
    });

    res.json(foods);
  } catch (error) {
    next(error);
  }
});

export { router as foodRouter };
