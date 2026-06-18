import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_starter/config/router/app_routes.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(titleText: 'Profile', centerTitle: true),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            final fullName = user.firstName != null && user.lastName != null
                ? '${user.firstName} ${user.lastName}'
                : 'User';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AppCard.filled(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary,
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? AppText(
                                  user.firstName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      user.email.substring(0, 1).toUpperCase(),
                                  variant: AppTextVariant.heading2,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppText(fullName, variant: AppTextVariant.heading3),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          user.email,
                          variant: AppTextVariant.bodyMedium,
                          color: AppColors.textSecondary,
                        ),
                        if (user.phone != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            user.phone!,
                            variant: AppTextVariant.bodyMedium,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: AppDataCard.compact(
                          title: 'Email',
                          value: user.isEmailVerified
                              ? 'Verified'
                              : 'Not verified',
                          trailing: AppIcon(
                            icon: user.isEmailVerified
                                ? Icons.verified_rounded
                                : Icons.cancel_outlined,
                            color: user.isEmailVerified
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppDataCard.compact(
                          title: 'Phone',
                          value: user.phone == null
                              ? 'Not added'
                              : (user.isPhoneVerified
                                    ? 'Verified'
                                    : 'Not verified'),
                          trailing: AppIcon(
                            icon: user.phone == null
                                ? Icons.phone_disabled_outlined
                                : (user.isPhoneVerified
                                      ? Icons.verified_rounded
                                      : Icons.cancel_outlined),
                            color: user.phone == null
                                ? AppColors.textSecondary
                                : (user.isPhoneVerified
                                      ? AppColors.success
                                      : AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppText('Account', variant: AppTextVariant.heading3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard.elevated(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ProfileActionTile(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          onTap: () {
                            context.pushNamed(AppRoutes.personalDetails.name);
                          },
                        ),
                        _ProfileActionTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          onTap: () {
                            context.pushNamed(AppRoutes.notification.name);
                          },
                        ),
                        _ProfileActionTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Pin',
                          onTap: () {
                            context.pushNamed(AppRoutes.changePin.name);
                          },
                        ),
                        _ProfileActionTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          onTap: () {
                            context.pushNamed(AppRoutes.setting.name);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2 * AppSpacing.lg),
                  AppButton.danger(
                    label: 'Logout',
                    icon: Icons.logout,
                    fullWidth: true,
                    onPressed: () {
                      AppDialog.confirm(
                        context: context,
                        title: 'Logout',
                        contentText: 'Are you sure you want to logout?',
                        confirmLabel: 'Logout',
                        confirmVariant: AppButtonVariant.danger,
                        cancelLabel: 'Cancel',
                      ).then((confirmed) {
                        if (confirmed == true) {
                          context.read<AuthBloc>().add(const LogoutEvent());
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final dynamic icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(icon: icon, color: AppColors.primary),
      title: AppText(title, variant: AppTextVariant.bodyLarge),
      trailing: const AppIcon(
        icon: Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
