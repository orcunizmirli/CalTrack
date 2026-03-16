"""
Standard portion sizes for Turkish foods.
Used for:
1. Calibrating AI portion estimates
2. Providing preset portion options in the UI
3. Fallback when vision model can't estimate portion

Sources: Turkish Nutrition Guide (BEBİS), dietitian references
"""

from app.models.schemas import PortionOption

# Standard portions: food_name_key -> { standard_g, label }
# Keys are lowercase, matched against both Turkish and English names
STANDARD_PORTIONS: dict[str, dict] = {
    # Kebaplar
    "adana kebap": {"standard_g": 200, "label": "1 porsiyon (2 şiş)"},
    "urfa kebap": {"standard_g": 200, "label": "1 porsiyon (2 şiş)"},
    "iskender kebap": {"standard_g": 300, "label": "1 porsiyon"},
    "tavuk şiş": {"standard_g": 180, "label": "1 porsiyon (2 şiş)"},
    "kuzu şiş": {"standard_g": 180, "label": "1 porsiyon (2 şiş)"},
    "tavuk döner": {"standard_g": 150, "label": "1 porsiyon"},
    "et döner": {"standard_g": 150, "label": "1 porsiyon"},
    "kuzu pirzola": {"standard_g": 200, "label": "4 adet"},
    "kuzu tandır": {"standard_g": 250, "label": "1 porsiyon"},
    "tantuni": {"standard_g": 200, "label": "1 dürüm"},
    "kokoreç": {"standard_g": 200, "label": "1 yarım ekmek"},
    # Köfteler
    "köfte": {"standard_g": 150, "label": "4-5 adet"},
    "inegöl köfte": {"standard_g": 150, "label": "4-5 adet"},
    "çiğ köfte": {"standard_g": 150, "label": "1 porsiyon"},
    "mercimek köftesi": {"standard_g": 120, "label": "4-5 adet"},
    # Dürümler
    "köfte dürüm": {"standard_g": 300, "label": "1 adet"},
    "tavuk dürüm": {"standard_g": 300, "label": "1 adet"},
    # Lahmacun & Pide
    "lahmacun": {"standard_g": 120, "label": "1 adet"},
    "kıymalı pide": {"standard_g": 350, "label": "1 adet"},
    "peynirli pide": {"standard_g": 350, "label": "1 adet"},
    # Börekler & Hamur İşleri
    "peynirli börek": {"standard_g": 150, "label": "2 dilim"},
    "ıspanaklı börek": {"standard_g": 150, "label": "2 dilim"},
    "kıymalı börek": {"standard_g": 150, "label": "2 dilim"},
    "su böreği": {"standard_g": 150, "label": "2 dilim"},
    "peynirli gözleme": {"standard_g": 200, "label": "1 adet"},
    "ıspanaklı gözleme": {"standard_g": 200, "label": "1 adet"},
    "simit": {"standard_g": 120, "label": "1 adet"},
    "poğaça": {"standard_g": 80, "label": "1 adet"},
    "açma": {"standard_g": 80, "label": "1 adet"},
    # Pilavlar
    "pirinç pilavı": {"standard_g": 150, "label": "1 porsiyon"},
    "bulgur pilavı": {"standard_g": 150, "label": "1 porsiyon"},
    "şehriyeli pilav": {"standard_g": 150, "label": "1 porsiyon"},
    "nohutlu pilav": {"standard_g": 150, "label": "1 porsiyon"},
    "pilav üstü tavuk": {"standard_g": 300, "label": "1 porsiyon"},
    # Çorbalar
    "mercimek çorbası": {"standard_g": 250, "label": "1 kase"},
    "ezogelin çorbası": {"standard_g": 250, "label": "1 kase"},
    "tarhana çorbası": {"standard_g": 250, "label": "1 kase"},
    "yayla çorbası": {"standard_g": 250, "label": "1 kase"},
    "domates çorbası": {"standard_g": 250, "label": "1 kase"},
    "tavuk çorbası": {"standard_g": 250, "label": "1 kase"},
    "işkembe çorbası": {"standard_g": 250, "label": "1 kase"},
    # Zeytinyağlılar
    "karnıyarık": {"standard_g": 250, "label": "2 adet"},
    "imam bayıldı": {"standard_g": 200, "label": "2 adet"},
    "zeytinyağlı yaprak sarma": {"standard_g": 150, "label": "5-6 adet"},
    "etli yaprak sarma": {"standard_g": 150, "label": "5-6 adet"},
    "zeytinyağlı biber dolma": {"standard_g": 200, "label": "2 adet"},
    "etli biber dolma": {"standard_g": 200, "label": "2 adet"},
    "zeytinyağlı taze fasulye": {"standard_g": 200, "label": "1 porsiyon"},
    "zeytinyağlı enginar": {"standard_g": 200, "label": "2 adet"},
    # Et Yemekleri
    "hünkâr beğendi": {"standard_g": 300, "label": "1 porsiyon"},
    "ali nazik": {"standard_g": 300, "label": "1 porsiyon"},
    "musakka": {"standard_g": 250, "label": "1 porsiyon"},
    "patlıcan musakka": {"standard_g": 250, "label": "1 porsiyon"},
    "etli türlü": {"standard_g": 250, "label": "1 porsiyon"},
    # Baklagiller
    "kuru fasulye": {"standard_g": 200, "label": "1 porsiyon"},
    "nohut yemeği": {"standard_g": 200, "label": "1 porsiyon"},
    "bamya": {"standard_g": 200, "label": "1 porsiyon"},
    # Mantı & Makarna
    "mantı": {"standard_g": 250, "label": "1 porsiyon"},
    "makarna": {"standard_g": 200, "label": "1 porsiyon"},
    "domates soslu makarna": {"standard_g": 250, "label": "1 porsiyon"},
    # Kahvaltı
    "menemen": {"standard_g": 200, "label": "1 porsiyon"},
    "sucuklu yumurta": {"standard_g": 150, "label": "1 porsiyon"},
    "haşlanmış yumurta": {"standard_g": 50, "label": "1 adet"},
    "sahanda yumurta": {"standard_g": 60, "label": "1 adet"},
    # Tostlar & Sandviçler
    "kaşarlı tost": {"standard_g": 150, "label": "1 adet"},
    "karışık tost": {"standard_g": 180, "label": "1 adet"},
    "balık ekmek": {"standard_g": 300, "label": "1 adet"},
    "ıslak hamburger": {"standard_g": 120, "label": "1 adet"},
    # Salatalar & Mezeler
    "çoban salatası": {"standard_g": 200, "label": "1 porsiyon"},
    "cacık": {"standard_g": 150, "label": "1 kase"},
    "kısır": {"standard_g": 150, "label": "1 porsiyon"},
    "humus": {"standard_g": 80, "label": "1 porsiyon"},
    "acılı ezme": {"standard_g": 80, "label": "1 porsiyon"},
    "haydari": {"standard_g": 80, "label": "1 porsiyon"},
    # Ekmekler
    "ekmek": {"standard_g": 50, "label": "1 dilim"},
    "tam buğday ekmeği": {"standard_g": 50, "label": "1 dilim"},
    "lavaş": {"standard_g": 80, "label": "1 adet"},
    # Fast Food
    "sucuklu pizza": {"standard_g": 120, "label": "1 dilim"},
    "patates kızartması": {"standard_g": 150, "label": "1 porsiyon"},
    "tavuk nugget": {"standard_g": 100, "label": "6 adet"},
    "kumpir": {"standard_g": 400, "label": "1 adet"},
    # Tatlılar
    "baklava": {"standard_g": 80, "label": "2 dilim"},
    "künefe": {"standard_g": 150, "label": "1 porsiyon"},
    "sütlaç": {"standard_g": 200, "label": "1 kase"},
    "kazandibi": {"standard_g": 150, "label": "1 porsiyon"},
    "tavuk göğsü tatlısı": {"standard_g": 150, "label": "1 porsiyon"},
    "aşure": {"standard_g": 200, "label": "1 kase"},
    "lokma": {"standard_g": 100, "label": "5-6 adet"},
    "tulumba tatlısı": {"standard_g": 100, "label": "4-5 adet"},
    "revani": {"standard_g": 100, "label": "1 dilim"},
    "dondurma": {"standard_g": 100, "label": "2 top"},
    # Midye
    "midye dolma": {"standard_g": 150, "label": "5-6 adet"},
    # İçecekler
    "ayran": {"standard_g": 200, "label": "1 bardak"},
    "türk kahvesi": {"standard_g": 60, "label": "1 fincan"},
    "çay": {"standard_g": 100, "label": "1 bardak"},
    "şalgam suyu": {"standard_g": 200, "label": "1 bardak"},
    "nar suyu": {"standard_g": 200, "label": "1 bardak"},
    # Peynirler
    "beyaz peynir": {"standard_g": 30, "label": "1 dilim"},
    "kaşar peyniri": {"standard_g": 25, "label": "1 dilim"},
    # Zeytinler
    "yeşil zeytin": {"standard_g": 30, "label": "5-6 adet"},
    "siyah zeytin": {"standard_g": 30, "label": "5-6 adet"},
    # Yoğurt
    "yoğurt": {"standard_g": 200, "label": "1 kase"},
    # Charcuterie
    "sucuk": {"standard_g": 50, "label": "3-4 dilim"},
    "pastırma": {"standard_g": 30, "label": "3-4 dilim"},
    # Meyveler
    "muz": {"standard_g": 120, "label": "1 adet"},
    "elma": {"standard_g": 180, "label": "1 adet"},
    "portakal": {"standard_g": 180, "label": "1 adet"},
    "karpuz": {"standard_g": 200, "label": "1 dilim"},
    "üzüm": {"standard_g": 100, "label": "1 salkım"},
    "çilek": {"standard_g": 150, "label": "8-10 adet"},
    # Balık
    "ızgara somon": {"standard_g": 180, "label": "1 fileto"},
    "ızgara levrek": {"standard_g": 200, "label": "1 adet"},
    "hamsi tava": {"standard_g": 150, "label": "1 porsiyon"},
    # Et
    "ızgara tavuk göğsü": {"standard_g": 150, "label": "1 adet"},
    "haşlama tavuk göğsü": {"standard_g": 150, "label": "1 adet"},
    "kıyma (pişmiş)": {"standard_g": 100, "label": "1 porsiyon"},
}


def _normalize(name: str) -> str:
    return name.lower().strip()


def get_standard_portions(name_tr: str, name_en: str | None = None) -> dict | None:
    """Look up standard portion for a food item."""
    key = _normalize(name_tr)
    if key in STANDARD_PORTIONS:
        return STANDARD_PORTIONS[key]

    # Try English name
    if name_en:
        key_en = _normalize(name_en)
        if key_en in STANDARD_PORTIONS:
            return STANDARD_PORTIONS[key_en]

    # Fuzzy: try partial match
    for k, v in STANDARD_PORTIONS.items():
        if k in key or key in k:
            return v

    return None


def get_portion_options(
    name_tr: str,
    name_en: str | None,
    cal_per_100g: float,
) -> list[PortionOption]:
    """
    Generate portion option presets for the UI slider.
    If we have a standard portion, use it as "Orta" and create small/large variants.
    Otherwise, create generic options.
    """
    std = get_standard_portions(name_tr, name_en)

    if std:
        base_g = std["standard_g"]
        options = [
            PortionOption(
                label="Küçük (½)",
                grams=round(base_g * 0.5),
                calories=round(cal_per_100g * base_g * 0.5 / 100, 1),
            ),
            PortionOption(
                label=std["label"],
                grams=base_g,
                calories=round(cal_per_100g * base_g / 100, 1),
            ),
            PortionOption(
                label="Büyük (1.5×)",
                grams=round(base_g * 1.5),
                calories=round(cal_per_100g * base_g * 1.5 / 100, 1),
            ),
        ]
    else:
        # Generic portions
        options = [
            PortionOption(
                label="Küçük",
                grams=75,
                calories=round(cal_per_100g * 0.75, 1),
            ),
            PortionOption(
                label="Orta",
                grams=150,
                calories=round(cal_per_100g * 1.5, 1),
            ),
            PortionOption(
                label="Büyük",
                grams=250,
                calories=round(cal_per_100g * 2.5, 1),
            ),
        ]

    return options
