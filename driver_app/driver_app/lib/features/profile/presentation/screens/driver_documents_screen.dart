import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();
  final ImagePicker _imagePicker = ImagePicker();

  DriverProfileSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isUploading = false;

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

  Future<void> _uploadPersonalId() async {
    final snapshot = _snapshot;
    final driverId = snapshot?.driverId;
    if (driverId == null) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final path =
          '$driverId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      final contentType = image.mimeType ?? 'image/jpeg';

      final storage = Supabase.instance.client.storage.from('driver_ids');
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      final publicUrl = storage.getPublicUrl(path);
      await _repository.updateDriver(driverId, {'personal_id_url': publicUrl});

      await _load();
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'ID document uploaded.',
        type: AppToastType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Could not upload document. Check Supabase storage setup.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'Could not open the document link.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Documents'),
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
                  _buildVerificationCard(snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDocumentPreview(snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVehicleCard(snapshot),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: snapshot?.personalIdUrl == null
                        ? 'UPLOAD ID DOCUMENT'
                        : 'REPLACE ID DOCUMENT',
                    icon: Icons.upload_file_rounded,
                    fullWidth: true,
                    isLoading: _isUploading,
                    onPressed: _uploadPersonalId,
                  ),
                  if (snapshot?.personalIdUrl != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppButton.outlinedSecondary(
                      label: 'OPEN DOCUMENT',
                      icon: Icons.open_in_new_rounded,
                      fullWidth: true,
                      onPressed: () => _openDocument(snapshot!.personalIdUrl!),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildVerificationCard(DriverProfileSnapshot? snapshot) {
    final approved = snapshot?.approvalStatus == 'Approved';
    final active = snapshot?.driver?['is_active'] != false;

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
          Row(
            children: [
              Icon(
                approved
                    ? Icons.verified_rounded
                    : Icons.pending_actions_rounded,
                color: approved ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  snapshot?.approvalStatus ?? 'Pending',
                  variant: AppTextVariant.heading3,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            active
                ? 'Your account is active. Keep documents current for dispatch.'
                : 'This account is inactive. Contact support before working.',
            variant: AppTextVariant.bodyMedium,
            color: context.appTextSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(DriverProfileSnapshot? snapshot) {
    final url = snapshot?.personalIdUrl;

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
            'Personal ID',
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.md),
          if (url == null)
            Container(
              height: 168,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    color: context.appTextSecondary,
                    size: 42,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    'No ID document uploaded',
                    variant: AppTextVariant.bodyMedium,
                    color: context.appTextSecondary,
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.network(
                url,
                height: 196,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 168,
                  alignment: Alignment.center,
                  color: context.appSurfaceAlt,
                  child: AppText(
                    'Document saved. Tap open to view it.',
                    variant: AppTextVariant.bodyMedium,
                    color: context.appTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(DriverProfileSnapshot? snapshot) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          _factRow(
            Icons.two_wheeler_rounded,
            'Vehicle',
            snapshot?.vehicleType ?? '--',
          ),
          const SizedBox(height: AppSpacing.md),
          _factRow(
            Icons.confirmation_number_rounded,
            'Plate',
            snapshot?.plateNumber ?? '--',
          ),
          const SizedBox(height: AppSpacing.md),
          _factRow(
            Icons.phone_rounded,
            'Phone',
            snapshot?.phone ?? '--',
          ),
        ],
      ),
    );
  }

  Widget _factRow(IconData icon, String label, String value) {
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
            variant: AppTextVariant.bodyMedium,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
