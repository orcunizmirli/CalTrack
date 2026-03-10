import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { generateTokens, verifyRefreshToken } from '../middleware/auth';
import { registerSchema, loginSchema, refreshTokenSchema } from '../validators/auth';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

// POST /auth/register
router.post('/register', async (req: Request, res: Response, next) => {
  try {
    const data = registerSchema.parse(req.body);

    const existingUser = await prisma.user.findUnique({ where: { email: data.email } });
    if (existingUser) {
      throw new AppError('Bu email zaten kayıtlı', 409);
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
    const data = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { email: data.email } });
    if (!user || !user.passwordHash) {
      throw new AppError('Geçersiz email veya şifre', 401);
    }

    const isValid = await bcrypt.compare(data.password, user.passwordHash);
    if (!isValid) {
      throw new AppError('Geçersiz email veya şifre', 401);
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
            : 'Kullanıcı',
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
    const { refreshToken } = refreshTokenSchema.parse(req.body);
    const userId = verifyRefreshToken(refreshToken);

    if (!userId) {
      throw new AppError('Geçersiz refresh token', 401);
    }

    const tokens = generateTokens(userId);
    res.json(tokens);
  } catch (error) {
    next(error);
  }
});

// POST /auth/logout
router.post('/logout', (_req: Request, res: Response) => {
  // In a more complete implementation, invalidate the refresh token in Redis
  res.json({ message: 'Çıkış yapıldı' });
});

export { router as authRouter };
