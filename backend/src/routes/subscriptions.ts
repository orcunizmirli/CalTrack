import { Router, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { config } from '../config';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';

const router = Router();

router.use(authenticate);

// Apple App Store verification URL
const APP_STORE_VERIFY_URL = config.isDev
  ? 'https://sandbox.itunes.apple.com/verifyReceipt'
  : 'https://buy.itunes.apple.com/verifyReceipt';

/**
 * Verify receipt with Apple App Store.
 * Returns the parsed receipt info or null if invalid.
 */
async function verifyWithApple(receipt: string): Promise<Record<string, any> | null> {
  try {
    const response = await fetch(APP_STORE_VERIFY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receipt,
        'password': config.apple.sharedSecret || '',
        'exclude-old-transactions': true,
      }),
    });

    const data = await response.json() as Record<string, any>;

    // Status 0 = valid, 21007 = sandbox receipt sent to production
    if (data.status === 21007) {
      // Retry with sandbox
      const sandboxResponse = await fetch(
        'https://sandbox.itunes.apple.com/verifyReceipt',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            'receipt-data': receipt,
            'password': config.apple.sharedSecret || '',
            'exclude-old-transactions': true,
          }),
        }
      );
      const sandboxData = await sandboxResponse.json() as Record<string, any>;
      if (sandboxData.status !== 0) return null;
      return sandboxData;
    }

    if (data.status !== 0) return null;
    return data;
  } catch (error) {
    console.error('Apple receipt verification error:', error);
    return null;
  }
}

/**
 * Extract subscription info from Apple receipt response.
 */
function extractSubscriptionInfo(receiptData: Record<string, any>): {
  productId: string;
  expiresDate: Date;
  isActive: boolean;
  plan: string;
} | null {
  const latestReceipt = receiptData.latest_receipt_info;
  if (!latestReceipt || !Array.isArray(latestReceipt) || latestReceipt.length === 0) {
    return null;
  }

  // Get the most recent transaction
  const latest = latestReceipt.sort(
    (a: any, b: any) =>
      parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms)
  )[0];

  const expiresDate = new Date(parseInt(latest.expires_date_ms));
  const isActive = expiresDate > new Date();

  // Determine plan from product_id
  const productId = latest.product_id || '';
  let plan = 'monthly';
  if (productId.includes('weekly')) plan = 'weekly';
  else if (productId.includes('yearly') || productId.includes('annual')) plan = 'yearly';

  return { productId, expiresDate, isActive, plan };
}

// POST /subscriptions/verify-receipt
router.post('/verify-receipt', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { receipt } = req.body;

    if (!receipt) {
      throw new AppError(t('subscription.receipt_required', locale), 400);
    }

    // Verify with Apple
    const receiptData = await verifyWithApple(receipt);

    if (!receiptData) {
      throw new AppError(t('subscription.invalid_receipt', locale), 400);
    }

    const subInfo = extractSubscriptionInfo(receiptData);

    if (!subInfo) {
      throw new AppError(t('subscription.info_not_found', locale), 400);
    }

    const subscription = await prisma.subscription.upsert({
      where: { userId: req.userId! },
      update: {
        plan: subInfo.plan,
        status: subInfo.isActive ? 'active' : 'expired',
        appleReceipt: receipt,
        expiresAt: subInfo.expiresDate,
      },
      create: {
        userId: req.userId!,
        plan: subInfo.plan,
        status: subInfo.isActive ? 'active' : 'expired',
        appleReceipt: receipt,
        startsAt: new Date(),
        expiresAt: subInfo.expiresDate,
      },
    });

    res.json({
      ...subscription,
      isActive: subInfo.isActive,
    });
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
