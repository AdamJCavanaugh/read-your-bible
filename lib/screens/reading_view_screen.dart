import 'package:flutter/material.dart';
import '../models/reading_plan.dart';
import '../providers/app_state.dart';

class ReadingViewScreen extends StatefulWidget {
  const ReadingViewScreen({super.key});

  @override
  State<ReadingViewScreen> createState() => _ReadingViewScreenState();
}

class _ReadingViewScreenState extends State<ReadingViewScreen> {
  String? _getFontFamily(BuildContext context, bool isSerifFont) {
    if (!isSerifFont) return null;
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return 'serif';
    } else {
      return 'Georgia';
    }
  }

  void _showAppearanceSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final fontFamily = _getFontFamily(context, state.isSerifFont);

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text & Typography',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size'),
                      Text('${state.fontSize.toInt()} pt'),
                    ],
                  ),
                  Slider(
                    value: state.fontSize,
                    min: 14.0,
                    max: 28.0,
                    divisions: 14,
                    label: '${state.fontSize.toInt()}',
                    onChanged: (val) {
                      state.setFontSize(val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(height: 32),

                  // Font Family
                  const Text('Font Family'),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Serif'),
                        icon: Icon(Icons.text_fields),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Sans'),
                        icon: Icon(Icons.text_format),
                      ),
                    ],
                    selected: {state.isSerifFont},
                    onSelectionChanged: (newVal) {
                      state.toggleSerifFont();
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Live Typography Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'In the beginning God created the heaven and the earth.',
                      style: TextStyle(
                        fontSize: state.fontSize,
                        fontFamily: fontFamily,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTranslationSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            final theme = Theme.of(context);
            final isWebInstalled = state.isTranslationInstalled('WEB');
            final isWebDownloading = state.isTranslationDownloading('WEB');
            final webProgress = state.getTranslationDownloadProgress('WEB');
            final isBSBInstalled = state.isTranslationInstalled('BSB');
            final isBSBDownloading = state.isTranslationDownloading('BSB');
            final bsbProgress = state.getTranslationDownloadProgress('BSB');

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Bible Translation',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KJV (Bundled Default)
                  RadioListTile<String>(
                    title: const Row(
                      children: [
                        Text('KJV', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Chip(
                          label: Text('Bundled / Offline', style: TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    subtitle: const Text('King James Version (Classic Public Domain)'),
                    value: 'KJV',
                    groupValue: state.selectedTranslation,
                    onChanged: (val) {
                      if (val != null) {
                        state.setTranslation(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),

                  // WEB (Downloadable Public Domain)
                  if (isWebInstalled)
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Text('WEB', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Chip(
                            label: Text('Downloaded', style: TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      subtitle: const Text('World English Bible (Modern Public Domain)'),
                      value: 'WEB',
                      groupValue: state.selectedTranslation,
                      onChanged: (val) {
                        if (val != null) {
                          state.setTranslation(val);
                          Navigator.pop(ctx);
                        }
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: const Text('WEB - World English Bible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modern Public Domain English (4.2 MB)'),
                          if (isWebDownloading) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: webProgress),
                            const SizedBox(height: 2),
                            Text(
                              'Downloading... ${(webProgress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      trailing: isWebDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: () async {
                                await state.downloadTranslation('WEB');
                              },
                              child: const Text('Download'),
                            ),
                    ),

                  const Divider(height: 16),

                  // BSB (Downloadable Public Domain)
                  if (isBSBInstalled)
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Text('BSB', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Chip(
                            label: Text('Downloaded', style: TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      subtitle: const Text('Berean Standard Bible (Modern Public Domain)'),
                      value: 'BSB',
                      groupValue: state.selectedTranslation,
                      onChanged: (val) {
                        if (val != null) {
                          state.setTranslation(val);
                          Navigator.pop(ctx);
                        }
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: const Text('BSB - Berean Standard Bible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Modern Public Domain English (4.2 MB)'),
                          if (isBSBDownloading) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: bsbProgress),
                            const SizedBox(height: 2),
                            Text(
                              'Downloading... ${(bsbProgress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                      trailing: isBSBDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: () async {
                                await state.downloadTranslation('BSB');
                              },
                              child: const Text('Download'),
                            ),
                    ),

                  const Divider(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Other translations (ESV, NIV, NLT) require publisher licensing.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
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
    final fontFamily = _getFontFamily(context, state.isSerifFont);

    // Handle combined mode vs single plan mode
    final activePlans = state.allPlans.where((p) => p.readings.isNotEmpty && p.hasStarted).toList();
    final isCombinedMode = state.combinePlansOnToday && activePlans.length > 1;

    final primaryReading = state.todayReading ??
        const DailyReading(
          id: 'default_passage',
          dayNumber: 1,
          title: 'Genesis 1',
          estimatedMinutes: 5,
          keyVerse: 'In the beginning God created the heaven and the earth.',
          keyVerseReference: 'Genesis 1:1',
          passages: [
            Passage(
              book: 'Genesis',
              startChapter: 1,
              startVerse: 1,
              endChapter: 1,
              endVerse: 31,
              verses: [],
            ),
          ],
        );

    final isCompleted = state.isTodayCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCombinedMode ? 'Combined Today Reading' : primaryReading.title),
        actions: [
          TextButton(
            onPressed: () => _showTranslationSheet(context, state),
            child: Text(
              state.selectedTranslation,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () => _showAppearanceSheet(context, state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCombinedMode ? 'Combined Active Plans' : '~${primaryReading.estimatedMinutes} min read',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCombinedMode ? 'Today\'s Combined Scripture Portions' : primaryReading.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
              ),
            ),
            const Divider(height: 32),

            // If combined mode, iterate across all active plans
            if (isCombinedMode) ...[
              ...activePlans.map((plan) {
                final dayIndex = plan.getCurrentDayIndex();
                final reading = plan.readings.isNotEmpty
                    ? plan.readings[dayIndex.clamp(0, plan.readings.length - 1)]
                    : null;
                if (reading == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildPassagesList(context, state, theme, reading.passages, fontFamily),
                    const Divider(height: 36),
                  ],
                );
              }),
            ] else ...[
              // Single active plan passages
              ..._buildPassagesList(context, state, theme, primaryReading.passages, fontFamily),
            ],

            const SizedBox(height: 30),
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Completed today\'s reading portion?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        if (isCombinedMode) {
                          state.toggleAllPlansTodayCompletion();
                        } else {
                          state.toggleTodayCompletion();
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Reading complete! Streak updated!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isCompleted
                            ? 'Marked as Complete ✓'
                            : 'Mark Complete & Continue',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPassagesList(BuildContext context, AppState state,
      ThemeData theme, List<Passage> passages, String? fontFamily) {
    return passages.map((passage) {
      final chapterWidgets = <Widget>[];

      for (int ch = passage.startChapter; ch <= passage.endChapter; ch++) {
        chapterWidgets.add(
          FutureBuilder<List<String>>(
            future: state.getVersesForPassageAsync(passage.book, '$ch'),
            builder: (context, snapshot) {
              final loadedVerses = snapshot.data ?? [];

              final startV = (ch == passage.startChapter) ? passage.startVerse : 1;
              final endV = (ch == passage.endChapter) ? passage.endVerse : loadedVerses.length;

              final filteredVerses = loadedVerses.asMap().entries.where((e) {
                final vNum = e.key + 1;
                return vNum >= startV && vNum <= endV;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${passage.book} Chapter $ch',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontFamily: fontFamily,
                        ),
                      ),
                      Chip(
                        label: Text(state.selectedTranslation),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting && loadedVerses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    ...filteredVerses.map((entry) {
                      final verseNum = entry.key + 1;
                      final verseText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$verseNum ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: state.fontSize * 0.75,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: verseText,
                                style: TextStyle(
                                  fontSize: state.fontSize,
                                  height: 1.6,
                                  fontFamily: fontFamily,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chapterWidgets,
      );
    }).toList();
  }
}