import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class DialogsScreen extends StatelessWidget {
  const DialogsScreen({super.key});

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
          titleText: 'Dialogs',
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
              title: 'Confirmation Dialogs',
              children: [
                AppButton.primary(
                  label: 'Show Confirmation Dialog',
                  onPressed: () => _showConfirmationDialog(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Show Delete Confirmation',
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Semantic Dialogs',
              children: [
                AppButton.custom(
                  label: 'Show Success Dialog',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () => _showSuccessDialog(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Show Error Dialog',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  onPressed: () => _showErrorDialog(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Show Warning Dialog',
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  onPressed: () => _showWarningDialog(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Show Info Dialog',
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  onPressed: () => _showInfoDialog(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Custom Content Dialog',
              children: [
                AppButton.primary(
                  label: 'Show Custom Dialog',
                  onPressed: () => _showCustomDialog(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Dialog Examples',
              description:
                  'Dialogs are modal overlays that require user interaction. '
                  'They can be used for confirmations, alerts, or custom content.',
              children: [
                Text(
                  'Click the buttons above to see different dialog variants in action.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    AppDialog.confirm(
      context: context,
      title: 'Confirm Action',
      contentText: 'Are you sure you want to proceed with this action?',
      confirmLabel: 'Confirm',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true) {
        _showSnackBar(context, 'Action confirmed');
      } else if (confirmed == false) {
        _showSnackBar(context, 'Action cancelled');
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    AppDialog.destructive(
      context: context,
      title: 'Delete Item',
      contentText:
          'This action cannot be undone. Are you sure you want to delete this item?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true) {
        _showSnackBar(context, 'Item deleted');
      }
    });
  }

  void _showSuccessDialog(BuildContext context) {
    AppDialog.success(
      context: context,
      title: 'Success!',
      contentText: 'Your operation completed successfully.',
    );
  }

  void _showErrorDialog(BuildContext context) {
    AppDialog.error(
      context: context,
      title: 'Error',
      contentText:
          'An error occurred while processing your request. Please try again.',
      primaryAction: AppDialogAction(
        label: 'Retry',
        onPressed: () {
          Navigator.of(context).pop();
          _showSnackBar(context, 'Retrying...');
        },
      ),
    );
  }

  void _showWarningDialog(BuildContext context) {
    AppDialog.warning(
      context: context,
      title: 'Warning',
      contentText:
          'This action may have unintended consequences. Please review before proceeding.',
    );
  }

  void _showInfoDialog(BuildContext context) {
    AppDialog.info(
      context: context,
      title: 'Information',
      contentText:
          'Here is some important information you should know about this feature.',
    );
  }

  void _showCustomDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      title: 'Custom Dialog',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 64, color: AppColors.warning),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'This is a custom dialog with custom content.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField.outlined(hint: 'Enter your feedback', maxLines: 3),
        ],
      ),
      primaryAction: AppDialogAction(
        label: 'Submit',
        onPressed: () {
          Navigator.of(context).pop();
          _showSnackBar(context, 'Feedback submitted');
        },
      ),
      secondaryAction: AppDialogAction(
        label: 'Cancel',
        onPressed: () => Navigator.of(context).pop(),
        variant: AppButtonVariant.secondary,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }
}
