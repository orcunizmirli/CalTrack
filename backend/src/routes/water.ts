import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { z } from 'zod';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';

const router = Router();

router.use(authenticate);

const waterSchema = z.object({
  amountMl: z.number().min(1).max(5000),
  date: z.string().optional(),
});

// GET /water/daily?date=
router.get('/daily', async (req: AuthRequest, res: Response, next) => {
  try {
    const dateStr = req.query.date as string || new Date().toISOString().split('T')[0];
    const date = new Date(dateStr);
    date.setHours(0, 0, 0, 0);
    const nextDay = new Date(date);
    nextDay.setDate(nextDay.getDate() + 1);

    const entries = await prisma.waterEntry.findMany({
      where: {
        userId: req.userId!,
        date: { gte: date, lt: nextDay },
      },
      orderBy: { createdAt: 'asc' },
    });

    const total = entries.reduce((sum, e) => sum + e.amountMl, 0);

    res.json({ entries, totalMl: total });
  } catch (error) {
    next(error);
  }
});

// POST /water
router.post('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = waterSchema.parse(req.body);

    const entry = await prisma.waterEntry.create({
      data: {
        userId: req.userId!,
        amountMl: data.amountMl,
        date: data.date ? new Date(data.date) : new Date(),
      },
    });

    res.status(201).json(entry);
  } catch (error) {
    next(error);
  }
});

// DELETE /water/:id
router.delete('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    await prisma.waterEntry.deleteMany({
      where: { id: req.params.id, userId: req.userId! },
    });
    res.json({ message: t('water.deleted', locale) });
  } catch (error) {
    next(error);
  }
});

export { router as waterRouter };
