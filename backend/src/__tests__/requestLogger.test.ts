import { describe, it, expect, vi, beforeEach } from 'vitest';
import { requestLogger } from '../middleware/requestLogger';

describe('requestLogger', () => {
  let consoleSpy: any;
  let warnSpy: any;

  beforeEach(() => {
    consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  function createMocks(path: string, statusCode = 200) {
    const req: any = {
      method: 'POST',
      originalUrl: path,
      path,
      ip: '127.0.0.1',
      socket: { remoteAddress: '127.0.0.1' },
      userId: 'user-1',
    };
    const listeners: Record<string, Function> = {};
    const res: any = {
      statusCode,
      on: (event: string, cb: Function) => { listeners[event] = cb; },
    };
    const next = vi.fn();
    return { req, res, next, fire: () => listeners['finish']?.() };
  }

  it('calls next immediately', () => {
    const { req, res, next } = createMocks('/api/v1/users/me');
    requestLogger(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('logs AI endpoint requests on finish', () => {
    const { req, res, next, fire } = createMocks('/api/v1/ai/analyze-food');
    requestLogger(req, res, next);
    fire();
    expect(consoleSpy).toHaveBeenCalled();
    const logged = JSON.parse(consoleSpy.mock.calls[0][0] as string);
    expect(logged.type).toBe('ai_request');
    expect(logged.path).toBe('/api/v1/ai/analyze-food');
  });

  it('logs rate limit hits (429)', () => {
    const { req, res, next, fire } = createMocks('/api/v1/ai/analyze-food', 429);
    requestLogger(req, res, next);
    fire();
    expect(warnSpy).toHaveBeenCalled();
    const logged = JSON.parse(warnSpy.mock.calls[0][0] as string);
    expect(logged.type).toBe('rate_limit_hit');
  });

  it('does not log non-AI endpoints', () => {
    const { req, res, next, fire } = createMocks('/api/v1/users/me');
    requestLogger(req, res, next);
    fire();
    expect(consoleSpy).not.toHaveBeenCalled();
  });
});
