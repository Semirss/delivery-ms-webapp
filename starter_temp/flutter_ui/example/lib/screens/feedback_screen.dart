import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

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
          titleText: 'Feedback Components',
          centerTitle: true,
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
              title: 'Toast Notifications - All Types',
              children: [
                AppButton.custom(
                  label: 'Success Toast',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () => AppToast.success(
                    context: context,
                    title: 'Success!',
                    message: 'Your operation completed successfully.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Error Toast',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  onPressed: () => AppToast.error(
                    context: context,
                    title: 'Error',
                    message: 'An error occurred while processing your request.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Warning Toast',
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  onPressed: () => AppToast.warning(
                    context: context,
                    title: 'Warning',
                    message: 'Please review your input before proceeding.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Info Toast',
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  onPressed: () => AppToast.info(
                    context: context,
                    title: 'Information',
                    message: 'Here is some useful information for you.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Toast with Different Durations',
              children: [
                AppButton.primary(
                  label: 'Quick Toast (1s)',
                  onPressed: () => AppToast.show(
                    context: context,
                    message: 'This disappears quickly',
                    duration: const Duration(seconds: 1),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Normal Toast (3s)',
                  onPressed: () => AppToast.show(
                    context: context,
                    message: 'This stays for 3 seconds',
                    duration: const Duration(seconds: 3),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Long Toast (5s)',
                  onPressed: () => AppToast.show(
                    context: context,
                    message: 'This stays longer for important messages',
                    duration: const Duration(seconds: 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Toast Positions',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Top',
                        size: AppButtonSize.large,
                        onPressed: () => AppToast.show(
                          position: AppToastPosition.top,
                          context: context,
                          message: 'Toast at the top',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Center',
                        onPressed: () => AppToast.show(
                          context: context,
                          message: 'Toast at the center',
                          position: AppToastPosition.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Bottom',
                        onPressed: () => AppToast.show(
                          context: context,
                          message: 'Toast at the bottom',
                          position: AppToastPosition.bottom,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Toast with Title & Message Variations',
              children: [
                AppButton.tertiary(
                  label: 'Title Only',
                  onPressed: () => AppToast.show(
                    context: context,
                    title: 'Important Update',
                    message: 'System update available',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.tertiary(
                  label: 'Message Only',
                  onPressed: () => AppToast.show(
                    context: context,
                    message: 'This is a simple message without a title',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.tertiary(
                  label: 'Title + Long Message',
                  onPressed: () => AppToast.info(
                    context: context,
                    title: 'System Notification',
                    message:
                        'This is a longer message that provides more detailed information about what just happened in the application.',
                    duration: const Duration(seconds: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Real-World Toast Examples',
              children: [
                AppButton.ghost(
                  label: 'File Uploaded',
                  icon: Icons.upload_file,
                  onPressed: () => AppToast.success(
                    context: context,
                    title: 'Upload Complete',
                    message: 'document.pdf has been uploaded successfully',
                    duration: const Duration(seconds: 2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Connection Lost',
                  icon: Icons.wifi_off,
                  onPressed: () => AppToast.error(
                    context: context,
                    title: 'Connection Error',
                    message:
                        'Unable to connect to server. Please check your internet.',
                    duration: const Duration(seconds: 4),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Low Battery',
                  icon: Icons.battery_alert,
                  onPressed: () => AppToast.warning(
                    context: context,
                    title: 'Battery Low',
                    message: 'Device battery is below 20%. Please charge soon.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'New Message',
                  icon: Icons.message,
                  onPressed: () => AppToast.info(
                    context: context,
                    title: 'New Message',
                    message: 'You have 3 unread messages',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'SnackBars - All Types',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton.custom(
                        label: 'Success',
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        size: AppButtonSize.small,
                        onPressed: () => AppSnackBar.success(
                          context: context,
                          message: 'Operation completed!',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.custom(
                        label: 'Error',
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        size: AppButtonSize.small,
                        onPressed: () => AppSnackBar.error(
                          context: context,
                          message: 'Something went wrong',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.custom(
                        label: 'Warning',
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        size: AppButtonSize.small,
                        onPressed: () => AppSnackBar.warning(
                          context: context,
                          message: 'Please review input',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.custom(
                        label: 'Info',
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        size: AppButtonSize.small,
                        onPressed: () => AppSnackBar.info(
                          context: context,
                          message: 'Useful information',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'SnackBars with Actions',
              children: [
                AppButton.primary(
                  label: 'Delete with Undo',
                  icon: Icons.delete,
                  onPressed: () => AppSnackBar.show(
                    context: context,
                    message: 'Item deleted',
                    actionLabel: 'Undo',
                    onAction: () {
                      AppToast.success(
                        context: context,
                        message: 'Deletion cancelled',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Save with Retry',
                  icon: Icons.save,
                  onPressed: () => AppSnackBar.error(
                    context: context,
                    message: 'Failed to save changes',
                    actionLabel: 'Retry',
                    onAction: () {
                      AppToast.info(
                        context: context,
                        message: 'Retrying save operation...',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Persistent with Close',
                  onPressed: () => AppSnackBar.show(
                    context: context,
                    message: 'This message stays until you close it',
                    duration: const Duration(seconds: 30),
                    showCloseButton: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Real-World SnackBar Examples',
              children: [
                AppButton.ghost(
                  label: 'Email Sent',
                  icon: Icons.email,
                  onPressed: () => AppSnackBar.success(
                    context: context,
                    message: 'Email sent to john@example.com',
                    actionLabel: 'View',
                    onAction: () {
                      AppToast.info(
                        context: context,
                        message: 'Opening sent items...',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Download Complete',
                  icon: Icons.download,
                  onPressed: () => AppSnackBar.success(
                    context: context,
                    message: 'report.pdf downloaded successfully',
                    actionLabel: 'Open',
                    onAction: () {
                      AppToast.info(
                        context: context,
                        message: 'Opening file...',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Network Error',
                  icon: Icons.cloud_off,
                  onPressed: () => AppSnackBar.error(
                    context: context,
                    message: 'No internet connection',
                    actionLabel: 'Retry',
                    duration: const Duration(seconds: 5),
                    onAction: () {
                      AppToast.info(
                        context: context,
                        message: 'Checking connection...',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Settings Saved',
                  icon: Icons.settings,
                  onPressed: () => AppSnackBar.success(
                    context: context,
                    message: 'Your preferences have been saved',
                    duration: const Duration(seconds: 2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Update Available',
                  icon: Icons.system_update,
                  onPressed: () => AppSnackBar.info(
                    context: context,
                    message: 'A new version is available',
                    actionLabel: 'Update',
                    duration: const Duration(seconds: 10),
                    onAction: () {
                      AppToast.info(
                        context: context,
                        message: 'Starting update...',
                      );
                    },
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
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }
}
