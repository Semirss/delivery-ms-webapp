# App UI - Comprehensive Examples

This document provides detailed examples for all App UI components and design tokens.

## Table of Contents

- [Design Tokens](#design-tokens)
  - [Colors](#colors)
  - [Typography](#typography)
  - [Spacing](#spacing)
  - [Border Radius](#border-radius)
  - [Shadows](#shadows)
- [Components](#components)
  - [Buttons](#buttons)
  - [Text Fields](#text-fields)
  - [Dropdowns](#dropdowns)
  - [Checkboxes](#checkboxes)
  - [Radio Buttons](#radio-buttons)
  - [Data Cards](#data-cards)
  - [Dialogs](#dialogs)
- [Theme Configuration](#theme-configuration)
- [Common Patterns](#common-patterns)

## Design Tokens

### Colors

App UI provides a comprehensive color palette with semantic meanings:

```dart
import 'package:flutter_ui/app_ui.dart';
// Primary colors for main actions
Container(color: AppColors.primary)
Container(color: AppColors.primaryLight)
Container(color: AppColors.primaryDark)

// Secondary colors for complementary actions
Container(color: AppColors.secondary)
Container(color: AppColors.secondaryLight)
Container(color: AppColors.secondaryDark)

// Accent colors for variety
Container(color: AppColors.accent1) // Cyan
Container(color: AppColors.accent2) // Green
Container(color: AppColors.accent3) // Amber
Container(color: AppColors.accent4) // Red

// Semantic colors for meaning
Container(color: AppColors.success) // Green for success
Container(color: AppColors.warning) // Amber for warnings
Container(color: AppColors.error)   // Red for errors
Container(color: AppColors.info)    // Blue for information

// Neutral colors for layout
Container(color: AppColors.background)
Container(color: AppColors.surface)
Container(color: AppColors.surfaceAlt)
Container(color: AppColors.border)

// Text colors
Text('Primary', style: TextStyle(color: AppColors.textPrimary))
Text('Secondary', style: TextStyle(color: AppColors.textSecondary))
Text('Disabled', style: TextStyle(color: AppColors.textDisabled))

// Dark mode colors
Container(color: AppColors.darkBackground)
Container(color: AppColors.darkSurface)
Text('Dark Text', style: TextStyle(color: AppColors.darkTextPrimary))
```

### Typography

Consistent text styles for all content:

```dart
// Headings
Text('Page Title', style: AppTypography.heading1)
Text('Section Title', style: AppTypography.heading2)
Text('Subsection Title', style: AppTypography.heading3)

// Body text
Text('Large body text', style: AppTypography.bodyLarge)
Text('Standard body text', style: AppTypography.bodyMedium)
Text('Small body text', style: AppTypography.bodySmall)

// Labels
Text('Large Label', style: AppTypography.labelLarge)
Text('Medium Label', style: AppTypography.labelMedium)
Text('Small Label', style: AppTypography.labelSmall)

// Customizing text styles
Text(
  'Custom Text',
  style: AppTypography.bodyMedium.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  ),
)
```

### Spacing

Standardized spacing for consistent layouts:

```dart
// Padding examples
Container(padding: EdgeInsets.all(AppSpacing.xs))   // 4px
Container(padding: EdgeInsets.all(AppSpacing.sm))   // 8px
Container(padding: EdgeInsets.all(AppSpacing.md))   // 12px
Container(padding: EdgeInsets.all(AppSpacing.lg))   // 16px
Container(padding: EdgeInsets.all(AppSpacing.xl))   // 20px
Container(padding: EdgeInsets.all(AppSpacing.xxl))  // 24px
Container(padding: EdgeInsets.all(AppSpacing.xxxl)) // 32px

// Margin examples
Container(margin: EdgeInsets.symmetric(vertical: AppSpacing.md))
Container(margin: EdgeInsets.only(bottom: AppSpacing.lg))

// Gap in Column/Row
Column(
  children: [
    Widget1(),
    SizedBox(height: AppSpacing.md),
    Widget2(),
  ],
)
```

### Border Radius

Consistent rounded corners:

```dart
// Border radius examples
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.sm),   // 4px
  ),
)

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.md),   // 8px
  ),
)

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg),   // 12px
  ),
)

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.xl),   // 16px
  ),
)

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.xxl),  // 24px
  ),
)

// Fully rounded (pill shape)
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.full), // 9999px
  ),
)
```

### Shadows

Elevation shadows for depth:

```dart
// Shadow examples
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.sm, // Subtle elevation
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.md, // Standard elevation
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.lg, // Prominent elevation
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)

Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.xl, // Maximum elevation
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

## Components

### Buttons

#### Basic Button Variants

```dart
// Primary button - Main call-to-action
AppButton.primary(
  label: 'Submit',
  onPressed: () => print('Submitted'),
)

// Secondary button - Alternative action
AppButton.secondary(
  label: 'Cancel',
  onPressed: () => print('Cancelled'),
)

// Tertiary button - Subtle action
AppButton.tertiary(
  label: 'Learn More',
  onPressed: () => print('Learn more'),
)

// Ghost button - Minimal styling
AppButton.ghost(
  label: 'Skip',
  onPressed: () => print('Skipped'),
)
```

#### Button Sizes

```dart
// Small button
AppButton.primary(
  label: 'Small',
  size: AppButtonSize.small,
  onPressed: () {},
)

// Medium button (default)
AppButton.primary(
  label: 'Medium',
  size: AppButtonSize.medium,
  onPressed: () {},
)

// Large button
AppButton.primary(
  label: 'Large',
  size: AppButtonSize.large,
  onPressed: () {},
)
```

#### Button with Icon

```dart
// Button with leading icon
AppButton.primary(
  label: 'Download',
  icon: Icons.download,
  onPressed: () => print('Download'),
)

// Icon-only button
AppButton.icon(
  icon: Icons.add,
  onPressed: () => print('Add'),
)
```

#### Button States

```dart
// Loading state
AppButton.primary(
  label: 'Processing',
  isLoading: true,
  onPressed: null,
)

// Disabled state
AppButton.primary(
  label: 'Disabled',
  onPressed: null, // null onPressed disables the button
)
```

#### Custom Button Colors

```dart
AppButton.custom(
  label: 'Custom',
  backgroundColor: AppColors.accent1,
  foregroundColor: Colors.white,
  onPressed: () => print('Custom pressed'),
)
```

### Text Fields

#### Basic Text Field Variants

```dart
// Outlined text field
AppTextField.outlined(
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
)

// Filled text field
AppTextField.filled(
  label: 'Username',
  hint: 'Enter username',
)

// Underlined text field
AppTextField.underlined(
  label: 'Search',
  hint: 'Search...',
)
```

#### Text Field with Icons

```dart
// Prefix icon
AppTextField.outlined(
  label: 'Email',
  hint: 'Enter your email',
  prefixIcon: Icons.email,
)

// Suffix icon with callback
AppTextField.outlined(
  label: 'Password',
  hint: 'Enter password',
  obscureText: true,
  suffixIcon: Icons.visibility,
  onSuffixPressed: () => print('Toggle visibility'),
)

// Both prefix and suffix icons
AppTextField.outlined(
  label: 'Search',
  hint: 'Search...',
  prefixIcon: Icons.search,
  suffixIcon: Icons.clear,
  onSuffixPressed: () => print('Clear'),
)
```

#### Text Field with Validation

```dart
AppTextField.outlined(
  label: 'Email',
  hint: 'Enter your email',
  errorText: 'Please enter a valid email',
  keyboardType: TextInputType.emailAddress,
)
```

#### Multi-line Text Field

```dart
AppTextField.outlined(
  label: 'Description',
  hint: 'Enter description',
  maxLines: 4,
)
```

#### Text Field with Controller

```dart
final controller = TextEditingController();

AppTextField.outlined(
  label: 'Name',
  hint: 'Enter your name',
  controller: controller,
  onChanged: (value) => print('Changed: $value'),
)
```

### Dropdowns

#### Basic Dropdown

```dart
AppDropdown<String>.medium(
  label: 'Country',
  items: ['USA', 'Canada', 'Mexico', 'UK'],
  value: 'USA',
  onChanged: (value) => print('Selected: $value'),
)
```

#### Dropdown Sizes

```dart
// Small dropdown
AppDropdown<String>.small(
  label: 'Size',
  items: ['S', 'M', 'L', 'XL'],
  onChanged: (value) => print(value),
)

// Medium dropdown (default)
AppDropdown<String>.medium(
  label: 'Country',
  items: countries,
  onChanged: (value) => print(value),
)

// Large dropdown
AppDropdown<String>.large(
  label: 'Category',
  items: categories,
  onChanged: (value) => print(value),
)
```

#### Searchable Dropdown

```dart
AppDropdown<String>.searchable(
  label: 'City',
  items: cities,
  searchHint: 'Search cities...',
  onChanged: (value) => print('Selected: $value'),
)
```

#### Multi-Select Dropdown

```dart
AppDropdown<String>.multiSelect(
  label: 'Tags',
  items: ['Flutter', 'Dart', 'Mobile', 'Web', 'Desktop'],
  values: ['Flutter', 'Dart'],
  onMultiChanged: (values) => print('Selected: $values'),
)
```

#### Dropdown with Custom Item Builder

```dart
class User {
  final String name;
  final String email;
  User(this.name, this.email);
}

AppDropdown<User>.medium(
  label: 'User',
  items: users,
  itemBuilder: (user) => '${user.name} (${user.email})',
  onChanged: (user) => print('Selected: ${user?.name}'),
)
```

### Checkboxes

#### Basic Checkbox

```dart
AppCheckbox.primary(
  label: 'Accept terms and conditions',
  value: true,
  onChanged: (value) => print('Checked: $value'),
)
```

#### Checkbox with Description

```dart
AppCheckbox.primary(
  label: 'Enable notifications',
  description: 'Receive updates about your account activity',
  value: false,
  onChanged: (value) => print('Checked: $value'),
)
```

#### Checkbox Variants

```dart
// Primary checkbox
AppCheckbox.primary(
  label: 'Primary',
  value: true,
  onChanged: (value) {},
)

// Secondary checkbox
AppCheckbox.secondary(
  label: 'Secondary',
  value: true,
  onChanged: (value) {},
)

// Compact checkbox
AppCheckbox.compact(
  label: 'Compact',
  value: true,
  onChanged: (value) {},
)
```

#### Disabled Checkbox

```dart
AppCheckbox.primary(
  label: 'Disabled',
  value: false,
  onChanged: null, // null onChanged disables the checkbox
)
```

#### Custom Checkbox Colors

```dart
AppCheckbox.custom(
  label: 'Custom',
  value: true,
  activeColor: AppColors.accent1,
  onChanged: (value) {},
)
```

### Radio Buttons

```dart
// Radio button group example
String selectedValue = 'option1';

Column(
  children: [
    AppRadio<String>.primary(
      label: 'Option 1',
      value: 'option1',
      groupValue: selectedValue,
      onChanged: (value) => setState(() => selectedValue = value!),
    ),
    AppRadio<String>.primary(
      label: 'Option 2',
      value: 'option2',
      groupValue: selectedValue,
      onChanged: (value) => setState(() => selectedValue = value!),
    ),
    AppRadio<String>.primary(
      label: 'Option 3',
      value: 'option3',
      groupValue: selectedValue,
      onChanged: (value) => setState(() => selectedValue = value!),
    ),
  ],
)
```

### Data Cards

#### Metric Card

```dart
AppDataCard.metric(
  title: 'Total Revenue',
  value: '\$45,231',
  change: '+12.5%',
  isPositive: true,
)
```

#### Compact Card

```dart
AppDataCard.compact(
  title: 'Active Users',
  value: '2,543',
  trailing: Icon(Icons.arrow_forward, size: 16),
)
```

#### Card with Icon

```dart
AppDataCard.withIcon(
  title: 'Conversion Rate',
  value: '3.24%',
  icon: Icons.trending_up,
  iconColor: AppColors.success,
  change: '+0.5%',
  isPositive: true,
)
```

#### Gradient Card

```dart
AppDataCard.gradient(
  title: 'Premium Users',
  value: '1,234',
  gradientColors: [AppColors.primary, AppColors.secondary],
  icon: Icons.star,
)
```

#### Clickable Card

```dart
AppDataCard.clickable(
  title: 'View Details',
  value: '156',
  icon: Icons.arrow_forward,
  change: '+23',
  isPositive: true,
  onTap: () => print('Card tapped'),
)
```

### Dialogs

#### Confirmation Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.confirmation(
    title: 'Delete Item',
    message: 'Are you sure you want to delete this item? This action cannot be undone.',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
    onConfirm: () {
      Navigator.pop(context);
      // Perform delete action
    },
    onCancel: () => Navigator.pop(context),
  ),
);
```

#### Success Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.success(
    title: 'Success',
    message: 'Your changes have been saved successfully.',
    onClose: () => Navigator.pop(context),
  ),
);
```

#### Error Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.error(
    title: 'Error',
    message: 'Something went wrong. Please try again.',
    onRetry: () {
      Navigator.pop(context);
      // Retry action
    },
    onClose: () => Navigator.pop(context),
  ),
);
```

#### Warning Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.warning(
    title: 'Warning',
    message: 'This action may have unintended consequences.',
    onConfirm: () => Navigator.pop(context),
  ),
);
```

#### Info Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.info(
    title: 'Information',
    message: 'Here is some important information you should know.',
    onClose: () => Navigator.pop(context),
  ),
);
```

#### Custom Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog.custom(
    title: 'Custom Dialog',
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Custom content goes here'),
        SizedBox(height: AppSpacing.md),
        AppTextField.outlined(
          label: 'Input',
          hint: 'Enter value',
        ),
      ],
    ),
    actions: [
      AppButton.secondary(
        label: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
      AppButton.primary(
        label: 'Submit',
        onPressed: () {
          Navigator.pop(context);
          // Handle submission
        },
      ),
    ],
  ),
);
```

## Theme Configuration

### Basic Theme Setup

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
      title: 'App UI App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system theme
      home: const HomePage(),
    );
  }
}
```

### Manual Theme Switching

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomePage(onToggleTheme: _toggleTheme),
    );
  }
}
```

### Custom Theme

```dart
class CustomTheme {
  static ThemeData get lightTheme {
    return AppTheme.lightTheme.copyWith(
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: const Color(0xFF1E40AF), // Custom primary color
      ),
    );
  }

  static ThemeData get darkTheme {
    return AppTheme.darkTheme.copyWith(
      colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
        primary: const Color(0xFF60A5FA), // Custom primary color for dark
      ),
    );
  }
}

// Use custom theme
MaterialApp(
  theme: CustomTheme.lightTheme,
  darkTheme: CustomTheme.darkTheme,
  home: HomePage(),
)
```

## Common Patterns

### Form Layout

```dart
class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Login', style: AppTypography.heading2),
          SizedBox(height: AppSpacing.xl),
          
          AppTextField.outlined(
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
          ),
          SizedBox(height: AppSpacing.md),
          
          AppTextField.outlined(
            label: 'Password',
            hint: 'Enter your password',
            obscureText: true,
            prefixIcon: Icons.lock,
            suffixIcon: Icons.visibility,
          ),
          SizedBox(height: AppSpacing.sm),
          
          AppCheckbox.compact(
            label: 'Remember me',
            value: false,
            onChanged: (value) {},
          ),
          SizedBox(height: AppSpacing.xl),
          
          AppButton.primary(
            label: 'Login',
            size: AppButtonSize.large,
            onPressed: () {},
          ),
          SizedBox(height: AppSpacing.md),
          
          AppButton.ghost(
            label: 'Forgot password?',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
```

### Dashboard Cards Grid

```dart
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        AppDataCard.metric(
          title: 'Total Revenue',
          value: '\$45,231',
          change: '+12.5%',
          isPositive: true,
        ),
        AppDataCard.withIcon(
          title: 'Active Users',
          value: '2,543',
          icon: Icons.people,
          iconColor: AppColors.primary,
          change: '+8.2%',
          isPositive: true,
        ),
        AppDataCard.gradient(
          title: 'Conversion',
          value: '3.24%',
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: Icons.trending_up,
        ),
        AppDataCard.clickable(
          title: 'View Details',
          value: '156',
          icon: Icons.arrow_forward,
          onTap: () => print('Tapped'),
        ),
      ],
    );
  }
}
```

### Settings List

```dart
class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Notifications', style: AppTypography.heading3),
        SizedBox(height: AppSpacing.md),
        
        AppCheckbox.primary(
          label: 'Email notifications',
          description: 'Receive updates via email',
          value: true,
          onChanged: (value) {},
        ),
        SizedBox(height: AppSpacing.sm),
        
        AppCheckbox.primary(
          label: 'Push notifications',
          description: 'Receive push notifications on your device',
          value: false,
          onChanged: (value) {},
        ),
        SizedBox(height: AppSpacing.xl),
        
        Text('Preferences', style: AppTypography.heading3),
        SizedBox(height: AppSpacing.md),
        
        AppDropdown<String>.medium(
          label: 'Language',
          items: ['English', 'Spanish', 'French', 'German'],
          value: 'English',
          onChanged: (value) {},
        ),
        SizedBox(height: AppSpacing.md),
        
        AppDropdown<String>.medium(
          label: 'Theme',
          items: ['Light', 'Dark', 'System'],
          value: 'System',
          onChanged: (value) {},
        ),
      ],
    );
  }
}
```

### Action Buttons Row

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    AppButton.secondary(
      label: 'Cancel',
      onPressed: () => Navigator.pop(context),
    ),
    SizedBox(width: AppSpacing.sm),
    AppButton.primary(
      label: 'Save',
      onPressed: () {
        // Save action
      },
    ),
  ],
)
```

### Loading State

```dart
class LoadingExample extends StatefulWidget {
  const LoadingExample({super.key});

  @override
  State<LoadingExample> createState() => _LoadingExampleState();
}

class _LoadingExampleState extends State<LoadingExample> {
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      label: _isLoading ? 'Processing...' : 'Submit',
      isLoading: _isLoading,
      onPressed: _isLoading ? null : _handleSubmit,
    );
  }
}
```

This comprehensive examples document covers all major use cases and patterns for App UI components.
