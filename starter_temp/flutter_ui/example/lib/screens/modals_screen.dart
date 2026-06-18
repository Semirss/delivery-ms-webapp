import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class ModalsScreen extends StatelessWidget {
  const ModalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          titleText: 'Modals',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSection(
              context,
              title: 'Basic Modals',
              children: [
                AppButton.primary(
                  label: 'Show Simple Modal',
                  onPressed: () => _showSimpleModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Show Modal with Header',
                  onPressed: () => _showModalWithHeader(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Show Modal with Footer',
                  onPressed: () => _showModalWithFooter(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Modal Sizes',
              description:
                  'Modals now use percentage-based sizing (0.0 to 1.0)',
              children: [
                AppButton.primary(
                  label: 'Small Modal (40%)',
                  onPressed: () => _showSizedModal(context, 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Medium Modal (60%)',
                  onPressed: () => _showSizedModal(context, 0.6),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Large Modal (80%)',
                  onPressed: () => _showSizedModal(context, 0.8),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Extra Large Modal (95%)',
                  onPressed: () => _showSizedModal(context, 0.95),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Fullscreen Modal (100%)',
                  onPressed: () => _showSizedModal(context, 1.0),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Interactive Modals',
              children: [
                AppButton.primary(
                  label: 'Form Modal',
                  onPressed: () => _showFormModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Selection Modal',
                  onPressed: () => _showSelectionModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Scrollable Content Modal',
                  onPressed: () => _showScrollableModal(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Semantic Modals',
              children: [
                AppButton.custom(
                  label: 'Alert Modal',
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  onPressed: () => _showAlertModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Confirmation Modal',
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  onPressed: () => _showConfirmationModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Success Modal',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () => _showSuccessModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Error Modal',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  onPressed: () => _showErrorModal(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Advanced Modals',
              children: [
                AppButton.primary(
                  label: 'Modal with Custom Header',
                  onPressed: () => _showCustomHeaderModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Modal with Custom Footer',
                  onPressed: () => _showCustomFooterModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Non-Dismissible Modal',
                  onPressed: () => _showNonDismissibleModal(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Modal without Close Button',
                  onPressed: () => _showNoCloseButtonModal(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.heading3.copyWith(color: textColor)),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(color: secondaryTextColor),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }

  void _showSimpleModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Simple Bottom Sheet',
      contentText:
          'This is a simple bottom sheet modal with minimal content. You can drag it down to dismiss or tap outside.',
      primaryAction: AppModalAction(
        label: 'Close',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showModalWithHeader(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Modal with Header',
      subtitle: 'This modal has a subtitle',
      icon: Icons.star,
      contentText: 'This modal has a custom header with an icon and subtitle.',
      primaryAction: AppModalAction(
        label: 'Got it',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showModalWithFooter(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Modal with Footer',
      contentText: 'This modal has action buttons in a footer section.',
      primaryAction: AppModalAction(
        label: 'Confirm',
        onPressed: () => Navigator.pop(context),
      ),
      secondaryAction: AppModalAction(
        label: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showSizedModal(BuildContext context, double heightPercentage) {
    final percentage = (heightPercentage * 100).toInt();

    AppModal.show(
      context: context,
      title: '$percentage% Modal',
      contentText: 'This modal takes up $percentage% of the screen height.',
      heightPercentage: heightPercentage,
      primaryAction: AppModalAction(
        label: 'Close',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showFormModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Contact Form',
      heightPercentage: 0.6,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField.outlined(label: 'Name', hint: 'Enter your name'),
          const SizedBox(height: AppSpacing.md),
          AppTextField.outlined(label: 'Email', hint: 'Enter your email'),
          const SizedBox(height: AppSpacing.md),
          AppTextField.outlined(
            label: 'Message',
            hint: 'Enter your message',
            maxLines: 4,
          ),
        ],
      ),
      primaryAction: AppModalAction(
        label: 'Submit',
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Form submitted!')));
        },
      ),
      secondaryAction: AppModalAction(
        label: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showSelectionModal(BuildContext context) {
    final options = [
      'Option 1',
      'Option 2',
      'Option 3',
      'Option 4',
      'Option 5',
    ];

    AppModal.show(
      context: context,
      title: 'Select an Option',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => ListTile(
                title: Text(option),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Selected: $option')));
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showScrollableModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Scrollable Content',
      heightPercentage: 0.6,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          20,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard.outlined(child: Text('Item ${index + 1}')),
          ),
        ),
      ),
      primaryAction: AppModalAction(
        label: 'Close',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showAlertModal(BuildContext context) {
    AppModal.alert(
      context: context,
      title: 'Alert',
      contentText: 'This is an alert modal with warning styling.',
    );
  }

  void _showConfirmationModal(BuildContext context) {
    AppModal.confirm(
      context: context,
      title: 'Confirm Action',
      contentText: 'Are you sure you want to proceed with this action?',
    ).then((confirmed) {
      if (confirmed == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Action confirmed')));
      }
    });
  }

  void _showSuccessModal(BuildContext context) {
    AppModal.success(
      context: context,
      title: 'Success!',
      contentText: 'Your operation completed successfully.',
    );
  }

  void _showErrorModal(BuildContext context) {
    AppModal.error(
      context: context,
      title: 'Error',
      contentText: 'An error occurred while processing your request.',
    );
  }

  void _showCustomHeaderModal(BuildContext context) {
    AppModal.show(
      context: context,
      customHeader: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 32),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Custom Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      contentText: 'This modal has a custom header with gradient background.',
      primaryAction: AppModalAction(
        label: 'Close',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showCustomFooterModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Custom Footer',
      contentText: 'This modal has a custom footer section.',
      customFooter: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom footer content'),
            AppButton.primary(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showNonDismissibleModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'Non-Dismissible Modal',
      icon: Icons.lock,
      contentText:
          'This modal cannot be dismissed by tapping outside. You must use the button.',
      barrierDismissible: false,
      primaryAction: AppModalAction(
        label: 'Close Modal',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _showNoCloseButtonModal(BuildContext context) {
    AppModal.show(
      context: context,
      title: 'No Close Button',
      contentText: 'This modal does not have a close button in the header.',
      showCloseButton: false,
      primaryAction: AppModalAction(
        label: 'Close',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
