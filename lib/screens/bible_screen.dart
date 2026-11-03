import 'package:flutter/material.dart';
import '../models/bible_data.dart';
import '../providers/app_state.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final fontFamily = _getFontFamily(context, state.isSerifFont);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        actions: [
          // Translation selector
          PopupMenuButton<String>(
            initialValue: state.selectedTranslation,
            onSelected: (translation) => _handleTranslationChange(context, state, translation),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'KJV',
                child: Row(
                  children: [
                    Expanded(child: Text('KJV - King James Version', overflow: TextOverflow.ellipsis)),
                    if (state.selectedTranslation == 'KJV') Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'WEB',
                child: Row(
                  children: [
                    Expanded(child: Text('WEB - World English Bible${state.isTranslationInstalled('WEB') ? '' : ' (Download)'}', overflow: TextOverflow.ellipsis)),
                    if (state.selectedTranslation == 'WEB') Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'BSB',
                child: Row(
                  children: [
                    Expanded(child: Text('BSB - Berean Standard Bible${state.isTranslationInstalled('BSB') ? '' : ' (Download)'}', overflow: TextOverflow.ellipsis)),
                    if (state.selectedTranslation == 'BSB') Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  state.selectedTranslation,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
          // Font size control
          PopupMenuButton<int>(
            initialValue: state.fontSize.toInt(),
            onSelected: (size) {
              state.setFontSize(size.toDouble());
            },
            itemBuilder: (context) => [14, 16, 18, 20, 22, 24, 26, 28]
                .map((size) => PopupMenuItem(value: size, child: Text('$size pt')))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('${state.fontSize.toInt()} pt'),
              ),
            ),
          ),
          // Font family toggle
          PopupMenuButton<bool>(
            initialValue: state.isSerifFont,
            onSelected: (val) {
              if (val != state.isSerifFont) state.toggleSerifFont();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: true, child: Text('Serif')),
              const PopupMenuItem(value: false, child: Text('Sans')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(state.isSerifFont ? Icons.text_fields : Icons.text_format),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation dropdowns at top
          _buildNavigationBar(context, state, theme),
          // Chapter content
          Expanded(
            child: _buildChapterContent(context, state, theme, fontFamily),
          ),
        ],
      ),
    );
  }

  String? _getFontFamily(BuildContext context, bool isSerifFont) {
    if (!isSerifFont) return null;
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return 'serif';
    } else {
      return 'Georgia';
    }
  }

  void _handleTranslationChange(BuildContext context, AppState state, String translation) {
    // If translation is already selected, do nothing
    if (state.selectedTranslation == translation) return;

    // If translation is installed, switch immediately
    if (state.isTranslationInstalled(translation)) {
      state.setTranslation(translation);
      return;
    }

    // Translation not installed - show download confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Download $translation?'),
        content: Text(
          '$translation is not installed. Download it now? (${state.getTranslationDownloadSize(translation)})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    ).then((shouldDownload) {
      if (shouldDownload == true) {
        _downloadAndSwitchTranslation(context, state, translation);
      }
      // If cancelled or dialog dismissed, do nothing - selector stays on current translation
    });
  }

  Future<void> _downloadAndSwitchTranslation(BuildContext context, AppState state, String translation) async {
    try {
      // Show downloading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Downloading $translation...'),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: _DownloadProgressNotifier(state, translation),
                builder: (context, progress, _) => LinearProgressIndicator(value: progress),
              ),
            ],
          ),
        ),
      );

      // Download the translation
      await state.downloadTranslation(translation);

      if (mounted) {
        Navigator.of(context).pop(); // Close download dialog
        state.setTranslation(translation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$translation downloaded and selected')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close download dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download $translation: $e')),
        );
      }
    }
  }

  Widget _buildNavigationBar(BuildContext context, AppState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Book selector
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: state.bibleCurrentBook,
              items: BibleData.allBooks.map((book) => DropdownMenuItem(value: book, child: Text(book))).toList(),
              onChanged: (book) {
                if (book != null) {
                  state.setBibleBook(book);
                }
              },
              decoration: InputDecoration(
                labelText: 'Book',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Chapter selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: state.bibleCurrentChapter,
              items: List.generate(
                  BibleData.chapterCounts[state.bibleCurrentBook ?? 'Genesis'] ?? 50,
                  (i) => i + 1)
                  .map((ch) => DropdownMenuItem(value: ch, child: Text('$ch')))
                  .toList(),
              onChanged: (chapter) {
                if (chapter != null) {
                  state.setBibleChapter(chapter);
                }
              },
              decoration: InputDecoration(
                labelText: 'Chapter',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Verse selector
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<int>(
              initialValue: state.bibleCurrentVerse,
              items: List.generate(
                  BibleData.getVerseCount(state.bibleCurrentBook ?? 'Genesis', state.bibleCurrentChapter ?? 1),
                  (i) => i + 1)
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (verse) {
                if (verse != null) {
                  state.setBibleVerse(verse);
                }
              },
              decoration: InputDecoration(
                labelText: 'Verse',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterContent(BuildContext context, AppState state, ThemeData theme, String? fontFamily) {
    final book = state.bibleCurrentBook ?? 'Genesis';
    final chapter = state.bibleCurrentChapter ?? 1;
    final verse = state.bibleCurrentVerse ?? 1;

    return FutureBuilder<List<String>>(
      future: state.getVersesForPassageAsync(book, '$chapter'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final verses = snapshot.data ?? [];

        if (verses.isEmpty) {
          return Center(
            child: Text(
              'No verses available',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }

        // Calculate scroll offset for the target verse
        final targetIndex = (verse - 1).clamp(0, verses.length - 1);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: verses.length + 1, // +1 for chapter header
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '$book $chapter',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final verseIndex = index - 1;
            final verseNum = verseIndex + 1;
            final isTarget = verseIndex == targetIndex;

            return Padding(
              key: ValueKey(verseNum),
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
                      text: verses[verseIndex],
                      style: TextStyle(
                        fontSize: state.fontSize,
                        height: 1.6,
                        fontFamily: fontFamily,
                        color: theme.colorScheme.onSurface,
                        backgroundColor: isTarget ? theme.colorScheme.primaryContainer : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Helper to expose download progress as a ValueListenable
class _DownloadProgressNotifier extends ValueNotifier<double> {
  final AppState _state;
  final String _translation;

  _DownloadProgressNotifier(this._state, this._translation) : super(0.0) {
    _updateProgress();
  }

  void _updateProgress() {
    final progress = _state.getTranslationDownloadProgress(_translation);
    value = progress;
    // If download is still in progress, schedule another update
    if (progress > 0.0 && progress < 1.0) {
      Future.delayed(const Duration(milliseconds: 100), _updateProgress);
    }
  }
}