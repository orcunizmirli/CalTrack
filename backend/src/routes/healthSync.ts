import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

/**
 * POST /health-sync/import
 * Import health data from Apple HealthKit into CalTrack DB.
 * iOS sends batched data (weight, steps, calories burned) periodically.
 */
router.post('/import', async (req: AuthRequest, res: Response, next) => {
  try {
    const { weightEntries, waterEntries, activeCalories, steps } = req.body;
    const userId = req.userId!;
    const results = { weights: 0, water: 0, profileUpdated: false };

    // Import weight entries from HealthKit
    if (weightEntries && Array.isArray(weightEntries)) {
      for (const entry of weightEntries) {
        if (!entry.weightKg || !entry.date) continue;

        const date = new Date(entry.date);
        date.setHours(0, 0, 0, 0);

        // Upsert: skip if already have an entry for that date from apple_health
        const existing = await prisma.weightLog.findFirst({
          where: {
            userId,
            date,
            source: 'apple_health',
          },
        });

        if (!existing) {
          await prisma.weightLog.create({
            data: {
              userId,
              weightKg: entry.weightKg,
              bodyFatPct: entry.bodyFatPct || null,
              date,
              source: 'apple_health',
            },
          });
          results.weights++;
        }
      }

      // Update user's current weight with latest HealthKit entry
      if (weightEntries.length > 0) {
        const latest = weightEntries.sort(
          (a: any, b: any) => new Date(b.date).getTime() - new Date(a.date).getTime()
        )[0];

        await prisma.user.update({
          where: { id: userId },
          data: {
            weightKg: latest.weightKg,
            ...(latest.bodyFatPct ? { bodyFatPct: latest.bodyFatPct } : {}),
          },
        });
        results.profileUpdated = true;
      }
    }

    // Import water entries from HealthKit
    if (waterEntries && Array.isArray(waterEntries)) {
      for (const entry of waterEntries) {
        if (!entry.amountMl || !entry.date) continue;

        const date = new Date(entry.date);
        date.setHours(0, 0, 0, 0);

        await prisma.waterEntry.create({
          data: {
            userId,
            amountMl: Math.round(entry.amountMl),
            date,
          },
        });
        results.water++;
      }
    }

    res.json({
      status: 'ok',
      imported: results,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /health-sync/export
 * Export CalTrack data for writing back to Apple HealthKit.
 * Returns meals (calories), water, and weight data for a date range.
 */
router.post('/export', async (req: AuthRequest, res: Response, next) => {
  try {
    const { startDate, endDate } = req.body;
    const userId = req.userId!;

    if (!startDate) {
      throw new AppError('startDate gerekli', 400);
    }

    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);
    const end = endDate ? new Date(endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    // Get meals for calorie export (to write dietary energy to HealthKit)
    const meals = await prisma.mealEntry.findMany({
      where: {
        userId,
        date: { gte: start, lte: end },
      },
      select: {
        id: true,
        date: true,
        mealType: true,
        calories: true,
        proteinG: true,
        carbsG: true,
        fatG: true,
      },
      orderBy: { date: 'asc' },
    });

    // Get water entries for export
    const water = await prisma.waterEntry.findMany({
      where: {
        userId,
        date: { gte: start, lte: end },
      },
      select: {
        id: true,
        date: true,
        amountMl: true,
      },
      orderBy: { date: 'asc' },
    });

    // Get weight entries (only manual ones, not already from HealthKit)
    const weights = await prisma.weightLog.findMany({
      where: {
        userId,
        date: { gte: start, lte: end },
        source: { not: 'apple_health' },
      },
      select: {
        id: true,
        date: true,
        weightKg: true,
        bodyFatPct: true,
      },
      orderBy: { date: 'asc' },
    });

    res.json({
      meals: meals.map(m => ({
        id: m.id,
        date: m.date,
        mealType: m.mealType,
        calories: Number(m.calories),
        proteinG: Number(m.proteinG || 0),
        carbsG: Number(m.carbsG || 0),
        fatG: Number(m.fatG || 0),
      })),
      water: water.map(w => ({
        id: w.id,
        date: w.date,
        amountMl: w.amountMl,
      })),
      weights: weights.map(w => ({
        id: w.id,
        date: w.date,
        weightKg: Number(w.weightKg),
        bodyFatPct: w.bodyFatPct ? Number(w.bodyFatPct) : null,
      })),
    });
  } catch (error) {
    next(error);
  }
});

export { router as healthSyncRouter };
