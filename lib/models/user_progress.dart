class DailyActivity {
  final String dayName;
  final int minutesRead;
  final bool isCompleted;

  const DailyActivity({
    required this.dayName,
    required this.minutesRead,
    required this.isCompleted,
  });
}

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final String unlockedDate;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedDate = '',
  });
}

final List<AchievementBadge> mockBadges = [
  const AchievementBadge(
    id: 'streak_7',
    title: '7-Day Streak',
    description: 'Read the Bible every day for a full week.',
    icon: '🔥',
    isUnlocked: true,
    unlockedDate: 'Oct 12',
  ),
  const AchievementBadge(
    id: 'first_book',
    title: 'Book Worm',
    description: 'Completed your first full book of scripture.',
    icon: '📜',
    isUnlocked: true,
    unlockedDate: 'Oct 04',
  ),
  const AchievementBadge(
    id: 'psalms_devotee',
    title: 'Psalm Singer',
    description: 'Read 20 Psalms with reflective heart.',
    icon: '🎵',
    isUnlocked: true,
    unlockedDate: 'Oct 18',
  ),
  const AchievementBadge(
    id: 'night_owl',
    title: 'Night Meditation',
    description: 'Completed evening scripture reflections.',
    icon: '🌙',
    isUnlocked: true,
    unlockedDate: 'Oct 21',
  ),
  const AchievementBadge(
    id: 'streak_30',
    title: '30-Day Warrior',
    description: 'Maintained a 30-day reading streak.',
    icon: '🛡️',
    isUnlocked: false,
  ),
  const AchievementBadge(
    id: 'proverbs_master',
    title: 'Wisdom Seeker',
    description: 'Completed all 31 chapters of Proverbs.',
    icon: '💡',
    isUnlocked: false,
  ),
];
