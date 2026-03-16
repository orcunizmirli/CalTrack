import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { z } from 'zod';
import { t, getLocale } from '../i18n';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

const weightLogSchema = z.object({
  weightKg: z.number().min(20).max(300),
  bodyFatPct: z.number().min(1).max(70).nullable().optional(),
  date: z.string().optional(),
  source: z.enum(['manual', 'apple_health']).optional(),
});

// GET /weight/history?range=week|month|3months|all
router.get('/history', async (req: AuthRequest, res: Response, next) => {
  try {
    const range = (req.query.range as string) || 'month';

    const now = new Date();
    let startDate: Date;

    switch (range) {
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case '3months':
        startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        break;
      case 'all':
        startDate = new Date('2020-01-01');
        break;
      default: // month
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    }

    const logs = await prisma.weightLog.findMany({
      where: {
        userId: req.userId!,
        date: { gte: startDate },
      },
      orderBy: { date: 'asc' },
    });

    // Calculate stats
    const weights = logs.map(l => Number(l.weightKg));
    const latest = weights[weights.length - 1] ?? null;
    const first = weights[0] ?? null;
    const change = latest !== null && first !== null ? +(latest - first).toFixed(1) : null;
    const min = weights.length > 0 ? Math.min(...weights) : null;
    const max = weights.length > 0 ? Math.max(...weights) : null;

    res.json({
      logs,
      stats: { latest, change, min, max, count: logs.length },
    });
  } catch (error) {
    next(error);
  }
});

// GET /weight/latest
router.get('/latest', async (req: AuthRequest, res: Response, next) => {
  try {
    const log = await prisma.weightLog.findFirst({
      where: { userId: req.userId! },
      orderBy: { date: 'desc' },
    });

    res.json(log);
  } catch (error) {
    next(error);
  }
});

// POST /weight
router.post('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const data = weightLogSchema.parse(req.body);
    const date = data.date ? new Date(data.date) : new Date();

    const log = await prisma.weightLog.create({
      data: {
        userId: req.userId!,
        weightKg: data.weightKg,
        bodyFatPct: data.bodyFatPct ?? undefined,
        date,
        source: data.source || 'manual',
      },
    });

    // Also update user's current weight
    await prisma.user.update({
      where: { id: req.userId },
      data: {
        weightKg: data.weightKg,
        bodyFatPct: data.bodyFatPct ?? undefined,
        updatedAt: new Date(),
      },
    });

    res.status(201).json(log);
  } catch (error) {
    next(error);
  }
});

// PUT /weight/:id
router.put('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const data = weightLogSchema.parse(req.body);

    const existing = await prisma.weightLog.findFirst({
      where: { id: req.params.id, userId: req.userId! },
    });

    if (!existing) {
      return res.status(404).json({ error: t('weight.not_found', locale) });
    }

    const log = await prisma.weightLog.update({
      where: { id: req.params.id },
      data: {
        weightKg: data.weightKg,
        bodyFatPct: data.bodyFatPct ?? undefined,
        date: data.date ? new Date(data.date) : undefined,
      },
    });

    res.json(log);
  } catch (error) {
    next(error);
  }
});

// DELETE /weight/:id
router.delete('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    await prisma.weightLog.deleteMany({
      where: { id: req.params.id, userId: req.userId! },
    });
    res.json({ message: t('weight.deleted', locale) });
  } catch (error) {
    next(error);
  }
});

export { router as weightRouter };
