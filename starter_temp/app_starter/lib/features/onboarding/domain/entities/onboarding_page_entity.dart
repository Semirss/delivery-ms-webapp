class OnboardingPageEntity {
  final String title;
  final String description;
  final String imagePath;
  final String? buttonText;

  OnboardingPageEntity({
    required this.title,
    required this.description,
    required this.imagePath,
    this.buttonText,
  });
}
