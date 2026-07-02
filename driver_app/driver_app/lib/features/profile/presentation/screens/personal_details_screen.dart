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
  bool _isSaving = false;

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

  Future<void> _showEditSheet() async {
    final snapshot = _snapshot;
    final driverId = snapshot?.driverId;
    if (snapshot == null || driverId == null) return;

    final nameController = TextEditingController(text: snapshot.name);
    final phoneController = TextEditingController(text: snapshot.phone);
    final plateController = TextEditingController(
      text: snapshot.plateNumber == 'Not added' ? '' : snapshot.plateNumber,
    );
    final telegramController = TextEditingController(
      text: snapshot.telegramUsername == 'Not connected'
          ? ''
          : snapshot.telegramUsername,
    );
    const vehicleOptions = {'Motor', 'Bike', 'Motorbike'};
    var vehicleType = vehicleOptions.contains(snapshot.vehicleType)
        ? snapshot.vehicleType
        : 'Motorbike';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.appBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppText(
                          'Edit Details',
                          variant: AppTextVariant.heading2,
                          color: context.appTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          value: vehicleType,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle type',
                            prefixIcon: Icon(Icons.two_wheeler_rounded),
                          ),
                          dropdownColor: context.appSurface,
                          items: const [
                            DropdownMenuItem(
                              value: 'Motor',
                              child: Text('Motor'),
                            ),
                            DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                            DropdownMenuItem(
                              value: 'Motorbike',
                              child: Text('Motorbike'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() => vehicleType = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: plateController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Plate number',
                            prefixIcon: Icon(Icons.confirmation_number_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: telegramController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Telegram username',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.primary(
                          label: 'SAVE CHANGES',
                          fullWidth: true,
                          isLoading: _isSaving,
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();
                            if (name.isEmpty || phone.isEmpty) {
                              AppToast.show(
                                context: context,
                                message: 'Name and phone are required.',
                                type: AppToastType.warning,
                              );
                              return;
                            }

                            setState(() => _isSaving = true);
                            try {
                              await _repository.updateDriver(driverId, {
                                'name': name,
                                'phone': phone,
                                'vehicle_type': vehicleType,
                                'plate_number': plateController.text.trim(),
                                'telegram_username':
                                    telegramController.text.trim(),
                              });
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              await _load();
                              if (!mounted) return;
                              AppToast.show(
                                context: context,
                                message: 'Profile details updated.',
                                type: AppToastType.success,
                              );
                            } catch (_) {
                              if (!mounted) return;
                              AppToast.show(
                                context: context,
                                message: 'Could not update profile details.',
                                type: AppToastType.error,
                              );
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    plateController.dispose();
    telegramController.dispose();
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
                  AppButton.primary(
                    label: 'EDIT DETAILS',
                    icon: Icons.edit_rounded,
                    fullWidth: true,
                    onPressed: _showEditSheet,
                  ),
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
