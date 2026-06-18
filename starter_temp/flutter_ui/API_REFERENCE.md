# App UI API Reference

Complete API reference for all App UI components and design tokens.

## Table of Contents

- [Design Tokens](#design-tokens)
- [Components](#components)
- [Enums](#enums)

## Design Tokens

### AppColors

Centralized color palette for the design system.

#### Primary Colors
```dart
static const Color primary       // #6366F1
static const Color primaryLight  // #818CF8
static const Color primaryDark   // #4F46E5
```

#### Secondary Colors
```dart
static const Color secondary       // #8B5CF6
static const Color secondaryLight  // #A78BFA
static const Color secondaryDark   // #7C3AED
```

#### Accent Colors
```dart
static const Color accent1  // #06B6D4 (Cyan)
static const Color accent2  // #10B981 (Green)
static const Color accent3  // #F59E0B (Amber)
static const Color accent4  // #EF4444 (Red)
```

#### Semantic Colors
```dart
static const Color success  // #10B981
static const Color warning  // #F59E0B
static const Color error    // #EF4444
static const Color info     // #3B82F6
```

#### Neutral Colors
```dart
static const Color background    // #FFFFFF
static const Color surface       // #F9FAFB
static const Color surfaceAlt    // #F3F4F6
static const Color border        // #E5E7EB
static const Color textPrimary   // #111827
static const Color textSecondary // #6B7280
static const Color textDisabled  // #9CA3AF
```

#### Dark Mode Colors
```dart
static const Color darkBackground    // #111827
static const Color darkSurface       // #1F2937
static const Color darkSurfaceAlt    // #374151
static const Color darkBorder        // #4B5563
static const Color darkTextPrimary   // #F9FAFB
static const Color darkTextSecondary // #D1D5DB
```

### AppTypography

Typography system with predefined text styles.

#### Headings
```dart
static const TextStyle heading1  // 32px, bold
static const TextStyle heading2  // 24px, bold
static const TextStyle heading3  // 20px, semibold
```

#### Body Text
```dart
static const TextStyle bodyLarge  // 16px
static const TextStyle bodyMedium // 14px
static const TextStyle bodySmall  // 12px
```

#### Labels
```dart
static const TextStyle labelLarge  // 14px, semibold
static const TextStyle labelMedium // 12px, semibold
static const TextStyle labelSmall  // 10px, semibold
```

### AppSpacing

Standardized spacing scale.

```dart
static const double xs    // 4.0
static const double sm    // 8.0
static const double md    // 12.0
static const double lg    // 16.0
static const double xl    // 20.0
static const double xxl   // 24.0
static const double xxxl  // 32.0
```

### AppRadius

Border radius scale.

```dart
static const double sm   // 4.0
static const double md   // 8.0
static const double lg   // 12.0
static const double xl   // 16.0
static const double xxl  // 24.0
static const double full // 9999.0
```

### AppShadows

Elevation shadow definitions.

```dart
static const List<BoxShadow> sm  // Subtle elevation
static const List<BoxShadow> md  // Standard elevation
static const List<BoxShadow> lg  // Prominent elevation
static const List<BoxShadow> xl  // Maximum elevation
```

### AppTheme

Theme configuration class.

```dart
static ThemeData get lightTheme  // Light theme configuration
static ThemeData get darkTheme   // Dark theme configuration
```

## Components

### AppButton

Customizable button component with multiple variants.

#### Constructor
```dart
const AppButton({
  Key? key,
  required String label,
  VoidCallback? onPressed,
  AppButtonVariant variant = AppButtonVariant.primary,
  AppButtonSize size = AppButtonSize.medium,
  bool isLoading = false,
  IconData? icon,
  Color? customBackgroundColor,
  Color? customForegroundColor,
})
```

#### Factory Constructors
```dart
AppButton.primary({...})    // Primary filled button
AppButton.secondary({...})  // Secondary outlined button
AppButton.tertiary({...})   // Tertiary subtle button
AppButton.ghost({...})      // Ghost transparent button
AppButton.icon({...})       // Icon-only button
AppButton.custom({...})     // Custom colored button
```

#### Properties
- `label` (String): Button text
- `onPressed` (VoidCallback?): Tap callback
- `variant` (AppButtonVariant): Visual variant
- `size` (AppButtonSize): Size variant
- `isLoading` (bool): Loading state
- `icon` (IconData?): Optional icon
- `customBackgroundColor` (Color?): Custom background
- `customForegroundColor` (Color?): Custom foreground

### AppIconButton

Circular icon-only button component.

#### Constructor
```dart
const AppIconButton({
  Key? key,
  required IconData icon,
  VoidCallback? onPressed,
  AppIconButtonVariant variant = AppIconButtonVariant.primary,
  AppIconButtonSize size = AppIconButtonSize.medium,
  bool isLoading = false,
  Color? customBackgroundColor,
  Color? customForegroundColor,
})
```

#### Factory Constructors
```dart
AppIconButton.primary({...})    // Primary filled icon button
AppIconButton.secondary({...})  // Secondary outlined icon button
AppIconButton.tertiary({...})   // Tertiary subtle icon button
AppIconButton.ghost({...})      // Ghost transparent icon button
AppIconButton.custom({...})     // Custom colored icon button
```

### AppTextField

Text input component with validation support.

#### Constructor
```dart
const AppTextField({
  Key? key,
  String? label,
  String? hint,
  String? errorText,
  TextEditingController? controller,
  AppTextFieldVariant variant = AppTextFieldVariant.outlined,
  IconData? prefixIcon,
  IconData? suffixIcon,
  VoidCallback? onSuffixPressed,
  VoidCallback? onPrefixPressed,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  String? Function(String?)? validator,
  Color? fillColor,
  Color? borderColor,
  bool enabled = true,
  void Function(String)? onChanged,
  VoidCallback? onEditingComplete,
})
```

#### Factory Constructors
```dart
AppTextField.outlined({...})   // Outlined text field
AppTextField.filled({...})     // Filled text field
AppTextField.underlined({...}) // Underlined text field
AppTextField.custom({...})     // Custom styled text field
```

### AppDropdown<T>

Dropdown component with search and multi-select.

#### Constructor
```dart
const AppDropdown<T>({
  Key? key,
  String? label,
  required List<T> items,
  T? value,
  List<T>? values,
  void Function(T?)? onChanged,
  void Function(List<T>)? onMultiChanged,
  AppDropdownSize size = AppDropdownSize.medium,
  bool searchable = false,
  bool multiSelect = false,
  String? searchHint,
  IconData? icon,
  String Function(T)? itemBuilder,
  String? hint,
  bool enabled = true,
})
```

#### Factory Constructors
```dart
AppDropdown<T>.small({...})       // Small dropdown
AppDropdown<T>.medium({...})      // Medium dropdown
AppDropdown<T>.large({...})       // Large dropdown
AppDropdown<T>.searchable({...})  // Searchable dropdown
AppDropdown<T>.multiSelect({...}) // Multi-select dropdown
```

### AppCheckbox

Checkbox component with labels and descriptions.

#### Constructor
```dart
const AppCheckbox({
  Key? key,
  String? label,
  String? description,
  required bool value,
  void Function(bool?)? onChanged,
  AppCheckboxVariant variant = AppCheckboxVariant.primary,
  Color? activeColor,
  Color? inactiveColor,
})
```

#### Factory Constructors
```dart
AppCheckbox.primary({...})   // Primary checkbox
AppCheckbox.secondary({...}) // Secondary checkbox
AppCheckbox.compact({...})   // Compact checkbox
AppCheckbox.custom({...})    // Custom colored checkbox
```

### AppRadio<T>

Radio button component for mutually exclusive selections.

#### Constructor
```dart
const AppRadio<T>({
  Key? key,
  String? label,
  String? description,
  required T value,
  required T? groupValue,
  void Function(T?)? onChanged,
  AppRadioVariant variant = AppRadioVariant.primary,
  Color? activeColor,
  Color? inactiveColor,
})
```

#### Factory Constructors
```dart
AppRadio<T>.primary({...})   // Primary radio button
AppRadio<T>.secondary({...}) // Secondary radio button
AppRadio<T>.compact({...})   // Compact radio button
AppRadio<T>.custom({...})    // Custom colored radio button
```

### AppDataCard

Data card component for displaying metrics.

#### Constructor
```dart
const AppDataCard({
  Key? key,
  required String title,
  required String value,
  String? change,
  bool? isPositive,
  IconData? icon,
  Color? iconColor,
  List<Color>? gradientColors,
  VoidCallback? onTap,
  Widget? trailing,
  ImageProvider? image,
  AppDataCardImagePlacement? imagePlacement,
  double? imageHeight,
  double? imageWidth,
  BoxFit imageFit = BoxFit.cover,
  bool showImageShimmer = true,
  Color? shimmerBaseColor,
  Color? shimmerHighlightColor,
  Color? overlayColor,
  double overlayOpacity = 0.4,
  double overlayHeightPercent = 1.0,
  AppDataCardVariant variant = AppDataCardVariant.metric,
})
```

#### Factory Constructors
```dart
AppDataCard.metric({...})    // Metric card with change indicator
AppDataCard.compact({...})   // Compact card
AppDataCard.withIcon({...})  // Card with icon
AppDataCard.gradient({...})  // Card with gradient background
AppDataCard.clickable({...}) // Clickable card with tap feedback
```

### AppDialog

Dialog component for confirmations and alerts.

#### Constructor
```dart
const AppDialog({
  Key? key,
  required String title,
  String? message,
  AppDialogVariant variant,
  Widget? content,
  List<Widget>? actions,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  VoidCallback? onClose,
  VoidCallback? onRetry,
  String? confirmLabel,
  String? cancelLabel,
})
```

#### Factory Constructors
```dart
AppDialog.confirmation({...}) // Confirmation dialog
AppDialog.success({...})      // Success dialog
AppDialog.error({...})        // Error dialog
AppDialog.info({...})         // Info dialog
AppDialog.warning({...})      // Warning dialog
AppDialog.custom({...})       // Custom dialog
```

### AppModal

Modal overlay component.

#### Constructor
```dart
const AppModal({
  Key? key,
  required Widget child,
  VoidCallback? onClose,
  bool barrierDismissible = true,
  Color? barrierColor,
})
```

## Enums

### AppButtonVariant
```dart
enum AppButtonVariant {
  primary,    // Filled primary button
  secondary,  // Outlined secondary button
  tertiary,   // Subtle tertiary button
  ghost,      // Transparent ghost button
  custom,     // Custom colored button
}
```

### AppButtonSize
```dart
enum AppButtonSize {
  small,   // Small button
  medium,  // Medium button (default)
  large,   // Large button
}
```

### AppIconButtonVariant
```dart
enum AppIconButtonVariant {
  primary,    // Filled primary icon button
  secondary,  // Outlined secondary icon button
  tertiary,   // Subtle tertiary icon button
  ghost,      // Transparent ghost icon button
  custom,     // Custom colored icon button
}
```

### AppIconButtonSize
```dart
enum AppIconButtonSize {
  small,   // 32px diameter
  medium,  // 40px diameter (default)
  large,   // 48px diameter
}
```

### AppTextFieldVariant
```dart
enum AppTextFieldVariant {
  outlined,   // Outlined text field
  filled,     // Filled text field
  underlined, // Underlined text field
  custom,     // Custom styled text field
}
```

### AppDropdownSize
```dart
enum AppDropdownSize {
  small,   // Small dropdown
  medium,  // Medium dropdown (default)
  large,   // Large dropdown
}
```

### AppCheckboxVariant
```dart
enum AppCheckboxVariant {
  primary,    // Primary checkbox
  secondary,  // Secondary checkbox
  compact,    // Compact checkbox
  custom,     // Custom colored checkbox
}
```

### AppRadioVariant
```dart
enum AppRadioVariant {
  primary,    // Primary radio button
  secondary,  // Secondary radio button
  compact,    // Compact radio button
  custom,     // Custom colored radio button
}
```

### AppDataCardVariant
```dart
enum AppDataCardVariant {
  metric,     // Metric card with change indicator
  compact,    // Compact card
  withIcon,   // Card with icon
  gradient,   // Card with gradient background
  clickable,  // Clickable card
}
```

### AppDataCardImagePlacement
```dart
enum AppDataCardImagePlacement {
  top,        // Image at top
  bottom,     // Image at bottom
  left,       // Image on left
  right,      // Image on right
  background, // Image as background
}
```

### AppDialogVariant
```dart
enum AppDialogVariant {
  confirmation, // Confirmation dialog
  success,      // Success dialog
  error,        // Error dialog
  info,         // Info dialog
  warning,      // Warning dialog
  custom,       // Custom dialog
}
```

## Usage Examples

See [EXAMPLES.md](EXAMPLES.md) for comprehensive usage examples of all components.

## Design Token Guide

See [DESIGN_TOKENS.md](DESIGN_TOKENS.md) for detailed information about the design token system.
