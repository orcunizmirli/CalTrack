import { describe, it, expect } from 'vitest';
import { getRegisterSchema, getLoginSchema } from '../validators/auth';
import { getUpdateProfileSchema, updateGoalsSchema } from '../validators/user';

describe('auth validators', () => {
  describe('getRegisterSchema', () => {
    it('validates valid registration data', () => {
      const schema = getRegisterSchema('en');
      const result = schema.safeParse({
        email: 'test@example.com',
        password: '12345678',
        name: 'John',
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid email', () => {
      const schema = getRegisterSchema('en');
      const result = schema.safeParse({
        email: 'invalid',
        password: '12345678',
        name: 'John',
      });
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors[0].message).toBe('Please enter a valid email');
      }
    });

    it('rejects short password', () => {
      const schema = getRegisterSchema('en');
      const result = schema.safeParse({
        email: 'test@example.com',
        password: '123',
        name: 'John',
      });
      expect(result.success).toBe(false);
    });

    it('returns Turkish error messages by default', () => {
      const schema = getRegisterSchema('tr');
      const result = schema.safeParse({
        email: 'invalid',
        password: '12345678',
        name: 'John',
      });
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors[0].message).toBe('Geçerli bir email giriniz');
      }
    });
  });

  describe('getLoginSchema', () => {
    it('validates valid login data', () => {
      const schema = getLoginSchema('en');
      const result = schema.safeParse({
        email: 'test@example.com',
        password: 'mypassword',
      });
      expect(result.success).toBe(true);
    });

    it('rejects empty password', () => {
      const schema = getLoginSchema('en');
      const result = schema.safeParse({
        email: 'test@example.com',
        password: '',
      });
      expect(result.success).toBe(false);
    });
  });
});

describe('user validators', () => {
  describe('getUpdateProfileSchema', () => {
    it('validates partial profile update', () => {
      const schema = getUpdateProfileSchema('en');
      const result = schema.safeParse({ name: 'Jane' });
      expect(result.success).toBe(true);
    });

    it('validates empty object (all optional)', () => {
      const schema = getUpdateProfileSchema('en');
      const result = schema.safeParse({});
      expect(result.success).toBe(true);
    });

    it('rejects invalid gender', () => {
      const schema = getUpdateProfileSchema('en');
      const result = schema.safeParse({ gender: 'other' });
      expect(result.success).toBe(false);
    });

    it('rejects height out of range', () => {
      const schema = getUpdateProfileSchema('en');
      const result = schema.safeParse({ heightCm: 10 });
      expect(result.success).toBe(false);
    });
  });

  describe('updateGoalsSchema', () => {
    it('validates valid goals', () => {
      const result = updateGoalsSchema.safeParse({
        goalType: 'lose_weight',
        dailyCalories: 2000,
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid goalType', () => {
      const result = updateGoalsSchema.safeParse({
        goalType: 'fly',
        dailyCalories: 2000,
      });
      expect(result.success).toBe(false);
    });

    it('rejects calories below minimum', () => {
      const result = updateGoalsSchema.safeParse({
        goalType: 'maintain',
        dailyCalories: 100,
      });
      expect(result.success).toBe(false);
    });
  });
});
