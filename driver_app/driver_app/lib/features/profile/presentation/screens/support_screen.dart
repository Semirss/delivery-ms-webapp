import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
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

  Future<void> _copyDriverId() async {
    final driverId = _snapshot?.driverId;
    if (driverId == null) return;

    await Clipboard.setData(ClipboardData(text: driverId));
    if (!mounted) return;
    AppToast.show(
      context: context,
      message: 'Driver ID copied.',
      type: AppToastType.success,
    );
  }

  Future<void> _sendSupportEmail() async {
    final snapshot = _snapshot;
    final body = Uri.encodeComponent(
      'Driver: ${snapshot?.name ?? ''}\n'
      'Driver ID: ${snapshot?.driverId ?? ''}\n'
      'Phone: ${snapshot?.phone ?? ''}\n\n'
      'Issue:\n',
    );
    final uri = Uri.parse(
      'mailto:support@motobike.app?subject=Driver%20support&body=$body',
    );

    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'No email app is available on this device.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _callDriverPhone() async {
    final phone = _snapshot?.phone;
    if (phone == null || phone == 'No phone added') return;

    final uri = Uri(scheme: 'tel', path: phone);
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'Could not open the phone dialer.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Help & Support'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _buildDriverCard(),
                const SizedBox(height: AppSpacing.lg),
                _actionTile(
                  Icons.email_rounded,
                  'Email support',
                  'Creates a message with your driver details attached.',
                  _sendSupportEmail,
                ),
                _actionTile(
                  Icons.copy_rounded,
                  'Copy driver ID',
                  _snapshot?.driverId ?? 'No driver ID found',
                  _copyDriverId,
                ),
                _actionTile(
                  Icons.phone_rounded,
                  'Call your registered number',
                  _snapshot?.phone ?? 'No phone added',
                  _callDriverPhone,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildGuide(),
              ],
            ),
    );
  }

  Widget _buildDriverCard() {
    final snapshot = _snapshot;

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
            alpha: context.isAppDark ? 0.25 : 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.support_agent_rounded, color: Colors.white),
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
                  snapshot?.driverId ?? 'Driver ID unavailable',
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

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(
          title,
          variant: AppTextVariant.bodyMedium,
          color: context.appTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        subtitle: AppText(
          subtitle,
          variant: AppTextVariant.bodySmall,
          color: context.appTextSecondary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.appTextSecondary,
        ),
      ),
    );
  }

  Widget _buildGuide() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Before contacting support',
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.md),
          _guideLine('Keep GPS enabled while online.'),
          _guideLine('Finish active deliveries before going offline.'),
          _guideLine('Refresh the app after admin changes your approval.'),
        ],
      ),
    );
  }

  Widget _guideLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              text,
              variant: AppTextVariant.bodyMedium,
              color: context.appTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
