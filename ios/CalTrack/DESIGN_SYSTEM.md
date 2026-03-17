# CalTrack Design System
## Cal.AI Aesthetic + Apple Liquid Glass (iOS 26)

> Bu dokuman CalTrack iOS uygulamasinin tum gorunum kararlari icin tek kaynak noktasidir.
> Her yeni ekran veya komponent bu kurallara uygun olmalidir.

---

## 1. Renk Sistemi

### Arka Plan Renkleri (Dark-First)
| Token | Hex | Kullanim |
|-------|-----|----------|
| `ctBackground` | `#000000` | Ana arka plan (OLED pure black) |
| `ctSurface` | `#0A0A0A` | Glass arkasindaki yukseltilmis yuzey |
| `ctSurfaceElevated` | `#141414` | Glass kullanilmayan kart arka planlari |

### Marka Renkleri
| Token | Hex | Kullanim |
|-------|-----|----------|
| `ctAccent` | `#4ADE80` | Ana vurgu rengi - tum CTA, ring, aktif durum |
| `ctAccentDim` | `#22C55E` | Basilmis/ikincil vurgu |

### Makro Renkleri
| Token | Hex | Kullanim |
|-------|-----|----------|
| `ctProtein` | `#60A5FA` | Protein (mavi) |
| `ctCarbs` | `#FB923C` | Karbonhidrat (turuncu) |
| `ctFat` | `#F87171` | Yag (kirmizi) |
| `ctCalories` | `#4ADE80` | Kalori = accent yesil |

### Semantik Renkler
| Token | Hex | Kullanim |
|-------|-----|----------|
| `ctSuccess` | `#4ADE80` | Basarili |
| `ctWarning` | `#FBBF24` | Uyari |
| `ctError` | `#EF4444` | Hata / silme |

### Metin Renkleri
| Token | Hex | Kullanim |
|-------|-----|----------|
| `ctTextPrimary` | `#FFFFFF` | Birincil metin |
| `ctTextSecondary` | `#9CA3AF` | Ikincil metin |
| `ctTextTertiary` | `#6B7280` | Ipucu metni |

### Ogun Renkleri
| Token | Kullanim |
|-------|----------|
| `ctBreakfast` | Kahvalti (altin) |
| `ctLunch` | Ogle (acik mavi) |
| `ctDinner` | Aksam (mor) |
| `ctSnack` | Atistirmalik (pembe) |

---

## 2. Tipografi

| Token | Boyut | Agirlik | Tasarim | Kullanim |
|-------|-------|---------|---------|----------|
| `ctHero` | 56pt | Bold | Rounded | Kalori ring icindeki ana sayi |
| `ctLargeTitle` | 34pt | Bold | Rounded | Ekran basliklari |
| `ctTitle` | 24pt | Bold | Rounded | Bolum basliklari |
| `ctTitle2` | 20pt | Semibold | Rounded | Alt-bolum basliklari |
| `ctHeadline` | 17pt | Semibold | Default | Kart basliklari |
| `ctBody` | 17pt | Regular | Default | Govde metni |
| `ctCallout` | 16pt | Regular | Default | Ikincil govde |
| `ctSubheadline` | 15pt | Regular | Default | Aciklamalar |
| `ctFootnote` | 13pt | Regular | Default | Ek bilgiler |
| `ctCaption` | 12pt | Regular | Default | Etiketler, rozetler |
| `ctMacroValue` | 20pt | Bold | Rounded | Makro sayilari |

---

## 3. Bosluk ve Duzenleme

- Temel birim: **4pt**
- Ekran yatay padding: **16pt**
- Kart ic padding: **16pt**
- Kartlar arasi dikey bosluk: **12pt**
- Bolumler arasi bosluk: **20pt**
- Kose yuvarlakliklari: **16pt** (kartlar), **20pt** (hero kartlar), **24pt** (sheet'ler), **12pt** (chip/rozet), **full** (haplar)

---

## 4. Glass Efekt Kurallari

### Ne Zaman Hangi Glass Kullanilir
| Baglam | Glass Tipi | Neden |
|--------|------------|-------|
| Tab bar | Otomatik (iOS 26) | Sistem yonetiyor |
| Navigation bar | Otomatik (iOS 26) | Sistem yonetiyor |
| Floating AI scan butonu | `.regular.tint(.ctAccent).interactive()` | Yuzen eleman, marka vurgusu |
| Dashboard kalori ring karti | `.regular` | Hero kart |
| Makro progress kartlari | `.regular` | Icerik kartlari |
| Ogun bolum kartlari | `.regular` | Icerik kartlari |
| Aktivite kartlari | `.regular` | Kucuk bilgi kartlari |
| Su takibi | `.regular` | Icerik karti |
| Beslenme rozetleri | `.clear` | Kucuk, daha saydam olmali |
| Arama cubugu | `.regular` | Yuzen arama |
| Chip / hap seciciler | `.clear.interactive()` | Interaktif kucuk elemanlar |
| Onboarding adim kartlari | `.regular` | Tam genislik icerik |
| Grafik kartlari | `.regular` | Analiz konteynerlari |

### Kurallar
1. `.glassEffect()` DAIMA modifier zincirinde **EN SON** uygulanir
2. Glass uzerine glass **ASLA** konulmaz -- `GlassEffectContainer` kullanilir
3. Glass **yuzen/overlay** UI icin kullanilir -- arka plan icerigi solid karanlik kalir
4. Secili/aktif chip: solid `ctAccent` fill, glass DEGIL
5. ScrollView icindeki glass elemanlar `GlassEffectContainer` ile sarilir
6. `.clipShape()` daima `.glassEffect()` oncesinde olmali

---

## 5. Buton Stilleri

| Stil | Gorunum | Kullanim |
|------|---------|----------|
| **Primary** | Solid `ctAccent`, siyah metin, 14pt radius | Ana CTA (Kaydet, Devam, Ekle) |
| **Glass Interactive** | `.glassEffect(.regular.interactive())`, accent metin | Ikincil aksiyonlar |
| **Ghost** | Transparan bg, `ctAccent` metin | Ucuncul aksiyonlar (Tekrar Cek, Iptal) |
| **Destructive** | Solid `ctError`, beyaz metin | Silme islemleri |
| **Chip (secili)** | Solid `ctAccent`, siyah metin, capsule | Aktif filtre |
| **Chip (secilmemis)** | `.glassEffect(.clear)`, birincil metin, capsule | Inaktif filtre |

---

## 6. Animasyon Rehberi

| Animasyon | Spec | Kullanim |
|-----------|------|----------|
| Spring | `response: 0.35, dampingFraction: 0.8` | Varsayilan gecis |
| Quick | `easeInOut(0.2)` | Hizli durum degisimi |
| Medium | `easeInOut(0.3)` | Orta gecis |
| Ring | `easeInOut(0.8)` | Progress ring animasyonu |
| Glass Morph | `glassEffectID(_:in:)` + `@Namespace` | Glass elemanlar arasi gecis |

### Haptic Geri Bildirim
- `.impact(.light)` -- chip secimi, kucuk aksiyonlar
- `.impact(.medium)` -- birincil buton, kamera tetikleme
- `.success` -- kaydetme/onaylama
- `.selection()` -- tarih degisimi, filtre secimi

---

## 7. Yapilmasi ve Yapilmamasi Gerekenler

### YAPILACAKLAR
- Pure black `#000000` arka plan (OLED verimlilik)
- Glass efektler sadece yuzen/overlay elemanlarda
- Birden fazla glass eleman varsa `GlassEffectContainer` kullan
- `.glassEffect()` en son modifier olarak uygula
- Accent yesil baskin vurgu olarak kullan -- arka plan dolgusu olarak DEGIL
- `.foregroundStyle()` kullan (`.foregroundColor()` degil)
- `NavigationStack` kullan (`NavigationView` degil)

### YAPILMAYACAKLAR
- Glass uzerine glass koymak (`GlassEffectContainer` olmadan)
- Glass'i arka plan/taban katmanlari icin kullanmak
- Her elemente glass uygulamak -- etkisini kaybeder
- Kartlarda opak renkli arka planlar (eski desen: `Color.ctSecondaryBg`)
- `.background(Color.ctSecondaryBg)` ile `.glassEffect()` karistirmak
- `.foregroundColor()` kullanmak (deprecated, glass uyumlu degil)
