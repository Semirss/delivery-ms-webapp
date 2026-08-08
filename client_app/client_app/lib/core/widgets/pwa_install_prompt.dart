import 'package:client_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:client_app/core/utils/pwa/pwa_install_helper.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PwaInstallPrompt extends StatefulWidget {
  const PwaInstallPrompt({required this.child, super.key});

  final Widget child;

  @override
  State<PwaInstallPrompt> createState() => _PwaInstallPromptState();
}

class _PwaInstallPromptState extends State<PwaInstallPrompt> {
  static const _dismissedKey = 'motobike_pwa_install_prompt_dismissed_v1';
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIfNeeded());
  }

  Future<void> _showIfNeeded() async {
    if (!kIsWeb || !mounted) return;
    if (Uri.base.path.toLowerCase().contains('login-callback')) return;

    final installState = await getPwaInstallState();
    if (!installState.isWeb || installState.isStandalone) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return;
    if (!mounted) return;

    final dismissed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InstallAppDialog(installState: installState),
    );

    if (dismissed == true) {
      await prefs.setBool(_dismissedKey, true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _InstallAppDialog extends StatefulWidget {
  const _InstallAppDialog({required this.installState});

  final PwaInstallState installState;

  @override
  State<_InstallAppDialog> createState() => _InstallAppDialogState();
}

class _InstallAppDialogState extends State<_InstallAppDialog> {
  bool _installing = false;

  Future<void> _handlePrimaryAction() async {
    if (widget.installState.canPrompt) {
      setState(() => _installing = true);
      await promptPwaInstall();
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isIos = widget.installState.isIos;
    final primaryLabel = widget.installState.canPrompt
        ? 'INSTALL APP'
        : isIos
            ? 'GOT IT'
            : 'OK';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7F3), Colors.white, Color(0xFFFFE7DF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      ImageConstants.appLogo,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Install MotoBike',
                          variant: AppTextVariant.heading3,
                          fontWeight: FontWeight.w900,
                        ),
                        SizedBox(height: 3),
                        AppText(
                          'Fast access from your home screen',
                          variant: AppTextVariant.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isIos) const _IosInstallSteps() else const _InstallBenefits(),
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: _installing ? 'INSTALLING...' : primaryLabel,
                fullWidth: true,
                isLoading: _installing,
                onPressed: _installing ? null : _handlePrimaryAction,
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Maybe later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallBenefits extends StatelessWidget {
  const _InstallBenefits();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _InstallLine(
          icon: Icons.flash_on_rounded,
          title: 'Opens like an app',
          subtitle: 'No browser tabs or address bar.',
        ),
        _InstallLine(
          icon: Icons.notifications_active_rounded,
          title: 'Ready for app features',
          subtitle: 'Built for quick delivery actions.',
        ),
        _InstallLine(
          icon: Icons.lock_rounded,
          title: 'Keeps your session',
          subtitle: 'Stay signed in on this device.',
        ),
      ],
    );
  }
}

class _IosInstallSteps extends StatelessWidget {
  const _IosInstallSteps();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _InstallLine(
          icon: Icons.ios_share_rounded,
          title: 'Tap Share in Safari',
          subtitle: 'Use the share button at the bottom of the screen.',
        ),
        _InstallLine(
          icon: Icons.add_box_rounded,
          title: 'Choose Add to Home Screen',
          subtitle: 'MotoBike will appear with your apps.',
        ),
        _InstallLine(
          icon: Icons.check_circle_rounded,
          title: 'Open from the icon',
          subtitle: 'You will get the standalone app experience.',
        ),
      ],
    );
  }
}

class _InstallLine extends StatelessWidget {
  const _InstallLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.labelLarge,
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: 2),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodySmall,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
