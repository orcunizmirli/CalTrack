import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { prisma } from '../utils/prisma';
import { syncPullSchema, syncPushSchema } from '../validators/sync';

const router = Router();

router.use(authenticate);

/**
 * POST /sync/pull
 * Client sends its lastSyncedAt timestamp, server returns all changes since then.
 * Uses updatedAt to catch both new and modified records.
 * Includes soft-deleted records so client can remove them locally.
 */
router.post('/pull', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;
    const { lastSyncedAt } = syncPullSchema.parse(req.body);

    const since = lastSyncedAt ? new Date(lastSyncedAt) : new Date(0);

    // Fetch all entities updated since last sync (including soft-deleted)
    const [meals, waterEntries, weightLogs, goals, user] = await Promise.all([
      prisma.mealEntry.findMany({
        where: { userId, updatedAt: { gt: since } },
        include: { food: true },
        orderBy: { updatedAt: 'asc' },
      }),
      prisma.waterEntry.findMany({
        where: { userId, updatedAt: { gt: since } },
        orderBy: { updatedAt: 'asc' },
      }),
      prisma.weightLog.findMany({
        where: { userId, updatedAt: { gt: since } },
        orderBy: { updatedAt: 'asc' },
      }),
      prisma.userGoal.findMany({
        where: { userId, updatedAt: { gt: since } },
        orderBy: { updatedAt: 'asc' },
      }),
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          weightKg: true,
          heightCm: true,
          bodyFatPct: true,
          activityLevel: true,
          language: true,
          unitSystem: true,
          updatedAt: true,
        },
      }),
    ]);

    const serverNow = new Date().toISOString();

    res.json({
      syncedAt: serverNow,
      changes: {
        meals: meals.map(m => ({
          id: m.id,
          foodId: m.foodId,
          foodName: m.foodName,
          mealType: m.mealType,
          date: m.date,
          quantity: Number(m.quantity),
          calories: Number(m.calories),
          proteinG: m.proteinG ? Number(m.proteinG) : null,
          carbsG: m.carbsG ? Number(m.carbsG) : null,
          fatG: m.fatG ? Number(m.fatG) : null,
          photoUrl: m.photoUrl,
          notes: m.notes,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
          deletedAt: m.deletedAt,
        })),
        waterEntries: waterEntries.map(w => ({
          id: w.id,
          amountMl: w.amountMl,
          date: w.date,
          createdAt: w.createdAt,
          updatedAt: w.updatedAt,
          deletedAt: w.deletedAt,
        })),
        weightLogs: weightLogs.map(w => ({
          id: w.id,
          weightKg: Number(w.weightKg),
          bodyFatPct: w.bodyFatPct ? Number(w.bodyFatPct) : null,
          date: w.date,
          source: w.source,
          createdAt: w.createdAt,
          updatedAt: w.updatedAt,
          deletedAt: w.deletedAt,
        })),
        goals,
        profile: user && user.updatedAt > since ? user : null,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /sync/push
 * Client sends locally created/updated/deleted records.
 * Supports soft delete via deletedIds arrays.
 * Uses batch createMany for new records.
 */
router.post('/push', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;
    const { meals, waterEntries, weightLogs, deletedMealIds, deletedWaterIds, deletedWeightIds } =
      syncPushSchema.parse(req.body) as any;

    const results = {
      meals: { created: 0, updated: 0, conflicts: 0 },
      waterEntries: { created: 0, updated: 0, conflicts: 0 },
      weightLogs: { created: 0, updated: 0, conflicts: 0 },
      deleted: { meals: 0, water: 0, weight: 0 },
    };

    // --- Soft delete processing ---
    if (deletedMealIds && Array.isArray(deletedMealIds) && deletedMealIds.length > 0) {
      const { count } = await prisma.mealEntry.updateMany({
        where: { id: { in: deletedMealIds }, userId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      results.deleted.meals = count;
    }

    if (deletedWaterIds && Array.isArray(deletedWaterIds) && deletedWaterIds.length > 0) {
      const { count } = await prisma.waterEntry.updateMany({
        where: { id: { in: deletedWaterIds }, userId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      results.deleted.water = count;
    }

    if (deletedWeightIds && Array.isArray(deletedWeightIds) && deletedWeightIds.length > 0) {
      const { count } = await prisma.weightLog.updateMany({
        where: { id: { in: deletedWeightIds }, userId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      results.deleted.weight = count;
    }

    // --- Sync meals ---
    if (meals && meals.length > 0) {
      const newMeals: Array<{
        userId: string; foodId?: string; foodName: string; mealType: string;
        date: Date; quantity: number; calories: number;
        proteinG?: number; carbsG?: number; fatG?: number;
        photoUrl?: string | null; notes?: string | null;
      }> = [];

      for (const meal of meals) {
        if (meal.serverId) {
          // Update existing — check conflict
          const existing = await prisma.mealEntry.findFirst({
            where: { id: meal.serverId, userId, deletedAt: null },
          });
          if (existing && meal.clientUpdatedAt) {
            const clientTime = new Date(meal.clientUpdatedAt).getTime();
            const serverTime = existing.updatedAt.getTime();
            if (serverTime > clientTime) {
              results.meals.conflicts++;
              continue;
            }
          }
          if (existing) {
            await prisma.mealEntry.update({
              where: { id: meal.serverId },
              data: {
                foodId: meal.foodId || undefined,
                foodName: meal.foodName,
                mealType: meal.mealType,
                date: new Date(meal.date),
                quantity: meal.quantity,
                calories: meal.calories,
                proteinG: meal.proteinG,
                carbsG: meal.carbsG,
                fatG: meal.fatG,
                photoUrl: meal.photoUrl,
                notes: meal.notes,
              },
            });
            results.meals.updated++;
          }
        } else {
          newMeals.push({
            userId,
            foodId: meal.foodId || undefined,
            foodName: meal.foodName,
            mealType: meal.mealType,
            date: new Date(meal.date),
            quantity: meal.quantity,
            calories: meal.calories,
            proteinG: meal.proteinG,
            carbsG: meal.carbsG,
            fatG: meal.fatG,
            photoUrl: meal.photoUrl,
            notes: meal.notes,
          });
        }
      }

      // Batch create new meals
      if (newMeals.length > 0) {
        const { count } = await prisma.mealEntry.createMany({ data: newMeals });
        results.meals.created = count;
      }
    }

    // --- Sync water entries (batch create) ---
    if (waterEntries && waterEntries.length > 0) {
      const newWater: Array<{ userId: string; amountMl: number; date: Date }> = [];

      for (const entry of waterEntries) {
        if (entry.serverId) {
          const existing = await prisma.waterEntry.findFirst({
            where: { id: entry.serverId, userId, deletedAt: null },
          });
          if (existing) {
            await prisma.waterEntry.update({
              where: { id: entry.serverId },
              data: { amountMl: entry.amountMl, date: new Date(entry.date) },
            });
            results.waterEntries.updated++;
          }
        } else {
          newWater.push({
            userId,
            amountMl: Math.round(entry.amountMl),
            date: new Date(entry.date),
          });
        }
      }

      if (newWater.length > 0) {
        const { count } = await prisma.waterEntry.createMany({ data: newWater });
        results.waterEntries.created = count;
      }
    }

    // --- Sync weight logs (batch create with dedup) ---
    if (weightLogs && weightLogs.length > 0) {
      const newWeights: Array<{
        userId: string; weightKg: number; bodyFatPct?: number;
        date: Date; source: string;
      }> = [];

      for (const log of weightLogs) {
        if (log.serverId) {
          const existing = await prisma.weightLog.findFirst({
            where: { id: log.serverId, userId, deletedAt: null },
          });
          if (existing) {
            await prisma.weightLog.update({
              where: { id: log.serverId },
              data: {
                weightKg: log.weightKg,
                bodyFatPct: log.bodyFatPct ?? undefined,
                date: new Date(log.date),
              },
            });
            results.weightLogs.updated++;
          }
        } else {
          const date = new Date(log.date);
          date.setHours(0, 0, 0, 0);
          const source = log.source || 'manual';

          // Check for duplicate
          const existing = await prisma.weightLog.findFirst({
            where: { userId, date, source, deletedAt: null },
          });

          if (!existing) {
            newWeights.push({
              userId,
              weightKg: log.weightKg,
              bodyFatPct: log.bodyFatPct ?? undefined,
              date,
              source,
            });
          } else {
            results.weightLogs.conflicts++;
          }
        }
      }

      if (newWeights.length > 0) {
        const { count } = await prisma.weightLog.createMany({ data: newWeights });
        results.weightLogs.created = count;

        // Update user weight with latest
        const latest = newWeights[newWeights.length - 1];
        await prisma.user.update({
          where: { id: userId },
          data: { weightKg: latest.weightKg },
        });
      }
    }

    res.json({
      status: 'ok',
      syncedAt: new Date().toISOString(),
      results,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /sync/status
 * Returns the server's current timestamp and counts (excluding soft-deleted).
 */
router.get('/status', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;

    const [mealCount, waterCount, weightCount] = await Promise.all([
      prisma.mealEntry.count({ where: { userId, deletedAt: null } }),
      prisma.waterEntry.count({ where: { userId, deletedAt: null } }),
      prisma.weightLog.count({ where: { userId, deletedAt: null } }),
    ]);

    res.json({
      serverTime: new Date().toISOString(),
      counts: {
        meals: mealCount,
        waterEntries: waterCount,
        weightLogs: weightCount,
      },
    });
  } catch (error) {
    next(error);
  }
});

export { router as syncRouter };
