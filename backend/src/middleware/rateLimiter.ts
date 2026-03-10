import { Request, Response, NextFunction } from 'express';

// Simple in-memory rate limiter (replace with Redis-based in production)
const requestCounts = new Map<string, { count: number; resetTime: number }>();

const WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS = 100;

export const rateLimiter = (req: Request, res: Response, next: NextFunction): void => {
  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  const now = Date.now();

  const entry = requestCounts.get(ip);

  if (!entry || now > entry.resetTime) {
    requestCounts.set(ip, { count: 1, resetTime: now + WINDOW_MS });
    next();
    return;
  }

  if (entry.count >= MAX_REQUESTS) {
    res.status(429).json({ error: 'Çok fazla istek. Lütfen bekleyin.' });
    return;
  }

  entry.count++;
  next();
};

// Stricter rate limiter for AI endpoints
export const aiRateLimiter = (req: Request, res: Response, next: NextFunction): void => {
  const ip = req.ip || req.socket.remoteAddress || 'unknown';
  const key = `ai:${ip}`;
  const now = Date.now();

  const entry = requestCounts.get(key);
  const AI_MAX = 20; // 20 requests per minute

  if (!entry || now > entry.resetTime) {
    requestCounts.set(key, { count: 1, resetTime: now + WINDOW_MS });
    next();
    return;
  }

  if (entry.count >= AI_MAX) {
    res.status(429).json({ error: 'AI istek limiti aşıldı. Lütfen bekleyin.' });
    return;
  }

  entry.count++;
  next();
};
