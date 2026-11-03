#!/usr/bin/env python3
"""
Convert assets/bible/kjv.json, assets/bible/web.json, and assets/bible/bsb.json
into indexed SQLite database files:
- assets/bible/kjv.db
- assets/bible/web.db
- assets/bible/bsb.db
"""

import json
import sqlite3
from pathlib import Path

# Canonical 66 Books Mapping (book_number 1 to 66)
CANONICAL_BOOKS = [
    # Old Testament (1..39)
    ("Genesis", "OT"), ("Exodus", "OT"), ("Leviticus", "OT"), ("Numbers", "OT"), ("Deuteronomy", "OT"),
    ("Joshua", "OT"), ("Judges", "OT"), ("Ruth", "OT"), ("1 Samuel", "OT"), ("2 Samuel", "OT"),
    ("1 Kings", "OT"), ("2 Kings", "OT"), ("1 Chronicles", "OT"), ("2 Chronicles", "OT"),
    ("Ezra", "OT"), ("Nehemiah", "OT"), ("Esther", "OT"), ("Job", "OT"), ("Psalms", "OT"), ("Proverbs", "OT"),
    ("Ecclesiastes", "OT"), ("Song of Solomon", "OT"), ("Isaiah", "OT"), ("Jeremiah", "OT"),
    ("Lamentations", "OT"), ("Ezekiel", "OT"), ("Daniel", "OT"), ("Hosea", "OT"), ("Joel", "OT"), ("Amos", "OT"),
    ("Obadiah", "OT"), ("Jonah", "OT"), ("Micah", "OT"), ("Nahum", "OT"), ("Habakkuk", "OT"), ("Zephaniah", "OT"),
    ("Haggai", "OT"), ("Zechariah", "OT"), ("Malachi", "OT"),
    # New Testament (40..66)
    ("Matthew", "NT"), ("Mark", "NT"), ("Luke", "NT"), ("John", "NT"), ("Acts", "NT"), ("Romans", "NT"),
    ("1 Corinthians", "NT"), ("2 Corinthians", "NT"), ("Galatians", "NT"), ("Ephesians", "NT"),
    ("Philippians", "NT"), ("Colossians", "NT"), ("1 Thessalonians", "NT"), ("2 Thessalonians", "NT"),
    ("1 Timothy", "NT"), ("2 Timothy", "NT"), ("Titus", "NT"), ("Philemon", "NT"), ("Hebrews", "NT"),
    ("James", "NT"), ("1 Peter", "NT"), ("2 Peter", "NT"), ("1 John", "NT"), ("2 John", "NT"), ("3 John", "NT"),
    ("Jude", "NT"), ("Revelation", "NT")
]

BOOK_NAME_TO_NUM = {name: i + 1 for i, (name, _) in enumerate(CANONICAL_BOOKS)}
# Add alternate aliases
BOOK_NAME_TO_NUM["Psalm"] = BOOK_NAME_TO_NUM["Psalms"]

def build_sqlite_from_json(json_file_path, db_file_path):
    print(f"Reading {json_file_path}...")
    with open(json_file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    translation_code = data.get("translation", "KJV")
    translation_name = data.get("name", "King James Version")
    books_dict = data.get("books", {})

    if db_file_path.exists():
        db_file_path.unlink()

    conn = sqlite3.connect(str(db_file_path))
    cursor = conn.cursor()

    # Create Schema
    cursor.execute("""
        CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE books (
            id INTEGER PRIMARY KEY,
            book_number INTEGER NOT NULL UNIQUE,
            name TEXT NOT NULL,
            testament TEXT NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation TEXT NOT NULL,
            book_number INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL
        );
    """)

    # Populate metadata
    cursor.execute("INSERT INTO meta (key, value) VALUES ('translation', ?)", (translation_code,))
    cursor.execute("INSERT INTO meta (key, value) VALUES ('name', ?)", (translation_name,))

    # Populate books table
    for book_num, (name, testament) in enumerate(CANONICAL_BOOKS, start=1):
        cursor.execute("INSERT INTO books (book_number, name, testament) VALUES (?, ?, ?)",
                       (book_num, name, testament))

    total_verses = 0
    total_chapters = 0

    # Populate verses table
    verses_rows = []
    for raw_book_name, chapters in books_dict.items():
        book_num = BOOK_NAME_TO_NUM.get(raw_book_name)
        if not book_num:
            print(f"  Warning: Unknown book name '{raw_book_name}'")
            continue

        for ch_str, verse_list in chapters.items():
            ch_num = int(ch_str)
            total_chapters += 1
            for v_idx, v_text in enumerate(verse_list, start=1):
                verses_rows.append((translation_code, book_num, ch_num, v_idx, v_text))
                total_verses += 1

    cursor.executemany("""
        INSERT INTO verses (translation, book_number, chapter, verse, text)
        VALUES (?, ?, ?, ?, ?)
    """, verses_rows)

    # Create Fast Indexes
    cursor.execute("CREATE INDEX idx_verses_lookup ON verses(translation, book_number, chapter);")
    cursor.execute("CREATE INDEX idx_verses_book_ch ON verses(book_number, chapter);")

    conn.commit()
    conn.close()

    print(f"✅ Generated {db_file_path.name}: {len(books_dict)} books, {total_chapters} chapters, {total_verses} verses ({db_file_path.stat().st_size / 1024 / 1024:.2f} MB)")

def main():
    bible_dir = Path(__file__).parent.parent / "assets" / "bible"
    kjv_json = bible_dir / "kjv.json"
    web_json = bible_dir / "web.json"
    bsb_json = bible_dir / "bsb.json"

    if kjv_json.exists():
        build_sqlite_from_json(kjv_json, bible_dir / "kjv.db")
    else:
        print(f"Error: {kjv_json} not found")

    if web_json.exists():
        build_sqlite_from_json(web_json, bible_dir / "web.db")
    else:
        print(f"Error: {web_json} not found")

    if bsb_json.exists():
        build_sqlite_from_json(bsb_json, bible_dir / "bsb.db")
    else:
        print(f"Error: {bsb_json} not found")

if __name__ == "__main__":
    main()