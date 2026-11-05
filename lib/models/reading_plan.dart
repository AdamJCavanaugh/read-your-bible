import 'bible_data.dart';

class Passage {
  final String book;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final List<String> verses;

  const Passage({
    required this.book,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.verses,
  });

  String get formattedRange {
    if (startChapter == endChapter) {
      final totalVs = BibleData.getVerseCount(book, startChapter);
      if (startVerse == 1 && endVerse >= totalVs) {
        return '$book $startChapter';
      }
      return '$book $startChapter:$startVerse–$endVerse';
    }
    return '$book $startChapter:$startVerse–$endChapter:$endVerse';
  }

  Passage copyWith({
    String? book,
    int? startChapter,
    int? startVerse,
    int? endChapter,
    int? endVerse,
    List<String>? verses,
  }) {
    return Passage(
      book: book ?? this.book,
      startChapter: startChapter ?? this.startChapter,
      startVerse: startVerse ?? this.startVerse,
      endChapter: endChapter ?? this.endChapter,
      endVerse: endVerse ?? this.endVerse,
      verses: verses ?? this.verses,
    );
  }
}

class DailyReading {
  final String id;
  final int dayNumber;
  final String title;
  final List<Passage> passages;
  final int estimatedMinutes;
  final String keyVerse;
  final String keyVerseReference;

  const DailyReading({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.passages,
    required this.estimatedMinutes,
    required this.keyVerse,
    required this.keyVerseReference,
  });

  DailyReading copyWith({
    String? title,
    List<Passage>? passages,
    int? estimatedMinutes,
    String? keyVerse,
    String? keyVerseReference,
  }) {
    return DailyReading(
      id: id,
      dayNumber: dayNumber,
      title: title ?? this.title,
      passages: passages ?? this.passages,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      keyVerse: keyVerse ?? this.keyVerse,
      keyVerseReference: keyVerseReference ?? this.keyVerseReference,
    );
  }
}

class ReadingPlan {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int durationDays;
  final String category;
  final String subscribersCount;
  final bool isFeatured;
  final List<DailyReading> readings;
  final DateTime startDate; // When the plan starts (day 1)

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.durationDays,
    required this.category,
    required this.subscribersCount,
    this.isFeatured = false,
    required this.readings,
    required this.startDate,
  });

  // Current day index based on actual date (0-indexed)
  int getCurrentDayIndex() {
    final daysSinceStart = DateTime.now().difference(startDate).inDays;
    return daysSinceStart.clamp(0, durationDays - 1);
  }

  // Whether today's reading for this plan is available (plan has started)
  bool get hasStarted =>
      DateTime.now().isAfter(startDate.subtract(const Duration(days: 1)));

  // Whether the plan is complete (all days passed)
  bool get isFinished {
    final daysSinceStart = DateTime.now().difference(startDate).inDays;
    return daysSinceStart >= durationDays;
  }

  // Days remaining in plan
  int get daysRemaining {
    final daysSinceStart = DateTime.now().difference(startDate).inDays;
    return (durationDays - daysSinceStart).clamp(0, durationDays);
  }

  ReadingPlan copyWith({
    String? title,
    String? subtitle,
    String? description,
    String? category,
    List<DailyReading>? readings,
    DateTime? startDate,
  }) {
    return ReadingPlan(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      durationDays: durationDays,
      category: category ?? this.category,
      subscribersCount: subscribersCount,
      isFeatured: isFeatured,
      readings: readings ?? this.readings,
      startDate: startDate ?? this.startDate,
    );
  }
}

// Default list is empty
final List<ReadingPlan> mockReadingPlans = [];

class _VerseRef {
  final String book;
  final int chapter;
  final int verse;
  _VerseRef(this.book, this.chapter, this.verse);
}

// Word-Count & Verse-Balanced Sequential Plan Generator with Strict Non-Overlapping Boundaries
ReadingPlan createCustomReadingPlan({
  required String title,
  required int durationDays,
  required List<String> selectedBooks,
  required int repeatCount,
  String? description,
  DateTime? startDate, // NEW: optional start date, defaults to today
}) {
  final totalDays = durationDays * repeatCount;
  final planId = 'custom_plan_${DateTime.now().millisecondsSinceEpoch}';
  final booksList = selectedBooks.isEmpty ? ['Genesis'] : selectedBooks;

  final bookSummary = selectedBooks.length == 66
      ? 'Whole Bible'
      : (selectedBooks.length == 39 && selectedBooks.first == 'Genesis'
            ? 'Old Testament'
            : (selectedBooks.length == 27 && selectedBooks.first == 'Matthew'
                  ? 'New Testament'
                  : (selectedBooks.length <= 3
                        ? selectedBooks.join(', ')
                        : '${selectedBooks.length} Selected Books')));

  // 1. Build a complete, flat sequential list of every single verse across all selected books
  final allSequentialVerses = <_VerseRef>[];
  for (final book in booksList) {
    final chapterCount = BibleData.chapterCounts[book] ?? 10;
    for (int ch = 1; ch <= chapterCount; ch++) {
      final verseCount = BibleData.getVerseCount(book, ch);
      for (int v = 1; v <= verseCount; v++) {
        allSequentialVerses.add(_VerseRef(book, ch, v));
      }
    }
  }

  final totalVerseCount = allSequentialVerses.length;
  final generatedReadings = <DailyReading>[];

  // Default start date to today if not provided
  final effectiveStartDate = startDate ?? DateTime.now();

  // 2. Partition verses evenly with ZERO overlapping boundary verses
  for (int cycle = 1; cycle <= repeatCount; cycle++) {
    int currentVerseIndex = 0;

    for (int day = 1; day <= durationDays; day++) {
      final overallDayNumber = (cycle - 1) * durationDays + day;

      final startIdx = currentVerseIndex;
      int endIdx = ((day * totalVerseCount) / durationDays).round() - 1;
      if (day == durationDays) endIdx = totalVerseCount - 1;

      if (endIdx < startIdx) endIdx = startIdx;
      endIdx = endIdx.clamp(0, totalVerseCount - 1);

      final dayVerseSlice = allSequentialVerses.sublist(startIdx, endIdx + 1);

      // Advance pointer strictly past endIdx for next day to guarantee no duplicate boundary verses
      currentVerseIndex = endIdx + 1;

      // Group consecutive verses in the day's slice into clean Passage ranges
      final passages = <Passage>[];
      if (dayVerseSlice.isNotEmpty) {
        var firstVerse = dayVerseSlice.first;
        var prevVerse = firstVerse;

        for (int i = 1; i < dayVerseSlice.length; i++) {
          final currVerse = dayVerseSlice[i];
          if (currVerse.book != prevVerse.book) {
            passages.add(
              Passage(
                book: firstVerse.book,
                startChapter: firstVerse.chapter,
                startVerse: firstVerse.verse,
                endChapter: prevVerse.chapter,
                endVerse: prevVerse.verse,
                verses: [],
              ),
            );
            firstVerse = currVerse;
          }
          prevVerse = currVerse;
        }

        passages.add(
          Passage(
            book: firstVerse.book,
            startChapter: firstVerse.chapter,
            startVerse: firstVerse.verse,
            endChapter: prevVerse.chapter,
            endVerse: prevVerse.verse,
            verses: [],
          ),
        );
      }

      final passageTitle = passages.map((p) => p.formattedRange).join(' & ');
      final repeatLabel = repeatCount > 1 ? ' (Cycle $cycle/$repeatCount)' : '';

      final firstP = passages.isNotEmpty ? passages.first : null;
      final keyVerseRef = firstP != null
          ? '${firstP.book} ${firstP.startChapter}:${firstP.startVerse}'
          : 'Genesis 1:1';

      generatedReadings.add(
        DailyReading(
          id: '${planId}_day_$overallDayNumber',
          dayNumber: overallDayNumber,
          title: '$passageTitle$repeatLabel',
          estimatedMinutes: (dayVerseSlice.length / 20).ceil().clamp(3, 30),
          keyVerse: 'Your word is a lamp for my feet, a light on my path.',
          keyVerseReference: keyVerseRef,
          passages: passages,
        ),
      );
    }
  }

  return ReadingPlan(
    id: planId,
    title: title.trim().isEmpty ? 'Custom Plan: $bookSummary' : title.trim(),
    subtitle:
        '$bookSummary • $durationDays Days${repeatCount > 1 ? ' ($repeatCount repeats)' : ''}',
    description: description?.trim().isNotEmpty == true
        ? description!
        : 'A personalized $totalDays-day reading plan covering $bookSummary sequentially over $durationDays days with $repeatCount repeat cycle(s).',
    durationDays: totalDays,
    category: 'Custom',
    subscribersCount: 'Personal Plan',
    isFeatured: false,
    readings: generatedReadings,
    startDate: startDate ?? DateTime.now(), // Default to today
  );
}
