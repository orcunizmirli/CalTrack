import { createClient, RedisClientType } from 'redis';
import { config } from '../config';

let redisClient: RedisClientType | null = null;
let isConnected = false;

export async function getRedisClient(): Promise<RedisClientType | null> {
  if (redisClient && isConnected) return redisClient;

  if (!redisClient) {
    redisClient = createClient({ url: config.redis.url });

    redisClient.on('error', (err) => {
      console.error('Redis connection error:', err.message);
      isConnected = false;
    });

    redisClient.on('connect', () => {
      console.log('Redis connected');
      isConnected = true;
    });

    redisClient.on('disconnect', () => {
      isConnected = false;
    });
  }

  try {
    if (!isConnected) {
      await redisClient.connect();
      isConnected = true;
    }
    return redisClient;
  } catch (err) {
    console.error('Redis connect failed, falling back to in-memory:', (err as Error).message);
    return null;
  }
}

export function isRedisConnected(): boolean {
  return isConnected;
}

/**
 * Get cached value from Redis. Returns parsed JSON or null.
 */
export async function getCache<T>(key: string): Promise<T | null> {
  const redis = await getRedisClient();
  if (!redis) return null;
  try {
    const data = await redis.get(key);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

/**
 * Set cache value in Redis with TTL in seconds.
 */
export async function setCache(key: string, value: unknown, ttlSeconds: number): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  try {
    await redis.set(key, JSON.stringify(value), { EX: ttlSeconds });
  } catch {
    // Cache write failure is non-critical
  }
}

/**
 * Delete cache entries matching a pattern prefix.
 * Uses SCAN instead of KEYS to avoid blocking Redis.
 */
export async function invalidateCache(prefix: string): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  try {
    let cursor = 0;
    do {
      const result = await redis.scan(cursor, { MATCH: `${prefix}*`, COUNT: 100 });
      cursor = result.cursor;
      if (result.keys.length > 0) {
        await redis.del(result.keys);
      }
    } while (cursor !== 0);
  } catch {
    // Cache invalidation failure is non-critical
  }
}

/**
 * Cache-through helper: returns cached value or computes, caches, and returns.
 */
export async function withCache<T>(key: string, ttlSeconds: number, compute: () => Promise<T>): Promise<T> {
  const cached = await getCache<T>(key);
  if (cached !== null) return cached;
  const result = await compute();
  await setCache(key, result, ttlSeconds);
  return result;
}
