import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

// POST /subscriptions/verify-receipt
router.post('/verify-receipt', async (req: AuthRequest, res: Response, next) => {
  try {
    const { receipt } = req.body;

    // TODO: Verify receipt with Apple's servers
    // For now, simulate verification

    const subscription = await prisma.subscription.upsert({
      where: { userId: req.userId! },
      update: {
        plan: 'monthly',
        status: 'active',
        appleReceipt: receipt,
        startsAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
      create: {
        userId: req.userId!,
        plan: 'monthly',
        status: 'active',
        appleReceipt: receipt,
        startsAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      },
    });

    res.json(subscription);
  } catch (error) {
    next(error);
  }
});

// GET /subscriptions/status
router.get('/status', async (req: AuthRequest, res: Response, next) => {
  try {
    const subscription = await prisma.subscription.findUnique({
      where: { userId: req.userId! },
    });

    if (!subscription) {
      res.json({ plan: 'free', status: 'none', isActive: false });
      return;
    }

    const isActive = subscription.status === 'active' &&
      subscription.expiresAt && subscription.expiresAt > new Date();

    res.json({
      ...subscription,
      isActive,
    });
  } catch (error) {
    next(error);
  }
});

export { router as subscriptionRouter };
