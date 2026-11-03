#!/usr/bin/env python3
"""
Download complete KJV Bible from aruljohn/Bible-kjv GitHub repository
and combine into the format our Flutter app expects.
"""

import json
import urllib.request
import urllib.parse
import sys
from pathlib import Path

BASE_URL = "https://raw.githubusercontent.com/aruljohn/Bible-kjv/master/"

BOOKS = [
    "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
    "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
    "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
    "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
    "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah",
    "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
    "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah",
    "Haggai", "Zechariah", "Malachi",
    "Matthew", "Mark", "Luke", "John", "Acts", "Romans",
    "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
    "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
    "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews",
    "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
    "Jude", "Revelation"
]

def fetch_book(book_name):
    """Fetch a single book's JSON from GitHub raw."""
    # URL encode the book name for spaces
    encoded_name = urllib.parse.quote(book_name)
    url = f"{BASE_URL}{encoded_name}.json"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode('utf-8'))
        return data
    except Exception as e:
        print(f"Error fetching {book_name}: {e}")
        return None

def convert_book_format(book_name, book_data):
    """Convert aruljohn format to our app's format.

    aruljohn format: { "book": "Genesis", "chapters": [ { "chapter": "1", "verses": [ { "verse": "1", "text": "..." }, ... ] }, ... ] }
    Our format: { "1": ["verse1", "verse2", ...], "2": [...] }
    """
    chapters = {}

    for chapter_obj in book_data.get("chapters", []):
        chapter_num = chapter_obj["chapter"]  # Already string
        verses = []

        for verse_obj in chapter_obj.get("verses", []):
            verse_text = verse_obj["text"].strip()
            verses.append(verse_text)

        chapters[chapter_num] = verses

    return chapters

def main():
    output_dir = Path(__file__).parent.parent / "assets" / "bible"
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Downloading KJV Bible from {BASE_URL}...")

    all_books = {}
    total_verses = 0
    total_chapters = 0

    for book in BOOKS:
        print(f"  Fetching {book}...")
        book_data = fetch_book(book)

        if book_data:
            chapters = convert_book_format(book, book_data)
            all_books[book] = chapters
            total_chapters += len(chapters)
            total_verses += sum(len(v) for v in chapters.values())
            print(f"    {len(chapters)} chapters, {sum(len(v) for v in chapters.values())} verses")
        else:
            print(f"    FAILED")

    # Build the final JSON structure
    kjv_json = {
        "translation": "KJV",
        "name": "King James Version",
        "language": "English",
        "books": all_books
    }

    output_file = output_dir / "kjv.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(kjv_json, f, ensure_ascii=False, separators=(',', ':'))

    print(f"\n✅ Complete! Saved to {output_file}")
    print(f"   Books: {len(all_books)}")
    print(f"   Chapters: {total_chapters}")
    print(f"   Verses: {total_verses}")
    print(f"   File size: {output_file.stat().st_size / 1024 / 1024:.2f} MB")

if __name__ == "__main__":
    main()