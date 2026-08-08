import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants/ui_constants.dart';
import '../../../../core/widgets/index.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  static const _supportPhone = '+251 931 323 328';

  Future<void> _callSupport(BuildContext context) async {
    final opened = await launchUrl(
      Uri(scheme: 'tel', path: _supportPhone),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      await AppModal.error<void>(
        context: context,
        title: 'Call failed',
        contentText: 'Could not open the phone dialer.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(titleText: 'Reset Password', centerTitle: true),
      body: AppContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
                kVerticalGap24,
                const AppText(
                  'Contact support',
                  variant: AppTextVariant.heading2,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w900,
                ),
                kVerticalGap8,
                AppText(
                  'For account safety, password reset is handled by support '
                  'after verifying account ownership.',
                  color: context.appTextSecondary,
                  textAlign: TextAlign.center,
                ),
                kVerticalGap32,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.appSurfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppText(
                          _supportPhone,
                          variant: AppTextVariant.heading3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                kVerticalGap24,
                AppButton.primary(
                  label: 'CALL SUPPORT',
                  icon: Icons.call_rounded,
                  fullWidth: true,
                  onPressed: () => _callSupport(context),
                ),
                kVerticalGap12,
                TextButton(
                  onPressed: () => context.pop(),
                  child: const AppText(
                    'Back to login',
                    variant: AppTextVariant.button,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
