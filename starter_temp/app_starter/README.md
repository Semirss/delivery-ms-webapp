# Flutter Boilerplate - Production Ready

A comprehensive Flutter boilerplate with modern architecture, dependency injection, error monitoring, and production-ready features.

## 🚀 Features

### Architecture & State Management
- **Clean Architecture** with separation of concerns
- **BLoC Pattern** for state management with base classes
- **Dependency Injection** using GetIt + Injectable
- **Repository Pattern** with error handling

### Error Handling & Monitoring
- **Sentry Integration** for crash reporting and performance monitoring
- **Centralized Logging** with different log levels
- **Error Boundaries** in BLoC and Repository layers
- **Network Error Handling** with retry mechanisms

### Network & API
- **Dio HTTP Client** with interceptors
- **Automatic Token Refresh** for authentication
- **Network Connectivity** checking
- **Chuck Interceptor** for API debugging (debug mode only)
- **Request/Response Logging** with Sentry breadcrumbs

### Storage & Caching
- **Hive** for local storage
- **Shared Preferences** for simple key-value storage
- **Secure Token Storage** with automatic cleanup

### UI & Theming
- **Responsive Design** with ScreenUtil
- **Dark/Light Theme** support
- **Google Fonts** integration
- **Consistent UI Constants** and spacing

### Development & Quality
- **Very Good Analysis** for strict linting
- **Code Generation** for models and dependency injection
- **Environment Configuration** with .env files
- **Build Configuration** for different environments

## 📁 Project Structure

```
lib/
├── core/
│   ├── base/                 # Base classes for BLoC, Repository, UseCase
│   ├── config/               # App configuration and environment
│   ├── di/                   # Dependency injection setup
│   ├── databases/            # API client and network layer
│   ├── errors/               # Error handling and failures
│   ├── logging/              # Centralized logging service
│   ├── monitoring/           # Sentry and error monitoring
│   ├── storage/              # Local storage services
│   └── utils/                # Utilities and constants
├── features/                 # Feature modules (Clean Architecture)
│   └── auth/                 # Example authentication feature
│       ├── data/             # Data sources and repositories
│       ├── domain/           # Entities, repositories, and use cases
│       └── presentation/     # UI, BLoC, and widgets
├── config/                   # App-level configuration
│   ├── router/               # Navigation and routing
│   └── theme/                # App theming
└── main.dart                 # App entry point
```

## 🛠 Setup

### 1. Environment Configuration

Create a `.env` file in the root directory:

```env
# Environment Configuration
ENVIRONMENT=development
APP_NAME=Flutter Boilerplate

# API Configuration
API_BASE_URL=https://api.example.com
API_TIMEOUT=30000

# Sentry Configuration
SENTRY_DSN=your_sentry_dsn_here
SENTRY_ENVIRONMENT=development

# Feature Flags
ENABLE_LOGGING=true
ENABLE_CHUCK_INTERCEPTOR=true
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Code

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
flutter run
```

## 🏗 Architecture Overview

### Dependency Injection
The app uses GetIt with Injectable for dependency injection. All services are registered in `lib/core/di/injection.dart`.

### Error Handling
- **Repository Level**: All API calls are wrapped in `safeCall` method
- **BLoC Level**: Base BLoC handles errors and logs them
- **Global Level**: Sentry captures unhandled exceptions

### State Management
- Uses BLoC pattern with base classes for consistent error handling
- Events and states extend base classes with Equatable
- Automatic logging and monitoring for all BLoC events

### Network Layer
- Dio client with multiple interceptors
- Automatic token refresh on 401 errors
- Retry mechanism for network timeouts
- Chuck interceptor for debugging (development only)

## 🔧 Configuration

### Adding New Features
1. Create feature folder in `lib/features/`
2. Follow Clean Architecture structure (data/domain/presentation)
3. Register dependencies in `injection.dart`
4. Extend base classes for consistent behavior

### Environment Setup
- Development: Uses `.env` file
- Staging/Production: Override environment variables in CI/CD

### Sentry Setup
1. Create Sentry project
2. Add DSN to `.env` file
3. Configure release tracking in CI/CD

## 📱 Production Checklist

- [ ] Update app name and package identifier
- [ ] Configure Sentry DSN for production
- [ ] Set up proper API endpoints
- [ ] Configure app icons and splash screen
- [ ] Set up CI/CD pipeline
- [ ] Configure code signing
- [ ] Test on different devices and screen sizes
- [ ] Performance testing and optimization
- [ ] Security review and penetration testing

## 🤝 Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Update documentation
4. Follow the linting rules
5. Use conventional commits

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
