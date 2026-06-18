import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../config/router/app_routes.dart';
import '../../../../core/storage/storage_adapter.dart';
import '../../../../core/storage/storage_key_constants.dart';
import '../../../../core/utils/constants/asset_constants/image_constants.dart';
import '../../../../core/utils/constants/ui_constants.dart';
import '../../../../core/utils/enums/onboarding_state.dart';
import '../../../../core/widgets/index.dart';
import '../../domain/entities/onboarding_page_entity.dart';
import '../widgets/onboarding_page_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final IStorageService _storageService = GetIt.instance<IStorageService>();
  int _currentPage = 0;

  final List<OnboardingPageEntity> _pages = [
    OnboardingPageEntity(
      title: 'Welcome',
      description:
          'Get started with our amazing app. Discover features that make your life easier.',
      imagePath: ImageConstants.onboarding1,
    ),
    OnboardingPageEntity(
      title: 'Stay Connected',
      description:
          'Keep in touch with your friends and family. Share moments and stay updated.',
      imagePath: ImageConstants.onboarding2,
    ),
    OnboardingPageEntity(
      title: 'All in One Place',
      description:
          'Everything you need is right here. Simple, fast, and easy to use.',
      imagePath: ImageConstants.onboarding3,
      buttonText: 'Get Started',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await _storageService.saveData(
      StorageKeys.onboardingState,
      OnboardingState.completed.toJson(),
    );
    if (mounted) {
      context.goNamed(AppRoutes.login.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppButton.ghost(
                  label: 'Skip',
                  onPressed: _skipOnboarding,
                  size: AppButtonSize.small,
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildPageIndicator(index == _currentPage, context),
              ),
            ),

            kVerticalGap24,

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: AppButton.primary(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                fullWidth: true,
              ),
            ),

            kVerticalGap32,
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive, BuildContext context) {
    return AppContainer(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      height: 8,
      width: isActive ? 24 : 8,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      backgroundColor: isActive
          ? AppColors.primary
          : AppColors.textSecondary.withValues(alpha: 0.3),
      child: const SizedBox.shrink(),
    );
  }
}
