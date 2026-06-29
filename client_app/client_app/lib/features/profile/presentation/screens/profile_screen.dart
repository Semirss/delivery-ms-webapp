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
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
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
                  expandedHeight: 226,
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
                            const SizedBox(height: 20),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 22,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
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
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<_RatingSummary>(
                              future: user == null
                                  ? Future<_RatingSummary>.value(
                                      const _RatingSummary.empty(),
                                    )
                                  : _loadRatingSummary('client', user.id),
                              builder: (context, snapshot) {
                                final rating =
                                    snapshot.data ?? const _RatingSummary.empty();
                                final label = rating.hasRatings
                                    ? '${rating.average.toStringAsFixed(1)} client rating'
                                    : 'No ratings yet';

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                              borderRadius: BorderRadius.circular(AppRadius.lg),
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

  Future<_RatingSummary> _loadRatingSummary(
    String rateeType,
    String rateeId,
  ) async {
    try {
      final data = await Supabase.instance.client
          .from('delivery_ratings')
          .select('rating')
          .eq('ratee_type', rateeType)
          .eq('ratee_id', rateeId);

      if (data.isEmpty) return const _RatingSummary.empty();
      final ratings = data
          .map(
            (row) => int.tryParse(row['rating']?.toString() ?? ''),
          )
          .whereType<int>()
          .toList();
      if (ratings.isEmpty) return const _RatingSummary.empty();

      final total = ratings.fold<int>(0, (sum, rating) => sum + rating);
      return _RatingSummary(
        average: total / ratings.length,
        count: ratings.length,
      );
    } catch (_) {
      return const _RatingSummary.empty();
    }
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.w900,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: tiles
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < tiles.length - 1)
                          Divider(
                            height: 1,
                            indent: 72,
                            color: context.appBorder,
                          ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.primaryLight.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: AppText(
        title,
        variant: AppTextVariant.bodyMedium,
        fontWeight: FontWeight.w900,
      ),
      subtitle: AppText(
        subtitle,
        variant: AppTextVariant.bodySmall,
        color: context.appTextSecondary,
      ),
      trailing: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          color: context.appTextSecondary,
        ),
      ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: AppText(
        title,
        variant: AppTextVariant.bodyMedium,
        fontWeight: FontWeight.w900,
      ),
      subtitle: AppText(
        subtitle,
        variant: AppTextVariant.bodySmall,
        color: context.appTextSecondary,
      ),
      trailing: trailing,
    );
  }
}

class _RatingSummary {
  const _RatingSummary({
    required this.average,
    required this.count,
  });

  const _RatingSummary.empty()
      : average = 0,
        count = 0;

  final double average;
  final int count;

  bool get hasRatings => count > 0;
}
