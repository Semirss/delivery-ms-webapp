import 'package:client_app/core/config/app_config.dart';
import 'package:client_ui/app_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppVersionPolicy {
  final int minimumBuild;
  final int latestBuild;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String releaseNotes;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final int installedBuild;
  final String installedVersion;

  const AppVersionPolicy({
    required this.minimumBuild,
    required this.latestBuild,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.releaseNotes,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.installedBuild,
    required this.installedVersion,
  });

  bool get requiresUpdate => forceUpdate && installedBuild < minimumBuild;
  bool get blocksApp => maintenanceMode || requiresUpdate;

  factory AppVersionPolicy.fromJson(
    Map<String, dynamic> json,
    PackageInfo packageInfo,
  ) {
    return AppVersionPolicy(
      minimumBuild: _intValue(json['minimum_build'], fallback: 1),
      latestBuild: _intValue(json['latest_build'], fallback: 1),
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      forceUpdate: json['force_update'] == true,
      updateUrl: _updateUrlValue(json['update_url'], packageInfo),
      releaseNotes: json['release_notes']?.toString() ?? '',
      maintenanceMode: json['maintenance_mode'] == true,
      maintenanceMessage: json['maintenance_message']?.toString() ?? '',
      installedBuild: int.tryParse(packageInfo.buildNumber) ?? 1,
      installedVersion: packageInfo.version,
    );
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _updateUrlValue(Object? value, PackageInfo packageInfo) {
    final configured = value?.toString().trim() ?? '';
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        packageInfo.packageName.isNotEmpty) {
      return 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
    }
    return '';
  }
}

class AppVersionService {
  final AppConfig config;

  const AppVersionService({required this.config});

  Future<AppVersionPolicy?> getPolicy(String app) async {
    final platform = _platformKey();
    final baseUrl = config.apiBaseUrl.trim();
    if (platform == null || baseUrl.isEmpty) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final dio = Dio(
        BaseOptions(
          connectTimeout: Duration(milliseconds: config.apiTimeout),
          receiveTimeout: Duration(milliseconds: config.apiTimeout),
        ),
      );
      final response = await dio.get<dynamic>(
        _appVersionsUrl(baseUrl),
        queryParameters: {'app': app, 'platform': platform},
      );

      final data = response.data;
      if (data is List && data.isNotEmpty && data.first is Map) {
        return AppVersionPolicy.fromJson(
          Map<String, dynamic>.from(data.first as Map),
          packageInfo,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _appVersionsUrl(String baseUrl) {
    final normalized = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/api')) return '$normalized/app-versions';
    return '$normalized/api/app-versions';
  }

  String? _platformKey() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }
}

class VersionGate extends StatefulWidget {
  final String app;
  final AppConfig config;
  final Widget child;

  const VersionGate({
    super.key,
    required this.app,
    required this.config,
    required this.child,
  });

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  late final AppVersionService _service;
  late Future<AppVersionPolicy?> _policyFuture;

  @override
  void initState() {
    super.initState();
    _service = AppVersionService(config: widget.config);
    _policyFuture = _service.getPolicy(widget.app);
  }

  void _retry() {
    setState(() {
      _policyFuture = _service.getPolicy(widget.app);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersionPolicy?>(
      future: _policyFuture,
      builder: (context, snapshot) {
        final policy = snapshot.data;
        if (policy == null || !policy.blocksApp) {
          return widget.child;
        }
        return _BlockedVersionScreen(policy: policy, onRetry: _retry);
      },
    );
  }
}

class _BlockedVersionScreen extends StatelessWidget {
  final AppVersionPolicy policy;
  final VoidCallback onRetry;

  const _BlockedVersionScreen({required this.policy, required this.onRetry});

  Future<void> _openUpdate(BuildContext context) async {
    final uri = Uri.tryParse(policy.updateUrl);
    if (uri == null || policy.updateUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update link is not configured yet.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = policy.maintenanceMode;
    final title = isMaintenance
        ? 'Service temporarily unavailable'
        : 'Update required';
    final message = isMaintenance
        ? (policy.maintenanceMessage.isNotEmpty
              ? policy.maintenanceMessage
              : 'The service is under maintenance. Please try again shortly.')
        : (policy.releaseNotes.isNotEmpty
              ? policy.releaseNotes
              : 'A newer app version is required to continue.');

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isMaintenance
                    ? Icons.construction_rounded
                    : Icons.system_update_rounded,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppText(
                title,
                variant: AppTextVariant.heading2,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppText(
                message,
                variant: AppTextVariant.bodyMedium,
                color: context.appTextSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  children: [
                    _VersionInfoRow(
                      label: 'Installed',
                      value:
                          '${policy.installedVersion}+${policy.installedBuild}',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _VersionInfoRow(
                      label: 'Latest',
                      value: '${policy.latestVersion}+${policy.latestBuild}',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _VersionInfoRow(
                      label: 'Minimum build',
                      value: policy.minimumBuild.toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!isMaintenance)
                AppButton.primary(
                  label: 'UPDATE APP',
                  fullWidth: true,
                  onPressed: () => _openUpdate(context),
                ),
              const SizedBox(height: AppSpacing.md),
              AppButton.outlinedSecondary(
                label: 'TRY AGAIN',
                fullWidth: true,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _VersionInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          color: context.appTextSecondary,
        ),
        AppText(
          value,
          variant: AppTextVariant.bodyMedium,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }
}
