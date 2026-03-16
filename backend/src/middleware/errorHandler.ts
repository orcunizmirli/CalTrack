import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { t, getLocale } from '../i18n';

export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Zod validation errors
  if (err instanceof ZodError) {
    res.status(400).json({
      error: err.errors[0]?.message || 'Validation error',
      statusCode: 400,
      details: err.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: err.message,
      statusCode: err.statusCode,
    });
    return;
  }

  console.error('Unexpected error:', err);

  const locale = getLocale(req);
  res.status(500).json({
    error: t('error.server_error', locale),
    statusCode: 500,
  });
};
