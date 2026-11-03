import 'package:flutter/material.dart';
import '../models/bible_data.dart';
import '../models/reading_plan.dart';
import '../providers/app_state.dart';

class PlanScheduleEditorScreen extends StatefulWidget {
  final ReadingPlan plan;

  const PlanScheduleEditorScreen({
    super.key,
    required this.plan,
  });

  @override
  State<PlanScheduleEditorScreen> createState() =>
      _PlanScheduleEditorScreenState();
}

class _PlanScheduleEditorScreenState extends State<PlanScheduleEditorScreen> {
  String _searchQuery = '';

  void _showEditDayModal(
      BuildContext context, AppState state, DailyReading reading, int dayIndex) {
    final passage = reading.passages.isNotEmpty
        ? reading.passages.first
        : Passage(
            book: 'Genesis',
            startChapter: 1,
            startVerse: 1,
            endChapter: 1,
            endVerse: 31,
            verses: [],
          );

    String selectedBook = passage.book;
    final startChController =
        TextEditingController(text: '${passage.startChapter}');
    final startVsController =
        TextEditingController(text: '${passage.startVerse}');
    final endChController =
        TextEditingController(text: '${passage.endChapter}');
    final endVsController =
        TextEditingController(text: '${passage.endVerse}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final startCh = int.tryParse(startChController.text) ?? 1;
            final startVs = int.tryParse(startVsController.text) ?? 1;
            final endCh = int.tryParse(endChController.text) ?? 1;
            final endVs = int.tryParse(endVsController.text) ?? 25;

            final previewPassage = Passage(
              book: selectedBook,
              startChapter: startCh,
              startVerse: startVs,
              endChapter: endCh,
              endVerse: endVs,
              verses: passage.verses,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Day ${dayIndex + 1} Layout',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Live Preview Chip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ASSIGNED PASSAGE RANGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  previewPassage.formattedRange,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Book Selector Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedBook,
                      decoration: InputDecoration(
                        labelText: 'Select Book',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: BibleData.allBooks.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text(b),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedBook = val;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Start Chapter & Verse
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startChController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Start Chapter',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: startVsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Start Verse',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // End Chapter & Verse
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: endChController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'End Chapter',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endVsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'End Verse',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          final updatedPassage = Passage(
                            book: selectedBook,
                            startChapter: startCh,
                            startVerse: startVs,
                            endChapter: endCh,
                            endVerse: endVs,
                            verses: passage.verses,
                          );

                          state.updateDayPassage(
                            planId: widget.plan.id,
                            dayIndex: dayIndex,
                            newPassages: [updatedPassage],
                          );

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Updated Day ${dayIndex + 1} layout to "${updatedPassage.formattedRange}"',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Save Layout Changes'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);

    // Find latest version of this plan from AppState
    final plan = state.allPlans.firstWhere(
      (p) => p.id == widget.plan.id,
      orElse: () => widget.plan,
    );

    final filteredReadings = _searchQuery.trim().isEmpty
        ? plan.readings
        : plan.readings.where((r) {
            final query = _searchQuery.toLowerCase();
            return r.dayNumber.toString().contains(query) ||
                r.title.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${plan.title} Schedule'),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text('${plan.durationDays} Days Total'),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any day below to inspect or modify its exact chapter and verse range.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search day number or passage (e.g. Day 5 or Psalms)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ],
            ),
          ),

          // Daily Readings List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filteredReadings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final reading = filteredReadings[index];
                final dayIdx = reading.dayNumber - 1;
                final passageStr = reading.passages.isNotEmpty
                    ? reading.passages.first.formattedRange
                    : reading.title;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${reading.dayNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      passageStr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('~${reading.estimatedMinutes} mins read'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_note),
                      tooltip: 'Edit Day Layout',
                      onPressed: () {
                        _showEditDayModal(context, state, reading, dayIdx);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
