import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client_ui/app_ui.dart';

import '../../../../core/utils/constants/ui_constants.dart';
import '../../../../core/utils/functions/base_functions/ethiopian_phone.dart';
import '../../../../core/widgets/index.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _supportPhone = '+251 931 323 328';

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _phoneVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    final validationError = _validationError();
    if (validationError != null) {
      AppModal.error<void>(
        context: context,
        title: 'Error',
        contentText: validationError,
      );
      return;
    }

    context.read<AuthBloc>().add(
      ResetPasswordEvent(
        phone: normalizeEthiopianPhone(_phoneController.text),
        newPassword: _phoneVerified ? _passwordController.text : null,
      ),
    );
  }

  String? _validationError() {
    final phoneError = validateEthiopianPhone(_phoneController.text);
    if (phoneError != null) return phoneError;
    if (!_phoneVerified) return null;
    if (_passwordController.text.isEmpty) {
      return 'Please enter your new password';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(titleText: 'Reset Password', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppModal.error<void>(
              context: context,
              title: 'Error',
              contentText: state.message,
            );
          } else if (state is ResetPasswordSuccess) {
            if (!_phoneVerified) {
              setState(() {
                _phoneVerified = true;
              });
              AppToast.success(
                context: context,
                title: 'Phone Confirmed',
                message: 'Enter a new password for this account.',
              );
              return;
            }

            AppToast.success(
              context: context,
              title: 'Success',
              message: 'Password updated. Sign in with your new password.',
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AppContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    kVerticalGap32,
                    AppText(
                      'Reset Password',
                      variant: AppTextVariant.heading2,
                      textAlign: TextAlign.center,
                    ),
                    kVerticalGap8,
                    AppText(
                      _phoneVerified
                          ? 'Phone number confirmed. Enter your new password.'
                          : 'Enter your phone number to find your client account.',
                      variant: AppTextVariant.bodyMedium,
                      color: context.appTextSecondary,
                      textAlign: TextAlign.center,
                    ),
                    kVerticalGap48,
                    AppTextField.outlined(
                      controller: _phoneController,
                      enabled: !isLoading && !_phoneVerified,
                      keyboardType: TextInputType.phone,
                      label: 'Phone number',
                      hint: '912 345 678',
                      prefixIcon: Icons.phone_outlined,
                      prefixText: '$ethiopianDialCode ',
                      validator: validateEthiopianPhone,
                    ),
                    if (_phoneVerified) ...[
                      kVerticalGap16,
                      AppTextField.outlined(
                        controller: _passwordController,
                        label: 'New password',
                        hint: 'Enter your new password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      kVerticalGap16,
                      AppTextField.outlined(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        hint: 'Confirm your new password',
                        prefixIcon: Icons.lock_rounded,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    kVerticalGap16,
                    AppText(
                      'Need help? Contact us: $_supportPhone',
                      variant: AppTextVariant.bodyMedium,
                      color: context.appTextSecondary,
                      textAlign: TextAlign.center,
                    ),
                    kVerticalGap24,
                    AppButton.primary(
                      label: _phoneVerified ? 'Update Password' : 'Continue',
                      onPressed: isLoading ? null : _handleResetPassword,
                      isLoading: isLoading,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
