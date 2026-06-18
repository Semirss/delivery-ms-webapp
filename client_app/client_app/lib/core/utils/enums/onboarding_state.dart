/// Enum representing the onboarding state of the application
enum OnboardingState {
  /// First time user - onboarding not shown yet
  firstTime('firstTime'),

  /// Onboarding is in progress
  inProgress('inProgress'),

  /// Onboarding has been completed
  completed('completed');

  final String value;
  const OnboardingState(this.value);

  /// Convert string to OnboardingState
  static OnboardingState fromString(String? value) {
    switch (value) {
      case 'firstTime':
        return OnboardingState.firstTime;
      case 'inProgress':
        return OnboardingState.inProgress;
      case 'completed':
        return OnboardingState.completed;
      default:
        return OnboardingState.firstTime;
    }
  }

  /// Convert OnboardingState to string
  String toJson() => value;

  /// Check if onboarding is completed
  bool get isCompleted => this == OnboardingState.completed;

  /// Check if this is the first time
  bool get isFirstTime => this == OnboardingState.firstTime;
}

