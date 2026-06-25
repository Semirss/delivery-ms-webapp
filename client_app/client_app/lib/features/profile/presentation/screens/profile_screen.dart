import 'package:client_app/config/router/app_routes.dart';
import 'package:client_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_ui/app_ui.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/home/presentation/screens/ride_history_screen.dart';
import 'package:client_app/core/preferences/app_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final Uri _websiteUri = Uri.parse('https://www.motobikedeliveryservice.com/');

  Future<void> _openWebsite(BuildContext context) async {
    final opened = await launchUrl(_websiteUri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppToast.show(
        context: context,
        message: 'Could not open website.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
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
                : user?.email ?? 'User';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
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
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.28)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  ImageConstants.appLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
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
                        _buildSection(context, 'Account', [
                          _buildTile(
                            context,
                            icon: Icons.history_rounded,
                            title: 'Delivery History',
                            subtitle: 'View all your past deliveries',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const RideHistoryScreen(),
                              ),
                            ),
                          ),
                          _buildTile(
                            context,
                            icon: Icons.notifications_rounded,
                            title: 'Notifications',
                            subtitle: 'Manage your preferences',
                            onTap: () => context.pushNamed(AppRoutes.notification.name),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection(context, 'App Preferences', [
                          _buildPreferenceTile(
                            context,
                            icon: Icons.dark_mode_outlined,
                            title: 'Theme',
                            subtitle: 'Choose how the app looks',
                            trailing: DropdownButton<ThemeMode>(
                              value: preferences.themeMode,
                              dropdownColor: context.appSurface,
                              style: TextStyle(color: context.appTextPrimary),
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
                            context,
                            icon: Icons.language_rounded,
                            title: 'Language',
                            subtitle: 'English and Amharic ready',
                            trailing: DropdownButton<String>(
                              value: preferences.languageCode,
                              dropdownColor: context.appSurface,
                              style: TextStyle(color: context.appTextPrimary),
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
                        _buildSection(context, 'Support', [
                          _buildTile(
                            context,
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'Get help from our team',
                            onTap: () => _openWebsite(context),
                          ),
                          _buildTile(
                            context,
                            icon: Icons.star_border_rounded,
                            title: 'Rate the App',
                            subtitle: 'Share your experience',
                            onTap: () {},
                          ),
                          _buildTile(
                            context,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'Read our privacy terms',
                            onTap: () => _openWebsite(context),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.outlinedSecondary(
                          label: 'SIGN OUT',
                          fullWidth: true,
                          onPressed: () {
                            context.read<AuthBloc>().add(const LogoutEvent());
                          },
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

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            children: tiles
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < tiles.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
      subtitle: AppText(subtitle, variant: AppTextVariant.bodySmall, color: context.appTextSecondary),
      trailing: Icon(Icons.chevron_right_rounded, color: context.appTextSecondary),
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context, {
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
      subtitle: AppText(subtitle, variant: AppTextVariant.bodySmall, color: context.appTextSecondary),
      trailing: trailing,
    );
  }
}
