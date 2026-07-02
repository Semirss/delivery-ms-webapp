import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _section(
            context,
            icon: Icons.location_on_rounded,
            title: 'Location data',
            body:
                'When you go online, the app sends your current GPS position so dispatch can assign nearby deliveries and customers can track active orders. Location updates stop when you go offline.',
          ),
          _section(
            context,
            icon: Icons.badge_rounded,
            title: 'Driver profile',
            body:
                'Your name, phone number, vehicle type, plate number, Telegram username, approval status, and verification document are used to operate and verify the driver service.',
          ),
          _section(
            context,
            icon: Icons.receipt_long_rounded,
            title: 'Delivery history',
            body:
                'Delivery records are stored so earnings, ratings, status updates, customer support, and operational reports can work correctly.',
          ),
          _section(
            context,
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            body:
                'The app stores driver notifications and read receipts so assignments and delivery updates are visible across sessions.',
          ),
          _section(
            context,
            icon: Icons.security_rounded,
            title: 'Account protection',
            body:
                'Only keep your own account signed in. Contact support immediately if your phone, account, or verification document is no longer under your control.',
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          AppText(
            title,
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            body,
            variant: AppTextVariant.bodyMedium,
            color: context.appTextSecondary,
          ),
        ],
      ),
    );
  }
}
