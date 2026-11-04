import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_plan.dart';
import '../models/bible_data.dart';
import '../services/scripture_service.dart';

class AppState extends ChangeNotifier {
  final ScriptureService _scriptureService = ScriptureService();

  // Theme state
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Combine Plans Toggle Setting
  bool _combinePlansOnToday = false;
  bool get combinePlansOnToday => _combinePlansOnToday;

  void setCombinePlansOnToday(bool value) {
    if (_combinePlansOnToday != value) {
      _combinePlansOnToday = value;
      notifyListeners();
    }
  }

  // Scripture Reader Settings - Default to KJV (Bundled)
  String _selectedTranslation = 'KJV';
  String get selectedTranslation => _selectedTranslation;

  Set<String> get installedTranslations =>
      _scriptureService.installedTranslations;

  bool isTranslationInstalled(String code) =>
      _scriptureService.isInstalled(code);

  double getTranslationDownloadProgress(String code) =>
      _scriptureService.getDownloadProgress(code);

  bool isTranslationDownloading(String code) =>
      _scriptureService.isDownloading(code);

  String getTranslationDownloadSize(String code) =>
      _scriptureService.getFileSizeDisplay(code);

  double _fontSize = 18.0;
  double get fontSize => _fontSize;

  bool _isSerifFont = true;
  bool get isSerifFont => _isSerifFont;

  // Bible Reading State (Global position across translations)
  String _bibleCurrentBook = 'Genesis';
  String get bibleCurrentBook => _bibleCurrentBook;

  int _bibleCurrentChapter = 1;
  int get bibleCurrentChapter => _bibleCurrentChapter;

  int _bibleCurrentVerse = 1;
  int get bibleCurrentVerse => _bibleCurrentVerse;

  void setBibleBook(String book) {
    if (_bibleCurrentBook != book) {
      _bibleCurrentBook = book;
      _bibleCurrentChapter = 1;
      _bibleCurrentVerse = 1;
      notifyListeners();
    }
  }

  void setBibleChapter(int chapter) {
    if (_bibleCurrentChapter != chapter) {
      _bibleCurrentChapter = chapter;
      _bibleCurrentVerse = 1;
      notifyListeners();
    }
  }

  void setBibleVerse(int verse) {
    if (_bibleCurrentVerse != verse) {
      _bibleCurrentVerse = verse;
      notifyListeners();
    }
  }

  // Notifications State
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay get reminderTime => _reminderTime;

  // Plans List & Per-Plan Progress Tracking
  final List<ReadingPlan> _allPlans = [];
  List<ReadingPlan> get allPlans => List.unmodifiable(_allPlans);

  ReadingPlan? _activePlan;
  ReadingPlan? get activePlan => _allPlans.isNotEmpty ? _activePlan : null;

  // Map of Plan ID -> Set of completed date strings (YYYY-MM-DD)
  final Map<String, Set<String>> _planCompletedDates = {};

  int _streakCount = 0;
  int get streakCount => _streakCount;

  int _longestStreak = 0;
  int get longestStreak => _longestStreak;

  int _totalChaptersRead = 0;
  int get totalChaptersRead => _totalChaptersRead;

  int _totalMinutesRead = 0;
  int get totalMinutesRead => _totalMinutesRead;

  final int _booksCompleted = 0;
  int get booksCompleted => _booksCompleted;

  final List<int> _weeklyMinutes = [0, 0, 0, 0, 0, 0, 0];
  List<int> get weeklyMinutes => List.unmodifiable(_weeklyMinutes);

  AppState() {
    _initScriptures();
    _initDefaultPlans();
  }

  // Initialize default plans on first launch
  Future<void> _initDefaultPlans() async {
    // Check if default plans have been initialized
    const defaultPlansKey = 'default_plans_initialized';
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(defaultPlansKey) ?? false;

    if (!initialized) {
      // Create Alphabetical Plan
      final alphabeticalPlan = createCustomReadingPlan(
        title: 'Alphabetical Bible',
        durationDays: 365,
        selectedBooks: BibleData.alphabeticalBooks,
        repeatCount: 1,
        description:
            'Read through the entire Bible in alphabetical order (Acts → Zephaniah). '
            'Numbered books sort naturally by their full name (1 Chronicles, 1 Corinthians, etc.).',
        startDate: DateTime.now(),
      );

      // Create Chronological Plan
      final chronologicalPlan = createCustomReadingPlan(
        title: 'Chronological Bible',
        durationDays: 365,
        selectedBooks: BibleData.chronologicalBooks,
        repeatCount: 1,
        description:
            'Read through the entire Bible in historical chronological order '
            '(Genesis → Job → Exodus → ... → Revelation). '
            'Based on the timeline of biblical events.',
        startDate: DateTime.now(),
      );

      // Add to plans list
      _allPlans.addAll([alphabeticalPlan, chronologicalPlan]);

      // Mark as initialized
      await prefs.setBool(defaultPlansKey, true);
      notifyListeners();
    }
  }

  Future<void> _initScriptures() async {
    await _scriptureService.init();
    notifyListeners();
  }

  // Download translation on demand
  Future<void> downloadTranslation(String translation) async {
    await _scriptureService.downloadTranslation(
      translation,
      onProgress: (progress) {
        notifyListeners();
      },
    );
    // Note: Does not auto-switch translation. Caller should call setTranslation() after successful download.
    notifyListeners();
  }

  // Delete downloaded translation
  void deleteTranslation(String translation) {
    if (translation == 'KJV') return;
    _scriptureService.deleteTranslation(translation);
    if (_selectedTranslation == translation) {
      _selectedTranslation = 'KJV';
    }
    notifyListeners();
  }

  Future<List<String>> getVersesForPassageAsync(
    String book,
    String chapter,
  ) async {
    final chNum = int.tryParse(chapter) ?? 1;
    return await _scriptureService.fetchVersesAsync(
      book: book,
      chapter: chNum,
      translation: _selectedTranslation,
    );
  }

  List<String>? getVersesForPassage(String book, String chapter) {
    return _scriptureService.getVerses(
      book: book,
      chapter: chapter,
      translation: _selectedTranslation,
    );
  }

  // Date-based completion helpers
  // Get today's date string for a specific plan (based on plan's start date)
  String _getTodayStringForPlan(ReadingPlan plan) {
    return DateTime.now().toIso8601String().split('T').first;
  }

  // Check if a specific date is completed for a plan
  bool isDateCompletedForPlan(String planId, String dateStr) {
    return _planCompletedDates[planId]?.contains(dateStr) ?? false;
  }

  // Check if today is completed for a plan
  bool isTodayCompletedForPlan(String planId) {
    final plan = _allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _allPlans.first,
    );
    if (!plan.hasStarted) return false;
    final todayStr = _getTodayStringForPlan(plan);
    return isDateCompletedForPlan(planId, todayStr);
  }

  // Get completed dates for a plan
  Set<String> getCompletedDatesForPlan(String planId) {
    return Set.unmodifiable(_planCompletedDates[planId] ?? {});
  }

  // Get plan progress percentage
  double getPlanProgressPercentage(String planId) {
    final plan = _allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _allPlans.first,
    );
    if (plan.durationDays == 0) return 0.0;
    final completedCount = _planCompletedDates[planId]?.length ?? 0;
    return (completedCount / plan.durationDays).clamp(0.0, 1.0);
  }

  bool isPlanFullyCompleted(String planId) {
    final plan = _allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _allPlans.first,
    );
    if (plan.durationDays == 0) return false;
    final completedCount = _planCompletedDates[planId]?.length ?? 0;
    return completedCount >= plan.durationDays;
  }

  // Toggle completion for today
  void togglePlanDayCompletion(String planId, int dayIndex) {
    final plan = _allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _allPlans.first,
    );

    // Only allow completion if plan has started
    if (!plan.hasStarted) return;

    // Use today's actual date
    final todayStr = _getTodayStringForPlan(plan);

    _planCompletedDates.putIfAbsent(planId, () => {});
    final completedSet = _planCompletedDates[planId]!;

    final reading =
        (plan.getCurrentDayIndex() >= 0 &&
            plan.getCurrentDayIndex() < plan.readings.length)
        ? plan.readings[plan.getCurrentDayIndex()]
        : null;

    if (completedSet.contains(todayStr)) {
      completedSet.remove(todayStr);
      _totalChaptersRead = (_totalChaptersRead - 3).clamp(0, 9999);
      _recalculateStreak();
    } else {
      completedSet.add(todayStr);
      _totalChaptersRead += 3;
      if (reading != null) {
        _totalMinutesRead += reading.estimatedMinutes;
        _weeklyMinutes[6] = (_weeklyMinutes[6] + reading.estimatedMinutes);
      }
      _recalculateStreak();
    }
    notifyListeners();
  }

  // Combined completion toggle for all active plans today
  void toggleAllPlansTodayCompletion() {
    final plans = _allPlans
        .where((p) => p.readings.isNotEmpty && p.hasStarted)
        .toList();
    if (plans.isEmpty) return;

    final allCompleted = plans.every((p) => isTodayCompletedForPlan(p.id));

    for (final plan in plans) {
      _planCompletedDates.putIfAbsent(plan.id, () => {});
      final completedSet = _planCompletedDates[plan.id]!;
      final todayStr = _getTodayStringForPlan(plan);

      if (allCompleted) {
        completedSet.remove(todayStr);
      } else {
        completedSet.add(todayStr);
      }
    }

    _recalculateStreak();
    notifyListeners();
  }

  bool areAllPlansCompletedToday() {
    final plans = _allPlans
        .where((p) => p.readings.isNotEmpty && p.hasStarted)
        .toList();
    if (plans.isEmpty) return false;
    return plans.every((p) => isTodayCompletedForPlan(p.id));
  }

  // Get current day index for a plan based on actual date
  int getCurrentDayIndexForPlan(String planId) {
    final plan = _allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => _allPlans.first,
    );
    return plan.getCurrentDayIndex();
  }

  // Streak calculation: consecutive days backwards from today where ALL active plans completed
  void _recalculateStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Only check past dates (today and backwards)
    while (true) {
      final dateStr = checkDate.toIso8601String().split('T').first;

      // Get all plans that should have readings on this date
      final applicablePlans = _allPlans.where((p) {
        if (!p.hasStarted) return false;
        if (checkDate.isBefore(p.startDate)) return false;
        final daysSinceStart = checkDate.difference(p.startDate).inDays;
        return daysSinceStart < p.durationDays;
      }).toList();

      if (applicablePlans.isEmpty) break;

      final allCompleted = applicablePlans.every(
        (p) => _planCompletedDates[p.id]?.contains(dateStr) ?? false,
      );

      if (allCompleted) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    _streakCount = streak;
    if (_streakCount > _longestStreak) _longestStreak = _streakCount;
  }

  // Get today's reading for active plan
  DailyReading? get todayReading {
    final plan = activePlan;
    if (plan == null || plan.readings.isEmpty) return null;
    if (!plan.hasStarted) return null;

    final dayIndex = plan.getCurrentDayIndex();
    if (dayIndex >= 0 && dayIndex < plan.readings.length) {
      return plan.readings[dayIndex];
    }
    return plan.readings.first;
  }

  bool get isTodayCompleted =>
      activePlan != null ? isTodayCompletedForPlan(activePlan!.id) : false;

  double get planProgressPercentage =>
      activePlan != null ? getPlanProgressPercentage(activePlan!.id) : 0.0;

  // Plan deletion
  void deletePlan(String planId) {
    _allPlans.removeWhere((p) => p.id == planId);
    _planCompletedDates.remove(planId);
    if (_activePlan?.id == planId) {
      _activePlan = _allPlans.isNotEmpty ? _allPlans.first : null;
    }
    _recalculateStreak();
    notifyListeners();
  }

  // State mutation actions
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setTranslation(String translation) {
    if (_selectedTranslation != translation) {
      _selectedTranslation = translation;
      notifyListeners();
    }
  }

  void setFontSize(double size) {
    if (_fontSize != size) {
      _fontSize = size;
      notifyListeners();
    }
  }

  void toggleSerifFont() {
    _isSerifFont = !_isSerifFont;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    notifyListeners();
  }

  void toggleTodayCompletion() {
    if (activePlan != null) {
      togglePlanDayCompletion(activePlan!.id, activePlan!.getCurrentDayIndex());
    }
  }

  void setActivePlan(ReadingPlan plan) {
    _activePlan = plan;
    notifyListeners();
  }

  void addCustomPlan(ReadingPlan plan, {bool setAsActive = true}) {
    _allPlans.insert(0, plan);
    if (setAsActive || _activePlan == null) {
      _activePlan = plan;
    }
    notifyListeners(); // FIXED: Always notify
  }

  void updateDayPassage({
    required String planId,
    required int dayIndex,
    required List<Passage> newPassages,
  }) {
    final planIdx = _allPlans.indexWhere((p) => p.id == planId);
    if (planIdx != -1) {
      final currentPlan = _allPlans[planIdx];
      if (dayIndex >= 0 && dayIndex < currentPlan.readings.length) {
        final currentReading = currentPlan.readings[dayIndex];
        final newTitle = newPassages.isNotEmpty
            ? newPassages.first.formattedRange
            : currentReading.title;

        final updatedReading = currentReading.copyWith(
          title: newTitle,
          passages: newPassages,
        );

        final updatedReadings = List<DailyReading>.from(currentPlan.readings);
        updatedReadings[dayIndex] = updatedReading;

        final updatedPlan = currentPlan.copyWith(readings: updatedReadings);
        _allPlans[planIdx] = updatedPlan;

        if (_activePlan?.id == planId) {
          _activePlan = updatedPlan;
        }

        notifyListeners();
      }
    }
  }

  void jumpToDay(int dayIndex) {
    final plan = activePlan;
    if (plan != null && dayIndex >= 0 && dayIndex < plan.readings.length) {
      // Note: This is for manual navigation, not date-based
      notifyListeners();
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
