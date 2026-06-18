# App UI

A professional, production-ready Flutter UI component library inspired by shadcn/ui's philosophy. App UI provides beautiful, accessible, and highly customizable components with a comprehensive design system.

## Features

✨ **Comprehensive Design System** - Centralized design tokens for colors, typography, spacing, radius, and shadows

🎨 **Rich Component Variants** - Multiple pre-configured variants accessible through factory constructors

🌓 **Seamless Theme Support** - Built-in light and dark mode with automatic theme switching

♿ **Accessibility First** - WCAG AA compliant with proper semantic labels and touch targets

🎯 **Type Safe** - Strong typing with enums and immutable widgets

🚀 **Zero Manual Styling** - All styling through design tokens, no hardcoded values

## Components

- **Buttons**: Primary, secondary, tertiary, ghost, icon, and custom variants
- **Text Fields**: Outlined, filled, and underlined variants with validation support
- **Dropdowns**: Single and multi-select with search functionality
- **Checkboxes & Radios**: Multiple variants with label and description support
- **Data Cards**: Metric cards with change indicators, icons, and gradients
- **Dialogs**: Confirmation, success, error, warning, and info dialogs
- **Modals**: Customizable modal overlays

## Getting Started

### Installation

Add App UI to your `pubspec.yaml`:

#### Option 1: From GitLab (Recommended)

```yaml
dependencies:
  flutter_ui:
    git:
      url: https://...../flutter-ui-library/flutter-ui-mobile.git
      ref: dev  # or specify a version tag
```

#### Option 2: From Local Path

```yaml
dependencies:
  flutter_ui:
    path: ../flutter_ui
```

#### Option 3: From pub.dev (Coming Soon)

```yaml
dependencies:
  flutter_ui: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Basic Setup

Wrap your app with the App UI theme:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App UI Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}
```

## Usage

### Buttons

App UI provides multiple button variants with consistent sizing and states:

```dart
// Primary button
AppButton.primary(
  label: 'Submit',
  onPressed: () => print('Pressed'),
  size: AppButtonSize.medium,
)

// Secondary button with icon
AppButton.secondary(
  label: 'Cancel',
  icon: Icons.close,
  onPressed: () => print('Cancelled'),
)

// Loading state
AppButton.primary(
  label: 'Processing',
  isLoading: true,
  onPressed: null,
)

// Custom colors
AppButton.custom(
  label: 'Custom',
  backgroundColor: AppColors.accent1,
  foregroundColor: Colors.white,
  onPressed: () => print('Custom pressed'),
)
```

### Text Fields

Create beautiful text inputs with validation and icons:

```dart
// Outlined text field
AppTextField.outlined(
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email,
)

// Filled text field with validation
AppTextField.filled(
  label: 'Password',
  hint: 'Enter password',
  obscureText: true,
  errorText: 'Password is required',
  suffixIcon: Icons.visibility,
  onSuffixPressed: () => print('Toggle visibility'),
)

// Multi-line text field
AppTextField.outlined(
  label: 'Description',
  hint: 'Enter description',
  maxLines: 4,
)
```

### Dropdowns

Single and multi-select dropdowns with search:

```dart
// Simple dropdown
AppDropdown<String>.medium(
  label: 'Country',
  items: ['USA', 'Canada', 'Mexico'],
  value: 'USA',
  onChanged: (value) => print('Selected: $value'),
)

// Searchable dropdown
AppDropdown<String>.searchable(
  label: 'City',
  items: cities,
  searchHint: 'Search cities...',
  onChanged: (value) => print('Selected: $value'),
)

// Multi-select dropdown
AppDropdown<String>.multiSelect(
  label: 'Tags',
  items: ['Flutter', 'Dart', 'Mobile', 'Web'],
  values: ['Flutter', 'Dart'],
  onMultiChanged: (values) => print('Selected: $values'),
)
```

### Checkboxes

Checkboxes with labels and descriptions:

```dart
// Primary checkbox
AppCheckbox.primary(
  label: 'Accept terms and conditions',
  value: true,
  onChanged: (value) => print('Checked: $value'),
)

// Checkbox with description
AppCheckbox.primary(
  label: 'Enable notifications',
  description: 'Receive updates about your account activity',
  value: false,
  onChanged: (value) => print('Checked: $value'),
)

// Compact checkbox
AppCheckbox.compact(
  label: 'Remember me',
  value: true,
  onChanged: (value) => print('Checked: $value'),
)
```

### Data Cards

Display metrics and data with beautiful cards:

```dart
// Metric card with change indicator
AppDataCard.metric(
  title: 'Total Revenue',
  value: '\$45,231',
  change: '+12.5%',
  isPositive: true,
)

// Card with icon
AppDataCard.withIcon(
  title: 'Active Users',
  value: '2,543',
  icon: Icons.people,
  iconColor: AppColors.primary,
  change: '+8.2%',
  isPositive: true,
)

// Gradient card
AppDataCard.gradient(
  title: 'Conversion Rate',
  value: '3.24%',
  gradientColors: [AppColors.primary, AppColors.secondary],
  icon: Icons.trending_up,
)

// Clickable card
AppDataCard.clickable(
  title: 'View Details',
  value: '156',
  icon: Icons.arrow_forward,
  onTap: () => print('Card tapped'),
)
```

### Dialogs

Show confirmation and alert dialogs:

```dart
// Confirmation dialog
showDialog(
  context: context,
  builder: (context) => AppDialog.confirmation(
    title: 'Delete Item',
    message: 'Are you sure you want to delete this item?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    onConfirm: () {
      Navigator.pop(context);
      print('Confirmed');
    },
    onCancel: () => Navigator.pop(context),
  ),
);

// Success dialog
showDialog(
  context: context,
  builder: (context) => AppDialog.success(
    title: 'Success',
    message: 'Your changes have been saved successfully.',
    onClose: () => Navigator.pop(context),
  ),
);

// Error dialog
showDialog(
  context: context,
  builder: (context) => AppDialog.error(
    title: 'Error',
    message: 'Something went wrong. Please try again.',
    onRetry: () {
      Navigator.pop(context);
      print('Retry');
    },
  ),
);
```

## Design Tokens

App UI uses centralized design tokens for consistent styling:

### Colors

```dart
// Primary colors
AppColors.primary
AppColors.primaryLight
AppColors.primaryDark

// Semantic colors
AppColors.success
AppColors.warning
AppColors.error
AppColors.info

// Neutral colors
AppColors.background
AppColors.surface
AppColors.textPrimary
AppColors.textSecondary

// Dark mode colors
AppColors.darkBackground
AppColors.darkSurface
AppColors.darkTextPrimary
```

### Typography

```dart
// Headings
AppTypography.heading1
AppTypography.heading2
AppTypography.heading3

// Body text
AppTypography.bodyLarge
AppTypography.bodyMedium
AppTypography.bodySmall

// Labels
AppTypography.labelLarge
AppTypography.labelMedium
AppTypography.labelSmall
```

### Spacing

```dart
AppSpacing.xs   // 4.0
AppSpacing.sm   // 8.0
AppSpacing.md   // 12.0
AppSpacing.lg   // 16.0
AppSpacing.xl   // 20.0
AppSpacing.xxl  // 24.0
AppSpacing.xxxl // 32.0
```

### Border Radius

```dart
AppRadius.sm   // 4.0
AppRadius.md   // 8.0
AppRadius.lg   // 12.0
AppRadius.xl   // 16.0
AppRadius.xxl  // 24.0
AppRadius.full // 9999.0
```

### Shadows

```dart
AppShadows.sm  // Small elevation
AppShadows.md  // Medium elevation
AppShadows.lg  // Large elevation
AppShadows.xl  // Extra large elevation
```

## Theme Customization

You can customize the theme by modifying design tokens or extending the theme:

```dart
// Custom theme with modified colors
class CustomTheme {
  static ThemeData get lightTheme {
    return AppTheme.lightTheme.copyWith(
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: const Color(0xFF1E40AF),
      ),
    );
  }
}

// Use custom theme
MaterialApp(
  theme: CustomTheme.lightTheme,
  home: MyHomePage(),
)
```

## Accessibility

App UI components are built with accessibility in mind:

- ✅ WCAG AA compliant contrast ratios
- ✅ Minimum 44x44 pixel touch targets
- ✅ Semantic labels for screen readers
- ✅ Keyboard navigation support
- ✅ Focus indicators
- ✅ State announcements for assistive technologies

## Best Practices

### Use Factory Constructors

Always use factory constructors for consistent styling:

```dart
// ✅ Good
AppButton.primary(label: 'Submit', onPressed: () {})

// ❌ Avoid
AppButton(
  label: 'Submit',
  variant: AppButtonVariant.primary,
  onPressed: () {},
)
```

### Leverage Design Tokens

Use design tokens instead of hardcoded values:

```dart
// ✅ Good
Container(
  padding: EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

// ❌ Avoid
Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFFF9FAFB),
    borderRadius: BorderRadius.circular(8.0),
  ),
)
```

### Handle States Properly

Always handle loading and disabled states:

```dart
AppButton.primary(
  label: isLoading ? 'Processing...' : 'Submit',
  isLoading: isLoading,
  onPressed: isLoading ? null : _handleSubmit,
)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions, please file an issue on the GitHub repository.
