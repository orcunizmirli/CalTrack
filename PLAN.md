# CalTrack iOS Premium Feature Implementation Plan

## Overview
14 major feature implementations to elevate CalTrack to a premium-quality iOS app.
Each phase is independent and will be committed separately.

---

## Phase 1: Onboarding Animasyonları
**Files:** `OnboardingFlowView.swift`, new `OnboardingAnimations.swift`

- Her adım için staggered fade-in + slide-up animasyonları
- Step geçişlerinde smooth page curl / slide efekti
- İkon ve başlıklar için bounce-in animasyonları
- Progress bar animated gradient efekti
- PlanSummaryView'da confetti-benzeri completion animasyonu
- Her adımda ikon için pulse/scale animasyonu

---

## Phase 2: Skeleton/Shimmer Loading
**Files:** New `Core/Components/ShimmerView.swift`, `DashboardView.swift`, `AnalyticsView.swift`, `FoodSearchView.swift`

- Reusable `ShimmerModifier` view modifier (gradient animation)
- `SkeletonCard` component (rounded rect shimmer placeholder)
- Dashboard'da yüklenirken shimmer kartlar
- Analytics'te chart placeholder shimmer
- Food search'te sonuç placeholder shimmer
- Recipe list'te shimmer kartlar

---

## Phase 3: Confetti/Celebration Animasyonları
**Files:** New `Core/Components/ConfettiView.swift`, `DashboardViewModel.swift`, `DashboardView.swift`, `CalorieRingView.swift`

- Reusable `ConfettiView` (particle system with SwiftUI Canvas)
- Günlük kalori hedefine ulaşıldığında confetti + haptic
- Su hedefi tamamlandığında mini celebration
- Streak milestone'larında özel animasyon (7, 30, 100 gün)
- CalorieRing %100'e ulaştığında glow pulse efekti

---

## Phase 4: WidgetKit - Ana Ekran Widget'ları
**Files:** New target `CalTrackWidget/`, `project.yml` update

- **CalorieRingWidget (small):** Günlük kalori ring + kalan
- **MacroWidget (medium):** Kalori ring + 3 makro bar
- **WaterWidget (small):** Su bardağı görseli + ilerleme
- App Group ile data paylaşımı
- Timeline provider ile otomatik güncelleme
- Widget tint renkleri ile iOS 26 uyumu

---

## Phase 5: Interactive Widget - Hızlı Su Ekleme
**Files:** `CalTrackWidget/` intent handlers

- Su bardağı interactive widget (AppIntent)
- +200ml, +330ml, +500ml butonları widget üzerinde
- Hızlı yemek ekleme widget'ı (son yenilen yemekleri tekrar ekle)
- Widget üzerinden AI scan'e deep link

---

## Phase 6: Apple Watch Uygulaması
**Files:** New target `CalTrackWatch/`

- **WatchApp ana ekran:** Günlük kalori ring (küçük)
- **Complication:** Kalori kalan / su takibi
- **Su ekleme:** Digital Crown ile ml seçimi
- **Öğün özeti:** Bugünkü yemekler listesi
- WatchConnectivity ile iPhone senkronizasyonu
- HealthKit doğrudan Watch'tan okuma

---

## Phase 7: Siri Shortcuts Entegrasyonu
**Files:** New `Core/Intents/`, `AppShortcutsProvider.swift`

- "Bugün kaç kalori aldım?" → kalori bilgisi
- "Su ekle" → hızlı 250ml ekleme
- "Yemek tara" → AI scan açma
- "Bugünkü makrolarım" → P/C/F özeti
- AppShortcutsProvider ile Shortcuts app'te görünme
- Spotlight donation for food items

---

## Phase 8: WelcomeView Logo & İllüstrasyon
**Files:** `WelcomeView.swift`, new `Core/Components/AppLogoView.swift`

- SF Symbol yerine custom SwiftUI ile çizilmiş animated logo
- Gradient çember içinde fork+knife ikonu
- Logo pulse/glow animasyonu
- Feature row ikonları için animated entrance
- Arka planda floating food emoji particle efekti

---

## Phase 9: Animated Gradient Arka Planlar
**Files:** New `Core/Components/AnimatedGradientBackground.swift`, `WelcomeView.swift`, `OnboardingFlowView.swift`, `PlanSummaryView.swift`

- Yavaş hareket eden mesh gradient arka plan
- Welcome ekranında ambient gradient
- Onboarding'de adıma göre renk değişen gradient
- Dashboard header'da subtle animated gradient
- Goal completion ekranlarında celebration gradient

---

## Phase 10: Parallax Scrolling Efekti
**Files:** `DashboardView.swift`, `AnalyticsView.swift`

- Dashboard CalorieRing için parallax (scroll ile küçülme/fade)
- Meal section kartları için depth parallax
- Analytics chart header parallax
- GeometryReader + ScrollView offset tracking
- Smooth scale + opacity transition on scroll

---

## Phase 11: Blur Transition Efektleri
**Files:** `RootView.swift`, `OnboardingFlowView.swift`, `DashboardView.swift`

- Ekran geçişlerinde blur → sharp transition
- Sheet presentation'larda blur background
- Tab değişimlerinde subtle blur cross-fade
- Modal dismiss'te blur-out efekti
- Navigation push/pop'ta blur transition

---

## Phase 12: Custom Progress Bar Animasyonları
**Files:** `CalorieRingView.swift`, `MacroProgressView.swift`, `WaterTrackerView.swift`, new `Core/Components/AnimatedProgressBar.swift`

- CalorieRing: Gradient stroke + animated glow trail
- MacroProgress: Wave-fill animasyonu
- WaterTracker: Sıvı dolum animasyonu (wave efekti)
- Onboarding progress: Animated gradient bar
- Micro nutrient bars: Staggered fill animasyonu

---

## Phase 13: Fotoğraf Galerisi Desteği + Yemek Kopyalama
**Files:** `AIFoodScanView.swift`, `AIFoodScanViewModel.swift`, `MealSectionView.swift`, `DashboardViewModel.swift`, `MealEntry.swift`

- Kamera yanında galeri butonu (PhotosPicker)
- Çekilen/seçilen fotoğrafı MealEntry'ye kaydetme (photoData field)
- MealItemRow'da küçük thumbnail gösterimi
- Yemek kopyalama: MealSection header'da "Dünden kopyala" butonu
- Tek yemek kopyalama: Swipe action ile "Bugüne ekle"
- Toplu kopyalama: Tüm öğünü başka güne kopyala

---

## Phase 14: Favori Yemekler / Sık Kullanılanlar
**Files:** `FoodSearchView.swift`, `FoodSearchViewModel.swift`, new model `FavoriteFoods.swift`, `MealSectionView.swift`

- FoodItem'a `isFavorite` flag ekleme
- Yemek detay sheet'te kalp ikonu ile favorilere ekleme
- FoodSearchView'da "Favoriler" tab/section
- MealItemRow'da swipe ile favorilere ekleme
- Favoriler sıralama: En çok eklenen önce
- Quick-add: Favorilerden tek tıkla ekleme

---

## Implementation Order & Dependencies
1. Phase 2 (Shimmer) → temel component, diğerleri kullanacak
2. Phase 8 (Logo) → bağımsız, hızlı
3. Phase 9 (Gradient backgrounds) → bağımsız
4. Phase 1 (Onboarding animations) → Phase 9'a bağlı olabilir
5. Phase 12 (Progress animations) → bağımsız
6. Phase 3 (Confetti) → bağımsız
7. Phase 10 (Parallax) → bağımsız
8. Phase 11 (Blur transitions) → bağımsız
9. Phase 13 (Gallery + Copy) → data model değişikliği
10. Phase 14 (Favorites) → data model değişikliği
11. Phase 4 (WidgetKit) → yeni target
12. Phase 5 (Interactive Widget) → Phase 4'e bağlı
13. Phase 6 (Apple Watch) → yeni target
14. Phase 7 (Siri Shortcuts) → bağımsız
