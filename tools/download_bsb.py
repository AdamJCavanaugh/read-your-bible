#!/usr/bin/env python3
"""
Download Berean Standard Bible (BSB) from thiagobodruk/bible
and convert into our app's standardized SQLite database format.
"""

import json
import urllib.request
from pathlib import Path

URL_BSB = "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_bsb.json"

# Map abbreviations to standard book names
BOOK_NAME_MAP = {
    "gn": "Genesis", "ex": "Exodus", "lv": "Leviticus", "nu": "Numbers", "dt": "Deuteronomy",
    "js": "Joshua", "jud": "Judges", "rt": "Ruth", "1sm": "1 Samuel", "2sm": "2 Samuel",
    "1kn": "1 Kings", "2kn": "2 Kings", "1ch": "1 Chronicles", "2ch": "2 Chronicles",
    "ez": "Ezra", "ne": "Nehemiah", "et": "Esther", "job": "Job", "ps": "Psalms",
    "prv": "Proverbs", "ec": "Ecclesiastes", "so": "Song of Solomon", "is": "Isaiah",
    "jr": "Jeremiah", "lm": "Lamentations", "ezk": "Ezekiel", "dn": "Daniel", "hs": "Hosea",
    "jl": "Joel", "am": "Amos", "ob": "Obadiah", "jn": "Jonah", "mc": "Micah", "na": "Nahum",
    "hk": "Habakkuk", "zp": "Zephaniah", "hg": "Haggai", "zc": "Zechariah", "ml": "Malachi",
    "mt": "Matthew", "mk": "Mark", "lk": "Luke", "jo": "John", "act": "Acts", "rm": "Romans",
    "1co": "1 Corinthians", "2co": "2 Corinthians", "gl": "Galatians", "ep": "Ephesians",
    "ph": "Philippians", "cl": "Colossians", "1ts": "1 Thessalonians", "2ts": "2 Thessalonians",
    "1tm": "1 Timothy", "2tm": "2 Timothy", "tt": "Titus", "phm": "Philemon", "hb": "Hebrews",
    "jm": "James", "1pt": "1 Peter", "2pt": "2 Peter", "1jo": "1 John", "2jo": "2 John",
    "3jo": "3 John", "jd": "Jude", "re": "Revelation"
}

def fetch_and_convert():
    print(f"Fetching BSB from {URL_BSB}...")
    req = urllib.request.Request(URL_BSB, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as resp:
        raw_data = json.loads(resp.read().decode('utf-8'))

    books_map = {}
    total_chapters = 0
    total_verses = 0

    for book_obj in raw_data:
        abbrev = book_obj.get("abbrev", "").lower()
        raw_name = book_obj.get("name", "")

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
        "translation": "BSB",
        "name": "Berean Standard Bible",
        "language": "English",
        "books": books_map
    }

    bible_dir = Path(__file__).parent.parent / "assets" / "bible"
    bible_dir.mkdir(parents=True, exist_ok=True)

    output_file = bible_dir / "bsb.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output_json, f, ensure_ascii=False, separators=(',', ':'))

    print(f"✅ Saved BSB JSON to {output_file}: {len(books_map)} books, {total_chapters} chapters, {total_verses} verses ({output_file.stat().st_size / 1024 / 1024:.2f} MB)")

if __name__ == "__main__":
    fetch_and_convert()