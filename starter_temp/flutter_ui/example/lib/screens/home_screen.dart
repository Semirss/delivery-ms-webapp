import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.currentThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog before exiting using App UI
        final shouldExit = await AppDialog.confirm(
          context: context,
          title: 'Exit App',
          contentText: 'Are you sure you want to exit the App UI Example app?',
          confirmLabel: 'Exit',
          cancelLabel: 'Stay',
        );

        if (shouldExit == true && context.mounted) {
          // Exit the app
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          titleText: 'App UI Components',
          automaticallyImplyLeading: false,
          actions: [
            AppIconButton.ghost(
              icon: currentThemeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
              onPressed: onThemeToggle,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Component Categories',
              style: AppTypography.heading2.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildCategoryCard(
              context,
              title: 'Buttons',
              description: 'Explore button variants and states',
              icon: Icons.smart_button,
              onTap: () => context.go('/buttons'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryCard(
              context,
              title: 'Form Fields',
              description: 'Text fields, dropdowns, checkboxes, and radios',
              icon: Icons.input,
              onTap: () => context.go('/form-fields'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryCard(
              context,
              title: 'Cards',
              description: 'Data cards with various styles',
              icon: Icons.dashboard,
              onTap: () => context.go('/cards'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryCard(
              context,
              title: 'Dialogs',
              description: 'Confirmation and alert dialogs',
              icon: Icons.message,
              onTap: () => context.go('/dialogs'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryCard(
              context,
              title: 'Modals',
              description: 'Bottom sheets and modal overlays',
              icon: Icons.view_agenda,
              onTap: () => context.go('/modals'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCategoryCard(
              context,
              title: 'Feedback',
              description: 'Toasts, snackbars, and notifications',
              icon: Icons.notifications,
              onTap: () => context.go('/feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return AppCard.elevated(
      onTap: onTap,
      child: Row(
        children: [
          AppContainer(
            width: 48,
            height: 48,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            alignment: Alignment.center,
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(color: textColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondaryTextColor),
        ],
      ),
    );
  }
}
