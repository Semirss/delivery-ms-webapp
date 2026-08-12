import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';

class AuthFormNotice extends StatelessWidget {
  const AuthFormNotice({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            AppColors.error.withValues(alpha: context.isAppDark ? 0.18 : 0.08),
            context.appSurface,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.error.withValues(
              alpha: context.isAppDark ? 0.42 : 0.28,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                message,
                variant: AppTextVariant.bodySmall,
                color: context.appTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
