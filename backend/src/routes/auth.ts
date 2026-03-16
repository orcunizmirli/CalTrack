import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { generateTokens, verifyRefreshToken } from '../middleware/auth';
import { registerSchema, loginSchema, refreshTokenSchema } from '../validators/auth';
import { AppError } from '../middleware/errorHandler';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';
import { getRedisClient } from '../utils/redis';
import { config } from '../config';

const router = Router();

// POST /auth/register
router.post('/register', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const data = registerSchema.parse(req.body);

    const existingUser = await prisma.user.findUnique({ where: { email: data.email } });
    if (existingUser) {
      throw new AppError(t('auth.email_exists', locale), 409);
    }

    const passwordHash = await bcrypt.hash(data.password, 12);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        passwordHash,
        name: data.name,
      },
    });

    const tokens = generateTokens(user.id);

    res.status(201).json({
      user: { id: user.id, email: user.email, name: user.name },
      ...tokens,
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/login
router.post('/login', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const data = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { email: data.email } });
    if (!user || !user.passwordHash) {
      throw new AppError(t('auth.invalid_credentials', locale), 401);
    }

    const isValid = await bcrypt.compare(data.password, user.passwordHash);
    if (!isValid) {
      throw new AppError(t('auth.invalid_credentials', locale), 401);
    }

    const tokens = generateTokens(user.id);

    res.json({
      user: { id: user.id, email: user.email, name: user.name },
      ...tokens,
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/apple
router.post('/apple', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    // TODO: Verify Apple identity token with Apple's servers
    const { identityToken, fullName, email } = req.body;

    // For now, decode the JWT payload (in production, verify with Apple)
    const payload = JSON.parse(
      Buffer.from(identityToken.split('.')[1], 'base64').toString()
    );
    const appleId = payload.sub;

    let user = await prisma.user.findUnique({ where: { appleId } });

    if (!user) {
      user = await prisma.user.create({
        data: {
          appleId,
          email: email || `${appleId}@privaterelay.appleid.com`,
          name: fullName
            ? `${fullName.givenName || ''} ${fullName.familyName || ''}`.trim()
            : t('auth.default_name', locale),
        },
      });
    }

    const tokens = generateTokens(user.id);

    res.json({
      user: { id: user.id, email: user.email, name: user.name },
      ...tokens,
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/google
router.post('/google', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { idToken } = req.body;

    if (!idToken) {
      throw new AppError(t('auth.google_token_required', locale), 400);
    }

    // Verify Google ID token via Google's tokeninfo endpoint
    const googleResponse = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
    );

    if (!googleResponse.ok) {
      throw new AppError(t('auth.invalid_google_token', locale), 401);
    }

    const payload = await googleResponse.json() as Record<string, any>;
    const googleId = payload.sub;
    const email = payload.email;
    const name = payload.name || payload.given_name || t('auth.default_name', locale);

    if (!googleId) {
      throw new AppError(t('auth.google_id_failed', locale), 401);
    }

    // Find or create user
    let user = await prisma.user.findUnique({ where: { googleId } });

    if (!user && email) {
      // Check if email already exists (user might have registered with email)
      user = await prisma.user.findUnique({ where: { email } });
      if (user) {
        // Link Google ID to existing account
        user = await prisma.user.update({
          where: { id: user.id },
          data: { googleId },
        });
      }
    }

    if (!user) {
      user = await prisma.user.create({
        data: {
          googleId,
          email,
          name,
        },
      });
    }

    const tokens = generateTokens(user.id);

    res.json({
      user: { id: user.id, email: user.email, name: user.name },
      ...tokens,
    });
  } catch (error) {
    next(error);
  }
});

// POST /auth/refresh
router.post('/refresh', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { refreshToken } = refreshTokenSchema.parse(req.body);

    // Check if token is blacklisted
    const redis = await getRedisClient();
    if (redis) {
      const isBlacklisted = await redis.get(`bl:${refreshToken}`);
      if (isBlacklisted) {
        throw new AppError(t('auth.invalid_refresh_token', locale), 401);
      }
    }

    const userId = verifyRefreshToken(refreshToken);

    if (!userId) {
      throw new AppError(t('auth.invalid_refresh_token', locale), 401);
    }

    const tokens = generateTokens(userId);
    res.json(tokens);
  } catch (error) {
    next(error);
  }
});

// POST /auth/logout
router.post('/logout', async (req: Request, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { refreshToken } = req.body;

    // Blacklist the refresh token in Redis if provided
    if (refreshToken) {
      const redis = await getRedisClient();
      if (redis) {
        // Parse token to get expiry, then set TTL accordingly
        const ttlSeconds = parseTTLFromConfig(config.jwt.refreshExpiresIn);
        await redis.set(`bl:${refreshToken}`, '1', { EX: ttlSeconds });
      }
    }

    res.json({ message: t('auth.logout_success', locale) });
  } catch (error) {
    next(error);
  }
});

function parseTTLFromConfig(expiresIn: string): number {
  const match = expiresIn.match(/^(\d+)([smhd])$/);
  if (!match) return 7 * 24 * 3600; // default 7 days
  const value = parseInt(match[1]);
  switch (match[2]) {
    case 's': return value;
    case 'm': return value * 60;
    case 'h': return value * 3600;
    case 'd': return value * 86400;
    default: return 7 * 86400;
  }
}

export { router as authRouter };
