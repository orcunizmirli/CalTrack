import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';
import { syncPullSchema, syncPushSchema } from '../validators/sync';

const router = Router();

router.use(authenticate);

/**
 * POST /sync/pull
 * Client sends its lastSyncedAt timestamp, server returns all changes since then.
 * Used by iOS to pull server changes into local SwiftData.
 */
router.post('/pull', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;
    const { lastSyncedAt } = syncPullSchema.parse(req.body);

    const since = lastSyncedAt ? new Date(lastSyncedAt) : new Date(0);

    // Fetch all entities updated since last sync
    const [meals, waterEntries, weightLogs, goals, user] = await Promise.all([
      prisma.mealEntry.findMany({
        where: { userId, createdAt: { gt: since } },
        include: { food: true },
        orderBy: { createdAt: 'asc' },
      }),
      prisma.waterEntry.findMany({
        where: { userId, createdAt: { gt: since } },
        orderBy: { createdAt: 'asc' },
      }),
      prisma.weightLog.findMany({
        where: { userId, createdAt: { gt: since } },
        orderBy: { createdAt: 'asc' },
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
        })),
        waterEntries: waterEntries.map(w => ({
          id: w.id,
          amountMl: w.amountMl,
          date: w.date,
          createdAt: w.createdAt,
        })),
        weightLogs: weightLogs.map(w => ({
          id: w.id,
          weightKg: Number(w.weightKg),
          bodyFatPct: w.bodyFatPct ? Number(w.bodyFatPct) : null,
          date: w.date,
          source: w.source,
          createdAt: w.createdAt,
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
 * Client sends locally created/updated records. Server applies them with
 * conflict resolution (server-wins for same ID, client creates for new).
 * Used by iOS to push offline SwiftData changes to server.
 */
router.post('/push', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;
    const { meals, waterEntries, weightLogs } = syncPushSchema.parse(req.body);

    const results = {
      meals: { created: 0, updated: 0, conflicts: 0 },
      waterEntries: { created: 0, updated: 0, conflicts: 0 },
      weightLogs: { created: 0, updated: 0, conflicts: 0 },
    };

    // Sync meals
    if (meals && Array.isArray(meals)) {
      for (const meal of meals) {
        try {
          if (meal.clientId && meal.serverId) {
            // Update existing record — check for conflicts
            const existing = await prisma.mealEntry.findFirst({
              where: { id: meal.serverId, userId },
            });

            if (existing && meal.clientUpdatedAt) {
              const clientTime = new Date(meal.clientUpdatedAt).getTime();
              const serverTime = existing.createdAt.getTime();
              if (serverTime > clientTime) {
                // Server version is newer — conflict, skip client update
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
            // Create new record
            await prisma.mealEntry.create({
              data: {
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
              },
            });
            results.meals.created++;
          }
        } catch (err) {
          console.error('Sync meal error:', err);
        }
      }
    }

    // Sync water entries
    if (waterEntries && Array.isArray(waterEntries)) {
      for (const entry of waterEntries) {
        try {
          if (entry.serverId) {
            const existing = await prisma.waterEntry.findFirst({
              where: { id: entry.serverId, userId },
            });

            if (existing) {
              await prisma.waterEntry.update({
                where: { id: entry.serverId },
                data: {
                  amountMl: entry.amountMl,
                  date: new Date(entry.date),
                },
              });
              results.waterEntries.updated++;
            }
          } else {
            await prisma.waterEntry.create({
              data: {
                userId,
                amountMl: Math.round(entry.amountMl),
                date: new Date(entry.date),
              },
            });
            results.waterEntries.created++;
          }
        } catch (err) {
          console.error('Sync water error:', err);
        }
      }
    }

    // Sync weight logs
    if (weightLogs && Array.isArray(weightLogs)) {
      for (const log of weightLogs) {
        try {
          if (log.serverId) {
            const existing = await prisma.weightLog.findFirst({
              where: { id: log.serverId, userId },
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
            // Check for duplicate by date + source to avoid double entries
            const date = new Date(log.date);
            date.setHours(0, 0, 0, 0);

            const existing = await prisma.weightLog.findFirst({
              where: {
                userId,
                date,
                source: log.source || 'manual',
              },
            });

            if (!existing) {
              await prisma.weightLog.create({
                data: {
                  userId,
                  weightKg: log.weightKg,
                  bodyFatPct: log.bodyFatPct ?? undefined,
                  date,
                  source: log.source || 'manual',
                },
              });
              results.weightLogs.created++;

              // Update user's current weight with latest entry
              await prisma.user.update({
                where: { id: userId },
                data: { weightKg: log.weightKg },
              });
            } else {
              results.weightLogs.conflicts++;
            }
          }
        } catch (err) {
          console.error('Sync weight error:', err);
        }
      }
    }

    const serverNow = new Date().toISOString();

    res.json({
      status: 'ok',
      syncedAt: serverNow,
      results,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /sync/status
 * Returns the server's current timestamp and counts, so the client
 * can decide if a sync is needed.
 */
router.get('/status', async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.userId!;

    const [mealCount, waterCount, weightCount] = await Promise.all([
      prisma.mealEntry.count({ where: { userId } }),
      prisma.waterEntry.count({ where: { userId } }),
      prisma.weightLog.count({ where: { userId } }),
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
