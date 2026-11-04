# read-your-bible

A mobile-first offline Bible reading application with deep customization of Bible reading plans.

## Features

- **Offline Bible Reading** - Full Bible text available without internet
- **Customizable Reading Plans** - Create personalized reading schedules
- **Progress Tracking** - Visual progress indicators and statistics
- **Multiple Translations** - Support for multiple Bible translations (KJV, BSB, WEB)
- **Cross-platform** - Currently Android only; iOS, Web, Windows, macOS, Linux planned

## Getting Started

### Prerequisites

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.3.0 or higher
- Platform-specific requirements:
  - **Android**: Android Studio, JDK 17+
  - **iOS**: Xcode 15+ (macOS only) - *planned*
  - **Web**: Chrome/Edge - *planned*
  - **Windows**: Visual Studio 2022 with Desktop development with C++ workload - *planned*
  - **macOS**: Xcode 15+ - *planned*
  - **Linux**: clang, cmake, ninja-build, pkg-config, libgtk-3-dev, liblzma-dev - *planned*

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/AdamJCavanaugh/read-your-bible.git
   cd read-your-bible
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # Mobile/Desktop
   flutter run
   
   # Web (planned)
   flutter run -d chrome
   
   # Specific platform (planned)
   flutter run -d android
   flutter run -d ios
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   ```

### Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (planned)
flutter build ios --release

# Web (planned)
flutter build web --release

# Desktop (planned)
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── bible_data.dart         # Bible verse/book data structures
│   ├── reading_plan.dart       # Reading plan models
│   └── user_progress.dart      # User progress tracking
├── screens/                     # UI screens
│   ├── bible_screen.dart       # Bible reading view
│   ├── plans_screen.dart       # Reading plans list
│   ├── today_screen.dart       # Today's reading
│   ├── progress_screen.dart    # Progress & statistics
│   ├── settings_screen.dart    # App settings
│   ├── create_plan_screen.dart # Plan creation wizard
│   ├── reading_view_screen.dart# Reading view
│   ├── main_navigation_screen.dart
│   └── plan_schedule_editor_screen.dart
├── widgets/                     # Reusable UI components
│   ├── plan_card.dart
│   ├── weekly_chart.dart
│   └── progress_ring.dart
├── services/                    # Business logic & data access
│   └── scripture_service.dart  # Bible data service
├── providers/                   # State management
│   └── app_state.dart          # Global app state
└── theme/                       # App theming
    └── app_theme.dart          # Material 3 theme

assets/
└── bible/                       # Bundled Bible assets
    ├── kjv.db                  # King James Version (SQLite)
    └── kjv.json                # KJV metadata

bibles/                          # Additional Bible translations (Git LFS)
    ├── bsb.db                  # Berean Standard Bible
    └── web.db                  # World English Bible

tools/                           # Build/maintenance scripts
├── download_bsb.py
├── download_kjv.py
├── download_full_bibles.py
└── build_sqlite_bibles.py
```

## Bible Database

The app uses SQLite databases for Bible content. The KJV database is bundled in `assets/bible/`. Additional translations (BSB, WEB) are stored in `bibles/` and tracked via Git LFS due to their size.

### Downloading Additional Translations

Run the tool scripts to download and build additional Bible databases:

```bash
cd tools
python download_bsb.py
python download_kjv.py
python build_sqlite_bibles.py
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Quick Start

1. Fork and clone the repository
2. Create a feature branch from `main`: `git checkout -b feature/your-feature`
3. Make your changes following the code style guidelines
4. Run analysis: `flutter analyze`
5. Push and create a Pull Request to `main`

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` for static analysis
- Format code with `dart format .`
- Follow Material Design 3 guidelines for UI

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`

Example:
```
feat(reading-plans): add weekly progress chart widget

Adds a new WeeklyChart widget to visualize reading progress
over the past 7 days with interactive tooltips.

Closes #42
```

## CI/CD

GitHub Actions workflows are configured in `.github/workflows/`:

- **CI** (`ci.yml`) - Runs on every push/PR: analyze, build all platforms
- **Release** (`release.yml`) - Triggered on version tags: builds and publishes all platform artifacts
- **Dependabot** (`dependabot.yml`) - Weekly dependency updates

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Bible text sources: Public domain / open license translations
- Flutter team for the amazing framework
- Contributors and testers