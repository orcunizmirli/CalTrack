import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

// GET /notifications/preferences
router.get('/preferences', async (req: AuthRequest, res: Response, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId! },
      select: { notificationPrefs: true },
    });

    const defaults = {
      breakfastReminder: true,
      breakfastTime: '08:00',
      lunchReminder: true,
      lunchTime: '12:30',
      dinnerReminder: true,
      dinnerTime: '19:00',
      waterReminder: false,
      waterIntervalMin: 60,
    };

    const prefs = user?.notificationPrefs
      ? { ...defaults, ...(user.notificationPrefs as Record<string, any>) }
      : defaults;

    res.json(prefs);
  } catch (error) {
    next(error);
  }
});

// PUT /notifications/preferences
router.put('/preferences', async (req: AuthRequest, res: Response, next) => {
  try {
    const prefs = req.body;

    await prisma.user.update({
      where: { id: req.userId! },
      data: { notificationPrefs: prefs },
    });

    res.json({ status: 'ok', preferences: prefs });
  } catch (error) {
    next(error);
  }
});

export { router as notificationRouter };
