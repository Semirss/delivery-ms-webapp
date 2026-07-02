import 'package:driver_app/config/router/app_routes.dart';
import 'package:driver_app/config/router/navigation_helper.dart';
import 'package:driver_app/core/preferences/app_preferences.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();

  DriverProfileSnapshot? _snapshot;
  RealtimeChannel? _driverChannel;
  RealtimeChannel? _deliveriesChannel;
  RealtimeChannel? _notificationsChannel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (mounted) setState(() => _isLoading = true);
    final snapshot = await _repository.load(user);
    if (!mounted) return;

    setState(() {
      _snapshot = snapshot;
      _isLoading = false;
    });

    _subscribe(snapshot.driverId);
  }

  void _subscribe(String? driverId) {
    _driverChannel?.unsubscribe();
    _deliveriesChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();

    if (driverId == null || driverId.isEmpty) return;

    final supabase = Supabase.instance.client;
    _driverChannel = supabase
        .channel('public:drivers:profile:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'drivers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: driverId,
          ),
          callback: (_) => _loadProfile(),
        )
        .subscribe();

    _deliveriesChannel = supabase
        .channel('public:deliveries:profile:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (_) => _loadProfile(),
        )
        .subscribe();

    _notificationsChannel = supabase
        .channel('public:app_notifications:profile:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'app',
            value: 'driver',
          ),
          callback: (_) => _loadProfile(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _driverChannel?.unsubscribe();
    _deliveriesChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();
    super.dispose();
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
        child: _isLoading && _snapshot == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildHeader(context),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverToBoxAdapter(child: _buildContent(context)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final snapshot = _snapshot;
    final name = snapshot?.name ?? 'Driver';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'D';
    final status = snapshot?.status ?? 'Offline';
    final approval = snapshot?.approvalStatus ?? 'Pending';
    final isApproved = approval == 'Approved';
    final isOnline = status == 'Online';

    return SliverAppBar(
      expandedHeight: 272,
      backgroundColor: AppColors.primary,
      pinned: true,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: 'Refresh profile',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadProfile,
        ),
      ],
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? AppColors.success
                                : AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            isApproved
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _HeaderBadge(
                        icon: isOnline
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        label: status,
                      ),
                      _HeaderBadge(
                        icon: isApproved
                            ? Icons.admin_panel_settings_rounded
                            : Icons.pending_actions_rounded,
                        label: approval,
                      ),
                      _HeaderBadge(
                        icon: Icons.two_wheeler_rounded,
                        label: snapshot?.vehicleType ?? 'Motorbike',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.hasDriver) {
      return _buildMissingProfile(context, snapshot?.errorMessage);
    }

    final preferences = AppPreferencesScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard(
              context,
              snapshot.displayDeliveries.toString(),
              'Deliveries',
              Icons.delivery_dining_rounded,
            ),
            const SizedBox(width: AppSpacing.md),
            _buildStatCard(
              context,
              '${snapshot.totalEarnings.toStringAsFixed(0)} ETB',
              'Earnings',
              Icons.payments_rounded,
            ),
            const SizedBox(width: AppSpacing.md),
            _buildStatCard(
              context,
              snapshot.rating.label,
              'Rating',
              Icons.star_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSummaryPanel(context, snapshot),
        const SizedBox(height: AppSpacing.xl),
        _buildSection(context, 'Performance', [
          _buildTile(
            context,
            icon: Icons.payments_outlined,
            title: 'Earnings',
            subtitle: 'Total ${snapshot.totalEarnings.toStringAsFixed(0)} ETB',
            onTap: context.navigator.navigateToEarningsTab,
          ),
          _buildTile(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Statistics',
            subtitle: 'Daily activity, completion and payouts',
            onTap: () => context.pushNamed(AppRoutes.driverStatistics.name),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSection(context, 'Account', [
          _buildTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Documents & Verification',
            subtitle: snapshot.personalIdUrl == null
                ? 'Upload your ID document'
                : 'ID document is on file',
            onTap: () => context.pushNamed(AppRoutes.driverDocuments.name),
          ),
          _buildTile(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Personal Details',
            subtitle: '${snapshot.vehicleType} - ${snapshot.plateNumber}',
            onTap: () => context.pushNamed(AppRoutes.personalDetails.name),
          ),
          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: snapshot.unreadNotifications == 0
                ? 'No unread alerts'
                : '${snapshot.unreadNotifications} unread alerts',
            onTap: context.navigator.pushNotificationScreen,
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSection(context, 'App Preferences', [
          _buildPreferenceTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'Light, dark, or system',
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
            subtitle: 'Send a support request with your driver ID',
            onTap: () => context.pushNamed(AppRoutes.support.name),
          ),
          _buildTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How driver data and location are handled',
            onTap: () => context.pushNamed(AppRoutes.privacy.name),
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
    );
  }

  Widget _buildMissingProfile(BuildContext context, String? message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 58,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'Profile not found',
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            message ?? 'Sign in again or contact support to link your account.',
            variant: AppTextVariant.bodyMedium,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'TRY AGAIN',
            icon: Icons.refresh_rounded,
            onPressed: _loadProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(
    BuildContext context,
    DriverProfileSnapshot snapshot,
  ) {
    final joined = snapshot.createdAt == null
        ? 'Unknown'
        : DateFormat('dd MMM yyyy').format(snapshot.createdAt!);
    final lastLocation = snapshot.lastLocationUpdate == null
        ? 'Not shared yet'
        : DateFormat('dd MMM, hh:mm a').format(snapshot.lastLocationUpdate!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          AppColors.primary.withValues(alpha: context.isAppDark ? 0.16 : 0.08),
          context.appSurface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: context.isAppDark ? 0.26 : 0.16,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildFactRow(
            context,
            Icons.calendar_month_rounded,
            'Joined',
            joined,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFactRow(
            context,
            Icons.my_location_rounded,
            'Last GPS update',
            lastLocation,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFactRow(
            context,
            Icons.today_rounded,
            'Today',
            '${snapshot.todayDeliveries} deliveries - '
                '${snapshot.todayEarnings.toStringAsFixed(0)} ETB',
          ),
        ],
      ),
    );
  }

  Widget _buildFactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppText(
            label,
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
          ),
        ),
        Flexible(
          child: AppText(
            value,
            variant: AppTextVariant.bodySmall,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 106),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            AppText(
              value,
              variant: AppTextVariant.labelLarge,
              fontWeight: FontWeight.bold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: context.appTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.bold,
          color: context.appTextPrimary,
        ),
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
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < tiles.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: context.appBorder,
                        ),
                    ],
                  ),
                )
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
      leading: _TileIcon(icon: icon),
      title: AppText(
        title,
        variant: AppTextVariant.bodyMedium,
        fontWeight: FontWeight.bold,
        color: context.appTextPrimary,
      ),
      subtitle: AppText(
        subtitle,
        variant: AppTextVariant.bodySmall,
        color: context.appTextSecondary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.appTextSecondary,
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
      leading: _TileIcon(icon: icon),
      title: AppText(
        title,
        variant: AppTextVariant.bodyMedium,
        fontWeight: FontWeight.bold,
        color: context.appTextPrimary,
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}
