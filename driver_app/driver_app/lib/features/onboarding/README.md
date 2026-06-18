# Onboarding Feature

A complete onboarding flow for first-time app users.

## Features

- ✅ Multi-page onboarding experience
- ✅ Page indicators
- ✅ Skip functionality
- ✅ Smooth page transitions
- ✅ Stores completion status in local storage
- ✅ Automatic navigation to login after completion

## Structure

```
onboarding/
├── domain/
│   └── entities/
│       └── onboarding_page_entity.dart
└── presentation/
    ├── screens/
    │   └── onboarding_screen.dart
    └── widgets/
        └── onboarding_page_widget.dart
```

## Usage

The onboarding screen is automatically shown when:
- User first launches the app
- Onboarding hasn't been completed yet

After completing onboarding (via "Get Started" button or "Skip"), the user is automatically navigated to the login screen.

## Customization

You can customize the onboarding pages by modifying the `_pages` list in `onboarding_screen.dart`:

```dart
final List<OnboardingPageEntity> _pages = [
  OnboardingPageEntity(
    title: 'Your Title',
    description: 'Your description',
    imagePath: 'assets/images/onboarding_1.png',
  ),
  // Add more pages...
];
```

## Router Integration

The router automatically:
- Checks if onboarding is completed
- Redirects to onboarding if not completed
- Redirects to login after onboarding is completed
- Prevents showing onboarding again after completion

The onboarding completion status is stored using `StorageKeys.onboardingCompleted`.

