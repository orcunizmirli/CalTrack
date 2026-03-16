export type Locale = 'tr' | 'en';

const translations: Record<string, Record<Locale, string>> = {
  // Rate limiter
  'rate_limit.too_many_requests': {
    tr: 'Çok fazla istek. Lütfen bekleyin.',
    en: 'Too many requests. Please wait.',
  },
  'rate_limit.ai_limit_exceeded': {
    tr: 'AI istek limiti aşıldı. Lütfen bekleyin.',
    en: 'AI request limit exceeded. Please wait.',
  },

  // Error handler
  'error.server_error': {
    tr: 'Sunucu hatası',
    en: 'Server error',
  },

  // Auth middleware
  'auth.required': {
    tr: 'Yetkilendirme gerekli',
    en: 'Authorization required',
  },
  'auth.invalid_token': {
    tr: 'Geçersiz veya süresi dolmuş token',
    en: 'Invalid or expired token',
  },

  // Auth routes
  'auth.email_exists': {
    tr: 'Bu email zaten kayıtlı',
    en: 'This email is already registered',
  },
  'auth.invalid_credentials': {
    tr: 'Geçersiz email veya şifre',
    en: 'Invalid email or password',
  },
  'auth.google_token_required': {
    tr: 'Google ID token gerekli',
    en: 'Google ID token required',
  },
  'auth.invalid_google_token': {
    tr: 'Geçersiz Google token',
    en: 'Invalid Google token',
  },
  'auth.google_id_failed': {
    tr: 'Google kimliği alınamadı',
    en: 'Failed to retrieve Google identity',
  },
  'auth.invalid_refresh_token': {
    tr: 'Geçersiz refresh token',
    en: 'Invalid refresh token',
  },
  'auth.logout_success': {
    tr: 'Çıkış yapıldı',
    en: 'Logged out successfully',
  },
  'auth.default_name': {
    tr: 'Kullanıcı',
    en: 'User',
  },

  // Validators
  'validation.email_invalid': {
    tr: 'Geçerli bir email giriniz',
    en: 'Please enter a valid email',
  },
  'validation.password_min': {
    tr: 'Şifre en az 8 karakter olmalı',
    en: 'Password must be at least 8 characters',
  },
  'validation.name_required': {
    tr: 'İsim gerekli',
    en: 'Name is required',
  },
  'validation.password_required': {
    tr: 'Şifre gerekli',
    en: 'Password is required',
  },

  // User routes
  'user.not_found': {
    tr: 'Kullanıcı bulunamadı',
    en: 'User not found',
  },
  'user.profile_incomplete': {
    tr: 'Profil bilgilerinizi (boy, kilo, cinsiyet, doğum tarihi) doldurun',
    en: 'Please complete your profile (height, weight, gender, date of birth)',
  },
  'user.account_deleted': {
    tr: 'Hesap silindi',
    en: 'Account deleted',
  },

  // Meal routes
  'meal.not_found': {
    tr: 'Öğün bulunamadı',
    en: 'Meal not found',
  },
  'meal.deleted': {
    tr: 'Öğün silindi',
    en: 'Meal deleted',
  },

  // AI routes
  'ai.photo_required': {
    tr: 'Fotoğraf gerekli',
    en: 'Photo is required',
  },
  'ai.service_unavailable': {
    tr: 'AI analiz servisi yanıt vermedi',
    en: 'AI analysis service is not responding',
  },
  'ai.recipe_service_unavailable': {
    tr: 'Tarif oluşturma servisi yanıt vermedi',
    en: 'Recipe generation service is not responding',
  },
  'ai.feedback_required': {
    tr: 'Düzeltme verisi gerekli',
    en: 'Correction data is required',
  },
  'ai.feedback_service_unavailable': {
    tr: 'Feedback servisi yanıt vermedi',
    en: 'Feedback service is not responding',
  },
  'ai.calculation_service_unavailable': {
    tr: 'Hesaplama servisi yanıt vermedi',
    en: 'Calculation service is not responding',
  },
  'ai.invalid_mimetype': {
    tr: 'Yalnızca JPEG, PNG ve HEIC görselleri desteklenir',
    en: 'Only JPEG, PNG, and HEIC images are allowed',
  },

  // Food routes
  'food.product_not_found': {
    tr: 'Ürün bulunamadı',
    en: 'Product not found',
  },
  'food.not_found': {
    tr: 'Yemek bulunamadı',
    en: 'Food not found',
  },

  // Weight routes
  'weight.not_found': {
    tr: 'Kayıt bulunamadı',
    en: 'Record not found',
  },
  'weight.deleted': {
    tr: 'Silindi',
    en: 'Deleted',
  },

  // Water routes
  'water.deleted': {
    tr: 'Silindi',
    en: 'Deleted',
  },

  // Recipe routes
  'recipe.not_found': {
    tr: 'Tarif bulunamadı',
    en: 'Recipe not found',
  },
  'recipe.already_saved': {
    tr: 'Zaten kaydedilmiş',
    en: 'Already saved',
  },
  'recipe.saved': {
    tr: 'Tarif kaydedildi',
    en: 'Recipe saved',
  },
  'recipe.unsaved': {
    tr: 'Kayıt silindi',
    en: 'Recipe removed from saved',
  },

  // Subscription routes
  'subscription.receipt_required': {
    tr: 'Receipt verisi gerekli',
    en: 'Receipt data is required',
  },
  'subscription.invalid_receipt': {
    tr: 'Geçersiz receipt. Abonelik doğrulanamadı.',
    en: 'Invalid receipt. Subscription could not be verified.',
  },
  'subscription.info_not_found': {
    tr: 'Abonelik bilgisi bulunamadı',
    en: 'Subscription information not found',
  },

  // Health sync
  'health_sync.start_date_required': {
    tr: 'startDate gerekli',
    en: 'startDate is required',
  },

  // Sync
  'sync.invalid_data': {
    tr: 'Geçersiz sync verisi',
    en: 'Invalid sync data',
  },
};

export default translations;
