# App UI Design Tokens Guide

This guide explains the design token system in App UI and how to use it effectively for consistent, maintainable styling.

## What are Design Tokens?

Design tokens are the centralized constants that define the visual design of your application. They ensure consistency across all components and make it easy to maintain and update your design system.

## Benefits of Design Tokens

- **Consistency**: All components use the same values, ensuring visual harmony
- **Maintainability**: Change a token once, update everywhere
- **Scalability**: Easy to extend and customize
- **Type Safety**: Compile-time checking prevents errors
- **Documentation**: Self-documenting code with clear naming

## Token Categories

### 1. Colors (AppColors)

Colors are organized by purpose and meaning:

#### Primary Colors
Used for main actions, links, and brand identity.

```dart
AppColors.primary       // Main brand color
AppColors.primaryLight  // Hover states, lighter accents
AppColors.primaryDark   // Pressed states, darker accents
```

**When to use:**
- Primary buttons
- Active navigation items
- Links
- Focus indicators
- Brand elements

#### Secondary Colors
Used for complementary actions and variety.

```dart
AppColors.secondary       // Secondary brand color
AppColors.secondaryLight  // Lighter variant
AppColors.secondaryDark   // Darker variant
```

**When to use:**
- Secondary buttons
- Alternative actions
- Complementary UI elements

#### Accent Colors
Used for variety and visual interest.

```dart
AppColors.accent1  // Cyan - Information, data
AppColors.accent2  // Green - Growth, positive
AppColors.accent3  // Amber - Attention, highlights
AppColors.accent4  // Red - Urgency, important
```

**When to use:**
- Data visualization
- Category colors
- Badges and tags
- Decorative elements

#### Semantic Colors
Colors with specific meanings.

```dart
AppColors.success  // Green - Success states
AppColors.warning  // Amber - Warning states
AppColors.error    // Red - Error states
AppColors.info     // Blue - Informational states
```

**When to use:**
- Success messages and indicators
- Warning alerts
- Error messages and validation
- Informational notices

#### Neutral Colors
Used for layout, backgrounds, and text.

```dart
AppColors.background    // Main background
AppColors.surface       // Card and elevated surfaces
AppColors.surfaceAlt    // Alternative surface
AppColors.border        // Borders and dividers
AppColors.textPrimary   // Main text
AppColors.textSecondary // Supporting text
AppColors.textDisabled  // Disabled text
```

**When to use:**
- Page backgrounds
- Card backgrounds
- Borders and dividers
- Text content
- Disabled states

#### Dark Mode Colors
Optimized colors for dark theme.

```dart
AppColors.darkBackground    // Dark background
AppColors.darkSurface       // Dark surface
AppColors.darkSurfaceAlt    // Dark alternative surface
AppColors.darkBorder        // Dark border
AppColors.darkTextPrimary   // Dark text primary
AppColors.darkTextSecondary // Dark text secondary
```

**When to use:**
- Automatically applied in dark theme
- Manual dark mode implementations

### 2. Typography (AppTypography)

Text styles organized by hierarchy and purpose.

#### Headings
For titles and section headers.

```dart
AppTypography.heading1  // 32px, bold - Page titles
AppTypography.heading2  // 24px, bold - Section titles
AppTypography.heading3  // 20px, semibold - Subsection titles
```

**Usage guidelines:**
- Use heading1 for main page titles
- Use heading2 for major sections
- Use heading3 for subsections
- Maintain hierarchy (don't skip levels)

#### Body Text
For main content.

```dart
AppTypography.bodyLarge  // 16px - Emphasized content
AppTypography.bodyMedium // 14px - Standard content
AppTypography.bodySmall  // 12px - Supporting content
```

**Usage guidelines:**
- Use bodyLarge for important paragraphs
- Use bodyMedium for standard text
- Use bodySmall for captions and footnotes

#### Labels
For UI labels and buttons.

```dart
AppTypography.labelLarge  // 14px, semibold - Large labels
AppTypography.labelMedium // 12px, semibold - Standard labels
AppTypography.labelSmall  // 10px, semibold - Small labels
```

**Usage guidelines:**
- Use for form labels
- Use for button text
- Use for navigation items
- Use for tags and badges

### 3. Spacing (AppSpacing)

Consistent spacing scale for layouts.

```dart
AppSpacing.xs    // 4px  - Minimal spacing
AppSpacing.sm    // 8px  - Small spacing
AppSpacing.md    // 12px - Medium spacing
AppSpacing.lg    // 16px - Large spacing
AppSpacing.xl    // 20px - Extra large spacing
AppSpacing.xxl   // 24px - Double extra large
AppSpacing.xxxl  // 32px - Triple extra large
```

**Usage guidelines:**

**xs (4px)**: Tight spacing
- Between icon and text in buttons
- Between checkbox and label
- Minimal gaps in compact layouts

**sm (8px)**: Close spacing
- Between related form fields
- Between list items
- Padding in compact components

**md (12px)**: Standard spacing
- Default padding in components
- Between form field groups
- Standard gaps in layouts

**lg (16px)**: Comfortable spacing
- Card padding
- Section padding
- Between major UI elements

**xl (20px)**: Generous spacing
- Between sections
- Large component padding
- Prominent separations

**xxl (24px)**: Large spacing
- Between major sections
- Page padding
- Large component spacing

**xxxl (32px)**: Extra large spacing
- Between page sections
- Hero element spacing
- Maximum separation

### 4. Border Radius (AppRadius)

Consistent rounded corners.

```dart
AppRadius.sm   // 4px   - Subtle rounding
AppRadius.md   // 8px   - Standard rounding
AppRadius.lg   // 12px  - Prominent rounding
AppRadius.xl   // 16px  - Large rounding
AppRadius.xxl  // 24px  - Extra large rounding
AppRadius.full // 9999px - Fully rounded (pill)
```

**Usage guidelines:**

**sm (4px)**: Subtle corners
- Small buttons
- Checkboxes
- Small badges

**md (8px)**: Standard corners
- Buttons
- Input fields
- Small cards

**lg (12px)**: Prominent corners
- Cards
- Modals
- Large buttons

**xl (16px)**: Large corners
- Hero cards
- Feature sections
- Large containers

**xxl (24px)**: Extra large corners
- Special cards
- Decorative elements

**full (9999px)**: Fully rounded
- Pills
- Circular avatars
- Rounded buttons

### 5. Shadows (AppShadows)

Elevation shadows for depth.

```dart
AppShadows.sm  // Subtle elevation
AppShadows.md  // Standard elevation
AppShadows.lg  // Prominent elevation
AppShadows.xl  // Maximum elevation
```

**Usage guidelines:**

**sm**: Subtle depth
- Buttons on hover
- Small cards
- Subtle elevation

**md**: Standard depth
- Cards
- Dropdowns
- Standard elevation

**lg**: Prominent depth
- Modals
- Dialogs
- Floating elements

**xl**: Maximum depth
- Tooltips
- Popovers
- Top-level overlays

## Best Practices

### 1. Always Use Tokens

❌ **Don't:**
```dart
Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF6366F1),
    borderRadius: BorderRadius.circular(8.0),
  ),
)
```

✅ **Do:**
```dart
Container(
  padding: EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

### 2. Use Semantic Colors

❌ **Don't:**
```dart
Text('Error', style: TextStyle(color: Color(0xFFEF4444)))
```

✅ **Do:**
```dart
Text('Error', style: TextStyle(color: AppColors.error))
```

### 3. Maintain Typography Hierarchy

❌ **Don't:**
```dart
Text('Title', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))
```

✅ **Do:**
```dart
Text('Title', style: AppTypography.heading2)
```

### 4. Use Consistent Spacing

❌ **Don't:**
```dart
Column(
  children: [
    Widget1(),
    SizedBox(height: 15),
    Widget2(),
    SizedBox(height: 18),
    Widget3(),
  ],
)
```

✅ **Do:**
```dart
Column(
  children: [
    Widget1(),
    SizedBox(height: AppSpacing.lg),
    Widget2(),
    SizedBox(height: AppSpacing.lg),
    Widget3(),
  ],
)
```

### 5. Combine Tokens Effectively

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.md,
    border: Border.all(color: AppColors.border),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Title', style: AppTypography.heading3),
      SizedBox(height: AppSpacing.sm),
      Text('Description', style: AppTypography.bodyMedium),
    ],
  ),
)
```

## Customizing Tokens

### Option 1: Extend Existing Tokens

```dart
class CustomColors {
  // Use existing tokens as base
  static const Color brandPrimary = AppColors.primary;
  
  // Add custom colors
  static const Color brandAccent = Color(0xFF00D9FF);
  static const Color brandDark = Color(0xFF1A1A2E);
}
```

### Option 2: Override in Theme

```dart
class CustomTheme {
  static ThemeData get lightTheme {
    return AppTheme.lightTheme.copyWith(
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: const Color(0xFF1E40AF),
        secondary: const Color(0xFF7C3AED),
      ),
    );
  }
}
```

### Option 3: Create New Token Classes

```dart
abstract class CustomSpacing {
  static const double tiny = 2.0;
  static const double huge = 48.0;
}

abstract class CustomRadius {
  static const double minimal = 2.0;
  static const double extreme = 32.0;
}
```

## Token Reference Quick Guide

### Color Selection Guide

| Use Case | Token |
|----------|-------|
| Primary action | `AppColors.primary` |
| Secondary action | `AppColors.secondary` |
| Success message | `AppColors.success` |
| Error message | `AppColors.error` |
| Warning message | `AppColors.warning` |
| Info message | `AppColors.info` |
| Main text | `AppColors.textPrimary` |
| Supporting text | `AppColors.textSecondary` |
| Disabled text | `AppColors.textDisabled` |
| Background | `AppColors.background` |
| Card surface | `AppColors.surface` |
| Border | `AppColors.border` |

### Typography Selection Guide

| Use Case | Token |
|----------|-------|
| Page title | `AppTypography.heading1` |
| Section title | `AppTypography.heading2` |
| Subsection title | `AppTypography.heading3` |
| Main content | `AppTypography.bodyMedium` |
| Emphasized content | `AppTypography.bodyLarge` |
| Supporting content | `AppTypography.bodySmall` |
| Form label | `AppTypography.labelMedium` |
| Button text | `AppTypography.labelMedium` |
| Small label | `AppTypography.labelSmall` |

### Spacing Selection Guide

| Use Case | Token |
|----------|-------|
| Tight spacing | `AppSpacing.xs` |
| Close spacing | `AppSpacing.sm` |
| Standard spacing | `AppSpacing.md` |
| Comfortable spacing | `AppSpacing.lg` |
| Generous spacing | `AppSpacing.xl` |
| Large spacing | `AppSpacing.xxl` |
| Extra large spacing | `AppSpacing.xxxl` |

## Conclusion

Design tokens are the foundation of App UI's consistency and maintainability. By using tokens consistently throughout your application, you ensure:

- Visual consistency across all screens
- Easy maintenance and updates
- Scalable design system
- Better collaboration between designers and developers
- Faster development with less decision-making

Always prefer tokens over hardcoded values, and your application will benefit from a cohesive, professional design system.
