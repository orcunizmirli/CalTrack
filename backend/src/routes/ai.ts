import { Router, Response } from 'express';
import multer from 'multer';
import { authenticate, AuthRequest } from '../middleware/auth';
import { aiRateLimiter } from '../middleware/rateLimiter';
import { recipeRequestSchema } from '../validators/meal';
import { config } from '../config';
import { AppError } from '../middleware/errorHandler';
import { uploadToS3 } from '../utils/s3';
import { t, getLocale } from '../i18n';
import { prisma } from '../utils/prisma';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.use(authenticate);

// POST /ai/analyze-food
router.post('/analyze-food', aiRateLimiter, upload.single('image'), async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    if (!req.file) {
      throw new AppError(t('ai.photo_required', locale), 400);
    }

    const startTime = Date.now();

    // Forward to AI service with user_id for personalized predictions
    const formData = new FormData();
    const blob = new Blob([req.file.buffer], { type: req.file.mimetype });
    formData.append('image', blob, 'food.jpg');
    if (req.body.meal_type) {
      formData.append('meal_type', req.body.meal_type);
    }
    formData.append('user_id', req.userId!);

    const aiResponse = await fetch(`${config.aiService.url}/ai/analyze-food`, {
      method: 'POST',
      body: formData,
    });

    if (!aiResponse.ok) {
      throw new AppError(t('ai.service_unavailable', locale), 502);
    }

    const result = await aiResponse.json() as Record<string, any>;
    const processingMs = Date.now() - startTime;

    // Upload photo to S3
    let photoUrl = '';
    try {
      const ext = req.file.mimetype === 'image/png' ? 'png' : 'jpg';
      photoUrl = await uploadToS3(req.file.buffer, 'ai-scans', req.file.mimetype, ext);
    } catch (uploadErr) {
      console.error('S3 upload failed, continuing without photo URL:', uploadErr);
    }

    // Save scan record
    const scan = await prisma.aiScan.create({
      data: {
        userId: req.userId!,
        photoUrl,
        rawResponse: result,
        detectedItems: result.items,
        modelUsed: result.model_used || 'gpt-5.2',
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
    const locale = getLocale(req);
    const data = recipeRequestSchema.parse(req.body);

    const aiResponse = await fetch(`${config.aiService.url}/api/v1/generate-recipes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });

    if (!aiResponse.ok) {
      throw new AppError(t('ai.recipe_service_unavailable', locale), 502);
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

// POST /ai/submit-feedback
router.post('/submit-feedback', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const { corrections, scanId } = req.body;

    if (!corrections || !Array.isArray(corrections) || corrections.length === 0) {
      throw new AppError(t('ai.feedback_required', locale), 400);
    }

    const aiResponse = await fetch(`${config.aiService.url}/ai/submit-feedback`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: req.userId,
        scan_id: scanId || null,
        corrections,
      }),
    });

    if (!aiResponse.ok) {
      throw new AppError(t('ai.feedback_service_unavailable', locale), 502);
    }

    const result = await aiResponse.json();
    res.json(result);
  } catch (error) {
    next(error);
  }
});

// POST /ai/recalculate-portions
router.post('/recalculate-portions', async (req: AuthRequest, res: Response, next) => {
  try {
    const locale = getLocale(req);
    const aiResponse = await fetch(`${config.aiService.url}/ai/recalculate-portions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body),
    });

    if (!aiResponse.ok) {
      throw new AppError(t('ai.calculation_service_unavailable', locale), 502);
    }

    const result = await aiResponse.json();
    res.json(result);
  } catch (error) {
    next(error);
  }
});

export { router as aiRouter };
