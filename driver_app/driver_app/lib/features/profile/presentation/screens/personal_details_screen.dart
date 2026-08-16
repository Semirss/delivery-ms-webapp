import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();

  DriverProfileSnapshot? _snapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final snapshot = await _repository.load(user);
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Personal Details'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildIdentityCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _detailTile(
                    Icons.phone_rounded,
                    'Phone',
                    _snapshot?.phone ?? '--',
                  ),
                  _detailTile(
                    Icons.two_wheeler_rounded,
                    'Vehicle',
                    _snapshot?.vehicleType ?? '--',
                  ),
                  _detailTile(
                    Icons.confirmation_number_rounded,
                    'Plate number',
                    _snapshot?.plateNumber ?? '--',
                  ),
                  _detailTile(
                    Icons.alternate_email_rounded,
                    'Telegram',
                    _snapshot?.telegramUsername ?? '--',
                  ),
                  _detailTile(
                    Icons.verified_user_rounded,
                    'Approval status',
                    _snapshot?.approvalStatus ?? '--',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildReadOnlyNotice(),
                ],
              ),
            ),
    );
  }

  Widget _buildIdentityCard() {
    final snapshot = _snapshot;
    final name = snapshot?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  snapshot?.name ?? 'Driver',
                  variant: AppTextVariant.heading3,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText(
                  snapshot?.driverId ?? 'No driver ID',
                  variant: AppTextVariant.bodySmall,
                  color: context.appTextSecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: context.appTextSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              'Admins manage driver information.',
              variant: AppTextVariant.bodySmall,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(
          label,
          variant: AppTextVariant.bodySmall,
          color: context.appTextSecondary,
        ),
        subtitle: AppText(
          value,
          variant: AppTextVariant.bodyMedium,
          color: context.appTextPrimary,
          fontWeight: FontWeight.bold,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
