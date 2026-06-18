import 'package:flutter/material.dart';
import 'package:client_ui/app_ui.dart';
import '../../domain/entities/onboarding_page_entity.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageEntity page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppContainer(
            width: double.infinity,
            height: 300,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Icon(
              _getIconForIndex(),
              size: 120,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AppText(
            page.title,
            variant: AppTextVariant.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            page.description,
            variant: AppTextVariant.bodyLarge,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForIndex() {
    // Return different icons based on page content
    if (page.title.toLowerCase().contains('welcome')) {
      return Icons.waving_hand;
    } else if (page.title.toLowerCase().contains('connected')) {
      return Icons.people;
    } else {
      return Icons.apps;
    }
  }
}
