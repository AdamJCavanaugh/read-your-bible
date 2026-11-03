import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../providers/app_state.dart';
import '../widgets/weekly_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'READING STATS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Growth & Consistency',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),

            // Top Streak Hero Banner Card
            Card(
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.streakCount} Day Streak!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Best streak: ${state.longestStreak} days. Keep praising and reading!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4 Stats Grid Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context,
                  title: 'Chapters Read',
                  value: '${state.totalChaptersRead}',
                  icon: Icons.auto_stories,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context,
                  title: 'Total Minutes',
                  value: '${state.totalMinutesRead}m',
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context,
                  title: 'Books Completed',
                  value: '${state.booksCompleted} / 66',
                  icon: Icons.bookmark_added,
                  color: Colors.purple,
                ),
                _buildStatCard(
                  context,
                  title: 'Plan Progress',
                  value: '${(state.planProgressPercentage * 100).toInt()}%',
                  icon: Icons.pie_chart_outline,
                  color: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Weekly Activity Chart Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: WeeklyChart(
                  weeklyMinutes: state.weeklyMinutes,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Testament Progress Breakdown Card
            Text(
              'Testament Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTestamentRow(
                      context,
                      title: 'Old Testament (39 Books)',
                      percentage: 0.38,
                      chaptersText: '352 / 929 chapters',
                      color: theme.colorScheme.primary,
                    ),
                    const Divider(height: 24),
                    _buildTestamentRow(
                      context,
                      title: 'New Testament (27 Books)',
                      percentage: 0.65,
                      chaptersText: '169 / 260 chapters',
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Achievement Badges Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements & Badges',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${mockBadges.where((b) => b.isUnlocked).length} / ${mockBadges.length} Unlocked',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: mockBadges.length,
              itemBuilder: (context, index) {
                final badge = mockBadges[index];
                return Card(
                  color: badge.isUnlocked
                      ? theme.colorScheme.surfaceContainerHigh
                      : theme.colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: badge.isUnlocked ? 1.0 : 0.3,
                          child: Text(
                            badge.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked
                                ? theme.textTheme.bodyMedium?.color
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          badge.isUnlocked ? badge.unlockedDate : 'Locked',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestamentRow(
    BuildContext context, {
    required String title,
    required double percentage,
    required String chaptersText,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          color: color,
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          chaptersText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
