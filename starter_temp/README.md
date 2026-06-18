# Create App Tool - Usage Guide

This tool creates a new Flutter project using your existing working boilerplate as a template, with custom app names and UI package names.

## 🚀 Quick Start

### Clone and Start from CLI

```bash
# 1) Clone the repository
git clone https://github.com/habte032/flutter-mobile-starter.git app_starter

# 2) Enter the workspace root
cd app_starter

# 3) Ensure the script is executable
chmod +x create_app.sh

# 4) Start the generator from CLI (interactive)
./create_app.sh
```

Or run directly with Python:

```bash
python3 create_app.py
```

### Interactive Mode (Recommended)

```bash
# Run interactive setup
./create_app.sh
# or
python3 create_app.py
```

### CLI Mode

```bash
# Basic usage
python3 create_app.py --name my_awesome_app

# Full customization
python3 create_app.py \
  --name ecommerce_store \
  --package com.mystore.ecommerce \
  --description "Modern e-commerce mobile application" \
  --ui-name ecommerce_ui
```

## 📋 What It Does

1. **Copies your working project** from `app_template/`
2. **Creates a parent folder with your project name** (next to the repo root)
3. **Creates app and UI package folders inside that parent folder**
4. **Renames everything** with your custom names:
   - Project name in `pubspec.yaml`
   - App class name in `main.dart` (e.g., `MyApp` → `EcommerceStoreApp`)
   - UI package name and imports
   - Package identifiers in Android/iOS configs
5. **Updates imports** to use your custom UI package name
6. **Fixes deprecations** (like `textScaleFactor` → `textScaler`)
7. **Installs dependencies** for both main project and UI package
8. **Runs code generation** (build_runner)
9. **Initializes Git** repository
10. **Includes launcher icon & splash config** in `pubspec.yaml`

## 🎯 Examples

### E-commerce App

```bash
python3 create_app.py \
  --name ecommerce_store \
  --package com.mystore.ecommerce \
  --ui-name store_ui
```

**Result:**

- Project: `ecommerce_store/`
- App class: `EcommerceStoreApp`
- UI package: `store_ui`
- Import: `import 'package:store_ui/app_ui.dart';`

### Social Media App

```bash
python3 create_app.py \
  --name social_connect \
  --package com.social.connect \
  --ui-name social_ui
```

**Result:**

- Project: `social_connect/`
- App class: `SocialConnectApp`
- UI package: `social_ui`
- Import: `import 'package:social_ui/app_ui.dart';`

### Fitness Tracker

```bash
python3 create_app.py \
  --name fitness_buddy \
  --package com.health.fitness \
  --ui-name fitness_ui
```

**Result:**

- Project: `fitness_buddy/`
- App class: `FitnessBuddyApp`
- UI package: `fitness_ui`
- Import: `import 'package:fitness_ui/app_ui.dart';`

## 📁 Project Structure After Creation

```
my_awesome_app/                    # Parent folder (project workspace)
├── my_awesome_app/               # Flutter app project
│   ├── android/                  # Android config (updated package name)
│   ├── ios/                      # iOS config (updated bundle ID)
│   ├── lib/
│   │   ├── main.dart             # Updated with MyAwesomeAppApp class
│   │   ├── config/
│   │   ├── core/
│   │   └── features/
│   ├── pubspec.yaml              # Updated project name and UI dependency
│   └── ...
└── my_awesome_app_ui/            # Your custom UI package
  ├── lib/
  │   ├── app_ui.dart           # Main export file
  │   └── src/
  │       ├── components/
  │       └── config/
  └── pubspec.yaml              # Updated UI package name
```

## 🔧 CLI Arguments

| Argument | Short | Description | Example |
|----------|-------|-------------|---------|
| `--name` | `-n` | Project name (required for CLI mode) | `my_awesome_app` |
| `--package` | `-p` | Package name (reverse domain) | `com.company.myapp` |
| `--description` | `-d` | Project description | `"My awesome app"` |
| `--ui-name` | `-u` | UI package name | `my_awesome_ui` |
| `--skip-codegen` | | Skip build_runner code generation | |
| `--skip-git` | | Skip git repository initialization | |

## ✅ What Gets Updated

### main.dart

```dart
// Before
import 'package:flutter_ui/app_ui.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // ...
}
runApp(const MyApp());

// After (for ecommerce_store with store_ui)
import 'package:store_ui/app_ui.dart';
class EcommerceStoreApp extends StatelessWidget {
  const EcommerceStoreApp({super.key});
  // ...
}
runApp(const EcommerceStoreApp());
```

### pubspec.yaml

```yaml
# Before
name: app_starter
description: "A new Flutter project."
dependencies:
  flutter_ui:
    path: ../flutter_ui

# After
name: ecommerce_store
description: "Modern e-commerce mobile application"
dependencies:
  store_ui:
    path: ../store_ui
```

## 🚀 After Creation

```bash
# Navigate to your new app project
cd my_awesome_app/my_awesome_app

# Run the app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk
```

## 🎨 Launcher Icon & Splash Screen

The generator ships with default config blocks in `pubspec.yaml` for
`flutter_launcher_icons` and `flutter_native_splash`.

Update these assets in your new app:

- `assets/icons/app_icon.png`
- `assets/images/splash.png`

Then run:

```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 🎨 Customizing Your UI Package

Your custom UI package (`my_awesome_app_ui`) contains:

- Design tokens (colors, spacing, typography)
- Reusable components (buttons, forms, cards)
- Theme configuration

Edit files in `../my_awesome_app_ui/lib/src/` to customize your design system.

## 🔍 Troubleshooting

### "Source project not found"

- Ensure `create_app.py` exists
- Ensure `app_template/pubspec.yaml` exists

### "Directory already exists"

- Choose a different project name
- Or delete the existing directory first

### Code generation fails

- Run `flutter clean && flutter pub get`
- Try running `flutter packages pub run build_runner clean` first

## 💡 Tips

1. **Use descriptive names**: `ecommerce_store` instead of `app1`
2. **Follow naming conventions**: lowercase with underscores
3. **Keep UI package names consistent**: `{project_name}_ui`
4. **Test immediately**: Run `flutter run` after creation to verify everything works

This tool gives you a fully working Flutter project based on your proven boilerplate, with all the custom naming you need! 🎉
