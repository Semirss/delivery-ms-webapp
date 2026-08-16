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
    final errorColor = Theme.of(context).colorScheme.error;
    final backgroundColor = context.isAppDark
        ? const Color(0xFFFFF4F0)
        : Color.alphaBlend(
            errorColor.withValues(alpha: 0.08),
            context.appSurface,
          );
    final textColor = context.isAppDark
        ? const Color(0xFF4E231D)
        : context.appTextPrimary;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: errorColor.withValues(
              alpha: context.isAppDark ? 0.42 : 0.28,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: errorColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppText(
                message,
                variant: AppTextVariant.bodySmall,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
