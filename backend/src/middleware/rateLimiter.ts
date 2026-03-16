import { Request, Response, NextFunction } from 'express';
import { RateLimiterRedis, RateLimiterMemory, RateLimiterAbstract } from 'rate-limiter-flexible';
import { getRedisClient } from '../utils/redis';
import { t, getLocale } from '../i18n';

let generalLimiter: RateLimiterAbstract | null = null;
let aiLimiter: RateLimiterAbstract | null = null;

const GENERAL_POINTS = 100; // requests
const GENERAL_DURATION = 60; // per 60 seconds
const AI_POINTS = 20;
const AI_DURATION = 60;

// In-memory fallbacks
const memoryGeneralLimiter = new RateLimiterMemory({
  points: GENERAL_POINTS,
  duration: GENERAL_DURATION,
});

const memoryAiLimiter = new RateLimiterMemory({
  points: AI_POINTS,
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

    aiLimiter = new RateLimiterRedis({
      storeClient: redis,
      keyPrefix: 'rl_ai',
      points: AI_POINTS,
      duration: AI_DURATION,
      insuranceLimiter: memoryAiLimiter,
    });

    console.log('Rate limiters initialized with Redis backend');
  } else {
    generalLimiter = memoryGeneralLimiter;
    aiLimiter = memoryAiLimiter;
    console.log('Rate limiters initialized with in-memory fallback');
  }
}

function getKey(req: Request): string {
  return req.ip || req.socket.remoteAddress || 'unknown';
}

export const rateLimiter = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const limiter = generalLimiter || memoryGeneralLimiter;
  try {
    await limiter.consume(getKey(req));
    next();
  } catch {
    const locale = getLocale(req);
    res.status(429).json({ error: t('rate_limit.too_many_requests', locale) });
  }
};

export const aiRateLimiter = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const limiter = aiLimiter || memoryAiLimiter;
  try {
    await limiter.consume(getKey(req));
    next();
  } catch {
    const locale = getLocale(req);
    res.status(429).json({ error: t('rate_limit.ai_limit_exceeded', locale) });
  }
};
