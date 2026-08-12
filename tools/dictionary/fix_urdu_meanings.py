#!/usr/bin/env python3
"""Fix wrong Urdu meanings in the dictionary packs.

The generated packs (urdu_wiktionary_pack.json, 000_wordnet_enrichment.json)
are built from Wiktionary/kaikki dumps and contain a mix of Hindi/Sanskrit
leakage and wrong senses (e.g. `hardship -> محنت` "hard work", `cell -> خلا`
"void", `well -> کلیہ` "kidney", `ever -> ہرگز` "never"). This script upserts
curated, learner-standard Urdu translations into zz_curated_corrections.json —
the pack that wins every merge (sorted last, "later wins").

Usage:
    python3 tools/dictionary/fix_urdu_meanings.py

Then regenerate + audit:
    python3 tools/dictionary/rebuild_dictionary.py
    python3 tools/dictionary/audit_packs.py
"""
import json

# word -> correct Urdu meanings (learner-standard, no Hindi/Sanskrit leakage)
FIXES = {
    "hardship": ["مشکل", "مشقت", "تکلیف"],
    "neat": ["صاف ستھرا", "سلیقہ مند"],
    "cell": ["خلیہ", "کوٹھڑی"],
    "well": ["اچھا", "اچھی طرح", "کنواں"],
    "die": ["مرنا", "وفات پانا"],
    "ever": ["کبھی"],
    "ride": ["سواری کرنا"],
    "section": ["حصہ", "طبقہ"],
    "shoot": ["گولی مارنا", "فائر کرنا"],
    "design": ["ڈیزائن", "نمونہ", "نقشہ"],
    "stress": ["دباؤ", "تناؤ"],
    "sense": ["حس", "احساس", "معنی"],
    "charge": ["الزام", "چارج", "قیمت"],
    "case": ["معاملہ", "کیس", "مقدمہ"],
    "figure": ["شکل", "انگ", "اعداد و شمار"],
    "much": ["بہت", "زیادہ"],
    "just": ["صرف", "بس", "ذرا"],
    "general": ["عام", "عمومی", "جنرل"],
    "complete": ["مکمل", "پورا"],
    "mind": ["ذہن", "دماغ", "دل"],
    "spirit": ["روح", "جان"],
    "war": ["جنگ", "لڑائی"],
    "power": ["طاقت", "قوت", "اختیار"],
    "action": ["عمل", "کارروائی"],
    "development": ["ترقی", "ارتقا"],
    "air": ["ہوا", "فضا"],
    "horse": ["گھوڑا"],
    "here": ["یہاں", "ادھر"],
    "three": ["تین"],
    "home": ["گھر", "مکان"],
    "office": ["دفتر", "آفس"],
    "head": ["سر"],
    "foot": ["پاؤں", "پیر"],
    "today": ["آج"],
    "government": ["حکومت", "سرکار"],
    "smile": ["مسکراہٹ", "تبسم"],
    "community": ["معاشرہ", "جماعت"],
    "century": ["صدی"],
    "available": ["موجود", "دستیاب"],
    "enemy": ["دشمن"],
    "battle": ["جنگ", "معرکہ"],
    "sing": ["گانا"],
    "red": ["سرخ", "لال"],
    "mass": ["کمیت", "عوام"],
    "evidence": ["ثبوت"],
    "material": ["مواد", "سامان"],
    "dark": ["اندھیرا", "تاریک"],
    "accept": ["قبول کرنا", "ماننا"],
    "view": ["نظارہ", "منظر", "رائے"],
    "apply": ["لگانا", "درخواست دینا"],
    "develop": ["ترقی کرنا", "تیار کرنا"],
    "lie": ["جھوٹ", "لیٹنا"],
    "act": ["عمل کرنا", "اداکاری کرنا"],
    "amount": ["مقدار", "رقم"],
    "range": ["حد", "وسعت", "دائرہ"],
    "hit": ["مارنا", "چوٹ", "ضرب"],
    "cut": ["کاٹنا", "کٹائی"],
    "discover": ["دریافت کرنا", "کھوج لگانا"],
    "function": ["فعل", "کام", "تقریب"],
    "human": ["انسان", "انسانی"],
    "local": ["مقامی", "دیسی"],
    "plant": ["پودا"],
    "product": ["مصنوعات", "پروڈکٹ"],
    "voice": ["آواز", "سر"],
    "even": ["برابر", "یکساں", "حتیٰ کہ"],
    "father": ["باپ", "والد"],
    "student": ["طالب علم"],
    "member": ["رکن"],
    "average": ["اوسط"],
    "tall": ["لمبا"],
    "rule": ["حکمرانی", "قاعدہ", "ضابطہ"],
    "attention": ["توجہ", "دھیان"],
    "admit": ["تسلیم کرنا", "مان لینا"],
    "declare": ["اعلان کرنا"],
    "stage": ["مرحلہ", "اسٹیج", "منچ"],
    "bear": ["ریچھ", "برداشت کرنا"],
    "feature": ["خصوصیت", "نمایاں خوبی"],
    "reflect": ["منعکس کرنا", "عکس دکھانا"],
    "space": ["خلا", "جگہ"],
    "object": ["چیز", "شے", "اعتراض کرنا"],
    "paper": ["کاغذ"],
    "meaning": ["معنی", "مطلب", "مراد"],
    "slowly": ["آہستہ", "دھیمے"],
    "swing": ["جھولنا", "جھولا"],
    "black": ["کالا", "سیاہ"],
    "particular": ["خاص", "مخصوص"],
    "table": ["میز"],
    "treat": ["علاج کرنا", "سلوک کرنا"],
    "door": ["دروازہ"],
    "care": ["خیال", "دیکھ بھال"],
    "arm": ["بازو"],
    "eye": ["آنکھ", "چشم"],
    "hand": ["ہاتھ", "دست"],
    "four": ["چار"],
    "information": ["معلومات", "خبر"],
    "establish": ["قائم کرنا"],
    "step": ["قدم", "گام"],
    "observe": ["مشاہدہ کرنا", "دھیان دینا"],
    "leg": ["ٹانگ"],
}

URDU = "assets/dictionary/urdu_wiktionary_pack.json"
ZZ = "assets/dictionary/zz_curated_corrections.json"


def main() -> None:
    urdu = {e["word"].lower(): e for e in json.load(open(URDU, encoding="utf-8"))}
    zz = json.load(open(ZZ, encoding="utf-8"))
    by_word = {e["word"].lower(): e for e in zz}

    added = updated = skipped = 0
    for w, urdu_meanings in FIXES.items():
        src = by_word.get(w) or urdu.get(w)
        if src is None:
            print(f"  !! {w}: not found in zz or urdu pack — skipped")
            skipped += 1
            continue
        entry = {
            "word": src["word"],
            "partOfSpeech": src.get("partOfSpeech", "noun"),
            "englishDefinition": src.get("englishDefinition", ""),
            "urduMeanings": urdu_meanings,
        }
        if w in by_word:
            by_word[w] = entry
            updated += 1
        else:
            by_word[w] = entry
            added += 1

    new_zz = sorted(by_word.values(), key=lambda e: e["word"])
    out = json.dumps(new_zz, indent=1, ensure_ascii=False) + "\n"
    open(ZZ, "w", encoding="utf-8").write(out)
    print(f"added={added} updated={updated} skipped={skipped} total={len(new_zz)}")


if __name__ == "__main__":
    main()
