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
 * Used to invalidate cache when data changes.
 */
export async function invalidateCache(prefix: string): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  try {
    const keys = await redis.keys(`${prefix}*`);
    if (keys.length > 0) {
      await redis.del(keys);
    }
  } catch {
    // Cache invalidation failure is non-critical
  }
}
