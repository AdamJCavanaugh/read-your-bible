import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> weeklyMinutes;
  final int dailyGoalMinutes;

  const WeeklyChart({
    super.key,
    required this.weeklyMinutes,
    this.dailyGoalMinutes = 15,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxMinutes = (weeklyMinutes.reduce((a, b) => a > b ? a : b)).clamp(25, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Goal: ${dailyGoalMinutes}m/day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final minutes = index < weeklyMinutes.length ? weeklyMinutes[index] : 0;
              final isToday = index == 6; // Sunday/Today in mock
              final meetsGoal = minutes >= dailyGoalMinutes;
              final heightPercent = (minutes / maxMinutes).clamp(0.08, 1.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${minutes}m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 90 * heightPercent,
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            )
                          : null,
                      color: !isToday
                          ? (meetsGoal
                              ? theme.colorScheme.primary.withValues(alpha: 0.7)
                              : theme.colorScheme.surfaceContainerHigh)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.secondary,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: minutes > 0
                        ? Center(
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: isToday || meetsGoal
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
