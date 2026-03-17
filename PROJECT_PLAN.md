# Forkcast - Proje Planı & Yazılım Mimarisi

## 1. Proje Genel Bakış

**Forkcast**, kullanıcıların günlük kalori ve besin takibini yapabildiği, yapay zeka destekli fotoğraf ile yemek tanıma özelliğine sahip, Apple Health entegrasyonlu bir iOS uygulamasıdır.

### 1.1 Hedef Kitle
- Kilo vermek, kas kazanmak veya sağlıklı beslenmek isteyen bireyler
- Fitness meraklıları ve sporcular
- Diyetisyen takibinde olan kişiler

### 1.2 Temel Değer Önerisi
- **Fotoğraf ile AI destekli kalori tespiti** (ana güç)
- Kapsamlı besin veritabanı ile manuel giriş
- Apple Health entegrasyonu ile otomatik veri senkronizasyonu
- Akıllı hedef belirleme ve makro/mikro besin takibi
- AI destekli kişiselleştirilmiş yemek tarifi önerisi

---

## 2. Özellik Kapsamı (Feature Scope)

### 2.1 Onboarding & Kullanıcı Profili
- **Kayıt/Giriş**: Email + şifre, Apple Sign-In, Google Sign-In
- **Profil Oluşturma**:
  - Boy, kilo, yaş, cinsiyet
  - Aktivite seviyesi (sedanter, hafif aktif, orta aktif, çok aktif, ekstra aktif)
  - Vücut yağ oranı (manuel giriş VEYA tahmini hesaplama - US Navy Method, BMI tabanlı)
  - Apple Health'ten otomatik veri çekme seçeneği (boy, kilo, yaş, adım sayısı, antrenman verileri)
- **Hedef Belirleme**:
  - Ana hedef: Kilo vermek, kas kazanmak, yağ yakmak, kilo korumak
  - Haftalık hedef değişim hızı (0.25kg, 0.5kg, 0.75kg, 1kg/hafta)
  - Hedef kilo
- **Günlük Kalori İhtiyacı Hesaplama**:
  - BMR hesaplama: Mifflin-St Jeor, Harris-Benedict, Katch-McArdle (yağ oranı biliniyorsa)
  - TDEE = BMR × Aktivite Çarpanı
  - Apple Health'ten gelen günlük adım ve antrenman verileriyle dinamik kalori ayarı
  - Hedef doğrultusunda kalori açığı/fazlası hesabı

### 2.2 Günlük Kalori & Besin Takibi (Dashboard)
- **Ana Ekran (Dashboard)**:
  - Günlük kalan kalori (büyük, merkezi gösterge - circular progress)
  - Makro besin dağılımı çubukları (protein, karbonhidrat, yağ)
  - Öğün listesi (Kahvaltı, Öğle, Akşam, Ara Öğün)
  - Günlük su tüketimi takibi
  - Yakılan kalori (Apple Health'ten)

### 2.3 Yemek Girişi - AI Fotoğraf Tarama
- **Fotoğraf Çekme/Seçme**: Kamera veya galeri
- **AI Analizi**:
  - Yemeği tanımlama (birden fazla bileşen)
  - Her bileşen için tahmini porsiyon ve kalori
  - Makro besin değerleri (protein, karb, yağ)
  - Mikro besin değerleri (vitaminler, mineraller)
- **Düzenleme Ekranı**:
  - AI sonuçlarını onaylama/düzenleme
  - Porsiyon miktarı değiştirme
  - Bileşen ekleme/çıkarma
  - Besin değerlerini manuel düzenleme
- **İşlem Süresi**: <3 saniye hedef

### 2.4 Yemek Girişi - Manuel
- **Arama**: Kapsamlı besin veritabanında arama (Türkçe ve İngilizce)
- **Barkod Tarama**: Paketli ürünler için barkod okuyucu
- **Veritabanı Kaynakları**:
  - USDA FoodData Central API
  - Open Food Facts (barkodlu ürünler)
  - Türk gıda veritabanı (TurKomp / özel)
  - Kullanıcı tarafından eklenen özel yiyecekler
- **Hızlı Giriş**: Son yenenler, sık yenenler, favoriler
- **Tarif Oluşturma**: Birden fazla malzemeyi birleştirip tarif olarak kaydetme

### 2.5 Hedef & Makro/Mikro Besin Yönetimi
- **Makro Hedefleri**:
  - Protein (gram), Karbonhidrat (gram), Yağ (gram) hedefi girişi
  - Otomatik hesaplama: Protein ve yağ girilince kalan kaloriyi karbonhidrata bölme
  - Görsel gösterge: Her makronun günlük hedefe oranı (progress bar)
  - Makro dağılım pasta grafiği
- **Mikro Besin Takibi**:
  - Vitaminler: A, B1, B2, B3, B5, B6, B7, B9, B12, C, D, E, K
  - Mineraller: Kalsiyum, Demir, Magnezyum, Potasyum, Çinko, Sodyum, Fosfor
  - Günlük önerilen değerlere (RDA) göre yüzdesel gösterim
  - Eksik/fazla besinler için uyarı

### 2.6 AI Destekli Yemek Tarifi Önerisi
- **Tarif İsteme Akışı**:
  - Kullanıcı kalan makro/kalori hedefini görür
  - Öğün tipi seçer (kahvaltı, öğle, akşam, ara öğün)
  - İstediği ana malzemeleri seçebilir (ör: tavuk göğsü, pirinç)
  - Hedef kalori aralığı belirler
  - Diyet kısıtlamaları (gluten-free, vegan, laktoz-free vb.)
- **AI Tarif Üretimi**:
  - Birden fazla tarif önerisi (3-5 adet)
  - Her tarif için: malzeme listesi, porsiyon, hazırlama süresi
  - Adım adım yapılış tarifi
  - Detaylı besin değerleri (makro + mikro)
  - Fotoğraflı görsel (AI-generated veya stok)
- **Tarif Kaydetme**: Favorilere ekleme, tarif defteri

### 2.7 Apple Health Entegrasyonu
- **Okunan Veriler**:
  - Boy, kilo, yaş, cinsiyet
  - Günlük adım sayısı
  - Aktif enerji yakımı
  - Egzersiz/antrenman verileri
  - Kalp atış hızı (ortalama)
- **Yazılan Veriler**:
  - Günlük kalori alımı
  - Makro besin değerleri
  - Su tüketimi
- **Dinamik Kalori Ayarı**: Günlük aktiviteye göre kalori hedefini otomatik güncelleme

### 2.8 Analitik & İlerleme
- **Günlük/Haftalık/Aylık Grafikler**:
  - Kalori alımı vs hedef
  - Makro besin trendleri
  - Kilo değişim grafiği
- **BMI Takibi**
- **Streak (Gün Serisi)**: Ardışık gün takibi, motivasyon rozeti
- **İlerleme Fotoğrafları**: Vücut fotoğrafı karşılaştırma (opsiyonel)

### 2.9 Ayarlar & Profil
- Profil düzenleme
- Bildirim tercihleri (öğün hatırlatma)
- Birim sistemi (metrik/imperial)
- Dil desteği (Türkçe, İngilizce)
- Gizlilik & veri yönetimi
- Abonelik yönetimi

---

## 3. Teknik Mimari

### 3.1 Genel Mimari Diyagramı

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │Onboarding│ │Dashboard │ │ AI Scan  │ │ Recipes  │   ...    │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              Local Storage (SwiftData)                │      │
│  └──────────────────────────────────────────────────────┘      │
│  ┌──────────────────┐  ┌────────────────────────────┐          │
│  │  HealthKit SDK   │  │    Network Layer (REST)     │          │
│  └──────────────────┘  └────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS / REST API
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API Gateway (Nginx)                           │
│                    Rate Limiting / Auth                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│   Main API (Node.js)     │  │   AI Service (Python)    │
│   Express + TypeScript   │  │   FastAPI                │
│                          │  │                          │
│  - Auth & User Mgmt      │  │  - Food Photo Analysis   │
│  - Food Database CRUD    │  │  - Recipe Generation     │
│  - Meal Logging          │  │  - Nutrition Estimation  │
│  - Goal Management       │  │  - Barcode Lookup        │
│  - Analytics             │  │                          │
│  - Subscription Mgmt     │  │  ┌────────────────────┐  │
│                          │  │  │ OpenAI GPT-4 Vision│  │
│  ┌────────────────────┐  │  │  │ Claude (Anthropic) │  │
│  │   PostgreSQL DB    │  │  │  │ (multi-model RAG)  │  │
│  └────────────────────┘  │  │  └────────────────────┘  │
│  ┌────────────────────┐  │  │  ┌────────────────────┐  │
│  │   Redis Cache      │  │  │  │ Food Vector DB     │  │
│  └────────────────────┘  │  │  │ (Pinecone/pgvector)│  │
│                          │  │  └────────────────────┘  │
└──────────────────────────┘  └──────────────────────────┘
                    │                    │
                    └─────────┬──────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Cloud Storage (AWS S3)                        │
│              Food Images / User Photos / Receipts               │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 iOS App (Frontend)

#### Teknoloji Seçimi
| Katman | Teknoloji | Gerekçe |
|--------|-----------|---------|
| UI Framework | **SwiftUI** | Modern, deklaratif, iOS native performans |
| Mimari | **MVVM + Clean Architecture** | Test edilebilirlik, separation of concerns |
| Networking | **URLSession + async/await** | Native, lightweight, modern Swift concurrency |
| Local DB | **SwiftData** | Apple'ın modern persistence framework'ü |
| DI | **Swift Package (manual DI)** | Lightweight, framework bağımsız |
| Image | **Kingfisher** | Resim cache ve yükleme |
| Charts | **Swift Charts** | Native Apple charting |
| Camera | **AVFoundation** | Kamera erişimi |
| Barcode | **AVFoundation / Vision** | Native barkod okuma |
| Health | **HealthKit** | Apple Health entegrasyonu |
| Auth | **AuthenticationServices** | Apple Sign-In |
| Payments | **StoreKit 2** | In-app subscription |

#### Proje Yapısı (iOS)
```
Forkcast/
├── ForkcastApp.swift                  # App entry point
├── Info.plist
├── Assets.xcassets/
├── Core/
│   ├── DI/
│   │   └── DependencyContainer.swift
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── APIEndpoints.swift
│   │   ├── APIError.swift
│   │   └── AuthInterceptor.swift
│   ├── Storage/
│   │   ├── SwiftDataManager.swift
│   │   └── UserDefaultsManager.swift
│   ├── HealthKit/
│   │   ├── HealthKitManager.swift
│   │   └── HealthKitModels.swift
│   ├── Camera/
│   │   ├── CameraManager.swift
│   │   └── BarcodeScanner.swift
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Double+Extensions.swift
│   │   └── Color+Theme.swift
│   └── Utils/
│       ├── CalorieCalculator.swift     # BMR, TDEE hesaplamaları
│       ├── MacroCalculator.swift
│       └── BodyFatEstimator.swift      # Navy Method, BMI-based
├── Models/
│   ├── User.swift
│   ├── FoodItem.swift
│   ├── MealEntry.swift
│   ├── DailyLog.swift
│   ├── NutritionInfo.swift
│   ├── MacroGoal.swift
│   ├── MicroNutrient.swift
│   ├── Recipe.swift
│   └── UserGoal.swift
├── Features/
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── PersonalInfoView.swift
│   │   │   ├── BodyMetricsView.swift
│   │   │   ├── ActivityLevelView.swift
│   │   │   ├── GoalSelectionView.swift
│   │   │   ├── MacroSetupView.swift
│   │   │   ├── PlanSummaryView.swift
│   │   │   └── PaywallView.swift
│   │   └── ViewModels/
│   │       └── OnboardingViewModel.swift
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   ├── CalorieRingView.swift
│   │   │   ├── MacroProgressView.swift
│   │   │   ├── MealSectionView.swift
│   │   │   └── WaterTrackerView.swift
│   │   └── ViewModels/
│   │       └── DashboardViewModel.swift
│   ├── FoodLogging/
│   │   ├── Views/
│   │   │   ├── AddFoodView.swift
│   │   │   ├── FoodSearchView.swift
│   │   │   ├── BarcodeScanView.swift
│   │   │   ├── AIFoodScanView.swift
│   │   │   ├── FoodResultView.swift
│   │   │   ├── FoodEditView.swift
│   │   │   └── QuickAddView.swift
│   │   └── ViewModels/
│   │       ├── FoodSearchViewModel.swift
│   │       └── AIFoodScanViewModel.swift
│   ├── Goals/
│   │   ├── Views/
│   │   │   ├── GoalsOverviewView.swift
│   │   │   ├── MacroGoalEditView.swift
│   │   │   ├── MicroNutrientView.swift
│   │   │   └── CalorieGoalView.swift
│   │   └── ViewModels/
│   │       └── GoalsViewModel.swift
│   ├── Recipes/
│   │   ├── Views/
│   │   │   ├── RecipeRequestView.swift
│   │   │   ├── RecipeListView.swift
│   │   │   ├── RecipeDetailView.swift
│   │   │   └── RecipeBookView.swift
│   │   └── ViewModels/
│   │       └── RecipeViewModel.swift
│   ├── Analytics/
│   │   ├── Views/
│   │   │   ├── AnalyticsView.swift
│   │   │   ├── CalorieChartView.swift
│   │   │   ├── MacroTrendView.swift
│   │   │   ├── WeightChartView.swift
│   │   │   └── StreakView.swift
│   │   └── ViewModels/
│   │       └── AnalyticsViewModel.swift
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   ├── ProfileEditView.swift
│       │   ├── NotificationSettingsView.swift
│       │   └── SubscriptionView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
├── Services/
│   ├── AuthService.swift
│   ├── FoodService.swift
│   ├── MealService.swift
│   ├── AIAnalysisService.swift
│   ├── RecipeService.swift
│   ├── AnalyticsService.swift
│   └── SubscriptionService.swift
└── Resources/
    ├── Localizable.strings          # TR & EN
    └── Theme.swift
```

#### Ekran Akışı (Navigation)
```
App Launch
    │
    ├── [İlk Açılış] → Onboarding Flow
    │   ├── Welcome
    │   ├── Apple Sign-In / Email Kayıt
    │   ├── Kişisel Bilgiler (boy, kilo, yaş, cinsiyet)
    │   ├── Apple Health İzni
    │   ├── Vücut Yağ Oranı (tahmini / manuel)
    │   ├── Aktivite Seviyesi
    │   ├── Hedef Seçimi (kilo ver, kas kazan, yağ yak, koru)
    │   ├── Makro Hedef Ayarı
    │   ├── Plan Özeti ("Günlük 2150 kcal - Gerçekçi Hedef!")
    │   └── Paywall (3 gün ücretsiz deneme)
    │
    └── [Mevcut Kullanıcı] → Tab Bar Navigation
        ├── 🏠 Dashboard (Ana Sayfa)
        │   ├── Kalori Halkası
        │   ├── Makro Progress Barları
        │   ├── Öğün Listesi
        │   └── Su Takibi
        │
        ├── 🔍 Arama / Keşfet
        │   ├── Yemek Arama
        │   ├── Barkod Tarama
        │   └── Popüler Yemekler
        │
        ├── 📸 AI Tarama (Merkez Buton - FAB)
        │   ├── Kamera
        │   ├── Galeri
        │   ├── AI Analiz Sonucu
        │   └── Düzenleme & Kaydet
        │
        ├── 📊 Analitik
        │   ├── Kalori Grafikleri
        │   ├── Makro Trendleri
        │   ├── Kilo Grafiği
        │   └── Streak / Başarılar
        │
        └── 👤 Profil / Ayarlar
            ├── Profil Düzenle
            ├── Hedefler
            ├── Mikro Besinler
            ├── Tarif Defteri
            ├── Bildirimler
            └── Abonelik
```

### 3.3 Backend - Main API (Node.js)

#### Teknoloji Seçimi
| Katman | Teknoloji | Gerekçe |
|--------|-----------|---------|
| Runtime | **Node.js 20 LTS** | Performans, ekosistem |
| Framework | **Express.js + TypeScript** | Hafif, esnek, type-safe |
| ORM | **Prisma** | Type-safe, migration support |
| Database | **PostgreSQL 16** | Güvenilir, JSON desteği, pgvector |
| Cache | **Redis** | Session, rate limiting, food cache |
| Auth | **JWT + Refresh Token** | Stateless, güvenli |
| Validation | **Zod** | Runtime type validation |
| API Docs | **Swagger/OpenAPI** | Otomatik API dokümantasyonu |
| Testing | **Vitest** | Hızlı, TypeScript native |
| File Storage | **AWS S3** | Ölçeklenebilir dosya depolama |
| Queue | **BullMQ** | Background job processing |

#### API Endpoint Yapısı
```
/api/v1/
├── /auth
│   ├── POST   /register              # Email ile kayıt
│   ├── POST   /login                 # Email ile giriş
│   ├── POST   /apple                 # Apple Sign-In
│   ├── POST   /google                # Google Sign-In
│   ├── POST   /refresh               # Token yenileme
│   └── POST   /logout                # Çıkış
│
├── /users
│   ├── GET    /me                    # Profil bilgisi
│   ├── PUT    /me                    # Profil güncelle
│   ├── PUT    /me/goals              # Hedef güncelle
│   ├── PUT    /me/macros             # Makro hedef güncelle
│   ├── GET    /me/stats              # Kullanıcı istatistikleri
│   └── DELETE /me                    # Hesap sil
│
├── /foods
│   ├── GET    /search?q=             # Yemek arama
│   ├── GET    /:id                   # Yemek detayı
│   ├── GET    /barcode/:code         # Barkod ile arama
│   ├── POST   /custom                # Özel yemek ekle
│   ├── GET    /recent                # Son yenenler
│   └── GET    /frequent              # Sık yenenler
│
├── /meals
│   ├── GET    /daily?date=           # Günlük öğünler
│   ├── POST   /                      # Öğün kaydet
│   ├── PUT    /:id                   # Öğün düzenle
│   ├── DELETE /:id                   # Öğün sil
│   └── GET    /summary?date=         # Günlük özet (kalori, makro, mikro)
│
├── /ai
│   ├── POST   /analyze-food          # Fotoğraftan yemek analizi
│   ├── POST   /generate-recipes      # AI tarif önerisi
│   └── GET    /recipes/:id           # Tarif detayı
│
├── /analytics
│   ├── GET    /calories?range=       # Kalori grafiği (günlük/haftalık/aylık)
│   ├── GET    /macros?range=         # Makro trendleri
│   ├── GET    /weight?range=         # Kilo grafiği
│   ├── GET    /streak                # Gün serisi
│   └── GET    /micronutrients?date=  # Mikro besin durumu
│
├── /health-sync
│   ├── POST   /import                # Apple Health verilerini al
│   └── POST   /export                # Apple Health'e veri yaz
│
├── /recipes
│   ├── GET    /saved                 # Kayıtlı tarifler
│   ├── POST   /:id/save             # Tarif kaydet
│   └── DELETE /:id/save             # Kaydedilen tarifi sil
│
├── /water
│   ├── GET    /daily?date=           # Günlük su
│   ├── POST   /                      # Su ekle
│   └── DELETE /:id                   # Su sil
│
└── /subscriptions
    ├── POST   /verify-receipt        # Apple receipt doğrulama
    └── GET    /status                # Abonelik durumu
```

#### Veritabanı Şeması (PostgreSQL)
```sql
-- Kullanıcılar
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE,
    password_hash   VARCHAR(255),
    apple_id        VARCHAR(255) UNIQUE,
    google_id       VARCHAR(255) UNIQUE,
    name            VARCHAR(100) NOT NULL,
    gender          VARCHAR(10),            -- male, female
    birth_date      DATE,
    height_cm       DECIMAL(5,1),
    weight_kg       DECIMAL(5,1),
    body_fat_pct    DECIMAL(4,1),           -- nullable, tahmini veya manuel
    activity_level  VARCHAR(20),            -- sedentary, light, moderate, active, very_active
    unit_system     VARCHAR(10) DEFAULT 'metric',
    language        VARCHAR(5) DEFAULT 'tr',
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Kullanıcı Hedefleri
CREATE TABLE user_goals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    goal_type       VARCHAR(20) NOT NULL,    -- lose_weight, gain_muscle, burn_fat, maintain
    target_weight   DECIMAL(5,1),
    weekly_change   DECIMAL(3,2),            -- kg/hafta
    daily_calories  INTEGER NOT NULL,
    protein_g       INTEGER,
    carbs_g         INTEGER,
    fat_g           INTEGER,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Besin Veritabanı
CREATE TABLE foods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    name_tr         VARCHAR(255),
    brand           VARCHAR(255),
    barcode         VARCHAR(50),
    serving_size_g  DECIMAL(7,1) NOT NULL,
    serving_label   VARCHAR(50),             -- "1 porsiyon", "100g", "1 adet"
    calories        DECIMAL(7,1) NOT NULL,   -- per serving
    protein_g       DECIMAL(6,1),
    carbs_g         DECIMAL(6,1),
    fat_g           DECIMAL(6,1),
    fiber_g         DECIMAL(6,1),
    sugar_g         DECIMAL(6,1),
    saturated_fat_g DECIMAL(6,1),
    sodium_mg       DECIMAL(7,1),
    -- Mikro besinler
    vitamin_a_mcg   DECIMAL(7,1),
    vitamin_c_mg    DECIMAL(7,1),
    vitamin_d_mcg   DECIMAL(7,1),
    vitamin_e_mg    DECIMAL(7,1),
    vitamin_k_mcg   DECIMAL(7,1),
    vitamin_b1_mg   DECIMAL(7,3),
    vitamin_b2_mg   DECIMAL(7,3),
    vitamin_b3_mg   DECIMAL(7,1),
    vitamin_b5_mg   DECIMAL(7,1),
    vitamin_b6_mg   DECIMAL(7,3),
    vitamin_b7_mcg  DECIMAL(7,1),
    vitamin_b9_mcg  DECIMAL(7,1),
    vitamin_b12_mcg DECIMAL(7,3),
    calcium_mg      DECIMAL(7,1),
    iron_mg         DECIMAL(7,1),
    magnesium_mg    DECIMAL(7,1),
    potassium_mg    DECIMAL(7,1),
    zinc_mg         DECIMAL(7,1),
    phosphorus_mg   DECIMAL(7,1),
    -- Meta
    source          VARCHAR(20),             -- usda, openfoodfacts, turkomp, custom, ai
    is_verified     BOOLEAN DEFAULT false,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_foods_name ON foods USING GIN (to_tsvector('simple', name));
CREATE INDEX idx_foods_name_tr ON foods USING GIN (to_tsvector('simple', name_tr));
CREATE INDEX idx_foods_barcode ON foods(barcode);

-- Öğün Kayıtları
CREATE TABLE meal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    food_id         UUID REFERENCES foods(id),
    meal_type       VARCHAR(20) NOT NULL,    -- breakfast, lunch, dinner, snack
    date            DATE NOT NULL,
    quantity        DECIMAL(7,1) NOT NULL,   -- gram cinsinden
    calories        DECIMAL(7,1) NOT NULL,
    protein_g       DECIMAL(6,1),
    carbs_g         DECIMAL(6,1),
    fat_g           DECIMAL(6,1),
    -- AI tarama sonucu ise
    ai_scan_id      UUID,
    photo_url       VARCHAR(500),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_meals_user_date ON meal_entries(user_id, date);

-- AI Tarama Sonuçları
CREATE TABLE ai_scans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    photo_url       VARCHAR(500) NOT NULL,
    raw_response    JSONB,                   -- AI'ın ham yanıtı
    detected_items  JSONB,                   -- [{name, portion, calories, ...}]
    model_used      VARCHAR(50),             -- gpt-4-vision, claude-3, etc.
    confidence      DECIMAL(3,2),
    processing_ms   INTEGER,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Su Tüketimi
CREATE TABLE water_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    amount_ml       INTEGER NOT NULL,
    date            DATE NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Kilo Geçmişi
CREATE TABLE weight_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    weight_kg       DECIMAL(5,1) NOT NULL,
    body_fat_pct    DECIMAL(4,1),
    date            DATE NOT NULL,
    source          VARCHAR(20),             -- manual, apple_health
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Kaydedilen Tarifler
CREATE TABLE recipes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    ingredients     JSONB NOT NULL,          -- [{name, amount, unit}]
    instructions    JSONB NOT NULL,          -- ["Adım 1...", "Adım 2..."]
    prep_time_min   INTEGER,
    cook_time_min   INTEGER,
    servings        INTEGER,
    calories        DECIMAL(7,1),
    protein_g       DECIMAL(6,1),
    carbs_g         DECIMAL(6,1),
    fat_g           DECIMAL(6,1),
    tags            TEXT[],                  -- ['high-protein', 'low-carb', 'vegan']
    photo_url       VARCHAR(500),
    ai_generated    BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_saved_recipes (
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    recipe_id       UUID REFERENCES recipes(id) ON DELETE CASCADE,
    saved_at        TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, recipe_id)
);

-- Abonelikler
CREATE TABLE subscriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    plan            VARCHAR(20) NOT NULL,    -- free, monthly, yearly
    status          VARCHAR(20) NOT NULL,    -- active, expired, cancelled
    apple_receipt   TEXT,
    starts_at       TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.4 Backend - AI Service (Python)

#### Teknoloji Seçimi
| Katman | Teknoloji | Gerekçe |
|--------|-----------|---------|
| Framework | **FastAPI** | Async, hızlı, auto-docs |
| AI - Vision | **OpenAI GPT-4o Vision** | En iyi yemek tanıma |
| AI - Backup | **Anthropic Claude 3.5 Sonnet** | Yedek model, farklı yiyecekler |
| AI - Recipes | **Claude 3.5 Sonnet** | Uzun metin üretimi |
| Vector DB | **pgvector** | PostgreSQL entegre, RAG için |
| Embeddings | **OpenAI text-embedding-3-small** | Besin arama RAG |
| Image | **Pillow** | Resim ön-işleme |

#### AI Food Analysis Pipeline
```
Fotoğraf Girişi
    │
    ▼
┌─────────────────────┐
│  Image Preprocessing │  ← Resize, optimize, EXIF strip
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Model Selection     │  ← Basit yemek → GPT-4o, Karmaşık → Claude
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Vision API Call     │  ← Structured prompt ile yemek analizi
│  (GPT-4o Vision)    │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  RAG Enhancement     │  ← Besin DB'den en yakın eşleşmeleri bul
│  (pgvector search)   │     AI sonucunu veritabanı ile zenginleştir
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Nutrition Calc      │  ← Porsiyon × birim besin değeri
│  + Confidence Score  │
└─────────────────────┘
    │
    ▼
┌─────────────────────┐
│  Response Format     │  ← Standart JSON formatında döndür
└─────────────────────┘
```

#### AI Prompt Stratejisi (Food Analysis)
```
System: You are a nutrition expert AI. Analyze the food photo and return:
- Each food item detected
- Estimated portion size in grams
- Calories and macronutrients per item
- Confidence level (0-1)

Return JSON format:
{
  "items": [
    {
      "name": "Tavuk Göğsü (Izgara)",
      "name_en": "Grilled Chicken Breast",
      "portion_g": 150,
      "calories": 248,
      "protein_g": 46.5,
      "carbs_g": 0,
      "fat_g": 5.4,
      "confidence": 0.92
    }
  ],
  "total_calories": 248,
  "meal_description": "Izgara tavuk göğsü, yanında yeşillik"
}
```

### 3.5 Altyapı & DevOps

| Bileşen | Teknoloji | Gerekçe |
|---------|-----------|---------|
| Cloud | **AWS** | Kapsamlı servisler |
| Compute | **AWS ECS (Fargate)** | Containerized, serverless |
| Database | **AWS RDS (PostgreSQL)** | Managed, güvenilir |
| Cache | **AWS ElastiCache (Redis)** | Managed Redis |
| Storage | **AWS S3** | Dosya depolama |
| CDN | **AWS CloudFront** | Hızlı içerik dağıtımı |
| CI/CD | **GitHub Actions** | Otomatik build & deploy |
| Monitoring | **AWS CloudWatch + Sentry** | Log & hata takibi |
| Container | **Docker** | Taşınabilir deploy |

---

## 4. Kalori & Besin Hesaplama Formülleri

### 4.1 BMR (Bazal Metabolizma Hızı)

**Mifflin-St Jeor (Varsayılan):**
```
Erkek:  BMR = 10 × kilo(kg) + 6.25 × boy(cm) - 5 × yaş - 161 + 166
Kadın:  BMR = 10 × kilo(kg) + 6.25 × boy(cm) - 5 × yaş - 161
```

**Katch-McArdle (Yağ oranı biliniyorsa - daha doğru):**
```
Yağsız kütle (LBM) = kilo × (1 - yağ_oranı / 100)
BMR = 370 + 21.6 × LBM
```

### 4.2 TDEE (Günlük Toplam Enerji Harcaması)
```
Aktivite Çarpanları:
- Sedanter (masa başı):           1.2
- Hafif aktif (1-3 gün/hafta):    1.375
- Orta aktif (3-5 gün/hafta):     1.55
- Çok aktif (6-7 gün/hafta):      1.725
- Ekstra aktif (2x/gün, ağır):    1.9

TDEE = BMR × Aktivite Çarpanı
```

### 4.3 Dinamik Kalori Ayarı (Apple Health)
```
Günlük_Ek_Kalori = (Adım_Sayısı × 0.04) + Apple_Health_Aktif_Kalori
Ayarlanmış_TDEE = BMR × Temel_Çarpan + Günlük_Ek_Kalori
```

### 4.4 Hedef Bazlı Kalori
```
Kilo Kaybı:  Günlük Kalori = TDEE - (haftalık_hedef_kg × 1100)
Kilo Alma:   Günlük Kalori = TDEE + (haftalık_hedef_kg × 1100)
Koruma:      Günlük Kalori = TDEE
```

### 4.5 Makro Hesaplama Mantığı
```
1 gram protein    = 4 kcal
1 gram karbonhidrat = 4 kcal
1 gram yağ        = 9 kcal

Örnek: 2000 kcal hedef, 150g protein, 70g yağ
- Protein kalori:  150 × 4 = 600 kcal
- Yağ kalori:      70 × 9  = 630 kcal
- Kalan kalori:    2000 - 600 - 630 = 770 kcal
- Karbonhidrat:    770 / 4 = 192.5g → kullanıcıya gösterilir
```

### 4.6 Vücut Yağ Oranı Tahmini

**US Navy Method:**
```
Erkek: %Yağ = 86.010 × log10(bel - boyun) - 70.041 × log10(boy) + 36.76
Kadın: %Yağ = 163.205 × log10(bel + kalça - boyun) - 97.684 × log10(boy) - 78.387
```

**BMI Tabanlı Tahmin:**
```
BMI = kilo / (boy_m)²
Erkek: %Yağ = 1.20 × BMI + 0.23 × yaş - 16.2
Kadın: %Yağ = 1.20 × BMI + 0.23 × yaş - 5.4
```

---

## 5. Geliştirme Fazları & Zaman Planı

### Faz 1: Temel Altyapı (Hafta 1-3)
- [ ] Proje kurulumu (iOS + Backend repo)
- [ ] PostgreSQL veritabanı şeması & migration
- [ ] Auth sistemi (JWT, Apple Sign-In)
- [ ] Kullanıcı profil CRUD
- [ ] iOS proje iskeleti (SwiftUI + MVVM)
- [ ] Temel network katmanı
- [ ] Onboarding ekranları (UI)

### Faz 2: Besin Veritabanı & Manuel Giriş (Hafta 3-5)
- [ ] USDA FoodData Central entegrasyonu
- [ ] Open Food Facts barkod API entegrasyonu
- [ ] Türkçe besin isim eşleştirme
- [ ] Yemek arama (full-text search)
- [ ] Barkod tarama (AVFoundation)
- [ ] Öğün kayıt sistemi
- [ ] Dashboard - kalori ve makro gösterimi

### Faz 3: AI Fotoğraf Analizi (Hafta 5-7)
- [ ] Python AI servisi kurulumu (FastAPI)
- [ ] GPT-4o Vision entegrasyonu
- [ ] Claude Vision yedek model
- [ ] RAG pipeline (pgvector)
- [ ] Fotoğraf çekme/seçme UI
- [ ] AI sonuç gösterim ve düzenleme ekranı
- [ ] Doğruluk testleri ve prompt optimizasyonu

### Faz 4: Hedef Yönetimi & Hesaplamalar (Hafta 7-9)
- [ ] Kalori hesaplama motoru (BMR, TDEE)
- [ ] Vücut yağ oranı tahmini
- [ ] Makro hedef sistemi (otomatik karbonhidrat hesabı)
- [ ] Mikro besin takibi (vitamin, mineral)
- [ ] Apple HealthKit entegrasyonu
- [ ] Dinamik kalori ayarı

### Faz 5: AI Tarif Önerisi (Hafta 9-10)
- [ ] Tarif üretim API'si
- [ ] Malzeme seçim arayüzü
- [ ] Diyet kısıtlama filtresi
- [ ] Tarif detay ekranı
- [ ] Tarif kaydetme ve favori sistemi

### Faz 6: Analitik & İlerleme (Hafta 10-11)
- [ ] Kalori/makro grafikleri (Swift Charts)
- [ ] Kilo takip grafiği
- [ ] Streak sistemi
- [ ] Günlük/haftalık/aylık analiz

### Faz 7: Monetizasyon & Lansman (Hafta 11-13)
- [ ] StoreKit 2 abonelik entegrasyonu
- [ ] Paywall tasarımı
- [ ] Bildirim sistemi (öğün hatırlatma)
- [ ] App Store hazırlıkları
- [ ] Beta test (TestFlight)
- [ ] Performans optimizasyonu
- [ ] App Store gönderimi

---

## 6. Üçüncü Parti Servisler & Maliyetler

| Servis | Kullanım | Tahmini Maliyet (Aylık) |
|--------|----------|------------------------|
| OpenAI GPT-4o Vision | Fotoğraf analizi | ~$200-500 (kullanıma bağlı) |
| Anthropic Claude | Yedek model + tarif | ~$100-300 |
| AWS ECS (Fargate) | Backend hosting | ~$50-150 |
| AWS RDS (PostgreSQL) | Veritabanı | ~$30-80 |
| AWS S3 + CloudFront | Dosya depolama | ~$10-30 |
| AWS ElastiCache | Redis cache | ~$15-40 |
| Apple Developer | App Store | $99/yıl |
| Sentry | Hata takibi | Ücretsiz (10K events) |
| **Toplam** | | **~$400-1100/ay** |

---

## 7. Güvenlik Gereksinimleri

- JWT token'lar RS256 ile imzalanacak
- Refresh token rotation
- Rate limiting (API Gateway + Redis)
- Kullanıcı fotoğrafları şifreli S3 bucket
- HTTPS zorunlu (TLS 1.3)
- Input sanitization (Zod validation)
- SQL injection koruması (Prisma ORM)
- Apple receipt server-side verification
- KVKK/GDPR uyumlu veri saklama
- Hesap silme özelliği (App Store zorunlu)

---

## 8. Başlangıç Adımları

Bu plan onaylandıktan sonra geliştirmeye şu sırayla başlanacak:

1. **iOS projesi oluştur** (Xcode, SwiftUI, paket yapısı)
2. **Backend projesi oluştur** (Node.js + TypeScript + Express)
3. **Veritabanı şemasını kur** (Prisma migration)
4. **Auth sistemi** (kayıt/giriş/token)
5. **Onboarding UI** (SwiftUI ekranları)
6. **Dashboard** (ana ekran, kalori halkası)
7. Iteratif olarak diğer fazlara geçiş
