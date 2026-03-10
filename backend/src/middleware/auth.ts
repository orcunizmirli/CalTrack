import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';

export interface AuthRequest extends Request {
  userId?: string;
}

interface JWTPayload {
  userId: string;
  iat: number;
  exp: number;
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Yetkilendirme gerekli' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret) as JWTPayload;
    req.userId = decoded.userId;
    next();
  } catch {
    res.status(401).json({ error: 'Geçersiz veya süresi dolmuş token' });
  }
};

export const generateTokens = (userId: string) => {
  const accessToken = jwt.sign(
    { userId },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );

  const refreshToken = jwt.sign(
    { userId },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiresIn }
  );

  return { accessToken, refreshToken };
};

export const verifyRefreshToken = (token: string): string | null => {
  try {
    const decoded = jwt.verify(token, config.jwt.refreshSecret) as JWTPayload;
    return decoded.userId;
  } catch {
    return null;
  }
};
