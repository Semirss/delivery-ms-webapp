import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

PersistentBottomNavBarItem getNavBarItem(
  BuildContext context, {
  required String title,
  required String icon,
  required VoidCallback onPressed,
  bool isDisabled = false,
}) => PersistentBottomNavBarItem(
  icon: _mainIcon(
    context,
    title: title,
    icon: icon,
    isActive: true,
    isDisabled: isDisabled,
  ),
  inactiveIcon: _mainIcon(
    context,
    title: title,
    icon: icon,
    isActive: false,
    isDisabled: isDisabled,
  ),
  onPressed: isDisabled ? (context) {} : (context) => onPressed(),
);

Widget _mainIcon(
  BuildContext context, {
  required String title,
  required String icon,
  required bool isActive,
  required bool isDisabled,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (isActive)
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.surface.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      SvgPicture.asset(
        icon,
        width: 23,
        colorFilter: ColorFilter.mode(
          isDisabled
              ? AppColors.textPrimary.withValues(alpha: 0.3)
              : isActive
              ? AppColors.surface
              : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
      AppText(
        title,
        variant: AppTextVariant.labelSmall,
        color: isDisabled
            ? AppColors.textPrimary.withValues(alpha: 0.3)
            : isActive
            ? AppColors.surface
            : AppColors.textSecondary,
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    ],
  );
}
