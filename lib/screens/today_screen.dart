import 'package:flutter/material.dart';
import '../models/reading_plan.dart';
import '../providers/app_state.dart';
import '../widgets/progress_ring.dart';
import 'create_plan_screen.dart';
import 'reading_view_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final activePlans = state.allPlans.where((p) => p.readings.isNotEmpty && p.hasStarted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Your Bible'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${state.streakCount} Day Streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Date Header
              Text(
                _getFormattedDate().toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today\'s Journey',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // If No Active Plans -> Show Welcome / Create First Plan Card
              if (activePlans.isEmpty) ...[
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.add_task,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Reading Plan Yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your custom reading plan by selecting books, duration, and optional repeat loops!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreatePlanScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Your First Plan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (state.combinePlansOnToday && activePlans.length > 1) ...[
                // Combined View for multiple plans
                _buildCombinedPlanCard(context, state, theme, activePlans),
              ] else ...[
                // Separate Cards view (current setup)
                if (activePlans.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Plans (${activePlans.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCompletedPlansBottomSheet(context, state, theme, activePlans),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('View Completed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                ...activePlans.map((plan) => _buildPlanCard(context, state, theme, plan)),
                // Show completed plans section if any are completed
                _buildCompletedPlansSection(context, state, theme, activePlans),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletedPlansBottomSheet(BuildContext context, AppState state, ThemeData theme, List<ReadingPlan> activePlans) {
    final completedPlans = activePlans.where((p) {
      return state.isTodayCompletedForPlan(p.id);
    }).toList();

    if (completedPlans.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final List<Widget> completedTiles = completedPlans.map((plan) {
          final today = plan.readings.isNotEmpty
              ? plan.readings[plan.getCurrentDayIndex().clamp(0, plan.readings.length - 1)]
              : null;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.check, color: Colors.green.shade800),
            ),
            title: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(today?.title ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.undo, color: Colors.orange),
              tooltip: 'Mark as Incomplete',
              onPressed: () {
                state.togglePlanDayCompletion(plan.id, plan.getCurrentDayIndex());
                Navigator.pop(ctx);
              },
            ),
          );
        }).toList();

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed Today',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...completedTiles,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedPlansSection(BuildContext context, AppState state, ThemeData theme, List<ReadingPlan> activePlans) {
    final completedPlans = activePlans.where((p) => state.isTodayCompletedForPlan(p.id)).toList();

    if (completedPlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completed Today (${completedPlans.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCompletedPlansBottomSheet(context, state, theme, activePlans),
              icon: const Icon(Icons.expand_more, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...completedPlans.map((plan) {
          final today = plan.readings.isNotEmpty
              ? plan.readings[plan.getCurrentDayIndex().clamp(0, plan.readings.length - 1)]
              : null;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.green.shade50.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.check, color: Colors.green.shade800, size: 22),
              ),
              title: Text(
                plan.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                today?.title ?? '',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.undo, color: Colors.orange.shade700),
                tooltip: 'Mark as Incomplete',
                onPressed: () {
                  state.togglePlanDayCompletion(plan.id, plan.getCurrentDayIndex());
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            state.togglePlanDayCompletion(plan.id, plan.getCurrentDayIndex());
                          },
                          icon: const Icon(Icons.undo),
                          label: const Text('Mark Incomplete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlanCard(
      BuildContext context, AppState state, ThemeData theme, ReadingPlan plan) {
    final today = plan.readings.isNotEmpty
        ? plan.readings[plan.getCurrentDayIndex().clamp(0, plan.readings.length - 1)]
        : null;
    final isCompleted = today != null && state.isTodayCompletedForPlan(plan.id);
    final progress = state.getPlanProgressPercentage(plan.id);

    // If completed, return a collapsed version (will be shown in completed section instead)
    if (isCompleted) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan header with progress ring
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day ${plan.getCurrentDayIndex() + 1} of ${plan.durationDays}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  progress: progress,
                  size: 56,
                  strokeWidth: 6,
                  centerChild: Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Today's reading assignment
            if (today != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${today.estimatedMinutes} min read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                today.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Buttons Row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        state.setActivePlan(plan);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReadingViewScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Start Reading'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Mark Complete',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    ),
                    onPressed: () {
                      state.togglePlanDayCompletion(plan.id, plan.getCurrentDayIndex());
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🎉 "${plan.title}" marked complete!',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.check_box_outline_blank,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedPlanCard(BuildContext context, AppState state,
      ThemeData theme, List<ReadingPlan> activePlans) {
    int totalEstimatedMins = 0;
    final planAssignments = <Map<String, dynamic>>[];

    for (final plan in activePlans) {
      final today = plan.readings.isNotEmpty
          ? plan.readings[plan.getCurrentDayIndex().clamp(0, plan.readings.length - 1)]
          : null;
      if (today != null) {
        totalEstimatedMins += today.estimatedMinutes;
        planAssignments.add({
          'plan': plan,
          'reading': today,
          'completed': state.isTodayCompletedForPlan(plan.id),
        });
      }
    }

    final areAllCompleted = state.areAllPlansCompletedToday();

    // If all completed, show collapsed version
    if (areAllCompleted) {
      return _buildCombinedCompletedCard(context, state, theme, activePlans, totalEstimatedMins);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Combined Today\'s Readings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day ${DateTime.now().day} • ~$totalEstimatedMins min total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text('${activePlans.length} Plans'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),

            // List of portions per plan
            ...planAssignments.map((assignment) {
              final plan = assignment['plan'] as ReadingPlan;
              final reading = assignment['reading'] as DailyReading;
              final isCompleted = assignment['completed'] as bool;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.shade50.withValues(alpha: 0.5)
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: isCompleted 
                        ? Border.all(color: Colors.green.shade200)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isCompleted,
                        onChanged: (val) {
                          state.togglePlanDayCompletion(plan.id, plan.getCurrentDayIndex());
                        },
                        activeColor: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              reading.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted 
                                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '~${reading.estimatedMinutes}m',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Combined Actions Row
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (activePlans.isNotEmpty) {
                        state.setActivePlan(activePlans.first);
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReadingViewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Start Combined Reading'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    state.toggleAllPlansTodayCompletion();
                  },
                  icon: Icon(areAllCompleted ? Icons.check_box : Icons.check_box_outline_blank),
                  label: Text(areAllCompleted ? 'All Done ✓' : 'Mark All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedCompletedCard(BuildContext context, AppState state,
      ThemeData theme, List<ReadingPlan> activePlans, int totalEstimatedMins) {
    return Card(
      elevation: 1,
      color: Colors.green.shade50.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.check_circle, color: Colors.green.shade800, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Readings Complete! 🎉',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day ${DateTime.now().day} • ~$totalEstimatedMins min total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'All ${activePlans.length} plans completed for today.',
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                state.toggleAllPlansTodayCompletion();
              },
              icon: const Icon(Icons.undo, color: Colors.orange),
              label: const Text('Mark All Incomplete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}