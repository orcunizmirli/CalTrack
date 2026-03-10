import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import multer from 'multer';
import { authenticate, AuthRequest } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';
import { recipeRequestSchema } from '../validators/meal';
import { config } from '../config';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.use(authenticate);

// POST /ai/analyze-food
router.post('/analyze-food', aiRateLimiter, upload.single('image'), async (req: AuthRequest, res: Response, next) => {
  try {
    if (!req.file) {
      throw new AppError('Fotoğraf gerekli', 400);
    }

    const startTime = Date.now();

    // Forward to AI service
    const formData = new FormData();
    const blob = new Blob([req.file.buffer], { type: req.file.mimetype });
    formData.append('image', blob, 'food.jpg');
    if (req.body.meal_type) {
      formData.append('meal_type', req.body.meal_type);
    }

    const aiResponse = await fetch(`${config.aiService.url}/api/v1/analyze`, {
      method: 'POST',
      body: formData,
    });

    if (!aiResponse.ok) {
      throw new AppError('AI analiz servisi yanıt vermedi', 502);
    }

    const result = await aiResponse.json() as Record<string, any>;
    const processingMs = Date.now() - startTime;

    // Save scan record
    const scan = await prisma.aiScan.create({
      data: {
        userId: req.userId!,
        photoUrl: '', // TODO: Upload to S3
        rawResponse: result,
        detectedItems: result.items,
        modelUsed: result.model_used || 'gpt-4o',
        confidence: result.confidence,
        processingMs,
      },
    });

    res.json({
      ...result,
      scanId: scan.id,
      processingMs,
    });
  } catch (error) {
    next(error);
  }
});

// POST /ai/generate-recipes
router.post('/generate-recipes', aiRateLimiter, async (req: AuthRequest, res: Response, next) => {
  try {
    const data = recipeRequestSchema.parse(req.body);

    const aiResponse = await fetch(`${config.aiService.url}/api/v1/generate-recipes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });

    if (!aiResponse.ok) {
      throw new AppError('Tarif oluşturma servisi yanıt vermedi', 502);
    }

    const recipes = await aiResponse.json() as Record<string, any>[];

    // Save recipes to DB
    for (const recipe of recipes) {
      await prisma.recipe.create({
        data: {
          title: recipe.title,
          description: recipe.description,
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          prepTimeMin: recipe.prep_time_min,
          cookTimeMin: recipe.cook_time_min,
          servings: recipe.servings,
          calories: recipe.calories,
          proteinG: recipe.protein_g,
          carbsG: recipe.carbs_g,
          fatG: recipe.fat_g,
          tags: recipe.tags || [],
          aiGenerated: true,
        },
      });
    }

    res.json(recipes);
  } catch (error) {
    next(error);
  }
});

export { router as aiRouter };
