#!/usr/bin/env python3
"""
Download complete KJV and WEB Bibles from thiagobodruk/bible
and convert into our app's standardized JSON format.
"""

import json
import urllib.request
from pathlib import Path

URL_KJV = "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json"
URL_WEB = "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_web.json"

# Map abbreviations to standard book names if needed
BOOK_NAME_MAP = {
    "gn": "Genesis",
    "ex": "Exodus",
    "lv": "Leviticus",
    "nu": "Numbers",
    "dt": "Deuteronomy",
    "js": "Joshua",
    "jud": "Judges",
    "rt": "Ruth",
    "1sm": "1 Samuel",
    "2sm": "2 Samuel",
    "1kn": "1 Kings",
    "2kn": "2 Kings",
    "1ch": "1 Chronicles",
    "2ch": "2 Chronicles",
    "ez": "Ezra",
    "ne": "Nehemiah",
    "et": "Esther",
    "job": "Job",
    "ps": "Psalms",
    "prv": "Proverbs",
    "ec": "Ecclesiastes",
    "so": "Song of Solomon",
    "is": "Isaiah",
    "jr": "Jeremiah",
    "lm": "Lamentations",
    "ezk": "Ezekiel",
    "dn": "Daniel",
    "hs": "Hosea",
    "jl": "Joel",
    "am": "Amos",
    "ob": "Obadiah",
    "jn": "Jonah",
    "mc": "Micah",
    "na": "Nahum",
    "hk": "Habakkuk",
    "zp": "Zephaniah",
    "hg": "Haggai",
    "zc": "Zechariah",
    "ml": "Malachi",
    "mt": "Matthew",
    "mk": "Mark",
    "lk": "Luke",
    "jo": "John",
    "act": "Acts",
    "rm": "Romans",
    "1co": "1 Corinthians",
    "2co": "2 Corinthians",
    "gl": "Galatians",
    "ep": "Ephesians",
    "ph": "Philippians",
    "cl": "Colossians",
    "1ts": "1 Thessalonians",
    "2ts": "2 Thessalonians",
    "1tm": "1 Timothy",
    "2tm": "2 Timothy",
    "tt": "Titus",
    "phm": "Philemon",
    "hb": "Hebrews",
    "jm": "James",
    "1pt": "1 Peter",
    "2pt": "2 Peter",
    "1jo": "1 John",
    "2jo": "2 John",
    "3jo": "3 John",
    "jd": "Jude",
    "re": "Revelation"
}

def fetch_and_convert(url, translation_code, translation_name):
    print(f"Fetching {translation_name} from {url}...")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as resp:
        raw_data = json.loads(resp.read().decode('utf-8'))

    books_map = {}
    total_chapters = 0
    total_verses = 0

    for book_obj in raw_data:
        raw_name = book_obj.get("name", "")
        abbrev = book_obj.get("abbrev", "").lower()

        # Standardize book name
        book_name = BOOK_NAME_MAP.get(abbrev, raw_name)
        if book_name == "Psalm":
            book_name = "Psalms"

        chapters_data = book_obj.get("chapters", [])
        book_chapters_map = {}

        for ch_idx, verses_list in enumerate(chapters_data):
            ch_num_str = str(ch_idx + 1)
            cleaned_verses = [v.strip() for v in verses_list]
            book_chapters_map[ch_num_str] = cleaned_verses
            total_verses += len(cleaned_verses)

        books_map[book_name] = book_chapters_map
        total_chapters += len(book_chapters_map)

    output_json = {
        "translation": translation_code,
        "name": translation_name,
        "language": "English",
        "books": books_map
    }

    return output_json, len(books_map), total_chapters, total_verses

def main():
    output_dir = Path(__file__).parent.parent / "assets" / "bible"
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Download & convert KJV
    kjv_data, b_cnt, c_cnt, v_cnt = fetch_and_convert(URL_KJV, "KJV", "King James Version")
    file_kjv = output_dir / "kjv.json"
    with open(file_kjv, "w", encoding="utf-8") as f:
        json.dump(kjv_data, f, ensure_ascii=False, separators=(',', ':'))
    print(f"✅ Saved full KJV to {file_kjv}: {b_cnt} books, {c_cnt} chapters, {v_cnt} verses ({file_kjv.stat().st_size / 1024 / 1024:.2f} MB)")

    # 2. Download & convert WEB
    web_data, b_cnt, c_cnt, v_cnt = fetch_and_convert(URL_WEB, "WEB", "World English Bible")
    file_web = output_dir / "web.json"
    with open(file_web, "w", encoding="utf-8") as f:
        json.dump(web_data, f, ensure_ascii=False, separators=(',', ':'))
    print(f"✅ Saved full WEB to {file_web}: {b_cnt} books, {c_cnt} chapters, {v_cnt} verses ({file_web.stat().st_size / 1024 / 1024:.2f} MB)")

if __name__ == "__main__":
    main()