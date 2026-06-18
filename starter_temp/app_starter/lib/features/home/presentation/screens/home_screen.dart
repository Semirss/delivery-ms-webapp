import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:app_starter/config/router/navigation_helper.dart';
import 'package:app_starter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_starter/features/auth/presentation/bloc/auth_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        titleText: 'Home',
        centerTitle: true,
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return AppIconButton.ghost(
                  icon: Icons.person,
                  onPressed: () {
                    context.navigator.pushProfileScreen();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            final displayName = user.firstName != null && user.lastName != null
                ? '${user.firstName} ${user.lastName}'
                : user.email;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, displayName),
                  const SizedBox(height: AppSpacing.lg),
                  AppDataCard.gradient(
                    title: 'Current Productivity',
                    value: '84%',
                    icon: Icons.rocket_launch_rounded,
                    gradientColors: const [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSummarySection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader('Verification Status', onAction: () {}),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppDataCard.compact(
                          title: 'Identity',
                          value: user.isEmailVerified
                              ? 'Verified'
                              : 'Unverified',
                          trailing: AppIcon(
                            icon: user.isEmailVerified
                                ? Icons.verified_rounded
                                : Icons.warning_amber_rounded,
                            color: user.isEmailVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppDataCard.compact(
                          title: 'Contact',
                          value: user.phone?.isNotEmpty == true
                              ? 'Complete'
                              : 'Incomplete',
                          trailing: AppIcon(
                            icon: user.phone?.isNotEmpty == true
                                ? Icons.check_circle_rounded
                                : Icons.pending_outlined,
                            color: user.phone?.isNotEmpty == true
                                ? AppColors.success
                                : AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSectionHeader('Recent Activity', onAction: () {}),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard.outlined(
                    child: Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.login_rounded,
                          title: 'Last Login',
                          subtitle: 'Today, 10:24 AM',
                          color: AppColors.primary,
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildActivityItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Profile Updated',
                          subtitle: 'Yesterday, 4:15 PM',
                          color: AppColors.success,
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildActivityItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Security Alert',
                          subtitle: 'Oct 24, 2023',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSectionHeader('Quick Shortcuts', onAction: null),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 1.4,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          context.navigator.pushSettingScreen();
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        onTap: () {
                          context.navigator.pushProfileScreen();
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {
                          context.navigator.pushNotificationScreen();
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.grid_view_rounded,
                        title: 'Components',
                        onTap: () {
                          _showComponentShowcase(context);
                        },
                      ),
                    ],
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

  Widget _buildHeader(BuildContext context, String displayName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Welcome back,',
                  variant: AppTextVariant.bodyMedium,
                  color: AppColors.textSecondary,
                ),
                AppText(
                  displayName,
                  variant: AppTextVariant.heading2,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              child: AppIcon(icon: Icons.person, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () => context.navigator.pushSearchScreen(),
          child: AbsorbPointer(
            child: AppTextField.filled(
              hint: 'Search features, help, or components...',
              prefixIcon: Icons.search_rounded,
              readOnly: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          title,
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.bold,
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const AppText(
              'View All',
              variant: AppTextVariant.labelLarge,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  void _showComponentShowcase(BuildContext context) {
    AppModal.showScrollable<void>(
      context: context,
      title: 'UI Components Showcase',
      builder: (BuildContext context, ScrollController controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Typography
              const _Section(
                title: 'Typography',
                children: [
                  AppText('Heading 1', variant: AppTextVariant.heading1),
                  AppText('Heading 2', variant: AppTextVariant.heading2),
                  AppText('Heading 3', variant: AppTextVariant.heading3),
                  AppText('Body Large', variant: AppTextVariant.bodyLarge),
                  AppText('Body Medium', variant: AppTextVariant.bodyMedium),
                  AppText(
                    'Body Small',
                    variant: AppTextVariant.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Buttons
              _Section(
                title: 'Buttons',
                children: [
                  AppButton.primary(
                    label: 'Primary Full Width',
                    onPressed: () {},
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.secondary(
                    label: 'Secondary Button',
                    onPressed: () {},
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.outlinedPrimary(
                    label: 'Outline Button',
                    onPressed: () {},
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.primary(
                          label: 'Split 1',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Split 2',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      AppIconButton.primary(icon: Icons.add, onPressed: () {}),
                      const SizedBox(width: AppSpacing.md),
                      AppIconButton.secondary(
                        icon: Icons.edit,
                        onPressed: () {},
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppIconButton.ghost(
                        icon: Icons.delete,
                        onPressed: () {},
                        iconColor: AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ),

              // Forms
              _Section(
                title: 'Forms',
                children: [
                  const AppTextField(
                    label: 'Text Field',
                    hint: 'Enter some text...',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>.medium(
                    label: 'Dropdown',
                    items: const ['Option 1', 'Option 2', 'Option 3'],
                    onChanged: (v) {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCheckbox(
                    label: 'Check me',
                    onChanged: (v) {
                      //checkbox value changed
                    },
                    value: false,
                  ),
                ],
              ),

              // Feedback
              _Section(
                title: 'Feedback',
                children: [
                  AppButton.outlinedPrimary(
                    label: 'Show Toast',
                    onPressed: () {
                      AppToast.show(
                        context: context,
                        message: 'Success Message',
                        type: AppToastType.success,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.outlinedSecondary(
                    label: 'Show Dialog',
                    onPressed: () {
                      AppDialog.show<void>(
                        context: context,
                        title: 'Confirm Action',
                        contentText: 'Are you sure you want to proceed?',
                        primaryAction: AppDialogAction(
                          label: 'Confirm',
                          onPressed: () => Navigator.pop(context),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        _buildSummaryCard(
          label: 'Success Rate',
          value: '98%',
          color: AppColors.success,
          point: 0.98,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildSummaryCard(
          label: 'Active Time',
          value: '4.2h',
          color: AppColors.info,
          point: 0.65,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required double point,
  }) {
    return Expanded(
      child: AppCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              value,
              variant: AppTextVariant.heading2,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: point,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AppIcon(icon: icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, variant: AppTextVariant.labelLarge),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textDisabled,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AppCard.outlined(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon: icon, size: 28, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            title,
            variant: AppTextVariant.labelLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        AppText(title, variant: AppTextVariant.heading3),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }
}
