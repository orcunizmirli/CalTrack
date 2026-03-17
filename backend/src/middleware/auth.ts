import { Request, Response, NextFunction } from 'express';
import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '../config';
import { t, getLocale } from '../i18n';

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
  const locale = getLocale(req);

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: t('auth.required', locale) });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret) as JWTPayload;
    req.userId = decoded.userId;
    next();
  } catch {
    res.status(401).json({ error: t('auth.invalid_token', locale) });
  }
};

export const generateTokens = (userId: string) => {
  const accessToken = jwt.sign(
    { userId },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn } as SignOptions
  );

  const refreshToken = jwt.sign(
    { userId },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiresIn } as SignOptions
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
