import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticate);

// GET /recipes/saved — must be before /:id to avoid conflict
router.get('/saved', async (req: AuthRequest, res: Response, next) => {
  try {
    const saved = await prisma.userSavedRecipe.findMany({
      where: { userId: req.userId! },
      include: { recipe: true },
      orderBy: { savedAt: 'desc' },
    });

    res.json(saved.map(s => s.recipe));
  } catch (error) {
    next(error);
  }
});

// GET /recipes/:id
router.get('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const recipe = await prisma.recipe.findUnique({
      where: { id: req.params.id },
    });

    if (!recipe) {
      res.status(404).json({ error: 'Tarif bulunamadı' });
      return;
    }

    // Check if user has saved this recipe
    const saved = await prisma.userSavedRecipe.findUnique({
      where: {
        userId_recipeId: {
          userId: req.userId!,
          recipeId: req.params.id,
        },
      },
    });

    res.json({
      ...recipe,
      isSaved: !!saved,
    });
  } catch (error) {
    next(error);
  }
});

// POST /recipes/:id/save
router.post('/:id/save', async (req: AuthRequest, res: Response, next) => {
  try {
    const existing = await prisma.userSavedRecipe.findUnique({
      where: {
        userId_recipeId: {
          userId: req.userId!,
          recipeId: req.params.id,
        },
      },
    });

    if (existing) {
      res.json({ message: 'Zaten kaydedilmiş' });
      return;
    }

    await prisma.userSavedRecipe.create({
      data: {
        userId: req.userId!,
        recipeId: req.params.id,
      },
    });

    res.status(201).json({ message: 'Tarif kaydedildi' });
  } catch (error) {
    next(error);
  }
});

// DELETE /recipes/:id/save
router.delete('/:id/save', async (req: AuthRequest, res: Response, next) => {
  try {
    await prisma.userSavedRecipe.deleteMany({
      where: {
        userId: req.userId!,
        recipeId: req.params.id,
      },
    });

    res.json({ message: 'Kayıt silindi' });
  } catch (error) {
    next(error);
  }
});

export { router as recipeRouter };
