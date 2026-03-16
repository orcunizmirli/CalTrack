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
