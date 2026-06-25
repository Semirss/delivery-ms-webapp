import 'package:driver_app/config/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:driver_app/core/preferences/app_preferences.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/presentation/screens/earnings_screen.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.goNamed(AppRoutes.login.name);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final preferences = AppPreferencesScope.of(context);
            final user = state is AuthAuthenticated ? state.user : null;
            final name = (user?.firstName != null && user?.lastName != null)
                ? '${user!.firstName} ${user.lastName}'
                : user?.email ?? 'Driver';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  backgroundColor: AppColors.primary,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: Text(
                                    initial,
                                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '5.0 - Motorbike Driver',
                                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.goNamed(AppRoutes.home.name),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            _buildStatCard('0', 'Deliveries', Icons.motorcycle_rounded),
                            const SizedBox(width: AppSpacing.md),
                            _buildStatCard('0 ETB', 'Earnings', Icons.payments_rounded),
                            const SizedBox(width: AppSpacing.md),
                            _buildStatCard('5.0', 'Rating', Icons.star_rounded),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSection('Performance', [
                          _buildTile(
                            icon: Icons.payments_outlined,
                            title: 'Earnings',
                            subtitle: 'View your income & delivery history',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
                          ),
                          _buildTile(
                            icon: Icons.bar_chart_rounded,
                            title: 'Statistics',
                            subtitle: 'Daily, weekly & monthly stats',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection('Account', [
                          _buildTile(
                            icon: Icons.badge_outlined,
                            title: 'Documents & Verification',
                            subtitle: 'License & vehicle papers',
                            onTap: () {},
                          ),
                          _buildTile(
                            icon: Icons.account_circle_outlined,
                            title: 'Personal Details',
                            subtitle: 'Update your profile info',
                            onTap: () {},
                          ),
                          _buildTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Manage your preferences',
                            onTap: () => context.pushNamed(AppRoutes.notification.name),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection('App Preferences', [
                          _buildPreferenceTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Theme',
                            subtitle: 'Choose how the app looks',
                            trailing: DropdownButton<ThemeMode>(
                              value: preferences.themeMode,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                              ],
                              onChanged: (value) {
                                if (value != null) preferences.setThemeMode(value);
                              },
                            ),
                          ),
                          _buildPreferenceTile(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            subtitle: 'English and Amharic ready',
                            trailing: DropdownButton<String>(
                              value: preferences.languageCode,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'am', child: Text('Amharic')),
                              ],
                              onChanged: (value) {
                                if (value != null) preferences.setLanguageCode(value);
                              },
                            ),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection('Support', [
                          _buildTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'Report an issue or get help',
                            onTap: () {},
                          ),
                          _buildTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'Read our privacy terms',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.outlinedSecondary(
                          label: 'SIGN OUT',
                          fullWidth: true,
                          onPressed: () => context.read<AuthBloc>().add(const LogoutEvent()),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            AppText(value, variant: AppTextVariant.labelLarge, fontWeight: FontWeight.bold),
            AppText(label, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: tiles.asMap().entries.map((e) => Column(
              children: [
                e.value,
                if (e.key < tiles.length - 1) const Divider(height: 1, indent: 56),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: AppText(title, variant: AppTextVariant.bodyMedium, fontWeight: FontWeight.bold),
      subtitle: AppText(subtitle, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: AppText(title, variant: AppTextVariant.bodyMedium, fontWeight: FontWeight.bold),
      subtitle: AppText(subtitle, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
      trailing: trailing,
    );
  }
}
