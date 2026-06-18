# App UI Example Application

This example application demonstrates all the components and features available in the App UI library.

## Features Demonstrated

### 1. Theme Switching
- Toggle between light and dark themes
- See how all components adapt to theme changes
- Demonstrates proper color contrast in both themes

### 2. Button Components
- All button variants (primary, secondary, tertiary, ghost)
- Button sizes (small, medium, large)
- Button states (enabled, disabled, loading)
- Buttons with icons
- Icon-only buttons
- Custom colored buttons

### 3. Form Fields
- Text fields with different variants (outlined, filled, underlined)
- Text field validation and error states
- Dropdowns with single selection
- Searchable dropdowns
- Multi-select dropdowns
- Checkboxes with labels and descriptions
- Radio buttons with descriptions
- Complete form example with validation

### 4. Data Cards
- Metric cards with change indicators
- Compact cards for dashboard layouts
- Cards with icons
- Gradient cards
- Clickable cards with tap callbacks
- Dashboard layout example

### 5. Dialogs
- Confirmation dialogs
- Semantic dialogs (success, error, warning, info)
- Custom content dialogs
- Dialog action callbacks

## Running the Example

1. Navigate to the example directory:
```bash
cd example
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Project Structure

```
example/
├── lib/
│   ├── main.dart              # App entry point with theme switching
│   └── screens/
│       ├── home_screen.dart   # Main navigation screen
│       ├── buttons_screen.dart
│       ├── form_fields_screen.dart
│       ├── cards_screen.dart
│       └── dialogs_screen.dart
├── pubspec.yaml
└── README.md
```

## Key Concepts

### Theme Integration
The example app demonstrates how to integrate App UI themes:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: _themeMode,
  // ...
)
```

### Component Usage
Each screen demonstrates proper component usage with various configurations:

```dart
// Button example
AppButton.primary(
  label: 'Primary Button',
  onPressed: () => print('Pressed'),
)

// Form field example
AppTextField.outlined(
  label: 'Email',
  hint: 'Enter your email',
  prefixIcon: Icons.email,
)

// Card example
AppDataCard.metric(
  title: 'Total Revenue',
  value: '\$45,231',
  change: '+20.1%',
  isPositive: true,
)
```

### Form Validation
The form fields screen shows how to implement form validation:

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      AppTextField.outlined(
        label: 'Required Field',
        errorText: _value.isEmpty ? 'Field is required' : null,
      ),
      AppButton.primary(
        label: 'Submit',
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            // Handle submission
          }
        },
      ),
    ],
  ),
)
```

## Learning Resources

- Explore each screen to see different component variants
- Toggle the theme to see how components adapt
- Interact with components to see state changes
- Review the source code to understand implementation patterns

## Next Steps

After exploring the example app:

1. Review the App UI documentation
2. Check out the component API reference
3. Start building your own application with App UI
4. Customize components using the design token system

## Support

For questions or issues, please refer to the main App UI documentation or open an issue in the repository.
