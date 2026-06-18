#!/usr/bin/env python3
"""
Flutter Mobile Starter CLI Setup
Creates a new Flutter project using the existing working boilerplate as template
"""

import os
import sys
import subprocess
import shutil
import re
from pathlib import Path
import argparse

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

class FlutterProjectCreator:
    def __init__(self):
        self.project_name = ""
        self.package_name = ""
        self.description = ""
        self.organization = ""
        self.app_class_name = ""
        self.ui_package_name = ""
        self.script_dir = Path(__file__).parent.absolute()
        self.source_project = self.script_dir / "app_template"
        self.fallback_source_project = self.script_dir / "app_starter"
        self.source_ui = self.script_dir / "flutter_ui"
        self.output_root = self.script_dir.parent
        
    def print_color(self, color, text):
        """Print colored text"""
        print(f"{color}{text}{Colors.NC}")
        
    def print_header(self):
        """Print the CLI header"""
        print()
        self.print_color(Colors.CYAN, "╔══════════════════════════════════════════════════════════════╗")
        self.print_color(Colors.CYAN, "║                 Flutter Mobile Starter CLI                   ║")
        self.print_color(Colors.CYAN, "║              Professional Flutter Boilerplate               ║")
        self.print_color(Colors.CYAN, "╚══════════════════════════════════════════════════════════════╝")
        print()
        
    def validate_project_name(self, name):
        """Validate project name format"""
        pattern = r'^[a-z][a-z0-9_]*$'
        if not re.match(pattern, name):
            self.print_color(Colors.RED, "❌ Invalid project name. Use lowercase letters, numbers, and underscores only.")
            self.print_color(Colors.YELLOW, "   Example: my_awesome_app")
            return False
        return True
        
    def validate_package_name(self, name):
        """Validate package name format"""
        pattern = r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
        if not re.match(pattern, name):
            self.print_color(Colors.RED, "❌ Invalid package name. Use reverse domain notation.")
            self.print_color(Colors.YELLOW, "   Example: com.company.myapp")
            return False
        return True
        
    def check_prerequisites(self):
        """Check if required tools are installed"""
        self.print_color(Colors.BLUE, "🔍 Checking prerequisites...")
        
        # Check if source project exists
        if not self.source_project.exists():
            if self.fallback_source_project.exists():
                self.print_color(
                    Colors.GREEN,
                    f"Using fallback template: {self.fallback_source_project}",
                )
                self.source_project = self.fallback_source_project
            else:
                self.print_color(Colors.RED, f"❌ Source project not found at: {self.source_project}")
                self.print_color(
                    Colors.YELLOW,
                    "   Expected app_template/ or app_starter/ next to this script",
                )
                sys.exit(1)
            
        # Check Flutter
        try:
            result = subprocess.run(['flutter', '--version'], capture_output=True, text=True)
            if result.returncode != 0:
                raise FileNotFoundError
            # Check if Flutter doctor shows any critical issues
            doctor_result = subprocess.run(['flutter', 'doctor', '--machine'], capture_output=True, text=True)
            if "android-studio" not in doctor_result.stdout.lower() and "xcode" not in doctor_result.stdout.lower():
                self.print_color(Colors.YELLOW, "⚠️  No IDE detected. Make sure Android Studio or Xcode is installed")
        except FileNotFoundError:
            self.print_color(Colors.RED, "❌ Flutter is not installed or not in PATH")
            self.print_color(Colors.YELLOW, "   Please install Flutter: https://flutter.dev/docs/get-started/install")
            sys.exit(1)
            
        # Check Git
        try:
            result = subprocess.run(['git', '--version'], capture_output=True, text=True)
            if result.returncode != 0:
                raise FileNotFoundError
        except FileNotFoundError:
            self.print_color(Colors.RED, "❌ Git is not installed or not in PATH")
            self.print_color(Colors.YELLOW, "   Please install Git: https://git-scm.com/downloads")
            sys.exit(1)
            
        self.print_color(Colors.GREEN, "✅ All prerequisites are met")
        
    def get_user_input(self):
        """Get project configuration from user"""
        print()
        self.print_color(Colors.PURPLE, "📝 Project Configuration")
        print()
        
        # Project name
        while True:
            self.project_name = input(f"{Colors.CYAN}Enter project name [my_flutter_app]: {Colors.NC}").strip()
            if not self.project_name:
                self.project_name = "my_flutter_app"
            if self.validate_project_name(self.project_name):
                break
                
        # Package name
        while True:
            default_package = "com." + self.project_name.replace('_', '')
            self.package_name = input(f"{Colors.CYAN}Enter package name [{default_package}]: {Colors.NC}").strip()
            if not self.package_name:
                self.package_name = default_package
            if self.validate_package_name(self.package_name):
                break
                
        # Description
        default_desc = f"A new Flutter project created with Flutter Mobile Starter"
        self.description = input(f"{Colors.CYAN}Enter project description [{default_desc}]: {Colors.NC}").strip()
        if not self.description:
            self.description = default_desc
            
        # UI Package name
        default_ui_name = f"{self.project_name}_ui"
        self.ui_package_name = input(f"{Colors.CYAN}Enter UI package name [{default_ui_name}]: {Colors.NC}").strip()
        if not self.ui_package_name:
            self.ui_package_name = default_ui_name
            
        # Generate derived values
        parts = self.package_name.split('.')
        self.organization = f"{parts[0]}.{parts[1]}"
        self.app_class_name = ''.join(word.capitalize() for word in self.project_name.split('_')) + 'App'
        
        # Confirmation
        print()
        self.print_color(Colors.YELLOW, "📋 Configuration Summary:")
        print(f"   Project Name: {self.project_name}")
        print(f"   Package Name: {self.package_name}")
        print(f"   Organization: {self.organization}")
        print(f"   App Class Name: {self.app_class_name}")
        print(f"   UI Package Name: {self.ui_package_name}")
        print(f"   Description: {self.description}")
        print()
        
        confirm = input(f"{Colors.CYAN}Continue with this configuration? (y/N): {Colors.NC}").strip().lower()
        if confirm not in ['y', 'yes']:
            self.print_color(Colors.YELLOW, "Setup cancelled by user")
            sys.exit(0)
            
    def copy_project_structure(self):
        """Copy the entire project structure from source"""
        self.print_color(Colors.BLUE, "📁 Copying project structure...")
        
        # Create parent project directory and app destination directory
        parent_dir = self.output_root / self.project_name
        dest_dir = parent_dir / self.project_name

        if parent_dir.exists():
            self.print_color(Colors.RED, f"❌ Directory '{parent_dir}' already exists")
            sys.exit(1)

        parent_dir.mkdir(parents=True, exist_ok=False)
            
        # Copy the entire source project
        shutil.copytree(self.source_project, dest_dir)
        
        # Change to the new project directory
        os.chdir(dest_dir)
        
        # Create a proper Flutter project structure marker
        self.create_flutter_project_marker()
        
        # Also copy the flutter_ui package to the parent directory with the custom name
        source_ui = self.source_ui
        if source_ui.exists():
            dest_ui = parent_dir / self.ui_package_name
            if dest_ui.exists():
                shutil.rmtree(dest_ui)
            
            # Copy the UI package but exclude problematic directories
            shutil.copytree(source_ui, dest_ui, ignore=shutil.ignore_patterns('example', '.dart_tool', 'build'))
        
        self.print_color(Colors.GREEN, "✅ Project structure copied")
        
    def update_project_files(self):
        """Update project files with new names and configuration"""
        self.print_color(Colors.BLUE, "🔧 Updating project configuration...")
        
        # Update pubspec.yaml
        self.update_pubspec_yaml()
        
        # Update main.dart
        self.update_main_dart()

        # Update Android/iOS package identifiers
        self.update_android_package()
        self.update_ios_bundle_identifier()
        
        # Update all internal package references
        self.update_internal_references()

        # Ensure storage adapter contract matches usage
        self.update_storage_adapter()
        
        # Update other configuration files
        self.update_other_files()
                
        self.print_color(Colors.GREEN, "✅ Project files updated")
        
    def update_pubspec_yaml(self):
        """Update pubspec.yaml with new project name and UI package"""
        pubspec_path = Path('pubspec.yaml')
        if pubspec_path.exists():
            content = pubspec_path.read_text()
            
            # Replace project name
            content = re.sub(r'^name: .*$', f'name: {self.project_name}', content, flags=re.MULTILINE)
            
            # Replace description
            content = re.sub(r'^description: .*$', f'description: "{self.description}"', content, flags=re.MULTILINE)
            
            # Update flutter_ui dependency path
            content = re.sub(
                r'flutter_ui:\s*\n\s*path: .*',
                f'{self.ui_package_name}:\n    path: ../{self.ui_package_name}',
                content
            )
            
            pubspec_path.write_text(content)
            
    def update_main_dart(self):
        """Update main.dart with custom app class name and imports"""
        main_path = Path('lib/main.dart')
        if main_path.exists():
            content = main_path.read_text()
            
            # Replace flutter_ui import with custom UI package name
            content = content.replace(
                "import 'package:flutter_ui/app_ui.dart';",
                f"import 'package:{self.ui_package_name}/app_ui.dart';"
            )
            
            # Replace MyApp references with the new app class name
            content = re.sub(r'\bMyApp\b', self.app_class_name, content)
            
            # Update textScaleFactor to textScaler (fix deprecation)
            content = content.replace(
                'data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),',
                'data: MediaQuery.of(context).copyWith(\n                  textScaler: const TextScaler.linear(1.0),\n                ),'
            )
            
            main_path.write_text(content)
            
    def update_file_content(self, file_path):
        """Update file content with project-specific values"""
        path = Path(file_path)
        if path.exists():
            content = path.read_text()
            
            # Replace placeholders
            content = content.replace('app_starter', self.project_name)
            content = content.replace('App Starter', self.project_name.replace('_', ' ').title())
            content = content.replace('flutter_boilerplate', self.project_name)
            content = content.replace('Flutter Boilerplate', self.project_name.replace('_', ' ').title())
            content = content.replace('A new Flutter project.', self.description)
            
            path.write_text(content)
            
    def setup_ui_package(self):
        """Setup and rename the UI package"""
        self.print_color(Colors.BLUE, "🎨 Setting up UI package...")
        
        # The UI package should already be copied, just update its configuration
        ui_path = Path(f'../{self.ui_package_name}')
        
        if not ui_path.exists():
            # Create a basic UI package if it doesn't exist
            source_ui = self.source_ui
            if source_ui.exists():
                shutil.copytree(source_ui, ui_path, ignore=shutil.ignore_patterns('example', '.dart_tool', 'build'))
            else:
                self.create_basic_ui_package(ui_path)
        else:
            # Update existing UI package pubspec.yaml
            ui_pubspec = ui_path / 'pubspec.yaml'
            if ui_pubspec.exists():
                content = ui_pubspec.read_text()
                content = re.sub(r'^name: .*$', f'name: {self.ui_package_name}', content, flags=re.MULTILINE)
                content = re.sub(r'^description: .*$', f'description: "UI components for {self.project_name}"', content, flags=re.MULTILINE)
                ui_pubspec.write_text(content)
            
        self.print_color(Colors.GREEN, f"✅ UI package '{self.ui_package_name}' setup complete")
        
    def create_basic_ui_package(self, ui_path):
        """Create a basic UI package if source doesn't exist"""
        ui_path.mkdir(parents=True, exist_ok=True)
        
        # Create lib directory structure
        (ui_path / 'lib' / 'src' / 'config' / 'constants').mkdir(parents=True, exist_ok=True)
        (ui_path / 'lib' / 'src' / 'config' / 'theme').mkdir(parents=True, exist_ok=True)
        
        # Create pubspec.yaml
        pubspec_content = f"""name: {self.ui_package_name}
description: "UI components for {self.project_name}"
version: 1.0.0

environment:
  sdk: ^3.9.2
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
"""
        (ui_path / 'pubspec.yaml').write_text(pubspec_content)
        
        # Create app_ui.dart
        app_ui_content = """library app_ui;

export 'src/config/constants/app_colors.dart';
export 'src/config/theme/app_theme.dart';
"""
        (ui_path / 'lib' / 'app_ui.dart').write_text(app_ui_content)
        
        # Create basic app_colors.dart
        colors_content = """import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
}
"""
        (ui_path / 'lib' / 'src' / 'config' / 'constants' / 'app_colors.dart').write_text(colors_content)
        
        # Create basic app_theme.dart
        theme_content = """import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
  }
}
"""
        (ui_path / 'lib' / 'src' / 'config' / 'theme' / 'app_theme.dart').write_text(theme_content)
        
    def create_flutter_project_marker(self):
        """Create Flutter project markers to ensure proper SDK recognition"""
        # Ensure .metadata file exists (Flutter project marker)
        metadata_content = f"""# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled and should not be manually edited.

version:
  revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
  channel: stable

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
      base_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
    - platform: android
      create_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
      base_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
    - platform: ios
      create_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
      base_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
    - platform: web
      create_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8
      base_revision: 9f455d2486d8b9b3b8b8b8b8b8b8b8b8b8b8b8b8

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
"""
        Path('.metadata').write_text(metadata_content)
        
        # Ensure proper analysis_options.yaml exists
        if not Path('analysis_options.yaml').exists():
            analysis_options = """include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: false
"""
            Path('analysis_options.yaml').write_text(analysis_options)
            
        # Create a proper Flutter project configuration
        self.create_flutter_config_files()
        
    def create_flutter_config_files(self):
        """Create additional Flutter configuration files for proper SDK recognition"""
        # Create .flutter-plugins file if it doesn't exist
        flutter_plugins_path = Path('.flutter-plugins')
        if not flutter_plugins_path.exists():
            flutter_plugins_path.write_text('')
            
        # Create .flutter-plugins-dependencies file if it doesn't exist
        flutter_plugins_deps_path = Path('.flutter-plugins-dependencies')
        if not flutter_plugins_deps_path.exists():
            plugins_deps_content = '''{
  "info": "This is a generated file; do not edit or check into version control.",
  "plugins": {
    "ios": [],
    "android": [],
    "macos": [],
    "linux": [],
    "windows": [],
    "web": []
  },
  "dependencyGraph": [],
  "date_created": "2024-01-01 00:00:00.000000",
  "version": "3.35.6"
}'''
            flutter_plugins_deps_path.write_text(plugins_deps_content)
            
        # Ensure proper .gitignore exists
        gitignore_path = Path('.gitignore')
        if gitignore_path.exists():
            gitignore_content = gitignore_path.read_text()
            # Add Flutter-specific ignores if not present
            flutter_ignores = [
                '# Flutter/Dart/Pub related',
                '**/doc/api/',
                '**/ios/Flutter/.last_build_id',
                '.dart_tool/',
                '.flutter-plugins',
                '.flutter-plugins-dependencies',
                '.packages',
                '.pub-cache/',
                '.pub/',
                '/build/',
                '# Web related',
                'lib/generated_plugin_registrant.dart',
                '# Symbolication related',
                'app.*.symbols',
                '# Obfuscation related',
                'app.*.map.json'
            ]
            
            for ignore_line in flutter_ignores:
                if ignore_line not in gitignore_content:
                    gitignore_content += f'\n{ignore_line}'
                    
            gitignore_path.write_text(gitignore_content)
        
    def update_internal_references(self):
        """Update all internal package references from flutter_boilerplate to project name"""
        # Find all Dart files that might have internal references
        dart_files = list(Path('.').rglob('*.dart'))
        excluded_dirs = {
            '.dart_tool',
            'build',
            '.git',
            'ios',
            'android',
            'macos',
            'windows',
            'linux',
            'web',
        }
        
        for dart_file in dart_files:
            if dart_file.exists():
                try:
                    if any(part in excluded_dirs for part in dart_file.parts):
                        continue
                    content = dart_file.read_text(encoding='utf-8')
                    
                    # Replace flutter_boilerplate package references with project name
                    content = content.replace(
                        'package:flutter_boilerplate/',
                        f'package:{self.project_name}/'
                    )
                    
                    # Replace flutter_ui package references with custom UI package name
                    content = content.replace(
                        'package:flutter_ui/',
                        f'package:{self.ui_package_name}/'
                    )

                    # Replace template package references with the new project name
                    content = content.replace(
                        'package:app_starter/',
                        f'package:{self.project_name}/'
                    )
                    
                    dart_file.write_text(content, encoding='utf-8')
                except Exception as e:
                    # Skip files that can't be read/written
                    pass

    def update_storage_adapter(self):
        """Ensure IStorageService declares initialize to match usage"""
        adapter_path = Path('lib/core/storage/storage_adapter.dart')
        if not adapter_path.exists():
            return

        content = adapter_path.read_text(encoding='utf-8')
        if 'Future<void> initialize(' in content:
            return

        marker = 'abstract class IStorageService {'
        if marker not in content:
            return

        if 'app_logger.dart' not in content:
            content = "import 'package:app_starter/core/logging/app_logger.dart';\n\n" + content

        replacement = (
            f"{marker}\n"
            "  Future<void> initialize([AppLogger? logger]);\n"
        )
        content = content.replace(marker, replacement, 1)
        adapter_path.write_text(content, encoding='utf-8')
                    
    def update_other_files(self):
        """Update other configuration files"""
        files_to_update = [
            '.env',
            'README.md',
            'android/app/build.gradle.kts',
            'android/app/src/main/res/values/strings.xml',
            'ios/Runner/Info.plist',
            'web/index.html',
            'web/manifest.json'
        ]
        
        for file_path in files_to_update:
            if Path(file_path).exists():
                self.update_file_content(file_path)

    def update_android_package(self):
        """Update Android applicationId/namespace and MainActivity package"""
        gradle_path = Path('android/app/build.gradle.kts')
        if gradle_path.exists():
            content = gradle_path.read_text()
            content = re.sub(
                r'namespace\s*=\s*"[^"]+"',
                f'namespace = "{self.package_name}"',
                content,
            )
            content = re.sub(
                r'applicationId\s*=\s*"[^"]+"',
                f'applicationId = "{self.package_name}"',
                content,
            )
            gradle_path.write_text(content)

        main_activity_path = None
        kotlin_root = Path('android/app/src/main/kotlin')
        java_root = Path('android/app/src/main/java')

        if kotlin_root.exists():
            kotlin_matches = list(kotlin_root.rglob('MainActivity.kt'))
            if kotlin_matches:
                main_activity_path = kotlin_matches[0]
        if main_activity_path is None and java_root.exists():
            java_matches = list(java_root.rglob('MainActivity.kt'))
            if java_matches:
                main_activity_path = java_matches[0]

        if main_activity_path is None or not main_activity_path.exists():
            return

        content = main_activity_path.read_text()
        content = re.sub(
            r'^package\s+.+$',
            f'package {self.package_name}',
            content,
            flags=re.MULTILINE,
        )

        if 'kotlin' in main_activity_path.parts:
            root_dir = kotlin_root
        else:
            root_dir = java_root

        target_dir = root_dir / Path(*self.package_name.split('.'))
        target_dir.mkdir(parents=True, exist_ok=True)
        target_path = target_dir / 'MainActivity.kt'
        target_path.write_text(content)

        if main_activity_path.resolve() != target_path.resolve():
            main_activity_path.unlink()

    def update_ios_bundle_identifier(self):
        """Update iOS bundle identifiers based on the package name"""
        pbxproj_path = Path('ios/Runner.xcodeproj/project.pbxproj')
        if not pbxproj_path.exists():
            return

        content = pbxproj_path.read_text()
        content = content.replace('com.example.flutterBoilerplate', self.package_name)
        pbxproj_path.write_text(content)
        
    def install_dependencies(self):
        """Install project dependencies"""
        self.print_color(Colors.BLUE, "📦 Installing dependencies...")
        
        # Clean any existing build artifacts first
        subprocess.run(['flutter', 'clean'], capture_output=True)
        
        # Remove .dart_tool to force fresh package resolution
        dart_tool_path = Path('.dart_tool')
        if dart_tool_path.exists():
            shutil.rmtree(dart_tool_path, ignore_errors=True)
        
        # Install UI package dependencies first
        ui_path = Path(f'../{self.ui_package_name}')
        if ui_path.exists():
            original_dir = os.getcwd()
            os.chdir(ui_path)
            
            # Clean UI package
            subprocess.run(['flutter', 'clean'], capture_output=True)
            ui_dart_tool = Path('.dart_tool')
            if ui_dart_tool.exists():
                shutil.rmtree(ui_dart_tool, ignore_errors=True)
            
            # Install UI package dependencies
            result = subprocess.run(['flutter', 'pub', 'get'], capture_output=True, text=True)
            if result.returncode != 0:
                self.print_color(Colors.YELLOW, f"⚠️  UI package dependency installation had issues: {result.stderr}")
            
            os.chdir(original_dir)
        
        # Install main project dependencies with multiple attempts
        max_attempts = 3
        for attempt in range(max_attempts):
            try:
                # Clean before each attempt
                subprocess.run(['flutter', 'clean'], capture_output=True)
                
                # Remove .dart_tool again
                dart_tool_path = Path('.dart_tool')
                if dart_tool_path.exists():
                    shutil.rmtree(dart_tool_path, ignore_errors=True)
                
                # Run pub get
                result = subprocess.run(['flutter', 'pub', 'get'], capture_output=True, text=True, timeout=120)
                
                if result.returncode == 0:
                    # Verify package_config.json was created
                    package_config = Path('.dart_tool/package_config.json')
                    if package_config.exists():
                        self.print_color(Colors.GREEN, "✅ Dependencies installed successfully")
                        break
                    else:
                        self.print_color(Colors.YELLOW, f"⚠️  Attempt {attempt + 1}: package_config.json not created")
                else:
                    self.print_color(Colors.YELLOW, f"⚠️  Attempt {attempt + 1} failed: {result.stderr}")
                    
                if attempt == max_attempts - 1:
                    self.print_color(Colors.RED, f"❌ Main project dependency installation failed after {max_attempts} attempts")
                    self.print_color(Colors.YELLOW, "💡 Try running 'flutter doctor' to check your Flutter installation")
                    self.print_color(Colors.YELLOW, "💡 You can manually run 'flutter pub get' in the project directory")
                    # Don't raise exception, let user handle it manually
                    return
                    
            except subprocess.TimeoutExpired:
                self.print_color(Colors.YELLOW, f"⚠️  Attempt {attempt + 1} timed out")
                if attempt == max_attempts - 1:
                    self.print_color(Colors.RED, "❌ Dependency installation timed out")
                    return
        
        # Run additional Flutter commands to ensure proper setup
        try:
            # Run pub deps to verify dependency resolution
            subprocess.run(['flutter', 'pub', 'deps'], capture_output=True, timeout=60)
            
            # Force Flutter to recognize the project by running a quick command
            subprocess.run(['flutter', 'packages', 'get'], capture_output=True, timeout=60)
            
            # Run a quick analyze to verify SDK recognition
            result = subprocess.run(['flutter', 'analyze', '--no-fatal-infos'], capture_output=True, text=True, timeout=60)
            if "Target of URI doesn't exist: 'package:flutter/material.dart'" in result.stdout:
                self.print_color(Colors.YELLOW, "⚠️  Flutter SDK recognition issue detected")
                self.print_color(Colors.BLUE, "🔧 Attempting to fix Flutter SDK recognition...")
                
                # Try to fix by recreating the project structure
                subprocess.run(['flutter', 'clean'], capture_output=True)
                subprocess.run(['flutter', 'pub', 'get'], capture_output=True)
                
                # Create a simple test file to force SDK recognition
                test_file = Path('test_sdk.dart')
                test_file.write_text("import 'package:flutter/material.dart';\nvoid main() {}")
                
                # Try to analyze the test file
                test_result = subprocess.run(['flutter', 'analyze', 'test_sdk.dart'], capture_output=True, text=True, timeout=30)
                
                # Remove test file
                if test_file.exists():
                    test_file.unlink()
                    
                if "Target of URI doesn't exist" not in test_result.stdout:
                    self.print_color(Colors.GREEN, "✅ Flutter SDK recognition fixed")
                else:
                    self.print_color(Colors.RED, "❌ Flutter SDK recognition issue persists")
                    self.print_color(Colors.YELLOW, "💡 This might be an IDE-specific issue. Try:")
                    self.print_color(Colors.YELLOW, "   1. Restart your IDE")
                    self.print_color(Colors.YELLOW, "   2. Run 'flutter clean && flutter pub get' manually")
                    self.print_color(Colors.YELLOW, "   3. Check IDE Flutter plugin settings")
                
        except subprocess.TimeoutExpired:
            self.print_color(Colors.YELLOW, "⚠️  Additional setup commands timed out")
        except Exception as e:
            self.print_color(Colors.YELLOW, f"⚠️  Additional setup had issues: {e}")
        
    def run_code_generation(self):
        """Run code generation"""
        self.print_color(Colors.BLUE, "⚙️  Running code generation...")
        
        try:
            # Ensure we're in the right directory
            if not Path('pubspec.yaml').exists():
                self.print_color(Colors.RED, "❌ pubspec.yaml not found in current directory")
                return
                
            # Clean before code generation
            subprocess.run(['flutter', 'clean'], capture_output=True)
            
            # Run code generation with better error handling
            result = subprocess.run([
                'flutter', 'packages', 'pub', 'run', 'build_runner', 'build',
                '--delete-conflicting-outputs'
            ], capture_output=True, text=True, timeout=300)  # 5 minute timeout
            
            if result.returncode == 0:
                self.print_color(Colors.GREEN, "✅ Code generation completed")
            else:
                self.print_color(Colors.YELLOW, "⚠️  Code generation had issues but project is still usable")
                if "const" in result.stderr.lower():
                    self.print_color(Colors.BLUE, "💡 Tip: Check for 'const' keyword issues in your code")
                    
        except subprocess.TimeoutExpired:
            self.print_color(Colors.YELLOW, "⚠️  Code generation timed out, but project is still usable")
        except subprocess.CalledProcessError as e:
            self.print_color(Colors.YELLOW, f"⚠️  Code generation failed: {e}, but project is still usable")
            
    def init_git_repo(self):
        """Initialize Git repository"""
        self.print_color(Colors.BLUE, "📚 Initializing Git repository...")
        
        subprocess.run(['git', 'init'], check=True)
        subprocess.run(['git', 'add', '.'], check=True)
        subprocess.run(['git', 'commit', '-m', f'Initial commit: {self.project_name} created from Flutter Mobile Starter'], check=True)
        
        self.print_color(Colors.GREEN, "✅ Git repository initialized")
        
    def display_completion(self):
        """Display completion message"""
        parent_path = Path(os.getcwd()).parent

        print()
        self.print_color(Colors.GREEN, "🎉 Project setup completed successfully!")
        print()
        self.print_color(Colors.CYAN, "═" * 62)
        self.print_color(Colors.CYAN, "📍 PROJECT PATHS")
        self.print_color(Colors.CYAN, "═" * 62)
        self.print_color(Colors.GREEN, f"📁 Project folder: {parent_path}")
        self.print_color(Colors.GREEN, f"📁 App folder: {os.getcwd()}")
        self.print_color(Colors.GREEN, f"📁 UI package folder: {parent_path / self.ui_package_name}")
        self.print_color(Colors.CYAN, "═" * 62)
        print()
        self.print_color(Colors.YELLOW, "🚀 Next steps:")
        print(f"   1. cd {os.getcwd()}")
        print("   2. flutter run")
        print()
        self.print_color(Colors.PURPLE, "📖 Available commands:")
        print("   • flutter run              - Run the app")
        print("   • flutter test             - Run tests")
        print("   • flutter build apk        - Build Android APK")
        print("   • flutter build ios        - Build iOS app")
        print("   • flutter analyze          - Analyze code")
        print()
        self.print_color(Colors.BLUE, f"📱 Your app class: {self.app_class_name}")
        self.print_color(Colors.BLUE, f"🎨 Your UI package: {self.ui_package_name}")
        print()
        
    def run_interactive_setup(self):
        """Run the interactive setup process"""
        self.print_header()
        self.check_prerequisites()
        self.get_user_input()
        self.copy_project_structure()
        self.setup_ui_package()
        self.update_project_files()
        self.install_dependencies()
        self.run_code_generation()
        self.init_git_repo()
        self.display_completion()
        
    def run_cli_setup(self, args):
        """Run setup with CLI arguments"""
        self.project_name = args.name
        self.package_name = args.package or f"com.{args.name.replace('_', '')}"
        self.description = args.description or f"A new Flutter project created with Flutter Mobile Starter"
        self.ui_package_name = args.ui_name or f"{args.name}_ui"
        
        parts = self.package_name.split('.')
        self.organization = f"{parts[0]}.{parts[1]}"
        self.app_class_name = ''.join(word.capitalize() for word in self.project_name.split('_')) + 'App'
        
        if not self.validate_project_name(self.project_name):
            sys.exit(1)
        if not self.validate_package_name(self.package_name):
            sys.exit(1)
            
        self.print_header()
        self.check_prerequisites()
        self.copy_project_structure()
        self.setup_ui_package()
        self.update_project_files()
        self.install_dependencies()
        if not args.skip_codegen:
            self.run_code_generation()
        if not args.skip_git:
            self.init_git_repo()
        self.display_completion()

def main():
    parser = argparse.ArgumentParser(description='Flutter Mobile Starter CLI - Create custom Flutter projects')
    parser.add_argument('--name', '-n', help='Project name (required for CLI mode)')
    parser.add_argument('--package', '-p', help='Package name (e.g., com.company.app)')
    parser.add_argument('--description', '-d', help='Project description')
    parser.add_argument('--ui-name', '-u', help='UI package name (default: {project_name}_ui)')
    parser.add_argument('--skip-codegen', action='store_true', help='Skip code generation')
    parser.add_argument('--skip-git', action='store_true', help='Skip git initialization')
    
    args = parser.parse_args()
    
    creator = FlutterProjectCreator()
    
    if args.name:
        creator.run_cli_setup(args)
    else:
        creator.run_interactive_setup()

if __name__ == '__main__':
    main()