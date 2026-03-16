import { Request, Response, NextFunction } from 'express';
import { RateLimiterRedis, RateLimiterMemory, RateLimiterAbstract } from 'rate-limiter-flexible';
import { getRedisClient } from '../utils/redis';
import { t, getLocale } from '../i18n';
import { AuthRequest } from './auth';

let generalLimiter: RateLimiterAbstract | null = null;
let aiIpLimiter: RateLimiterAbstract | null = null;
let aiUserLimiter: RateLimiterAbstract | null = null;

const GENERAL_POINTS = 100; // requests
const GENERAL_DURATION = 60; // per 60 seconds
const AI_IP_POINTS = 20; // per IP
const AI_USER_POINTS = 10; // per authenticated user (stricter)
const AI_DURATION = 60;

// In-memory fallbacks
const memoryGeneralLimiter = new RateLimiterMemory({
  points: GENERAL_POINTS,
  duration: GENERAL_DURATION,
});

const memoryAiIpLimiter = new RateLimiterMemory({
  points: AI_IP_POINTS,
  duration: AI_DURATION,
});

const memoryAiUserLimiter = new RateLimiterMemory({
  points: AI_USER_POINTS,
  duration: AI_DURATION,
});

/**
 * Initialize Redis-based rate limiters.
 * Falls back to in-memory if Redis is unavailable.
 */
export async function initRateLimiters(): Promise<void> {
  const redis = await getRedisClient();

  if (redis) {
    generalLimiter = new RateLimiterRedis({
      storeClient: redis,
      keyPrefix: 'rl_general',
      points: GENERAL_POINTS,
      duration: GENERAL_DURATION,
      insuranceLimiter: memoryGeneralLimiter,
    });

    aiIpLimiter = new RateLimiterRedis({
      storeClient: redis,
      keyPrefix: 'rl_ai_ip',
      points: AI_IP_POINTS,
      duration: AI_DURATION,
      insuranceLimiter: memoryAiIpLimiter,
    });

    aiUserLimiter = new RateLimiterRedis({
      storeClient: redis,
      keyPrefix: 'rl_ai_user',
      points: AI_USER_POINTS,
      duration: AI_DURATION,
      insuranceLimiter: memoryAiUserLimiter,
    });

    console.log('Rate limiters initialized with Redis backend');
  } else {
    generalLimiter = memoryGeneralLimiter;
    aiIpLimiter = memoryAiIpLimiter;
    aiUserLimiter = memoryAiUserLimiter;
    console.log('Rate limiters initialized with in-memory fallback');
  }
}

function getIpKey(req: Request): string {
  return req.ip || req.socket.remoteAddress || 'unknown';
}

export const rateLimiter = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const limiter = generalLimiter || memoryGeneralLimiter;
  try {
    await limiter.consume(getIpKey(req));
    next();
  } catch {
    const locale = getLocale(req);
    res.status(429).json({ error: t('rate_limit.too_many_requests', locale) });
  }
};

/**
 * AI rate limiter: enforces both IP-based and user-based limits.
 * This prevents a single user from exhausting the shared IP pool,
 * and also prevents users behind shared IPs from affecting each other.
 */
export const aiRateLimiter = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const ipLimiter = aiIpLimiter || memoryAiIpLimiter;
  const userLimiter = aiUserLimiter || memoryAiUserLimiter;
  const locale = getLocale(req);

  try {
    // Check IP-based limit
    await ipLimiter.consume(getIpKey(req));
  } catch {
    res.status(429).json({ error: t('rate_limit.ai_limit_exceeded', locale) });
    return;
  }

  // Check user-based limit (if authenticated)
  const userId = (req as AuthRequest).userId;
  if (userId) {
    try {
      await userLimiter.consume(userId);
    } catch {
      res.status(429).json({ error: t('rate_limit.ai_limit_exceeded', locale) });
      return;
    }
  }

  next();
};
