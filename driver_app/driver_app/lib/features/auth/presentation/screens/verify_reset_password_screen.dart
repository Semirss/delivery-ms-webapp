import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_app/config/router/app_routes.dart';
import 'package:driver_app/core/utils/constants/ui_constants.dart';
import 'package:driver_app/core/widgets/index.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_ui/app_ui.dart';

class VerifyResetPasswordScreen extends StatefulWidget {
  final String? userId;
  final bool? isPhone;

  const VerifyResetPasswordScreen({super.key, this.userId, this.isPhone});

  @override
  State<VerifyResetPasswordScreen> createState() =>
      _VerifyResetPasswordScreenState();
}

class _VerifyResetPasswordScreenState extends State<VerifyResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleVerifyResetPassword() {
    if (_formKey.currentState!.validate() && widget.userId != null) {
      context.read<AuthBloc>().add(
        VerifyResetPasswordEvent(
          userId: widget.userId!,
          otp: _otpController.text,
          newPassword: _newPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(titleText: 'Reset Password', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppToast.error(
              context: context,
              title: 'Error',
              message: state.message,
            );
          } else if (state is ResetPasswordVerified) {
            AppToast.success(
              context: context,
              title: 'Success',
              message: 'Password reset successfully',
            );
            context.goNamed(AppRoutes.login.name);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AppContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kVerticalGap32,
                  AppText(
                    'Set New Password',
                    variant: AppTextVariant.heading2,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap8,
                  AppText(
                    widget.isPhone == true
                        ? 'Enter the OTP sent to your phone'
                        : 'Enter the OTP sent to your email',
                    variant: AppTextVariant.bodyLarge,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppTextField.outlined(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    label: 'OTP Code',
                    hint: 'Enter OTP',
                    prefixIcon: Icons.lock_clock,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (value.length < 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.outlined(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    label: 'New Password',
                    hint: 'Enter new password',
                    prefixIcon: Icons.lock,
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
                        return 'Please enter new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField.outlined(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    label: 'Confirm Password',
                    hint: 'Confirm new password',
                    prefixIcon: Icons.lock_outline,
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
                        return 'Please confirm password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    label: 'Reset Password',
                    onPressed: isLoading ? null : _handleVerifyResetPassword,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
