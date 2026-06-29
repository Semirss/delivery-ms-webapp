import 'dart:typed_data';

import 'package:driver_app/config/router/app_routes.dart';
import 'package:driver_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:driver_app/core/utils/constants/ui_constants.dart';
import 'package:driver_app/core/utils/functions/base_functions/validators.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _maxIdImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _plateController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPickingId = false;
  String _selectedVehicleType = 'Bike';
  Uint8List? _personalIdBytes;
  String? _personalIdFileName;
  String? _personalIdMimeType;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickPersonalIdImage() async {
    if (_isPickingId) return;

    setState(() => _isPickingId = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > _maxIdImageBytes) {
        if (!mounted) return;
        AppModal.error<void>(
          context: context,
          title: 'Image too large',
          contentText: 'Personal ID photo must be under 5MB.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _personalIdBytes = bytes;
        _personalIdFileName = image.name;
        _personalIdMimeType = image.mimeType;
      });
    } catch (e) {
      if (!mounted) return;
      AppModal.error<void>(
        context: context,
        title: 'Upload failed',
        contentText: 'Could not read the selected ID photo.',
      );
    } finally {
      if (mounted) setState(() => _isPickingId = false);
    }
  }

  void _handleSignUp() {
    final validationError = _validationError;
    if (validationError != null) {
      AppModal.error<void>(
        context: context,
        title: 'Check application',
        contentText: validationError,
      );
      return;
    }

    context.read<AuthBloc>().add(
      SignUpEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        telegramUsername: _telegramController.text.trim(),
        plateNumber: _plateController.text.trim(),
        vehicleType: _selectedVehicleType,
        personalIdBytes: _personalIdBytes,
        personalIdFileName: _personalIdFileName,
        personalIdMimeType: _personalIdMimeType,
      ),
    );
  }

  String? get _validationError {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final telegram = _telegramController.text.trim();
    final plate = _plateController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty) return 'Please enter your first name.';
    if (lastName.isEmpty) return 'Please enter your last name.';
    if (email.isEmpty || !isValidEmail(email))
      return 'Please enter a valid email.';
    if (phone.isEmpty) return 'Please enter your phone number.';
    if (telegram.isEmpty) return 'Please enter your Telegram username.';
    if (plate.isEmpty) return 'Please enter your plate number.';
    if (!isValidPassword(password))
      return 'Password must be at least 6 characters.';
    if (password != confirmPassword) return 'Passwords do not match.';
    if (_personalIdBytes == null) return 'Please upload a personal ID photo.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Driver Sign Up', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppModal.error<void>(
              context: context,
              title: 'Error',
              contentText: state.message,
            );
          } else if (state is AuthApprovalPending) {
            AppModal.success<void>(
              context: context,
              title: 'Application Submitted',
              contentText: state.message,
              primaryAction: AppModalAction(
                label: 'Back to Login',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.goNamed(AppRoutes.login.name);
                },
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kVerticalGap24,
                  _buildLogoHeader(),
                  kVerticalGap32,
                  AppTextField.outlined(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    prefixIcon: Icons.person,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    prefixIcon: Icons.person_outline,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'driver@email.com',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '0987733... or +251 944...',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _telegramController,
                    label: 'Telegram Username',
                    hint: '@username',
                    prefixIcon: Icons.send_rounded,
                  ),
                  kVerticalGap16,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField.outlined(
                          controller: _plateController,
                          label: 'Plate Number',
                          hint: 'AA 12345',
                          prefixIcon: Icons.pin_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _buildVehicleDropdown()),
                    ],
                  ),
                  kVerticalGap16,
                  _buildPersonalIdPicker(),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onSuffixPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onSuffixPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  kVerticalGap24,
                  AppButton.primary(
                    label: 'Submit Application',
                    onPressed: isLoading ? null : _handleSignUp,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                  kVerticalGap16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppText(
                        'Already have an account? ',
                        variant: AppTextVariant.bodyMedium,
                      ),
                      AppButton.ghost(
                        label: 'Login',
                        onPressed: () {
                          context.pop();
                        },
                        size: AppButtonSize.small,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(ImageConstants.appLogo, fit: BoxFit.cover),
        ),
        kVerticalGap16,
        const AppText(
          'Create Driver Account',
          variant: AppTextVariant.heading2,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.bold,
        ),
        kVerticalGap8,
        AppText(
          'Submit your fleet application for admin approval',
          variant: AppTextVariant.bodyMedium,
          color: context.appTextSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVehicleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('Vehicle Type', variant: AppTextVariant.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedVehicleType,
          dropdownColor: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Bike', child: Text('Bike')),
            DropdownMenuItem(value: 'Motor', child: Text('Motor')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedVehicleType = value);
          },
        ),
      ],
    );
  }

  Widget _buildPersonalIdPicker() {
    final hasImage = _personalIdBytes != null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: _isPickingId ? null : _pickPersonalIdImage,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasImage ? AppColors.success : context.appBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.memory(_personalIdBytes!, fit: BoxFit.cover)
                  : Icon(Icons.badge_rounded, color: context.appTextSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    hasImage ? 'Personal ID selected' : 'Personal ID Photo',
                    variant: AppTextVariant.bodyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    hasImage
                        ? (_personalIdFileName ?? 'Ready to upload')
                        : 'Upload a clear image under 5MB',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _isPickingId
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    hasImage
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: hasImage ? AppColors.success : AppColors.primary,
                  ),
          ],
        ),
      ),
    );
  }
}
