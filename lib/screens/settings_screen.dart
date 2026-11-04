import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../services/scripture_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String? _getFontFamily(BuildContext context, bool isSerifFont) {
    if (!isSerifFont) return null;
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) {
      return 'serif';
    } else {
      return 'Georgia';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final scriptureService = ScriptureService();

    final translationFullName = state.selectedTranslation == 'KJV'
        ? 'King James Version'
        : (state.selectedTranslation == 'WEB'
              ? 'World English Bible'
              : (state.selectedTranslation == 'BSB'
                    ? 'Berean Standard Bible'
                    : state.selectedTranslation));

    final isWebInstalled = state.isTranslationInstalled('WEB');
    final isBSBInstalled = state.isTranslationInstalled('BSB');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'PREFERENCES',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Theme Selector Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.brightness_6,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'App Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.settings_suggest),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {state.themeMode},
                    onSelectionChanged: (Set<ThemeMode> selection) {
                      state.setThemeMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reading & Translation Settings
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.menu_book,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Bible Translation'),
                  subtitle: Text(
                    'Current: ${state.selectedTranslation} ($translationFullName)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    _showTranslationPicker(context, state);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.text_fields,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Scripture Text Size & Style'),
                  subtitle: Text(
                    '${state.fontSize.toInt()} pt (${state.isSerifFont ? 'Serif' : 'Sans-serif'})',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    _showFontSizeModal(context, state);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: Icon(
                    Icons.view_agenda_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Combine Plans on Today View'),
                  subtitle: const Text(
                    'Merge daily portions from all active plans into a single card',
                  ),
                  value: state.combinePlansOnToday,
                  onChanged: (val) {
                    state.setCombinePlansOnToday(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'NOTIFICATIONS & REMINDERS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Daily Reading Reminder'),
                  subtitle: const Text('Get a subtle daily encouragement'),
                  value: state.notificationsEnabled,
                  onChanged: (val) {
                    state.setNotificationsEnabled(val);
                  },
                ),
                if (state.notificationsEnabled) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Reminder Time'),
                    subtitle: Text(state.reminderTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: state.reminderTime,
                      );
                      if (picked != null) {
                        state.setReminderTime(picked);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'OFFLINE TRANSLATIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                // KJV - Bundled
                ListTile(
                  leading: Icon(Icons.book, color: theme.colorScheme.primary),
                  title: const Text('KJV - King James Version'),
                  subtitle: Text(
                    'Bundled with app (${scriptureService.getFileSizeDisplay('KJV')}) • Always available offline',
                  ),
                  trailing: Chip(
                    label: const Text('Installed'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // WEB - Downloadable
                _buildTranslationTile(
                  context,
                  state,
                  'WEB',
                  'World English Bible',
                  'Modern Public Domain English (${scriptureService.getFileSizeDisplay('WEB')})',
                  isWebInstalled,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // BSB - Downloadable
                _buildTranslationTile(
                  context,
                  state,
                  'BSB',
                  'Berean Standard Bible',
                  'Modern Public Domain English (${scriptureService.getFileSizeDisplay('BSB')})',
                  isBSBInstalled,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // Info
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('About Translations'),
                  subtitle: const Text(
                    'KJV is bundled by default. WEB and BSB are modern public domain translations '
                    'downloaded from GitHub on demand. Use "Bible Translation" above to switch your active reading translation.',
                  ),
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'ABOUT',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Read Your Bible'),
                  subtitle: const Text(
                    'Version 1.0.0 • Mobile-first Offline Bible App',
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Privacy & Offline First'),
                  subtitle: const Text(
                    'No account required. All scripture and plan data stays local on your device.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTranslationTile(
    BuildContext context,
    AppState state,
    String code,
    String name,
    String description,
    bool isInstalled,
  ) {
    if (isInstalled) {
      return ListTile(
        leading: Icon(
          Icons.download_done,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('$code - $name'),
        subtitle: Text('Downloaded • Downloaded from GitHub'),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Delete $code Translation',
          onPressed: () {
            _confirmDeleteTranslation(context, state, code);
          },
        ),
      );
    } else {
      return ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final isDownloading = state.isTranslationDownloading(code);
          final progress = state.getTranslationDownloadProgress(code);

          return ListTile(
            leading: Icon(
              Icons.download_for_offline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('$code - $name'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not installed • $description'),
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    'Downloading... ${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton(
                    onPressed: () async {
                      await state.downloadTranslation(code);
                    },
                    child: const Text('Download'),
                  ),
          );
        },
      );
    }
  }

  void _confirmDeleteTranslation(
    BuildContext context,
    AppState state,
    String translation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Translation?'),
        content: Text(
          'This will remove the $translation translation from your device. '
          'You can re-download it later if needed.',
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
              state.deleteTranslation(translation);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$translation translation removed.'),
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

  void _showTranslationPicker(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: state,
          builder: (context, _) {
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
                    'Select Primary Translation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('KJV - King James Version'),
                    subtitle: const Text('Bundled / Offline Default'),
                    value: 'KJV',
                    groupValue: state.selectedTranslation,
                    onChanged: (val) {
                      if (val != null) {
                        state.setTranslation(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  if (isWebInstalled)
                    RadioListTile<String>(
                      title: const Text('WEB - World English Bible'),
                      subtitle: const Text('Downloaded (Modern Public Domain)'),
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
                      leading: const Icon(Icons.download),
                      title: const Text('WEB - World English Bible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modern Public Domain English (${ScriptureService().getFileSizeDisplay('WEB')})',
                          ),
                          if (isWebDownloading) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: webProgress),
                          ],
                        ],
                      ),
                      trailing: isWebDownloading
                          ? Text('${(webProgress * 100).toInt()}%')
                          : OutlinedButton(
                              onPressed: () async {
                                await state.downloadTranslation('WEB');
                              },
                              child: const Text('Download'),
                            ),
                    ),
                  const Divider(height: 16),
                  if (isBSBInstalled)
                    RadioListTile<String>(
                      title: const Text('BSB - Berean Standard Bible'),
                      subtitle: const Text('Downloaded (Modern Public Domain)'),
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
                      leading: const Icon(Icons.download),
                      title: const Text('BSB - Berean Standard Bible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modern Public Domain English (${ScriptureService().getFileSizeDisplay('BSB')})',
                          ),
                          if (isBSBDownloading) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: bsbProgress),
                          ],
                        ],
                      ),
                      trailing: isBSBDownloading
                          ? Text('${(bsbProgress * 100).toInt()}%')
                          : OutlinedButton(
                              onPressed: () async {
                                await state.downloadTranslation('BSB');
                              },
                              child: const Text('Download'),
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

  void _showFontSizeModal(BuildContext context, AppState state) {
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
                    'Text Appearance',
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
                  ListenableBuilder(
                    listenable: state,
                    builder: (context, _) {
                      return SegmentedButton<bool>(
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
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Live Preview Box
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
}
