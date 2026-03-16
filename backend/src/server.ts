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
import { errorHandler } from './middleware/errorHandler';
import { rateLimiter } from './middleware/rateLimiter';

const app = express();

// Middleware
app.use(helmet());
app.use(cors({
  origin: config.isDev ? '*' : ['https://caltrack.app'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(config.isDev ? 'dev' : 'combined'));
app.use(rateLimiter);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
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

// Error handler
app.use(errorHandler);

// Start server
app.listen(config.port, () => {
  console.log(`CalTrack API running on port ${config.port} [${config.nodeEnv}]`);
});

export default app;
