import 'package:flutter/material.dart';
import '../models/reading_plan.dart';
import '../providers/app_state.dart';
import '../widgets/plan_card.dart';
import 'create_plan_screen.dart';
import 'plan_schedule_editor_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _showCompletedPlans = false;

  void _showPlanDetailsModal(
    BuildContext context,
    ReadingPlan plan,
    AppState state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(context);
        final isPlanCompleted = state.isPlanFullyCompleted(plan.id);

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(plan.category),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                      Text(
                        '${plan.durationDays} Days',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlanScheduleEditorScreen(plan: plan),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_calendar),
                          label: const Text('Edit Schedule'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isPlanCompleted
                              ? null
                              : () {
                                  _confirmDeletePlan(context, state, plan);
                                },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Plan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exact Schedule Layout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlanScheduleEditorScreen(plan: plan),
                            ),
                          );
                        },
                        child: const Text('Adjust All Days'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...plan.readings.take(10).map((reading) {
                    final passageStr = reading.passages.isNotEmpty
                        ? reading.passages.first.formattedRange
                        : reading.title;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        child: Text(
                          '${reading.dayNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        passageStr,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('~${reading.estimatedMinutes} mins read'),
                      trailing: const Icon(Icons.edit_note, size: 18),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlanScheduleEditorScreen(plan: plan),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePlan(
    BuildContext context,
    AppState state,
    ReadingPlan plan,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reading Plan?'),
        content: Text(
          'This will permanently delete "${plan.title}" and all its progress. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              state.deletePlan(plan.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${plan.title}" deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    // Separate active and completed plans
    final activePlans = state.allPlans
        .where((p) => !state.isPlanFullyCompleted(p.id))
        .toList();
    final completedPlans = state.allPlans
        .where((p) => state.isPlanFullyCompleted(p.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Plans'),
        actions: [
          IconButton(
            tooltip: 'Create Plan',
            icon: const Icon(Icons.add_task),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreatePlanScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR PLANS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage Your Reading Journeys',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Create Custom Plan Hero Card
            Card(
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Custom Reading Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choose custom duration, books & repeat cycles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreatePlanScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Build Your Plan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Active Plans Section
            if (activePlans.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Plans (${activePlans.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activePlans.map((plan) {
                return PlanCard(
                  plan: plan,
                  isActive: false,
                  onTap: () => _showPlanDetailsModal(context, plan, state),
                  onActivate: null,
                );
              }),
              const SizedBox(height: 24),
            ],

            // Completed Plans Section (Collapsible)
            if (completedPlans.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed Plans (${completedPlans.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showCompletedPlans = !_showCompletedPlans;
                      });
                    },
                    icon: Icon(
                      _showCompletedPlans
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: _showCompletedPlans ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showCompletedPlans)
                ...completedPlans.map((plan) {
                  return PlanCard(
                    plan: plan,
                    isActive: false,
                    isCompleted: true,
                    onTap: () => _showPlanDetailsModal(context, plan, state),
                    onActivate: null,
                  );
                }),
              const SizedBox(height: 24),
            ],

            // Empty State
            if (state.allPlans.isEmpty)
              Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Plans Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "Build Your Plan" above to create your first customized reading plan!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
