import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock redis before importing rateLimiter
vi.mock('../utils/redis', () => ({
  getRedisClient: vi.fn().mockResolvedValue(null),
  isRedisConnected: vi.fn().mockReturnValue(false),
}));

import { initRateLimiters, rateLimiter, aiRateLimiter } from '../middleware/rateLimiter';

function mockReq(overrides: Record<string, any> = {}) {
  return {
    ip: '127.0.0.1',
    socket: { remoteAddress: '127.0.0.1' },
    query: {},
    headers: {},
    ...overrides,
  } as any;
}

function mockRes() {
  const res: any = {
    statusCode: 200,
    status: vi.fn().mockReturnThis(),
    json: vi.fn().mockReturnThis(),
  };
  return res;
}

describe('rateLimiter', () => {
  beforeEach(async () => {
    // Re-init with in-memory fallback (no Redis)
    await initRateLimiters();
  });

  it('allows requests under the limit', async () => {
    const req = mockReq();
    const res = mockRes();
    const next = vi.fn();

    await rateLimiter(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('initializes without Redis (in-memory fallback)', async () => {
    // Should not throw
    await expect(initRateLimiters()).resolves.toBeUndefined();
  });
});

describe('aiRateLimiter', () => {
  beforeEach(async () => {
    await initRateLimiters();
  });

  it('allows AI requests under the limit', async () => {
    const req = mockReq({ userId: 'user-123' });
    const res = mockRes();
    const next = vi.fn();

    await aiRateLimiter(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('works without userId (unauthenticated)', async () => {
    const req = mockReq();
    const res = mockRes();
    const next = vi.fn();

    await aiRateLimiter(req, res, next);
    expect(next).toHaveBeenCalled();
  });
});
