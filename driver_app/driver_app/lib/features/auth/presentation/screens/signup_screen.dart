import 'dart:typed_data';

import 'package:driver_app/config/router/app_routes.dart';
import 'package:driver_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:driver_app/core/utils/constants/ui_constants.dart';
import 'package:driver_app/core/utils/functions/base_functions/ethiopian_phone.dart';
import 'package:driver_app/core/utils/functions/base_functions/validators.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/auth/presentation/widgets/auth_form_notice.dart';
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
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _telegramFocusNode = FocusNode();
  final _plateFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _imagePicker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPickingId = false;
  bool _hasSubmitted = false;
  String _selectedVehicleType = 'Bike';
  Uint8List? _personalIdBytes;
  String? _personalIdFileName;
  String? _personalIdMimeType;
  String? _formError;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _telegramError;
  String? _plateError;
  String? _personalIdError;
  String? _passwordError;
  String? _confirmPasswordError;

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
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _telegramFocusNode.dispose();
    _plateFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
        _applySignUpError('Personal ID photo must be under 5MB.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _personalIdBytes = bytes;
        _personalIdFileName = image.name;
        _personalIdMimeType = image.mimeType;
        _formError = null;
        _personalIdError = null;
      });
    } catch (e) {
      if (!mounted) return;
      _applySignUpError('Could not read the selected ID photo.');
    } finally {
      if (mounted) setState(() => _isPickingId = false);
    }
  }

  void _handleSignUp() {
    setState(() {
      _hasSubmitted = true;
      _clearAuthErrorsWithoutSetState();
    });

    final validationError = _validationError;
    if (validationError != null) {
      _applySignUpError(validationError);
      return;
    }

    final phone = _phoneController.text.trim();
    context.read<AuthBloc>().add(
      SignUpEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: phone.isEmpty ? null : normalizeEthiopianPhone(phone),
        telegramUsername: _telegramController.text.trim(),
        plateNumber: _plateController.text.trim(),
        vehicleType: _selectedVehicleType,
        personalIdBytes: _personalIdBytes,
        personalIdFileName: _personalIdFileName,
        personalIdMimeType: _personalIdMimeType,
      ),
    );
  }

  void _applySignUpError(String rawMessage) {
    final message = _cleanAuthMessage(rawMessage);
    final lower = message.toLowerCase();
    String? formError = message;
    String? firstNameError;
    String? lastNameError;
    String? emailError;
    String? phoneError;
    String? telegramError;
    String? plateError;
    String? personalIdError;
    String? passwordError;
    String? confirmPasswordError;
    FocusNode? focusNode;

    if (lower.contains('first name')) {
      formError = 'Check the highlighted first name.';
      firstNameError = message;
      focusNode = _firstNameFocusNode;
    } else if (lower.contains('last name')) {
      formError = 'Check the highlighted last name.';
      lastNameError = message;
      focusNode = _lastNameFocusNode;
    } else if (lower.contains('email') &&
        (lower.contains('already') ||
            lower.contains('exists') ||
            lower.contains('duplicate'))) {
      formError = 'This email is already registered.';
      emailError = 'Use a different email or log in with this one.';
      focusNode = _emailFocusNode;
    } else if (lower.contains('email')) {
      formError = 'Check the highlighted email.';
      emailError = message;
      focusNode = _emailFocusNode;
    } else if (lower.contains('phone') &&
        (lower.contains('already') ||
            lower.contains('exists') ||
            lower.contains('duplicate'))) {
      formError = 'This phone number is already registered.';
      phoneError = 'Use a different phone number or log in with this one.';
      focusNode = _phoneFocusNode;
    } else if (lower.contains('phone') ||
        lower.contains('09') ||
        lower.contains('ethiopian')) {
      formError = 'Check the highlighted phone number.';
      phoneError = message;
      focusNode = _phoneFocusNode;
    } else if (lower.contains('telegram')) {
      formError = 'Check the highlighted Telegram username.';
      telegramError = message;
      focusNode = _telegramFocusNode;
    } else if (lower.contains('plate')) {
      formError = 'Check the highlighted plate number.';
      plateError = message;
      focusNode = _plateFocusNode;
    } else if (lower.contains('match') || lower.contains('confirm')) {
      formError = 'Check the highlighted password confirmation.';
      confirmPasswordError = message;
      focusNode = _confirmPasswordFocusNode;
    } else if (lower.contains('password')) {
      formError = 'Check the highlighted password.';
      passwordError = message;
      focusNode = _passwordFocusNode;
    } else if (lower.contains('id') ||
        lower.contains('photo') ||
        lower.contains('image')) {
      formError = 'Check the highlighted ID photo.';
      personalIdError = message;
    }

    setState(() {
      _formError = formError;
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _emailError = emailError;
      _phoneError = phoneError;
      _telegramError = telegramError;
      _plateError = plateError;
      _personalIdError = personalIdError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    _focusAfterFrame(focusNode);
  }

  void _clearAuthErrors({
    bool firstName = false,
    bool lastName = false,
    bool email = false,
    bool phone = false,
    bool telegram = false,
    bool plate = false,
    bool personalId = false,
    bool password = false,
    bool confirmPassword = false,
    bool all = false,
  }) {
    if (_formError == null &&
        _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _telegramError == null &&
        _plateError == null &&
        _personalIdError == null &&
        _passwordError == null &&
        _confirmPasswordError == null) {
      return;
    }

    setState(() {
      _formError = null;
      if (firstName || all) _firstNameError = null;
      if (lastName || all) _lastNameError = null;
      if (email || all) _emailError = null;
      if (phone || all) _phoneError = null;
      if (telegram || all) _telegramError = null;
      if (plate || all) _plateError = null;
      if (personalId || all) _personalIdError = null;
      if (password || all) _passwordError = null;
      if (confirmPassword || all) _confirmPasswordError = null;
    });
  }

  void _clearAuthErrorsWithoutSetState() {
    _formError = null;
    _firstNameError = null;
    _lastNameError = null;
    _emailError = null;
    _phoneError = null;
    _telegramError = null;
    _plateError = null;
    _personalIdError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  String _cleanAuthMessage(String rawMessage) {
    return rawMessage.replaceFirst('Exception: ', '').trim();
  }

  void _focusAfterFrame(FocusNode? focusNode) {
    if (focusNode == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  void _submitSignUpFromKeyboard(String _) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    _handleSignUp();
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
    if (phone.isNotEmpty) {
      final phoneError = validateEthiopianPhone(phone);
      if (phoneError != null) return phoneError;
    }
    if (telegram.isEmpty) return 'Please enter your Telegram username.';
    if (plate.isEmpty) return 'Please enter your plate number.';
    if (!isValidPassword(password))
      return 'Password must be at least 6 characters.';
    if (password != confirmPassword) return 'Passwords do not match.';
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
            _applySignUpError(state.message);
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _hasSubmitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kVerticalGap24,
                  _buildLogoHeader(),
                  if (_formError != null) ...[
                    kVerticalGap24,
                    AuthFormNotice(message: _formError!),
                  ],
                  kVerticalGap32,
                  AppTextField.outlined(
                    controller: _firstNameController,
                    focusNode: _firstNameFocusNode,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    errorText: _firstNameError,
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(firstName: true),
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _lastNameController,
                    focusNode: _lastNameFocusNode,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    errorText: _lastNameError,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(lastName: true),
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: 'Email',
                    hint: 'driver@email.com',
                    errorText: _emailError,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(email: true),
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    label: 'Phone Number (optional)',
                    hint: '0912345678',
                    errorText: _phoneError,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(phone: true),
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    'Optional. If provided, start with 09. Do not use +251.',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _telegramController,
                    focusNode: _telegramFocusNode,
                    label: 'Telegram Username',
                    hint: '@username',
                    errorText: _telegramError,
                    prefixIcon: Icons.send_rounded,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(telegram: true),
                  ),
                  kVerticalGap16,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField.outlined(
                          controller: _plateController,
                          focusNode: _plateFocusNode,
                          label: 'Plate Number',
                          hint: 'AA 12345',
                          errorText: _plateError,
                          prefixIcon: Icons.pin_rounded,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _clearAuthErrors(plate: true),
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
                    focusNode: _passwordFocusNode,
                    label: 'Password',
                    hint: 'Enter your password',
                    errorText: _passwordError,
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(password: true),
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
                    focusNode: _confirmPasswordFocusNode,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    errorText: _confirmPasswordError,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _clearAuthErrors(confirmPassword: true),
                    onSubmitted: _submitSignUpFromKeyboard,
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
    final hasError = _personalIdError != null;
    final errorColor = Theme.of(context).colorScheme.error;
    final Color borderColor;
    final Color actionIconColor;
    if (hasError) {
      borderColor = errorColor;
      actionIconColor = errorColor;
    } else if (hasImage) {
      borderColor = AppColors.success;
      actionIconColor = AppColors.success;
    } else {
      borderColor = context.appBorder;
      actionIconColor = AppColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: _isPickingId ? null : _pickPersonalIdImage,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.appSurfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor),
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
                      : Icon(
                          Icons.badge_rounded,
                          color: hasError
                              ? errorColor
                              : context.appTextSecondary,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        hasImage
                            ? 'Personal ID selected'
                            : 'Personal ID Photo (optional)',
                        variant: AppTextVariant.bodyMedium,
                        fontWeight: FontWeight.bold,
                        color: hasError ? errorColor : null,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        hasImage
                            ? (_personalIdFileName ?? 'Ready to upload')
                            : 'Optional. Upload a clear image under 5MB',
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
                        color: actionIconColor,
                      ),
              ],
            ),
          ),
        ),
        if (_personalIdError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          AppText(
            _personalIdError!,
            variant: AppTextVariant.bodySmall,
            color: errorColor,
          ),
        ],
      ],
    );
  }
}
