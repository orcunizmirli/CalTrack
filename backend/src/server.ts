import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config';
import { authRouter } from './routes/auth';
import { userRouter } from './routes/users';
import { foodRouter } from './routes/foods';
import { mealRouter } from './routes/meals';
import { aiRouter } from './routes/ai';
import { analyticsRouter } from './routes/analytics';
import { waterRouter } from './routes/water';
import { recipeRouter } from './routes/recipes';
import { subscriptionRouter } from './routes/subscriptions';
import { weightRouter } from './routes/weight';
import { healthSyncRouter } from './routes/healthSync';
import { notificationRouter } from './routes/notifications';
import { syncRouter } from './routes/sync';
import { errorHandler } from './middleware/errorHandler';
import { requestLogger } from './middleware/requestLogger';
import { rateLimiter, initRateLimiters } from './middleware/rateLimiter';
import { prisma } from './utils/prisma';
import { isRedisConnected, getRedisClient } from './utils/redis';

const app = express();

// Security: Validate critical secrets on startup (production only)
if (!config.isDev) {
  const missingSecrets: string[] = [];
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'dev-secret-change-me') {
    missingSecrets.push('JWT_SECRET');
  }
  if (!process.env.JWT_REFRESH_SECRET || process.env.JWT_REFRESH_SECRET === 'dev-refresh-secret') {
    missingSecrets.push('JWT_REFRESH_SECRET');
  }
  if (missingSecrets.length > 0) {
    console.error(`FATAL: Missing or insecure secrets in production: ${missingSecrets.join(', ')}`);
    process.exit(1);
  }
}

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));
app.use(cors({
  origin: config.isDev ? '*' : ['https://caltrack.app'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(config.isDev ? 'dev' : 'combined'));
app.use(requestLogger);
app.use(rateLimiter);

// Health check — includes DB and Redis connectivity
app.get('/health', async (_req, res) => {
  let dbStatus: 'connected' | 'disconnected' = 'disconnected';
  try {
    await prisma.$queryRaw`SELECT 1`;
    dbStatus = 'connected';
  } catch {
    // DB unreachable
  }

  let redisStatus: 'connected' | 'disconnected' = 'disconnected';
  try {
    const redis = await getRedisClient();
    if (redis && isRedisConnected()) {
      await redis.ping();
      redisStatus = 'connected';
    }
  } catch {
    // Redis unreachable
  }

  const allHealthy = dbStatus === 'connected' && redisStatus === 'connected';

  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    services: {
      database: dbStatus,
      redis: redisStatus,
    },
  });
});

// API Routes
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/users', userRouter);
app.use('/api/v1/foods', foodRouter);
app.use('/api/v1/meals', mealRouter);
app.use('/api/v1/ai', aiRouter);
app.use('/api/v1/analytics', analyticsRouter);
app.use('/api/v1/water', waterRouter);
app.use('/api/v1/recipes', recipeRouter);
app.use('/api/v1/subscriptions', subscriptionRouter);
app.use('/api/v1/weight', weightRouter);
app.use('/api/v1/health-sync', healthSyncRouter);
app.use('/api/v1/notifications', notificationRouter);
app.use('/api/v1/sync', syncRouter);

// Error handler
app.use(errorHandler);

// Initialize rate limiters (Redis) and start server
initRateLimiters().then(() => {
  app.listen(config.port, () => {
    console.log(`CalTrack API running on port ${config.port} [${config.nodeEnv}]`);
  });
}).catch((err) => {
  console.error('Failed to initialize rate limiters:', err);
  // Start anyway with in-memory fallback
  app.listen(config.port, () => {
    console.log(`CalTrack API running on port ${config.port} [${config.nodeEnv}] (in-memory rate limiting)`);
  });
});

export default app;
