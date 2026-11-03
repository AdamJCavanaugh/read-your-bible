import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ScriptureService {
  static final ScriptureService _instance = ScriptureService._internal();
  factory ScriptureService() => _instance;
  ScriptureService._internal();

  final Map<String, Database> _databases = {};
  final Map<String, List<String>> _verseCache = {};
  final Map<String, Map<int, Map<int, int>>> _verseCountCache = {};
  final Set<String> _installedTranslations = {'KJV'};
  final Map<String, double> _downloadProgress = {};

  // GitHub Release download URLs
  // Updated for: https://github.com/AdamJCavanaugh/read-your-bible/releases/tag/bibles-v1.0.0
  static const Map<String, String> _downloadUrls = {
    'WEB': 'https://github.com/AdamJCavanaugh/read-your-bible/releases/download/bibles-v1.0.0/web.db',
    'BSB': 'https://github.com/AdamJCavanaugh/read-your-bible/releases/download/bibles-v1.0.0/bsb.db',
  };

  // Expected SHA-256 checksums for integrity verification
  static const Map<String, String> _expectedChecksums = {
    'WEB': '8362a8acadbbcb8031f46a29da8d815267217a4ed4641dac5d566cf9b0e61456',
    'BSB': 'f88b745bc556684e8cdb64c8ceabfc32ffec0040c8edee0758407549d67914b4',
  };

  // Expected file sizes in bytes (for progress calculation)
  static const Map<String, int> _expectedSizes = {
    'WEB': 5586944, // 5.33 MB
    'BSB': 5328896, // 5.08 MB
  };

  static const Map<String, int> bookNameToNum = {
    'Genesis': 1, 'Exodus': 2, 'Leviticus': 3, 'Numbers': 4, 'Deuteronomy': 5,
    'Joshua': 6, 'Judges': 7, 'Ruth': 8, '1 Samuel': 9, '2 Samuel': 10,
    '1 Kings': 11, '2 Kings': 12, '1 Chronicles': 13, '2 Chronicles': 14,
    'Ezra': 15, 'Nehemiah': 16, 'Esther': 17, 'Job': 18, 'Psalms': 19, 'Psalm': 19,
    'Proverbs': 20, 'Ecclesiastes': 21, 'Song of Solomon': 22, 'Isaiah': 23,
    'Jeremiah': 24, 'Lamentations': 25, 'Ezekiel': 26, 'Daniel': 27, 'Hosea': 28,
    'Joel': 29, 'Amos': 30, 'Obadiah': 31, 'Jonah': 32, 'Micah': 33, 'Nahum': 34,
    'Habakkuk': 35, 'Zephaniah': 36, 'Haggai': 37, 'Zechariah': 38, 'Malachi': 39,
    'Matthew': 40, 'Mark': 41, 'Luke': 42, 'John': 43, 'Acts': 44, 'Romans': 45,
    '1 Corinthians': 46, '2 Corinthians': 47, 'Galatians': 48, 'Ephesians': 49,
    'Philippians': 50, 'Colossians': 51, '1 Thessalonians': 52, '2 Thessalonians': 53,
    '1 Timothy': 54, '2 Timothy': 55, 'Titus': 56, 'Philemon': 57, 'Hebrews': 58,
    'James': 59, '1 Peter': 60, '2 Peter': 61, '1 John': 62, '2 John': 63, '3 John': 64,
    'Jude': 65, 'Revelation': 66
  };

  Set<String> get installedTranslations => Set.unmodifiable(_installedTranslations);

  bool isInstalled(String translation) => _installedTranslations.contains(translation);

  double getDownloadProgress(String translation) => _downloadProgress[translation] ?? 0.0;

  bool isDownloading(String translation) {
    final prog = _downloadProgress[translation];
    return prog != null && prog > 0.0 && prog < 1.0;
  }

  Future<void> init() async {
    if (kIsWeb) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (e) {
      debugPrint('SQLite FFI Init error: $e');
    }

    // KJV is always bundled
    await _loadBundledDatabase('KJV');
  }

  Future<void> _loadBundledDatabase(String translation) async {
    if (_databases.containsKey(translation)) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(join(docDir.path, 'read_your_bible_databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      final dbPath = join(dbDir.path, '${translation.toLowerCase()}.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists() || await dbFile.length() < 1000) {
        try {
          final byteData = await rootBundle.load('assets/bible/${translation.toLowerCase()}.db');
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          await dbFile.writeAsBytes(bytes, flush: true);
        } catch (e) {
          debugPrint('Error writing $translation DB asset to disk: $e');
        }
      }

      if (await dbFile.exists()) {
        final db = await openDatabase(dbPath, readOnly: true);
        _databases[translation] = db;
        _installedTranslations.add(translation);
        await _loadVerseCounts(translation);
      }
    } catch (e) {
      debugPrint('Error loading $translation database: $e');
    }
  }

  Future<void> _loadVerseCounts(String translation) async {
    final db = _databases[translation];
    if (db == null) return;

    try {
      final results = await db.rawQuery('''
        SELECT book_number, chapter, MAX(verse) as verse_count
        FROM verses
        WHERE translation = ?
        GROUP BY book_number, chapter
        ORDER BY book_number, chapter
      ''', [translation]);

      final Map<int, Map<int, int>> bookChapterCounts = {};
      for (final row in results) {
        final bookNum = row['book_number'] as int;
        final chapter = row['chapter'] as int;
        final verseCount = row['verse_count'] as int;
        bookChapterCounts.putIfAbsent(bookNum, () => {})[chapter] = verseCount;
      }
      _verseCountCache[translation] = bookChapterCounts;
    } catch (e) {
      debugPrint('Error loading verse counts for $translation: $e');
    }
  }

  // Download translation from GitHub Releases
  Future<void> downloadTranslation(
    String translation, {
    required void Function(double progress) onProgress,
  }) async {
    if (_installedTranslations.contains(translation) && _databases.containsKey(translation)) return;
    if (translation == 'KJV') return; // KJV is bundled

    final url = _downloadUrls[translation];
    final expectedSize = _expectedSizes[translation] ?? 0;
    final expectedChecksum = _expectedChecksums[translation] ?? '';

    if (url == null || url.contains('<your-username>')) {
      throw Exception('Download URL not configured for $translation. Please update _downloadUrls in scripture_service.dart');
    }

    _downloadProgress[translation] = 0.0;
    onProgress(0.0);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(join(docDir.path, 'read_your_bible_databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      final dbPath = join(dbDir.path, '${translation.toLowerCase()}.db');
      final dbFile = File(dbPath);

      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download $translation: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? expectedSize;
      var received = 0;
      final sink = dbFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloadProgress[translation] = received / contentLength;
          onProgress(_downloadProgress[translation]!);
        }
      }
      await sink.flush();
      await sink.close();
      client.close();

      // Verify file size
      final actualSize = await dbFile.length();
      if (expectedSize > 0 && actualSize != expectedSize) {
        debugPrint('Warning: $translation size mismatch. Expected: $expectedSize, Got: $actualSize');
      }

      // Verify checksum if provided
      if (expectedChecksum.isNotEmpty) {
        final bytes = await dbFile.readAsBytes();
        final digest = sha256.convert(bytes);
        final actualChecksum = digest.toString();
        if (actualChecksum.toLowerCase() != expectedChecksum.toLowerCase()) {
          await dbFile.delete();
          throw Exception('Checksum verification failed for $translation. File may be corrupted.');
        }
      }

      // Open database
      final db = await openDatabase(dbPath, readOnly: true);
      _databases[translation] = db;
      _installedTranslations.add(translation);
      _downloadProgress[translation] = 1.0;
      onProgress(1.0);

      await _loadVerseCounts(translation);
    } catch (e) {
      _downloadProgress.remove(translation);
      rethrow;
    }
  }

  // Delete downloaded translation
  void deleteTranslation(String translation) {
    if (translation == 'KJV') return;
    final db = _databases.remove(translation);
    db?.close();
    _installedTranslations.remove(translation);
    _downloadProgress.remove(translation);
    _verseCache.removeWhere((key, _) => key.startsWith('$translation:'));
    _verseCountCache.remove(translation);

    // Delete file from disk
    _deleteDatabaseFile(translation);
  }

  Future<void> _deleteDatabaseFile(String translation) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docDir.path, 'read_your_bible_databases', '${translation.toLowerCase()}.db');
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting $translation database file: $e');
    }
  }

  // Async query for chapter verses from SQLite database
  Future<List<String>> fetchVersesAsync({
    required String book,
    required int chapter,
    required String translation,
  }) async {
    final bookNum = bookNameToNum[book] ?? 1;
    final activeTrans = _databases.containsKey(translation) ? translation : 'KJV';
    final cacheKey = '$activeTrans:$bookNum:$chapter';

    if (_verseCache.containsKey(cacheKey)) {
      return _verseCache[cacheKey]!;
    }

    final db = _databases[activeTrans] ?? _databases['KJV'];
    if (db != null && db.isOpen) {
      try {
        final results = await db.query(
          'verses',
          columns: ['text'],
          where: 'book_number = ? AND chapter = ?',
          whereArgs: [bookNum, chapter],
          orderBy: 'verse ASC',
        );

        if (results.isNotEmpty) {
          final verses = results.map((row) => row['text'].toString()).toList();
          _verseCache[cacheKey] = verses;
          return verses;
        }
      } catch (e) {
        debugPrint('Query verses error ($activeTrans $book $chapter): $e');
      }
    }

    return [
      'In the beginning God created the heavens and the earth.',
      'Your word is a lamp unto my feet and a light unto my path.',
    ];
  }

  // Synchronous verse accessor for reader view using cache / instant lookup
  List<String> getVerses({
    required String book,
    required String chapter,
    required String translation,
  }) {
    final chNum = int.tryParse(chapter) ?? 1;
    final bookNum = bookNameToNum[book] ?? 1;
    final activeTrans = _databases.containsKey(translation) ? translation : 'KJV';
    final cacheKey = '$activeTrans:$bookNum:$chNum';

    if (_verseCache.containsKey(cacheKey)) {
      return _verseCache[cacheKey]!;
    }

    // Trigger async fetch to populate cache for subsequent builds
    fetchVersesAsync(book: book, chapter: chNum, translation: activeTrans);

    return [
      'Loading scripture passage...',
    ];
  }

  // Accurate verse count from pre-loaded database cache
  int getVerseCount(String book, int chapter) {
    for (final trans in ['KJV', 'WEB', 'BSB']) {
      if (_verseCountCache.containsKey(trans)) {
        final bookCache = _verseCountCache[trans]![bookNameToNum[book] ?? 1];
        if (bookCache != null && bookCache.containsKey(chapter)) {
          return bookCache[chapter]!;
        }
      }
    }
    return 25;
  }

  // Human-readable file size
  String getFileSizeDisplay(String translation) {
    final size = _expectedSizes[translation];
    if (size == null) return 'Unknown size';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}