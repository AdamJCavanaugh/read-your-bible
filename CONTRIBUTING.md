# Contributing to read-your-bible

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)

## Getting Started

### Prerequisites

- Flutter SDK 3.19.0+
- Dart SDK 3.3.0+
- Git
- Platform-specific tools (see [README.md](README.md#prerequisites))

### Setting Up Your Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/AdamJCavanaugh/read-your-bible.git
   cd read-your-bible
   ```

3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/AdamJCavanaugh/read-your-bible.git
   ```

4. Install dependencies:
   ```bash
   flutter pub get
   ```

5. Verify the setup:
   ```bash
   flutter analyze
   flutter run
   ```

## Development Workflow

### Branching Strategy

We use **trunk-based development**:

| Branch | Purpose |
|--------|---------|
| `main` | Only long-running branch; production-ready code, tagged releases |
| `feature/*` | Short-lived feature branches, branched from `main` |
| `fix/*` | Short-lived bug fix branches, branched from `main` |
| `hotfix/*` | Urgent production fixes, branched from `main` |

**No `develop` branch** - all work integrates directly into `main` via short-lived branches.

### Creating a Feature Branch

```bash
# Ensure you're up to date
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes...

# Push to your fork
git push origin feature/your-feature-name
```

### Keeping Your Branch Updated

```bash
# Fetch latest changes
git fetch upstream

# Rebase onto latest main
git rebase upstream/main
```

## Code Style

### Dart/Flutter Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` for static analysis
- Format code with `dart format .` (run before committing)
- Follow Material Design 3 guidelines for UI

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes/Types | PascalCase | `ReadingPlan`, `BibleVerse` |
| Functions/Variables | camelCase | `getVerses()`, `currentPlan` |
| Constants | lowerCamelCase | `defaultFontSize` |
| Enum values | lowerCamelCase | `ReadingStatus.inProgress` |
| Files | snake_case | `reading_plan.dart`, `bible_screen.dart` |
| Private members | prefix with `_` | `_internalCache` |

### Import Organization

```dart
// 1. Dart core libraries
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

// 4. Project imports (relative)
import '../models/bible_data.dart';
import '../services/scripture_service.dart';
```

### Documentation

- Document public APIs with `///` comments
- Include examples for complex functions
- Keep comments up-to-date with code changes

```dart
/// Retrieves verses for a given passage reference.
///
/// Returns a [Future] that completes with a list of [BibleVerse] objects.
/// Throws [PassageNotFoundException] if the reference is invalid.
///
/// Example:
/// ```dart
/// final verses = await getVerses('John 3:16');
/// ```
Future<List<BibleVerse>> getVerses(String reference) async {
  // implementation
}
```

## Pull Request Process

### Before Submitting

1. **Run the full test suite:**
   ```bash
   flutter analyze
   dart format --set-exit-if-changed .
   ```

2. **Update documentation** if needed:
   - README.md for user-facing changes
   - Code comments for API changes

3. **Self-review your changes:**
   - Check for debug prints, commented code
   - Verify no sensitive data (API keys, etc.)
   - Ensure commit messages follow conventions

### Creating the Pull Request

1. Push your branch to your fork
2. Open a PR against `upstream/main`
3. Fill out the PR template completely
4. Link related issues: `Fixes #123` or `Relates to #123`
5. Request review from maintainers

### PR Requirements

- [ ] All CI checks pass (analyze, build)
- [ ] Code formatted (`dart format .`)
- [ ] No new analyzer warnings
- [ ] Documentation updated
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] PR description explains the "why" and "what"

### Review Process

- Maintainers will review within 2-3 business days
- Address review comments promptly
- Resolve conflicts with base branch if needed
- Squash commits if requested before merge

### Merge Strategy

- Feature/fix/hotfix branches: **Squash and merge** (clean history)

## Getting Help

- Check existing [issues](https://github.com/AdamJCavanaugh/read-your-bible/issues)
- Read the [documentation](https://github.com/AdamJCavanaugh/read-your-bible/wiki)
- Ask in [Discussions](https://github.com/AdamJCavanaugh/read-your-bible/discussions)
- Contact maintainers via email

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md
- Release notes
- GitHub contributors graph

Thank you for contributing! 🙏