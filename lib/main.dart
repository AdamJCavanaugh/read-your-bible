import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ReadYourBibleApp());
}

class ReadYourBibleApp extends StatefulWidget {
  const ReadYourBibleApp({super.key});

  @override
  State<ReadYourBibleApp> createState() => _ReadYourBibleAppState();
}

class _ReadYourBibleAppState extends State<ReadYourBibleApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Read Your Bible',
            debugShowCheckedModeBanner: false,
            themeMode: _appState.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
