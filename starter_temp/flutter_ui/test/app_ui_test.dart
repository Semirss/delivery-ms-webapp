import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/app_ui.dart';

void main() {
  group('Barrel Export Tests', () {
    test('should export all design token classes', () {
      // Test that all design token classes are accessible
      expect(AppColors.primary, isA<Color>());
      expect(AppSpacing.md, isA<double>());
      expect(AppRadius.lg, isA<double>());
      expect(AppShadows.sm, isA<List<BoxShadow>>());
      expect(AppTypography.bodyMedium, isA<TextStyle>());
    });

    test('should export AppTheme class', () {
      // Test that AppTheme is accessible
      expect(AppTheme.lightTheme, isA<ThemeData>());
      expect(AppTheme.darkTheme, isA<ThemeData>());
    });

    test('should export all button components and enums', () {
      // Test AppButton and its enums
      expect(AppButtonVariant.primary, isA<AppButtonVariant>());
      expect(AppButtonSize.medium, isA<AppButtonSize>());

      final button = AppButton.primary(label: 'Test', onPressed: () {});
      expect(button, isA<AppButton>());
      expect(button, isA<Widget>());
    });

    test('should export AppIconButton component', () {
      // Test AppIconButton
      final iconButton = AppIconButton(icon: Icons.add, onPressed: () {});
      expect(iconButton, isA<AppIconButton>());
      expect(iconButton, isA<Widget>());
    });

    test('should export all form field components and enums', () {
      // Test AppTextField and its enum
      expect(AppTextFieldVariant.outlined, isA<AppTextFieldVariant>());

      final textField = AppTextField.outlined(label: 'Test');
      expect(textField, isA<AppTextField>());
      expect(textField, isA<Widget>());

      // Test AppDropdown and its enum
      expect(AppDropdownSize.medium, isA<AppDropdownSize>());

      final dropdown = AppDropdown<String>.medium(items: ['Item 1', 'Item 2']);
      expect(dropdown, isA<AppDropdown<String>>());
      expect(dropdown, isA<Widget>());

      // Test AppCheckbox and its enum
      expect(AppCheckboxVariant.primary, isA<AppCheckboxVariant>());

      final checkbox = AppCheckbox.primary(value: true, onChanged: (value) {});
      expect(checkbox, isA<AppCheckbox>());
      expect(checkbox, isA<Widget>());

      // Test AppRadio
      final radio = AppRadio<int>(
        value: 1,
        groupValue: 1,
        onChanged: (value) {},
      );
      expect(radio, isA<AppRadio<int>>());
      expect(radio, isA<Widget>());
    });

    test('should export card components and enums', () {
      // Test AppDataCard and its enums
      expect(AppDataCardVariant.metric, isA<AppDataCardVariant>());
      expect(AppDataCardImagePlacement.top, isA<AppDataCardImagePlacement>());

      final card = AppDataCard.metric(title: 'Test', value: '100');
      expect(card, isA<AppDataCard>());
      expect(card, isA<Widget>());
    });

    test('should export modal component and enums', () {
      // Test AppModal and its enums
      expect(AppModalSize.medium, isA<AppModalSize>());
      expect(AppModalVariant.default_, isA<AppModalVariant>());

      final modal = AppModal(title: 'Test', contentText: 'Test content');
      expect(modal, isA<AppModal>());
      expect(modal, isA<Widget>());

      // Test AppModalAction
      final action = AppModalAction(label: 'OK', onPressed: () {});
      expect(action, isA<AppModalAction>());
    });

    test('should export dialog component and enums', () {
      // Test AppDialog and its enums
      expect(AppDialogVariant.confirmation, isA<AppDialogVariant>());
      expect(AppDialogSize.medium, isA<AppDialogSize>());
      expect(AppDialogAnimation.scale, isA<AppDialogAnimation>());

      final dialog = AppDialog(title: 'Test', contentText: 'Test message');
      expect(dialog, isA<AppDialog>());
      expect(dialog, isA<Widget>());

      // Test AppDialogAction
      final action = AppDialogAction(label: 'OK', onPressed: () {});
      expect(action, isA<AppDialogAction>());
    });

    test('should export all button variant enum values', () {
      // Verify all button variant values are accessible
      expect(AppButtonVariant.values, hasLength(5));
      expect(AppButtonVariant.values, contains(AppButtonVariant.primary));
      expect(AppButtonVariant.values, contains(AppButtonVariant.secondary));
      expect(AppButtonVariant.values, contains(AppButtonVariant.tertiary));
      expect(AppButtonVariant.values, contains(AppButtonVariant.ghost));
      expect(AppButtonVariant.values, contains(AppButtonVariant.custom));
    });

    test('should export all button size enum values', () {
      // Verify all button size values are accessible
      expect(AppButtonSize.values, hasLength(3));
      expect(AppButtonSize.values, contains(AppButtonSize.small));
      expect(AppButtonSize.values, contains(AppButtonSize.medium));
      expect(AppButtonSize.values, contains(AppButtonSize.large));
    });

    test('should export all text field variant enum values', () {
      // Verify all text field variant values are accessible
      expect(AppTextFieldVariant.values, hasLength(4));
      expect(
        AppTextFieldVariant.values,
        contains(AppTextFieldVariant.outlined),
      );
      expect(AppTextFieldVariant.values, contains(AppTextFieldVariant.filled));
      expect(
        AppTextFieldVariant.values,
        contains(AppTextFieldVariant.underlined),
      );
      expect(AppTextFieldVariant.values, contains(AppTextFieldVariant.custom));
    });

    test('should export all dropdown size enum values', () {
      // Verify all dropdown size values are accessible
      expect(AppDropdownSize.values, hasLength(3));
      expect(AppDropdownSize.values, contains(AppDropdownSize.small));
      expect(AppDropdownSize.values, contains(AppDropdownSize.medium));
      expect(AppDropdownSize.values, contains(AppDropdownSize.large));
    });

    test('should export all checkbox variant enum values', () {
      // Verify all checkbox variant values are accessible
      expect(AppCheckboxVariant.values, hasLength(4));
      expect(AppCheckboxVariant.values, contains(AppCheckboxVariant.primary));
      expect(AppCheckboxVariant.values, contains(AppCheckboxVariant.secondary));
      expect(AppCheckboxVariant.values, contains(AppCheckboxVariant.compact));
      expect(AppCheckboxVariant.values, contains(AppCheckboxVariant.custom));
    });

    test('should export all data card variant enum values', () {
      // Verify all data card variant values are accessible
      expect(AppDataCardVariant.values, hasLength(5));
      expect(AppDataCardVariant.values, contains(AppDataCardVariant.metric));
      expect(AppDataCardVariant.values, contains(AppDataCardVariant.compact));
      expect(AppDataCardVariant.values, contains(AppDataCardVariant.withIcon));
      expect(AppDataCardVariant.values, contains(AppDataCardVariant.gradient));
      expect(AppDataCardVariant.values, contains(AppDataCardVariant.clickable));
    });

    test('should export all data card image placement enum values', () {
      // Verify all image placement values are accessible
      expect(AppDataCardImagePlacement.values, hasLength(5));
      expect(
        AppDataCardImagePlacement.values,
        contains(AppDataCardImagePlacement.top),
      );
      expect(
        AppDataCardImagePlacement.values,
        contains(AppDataCardImagePlacement.bottom),
      );
      expect(
        AppDataCardImagePlacement.values,
        contains(AppDataCardImagePlacement.left),
      );
      expect(
        AppDataCardImagePlacement.values,
        contains(AppDataCardImagePlacement.right),
      );
      expect(
        AppDataCardImagePlacement.values,
        contains(AppDataCardImagePlacement.background),
      );
    });

    test('should export all dialog variant enum values', () {
      // Verify all dialog variant values are accessible
      expect(AppDialogVariant.values, hasLength(8));
      expect(AppDialogVariant.values, contains(AppDialogVariant.default_));
      expect(AppDialogVariant.values, contains(AppDialogVariant.alert));
      expect(AppDialogVariant.values, contains(AppDialogVariant.confirmation));
      expect(AppDialogVariant.values, contains(AppDialogVariant.success));
      expect(AppDialogVariant.values, contains(AppDialogVariant.error));
      expect(AppDialogVariant.values, contains(AppDialogVariant.info));
      expect(AppDialogVariant.values, contains(AppDialogVariant.warning));
      expect(AppDialogVariant.values, contains(AppDialogVariant.destructive));
    });

    test('should allow importing from single entry point', () {
      // This test verifies that all imports work from the barrel file
      // by checking that we can access various symbols without errors

      // Design tokens
      final color = AppColors.primary;
      final spacing = AppSpacing.lg;
      final radius = AppRadius.md;
      final shadows = AppShadows.sm;
      final typography = AppTypography.bodyMedium;

      // Theme
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      // Components
      final button = AppButton.primary(label: 'Test', onPressed: () {});
      final textField = AppTextField.outlined();
      final dropdown = AppDropdown<String>.medium(items: []);
      final checkbox = AppCheckbox.primary(value: true);
      final card = AppDataCard.metric(title: 'Test', value: '100');
      final modal = AppModal(title: 'Test', contentText: 'Test');
      final dialog = AppDialog(title: 'Test', contentText: 'Test');

      // Verify all are non-null
      expect(color, isNotNull);
      expect(spacing, isNotNull);
      expect(radius, isNotNull);
      expect(shadows, isNotNull);
      expect(typography, isNotNull);
      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(button, isNotNull);
      expect(textField, isNotNull);
      expect(dropdown, isNotNull);
      expect(checkbox, isNotNull);
      expect(card, isNotNull);
      expect(modal, isNotNull);
      expect(dialog, isNotNull);
    });
  });

  group('AppTheme', () {
    test('lightTheme should be configured correctly', () {
      final theme = AppTheme.lightTheme;

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('darkTheme should be configured correctly', () {
      final theme = AppTheme.darkTheme;

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primaryLight);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    });

    test('lightTheme should have proper text theme', () {
      final theme = AppTheme.lightTheme;

      expect(theme.textTheme.displayLarge?.color, AppColors.textPrimary);
      expect(theme.textTheme.bodyLarge?.color, AppColors.textPrimary);
    });

    test('darkTheme should have proper text theme', () {
      final theme = AppTheme.darkTheme;

      expect(theme.textTheme.displayLarge?.color, AppColors.darkTextPrimary);
      expect(theme.textTheme.bodyLarge?.color, AppColors.darkTextPrimary);
    });

    test('lightTheme should have card theme configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme.cardTheme.color, AppColors.surface);
      expect(theme.cardTheme.elevation, 0);
    });

    test('darkTheme should have card theme configured', () {
      final theme = AppTheme.darkTheme;

      expect(theme.cardTheme.color, AppColors.darkSurface);
      expect(theme.cardTheme.elevation, 0);
    });

    test('lightTheme should have input decoration theme configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme.inputDecorationTheme.filled, true);
      expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
    });

    test('darkTheme should have input decoration theme configured', () {
      final theme = AppTheme.darkTheme;

      expect(theme.inputDecorationTheme.filled, true);
      expect(theme.inputDecorationTheme.fillColor, AppColors.darkSurface);
    });
  });
}
