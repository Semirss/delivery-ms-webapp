import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_ui/app_ui.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/home/presentation/screens/ride_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
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
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('Account', [
                          _buildTile(
                            icon: Icons.history_rounded,
                            title: 'Ride History',
                            subtitle: 'View all your past trips',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen())),
                          ),
                          _buildTile(
                            icon: Icons.payment_rounded,
                            title: 'Payment Methods',
                            subtitle: 'Manage your payment options',
                            onTap: () {},
                          ),
                          _buildTile(
                            icon: Icons.notifications_rounded,
                            title: 'Notifications',
                            subtitle: 'Manage your preferences',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSection('Support', [
                          _buildTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'Get help from our team',
                            onTap: () {},
                          ),
                          _buildTile(
                            icon: Icons.star_border_rounded,
                            title: 'Rate the App',
                            subtitle: 'Share your experience',
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

  Widget _buildTile({
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
      subtitle: AppText(subtitle, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
    );
  }
}
