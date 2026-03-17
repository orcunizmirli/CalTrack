import { Request, Response, NextFunction } from 'express';
import { AuthRequest } from './auth';
import { getClientIp } from '../utils/request';

/**
 * Logs AI endpoint response times and rate limit hits for monitoring.
 */
export const requestLogger = (req: Request, res: Response, next: NextFunction): void => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    const path = req.originalUrl || req.path;
    const userId = (req as AuthRequest).userId || null;

    // Log AI endpoint response times
    if (path.startsWith('/api/v1/ai/')) {
      console.log(
        JSON.stringify({
          type: 'ai_request',
          method: req.method,
          path,
          statusCode: res.statusCode,
          durationMs: duration,
          userId,
          timestamp: new Date().toISOString(),
        })
      );
    }

    // Log rate limit hits (429 responses)
    if (res.statusCode === 429) {
      console.warn(
        JSON.stringify({
          type: 'rate_limit_hit',
          method: req.method,
          path,
          ip: getClientIp(req),
          userId,
          timestamp: new Date().toISOString(),
        })
      );
    }

    // Log slow requests (>3s)
    if (duration > 3000) {
      console.warn(
        JSON.stringify({
          type: 'slow_request',
          method: req.method,
          path,
          statusCode: res.statusCode,
          durationMs: duration,
          timestamp: new Date().toISOString(),
        })
      );
    }
  });

  next();
};
