import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:app_starter/config/router/app_routes.dart';
import 'package:app_starter/core/utils/functions/base_functions/validators.dart';
import 'package:app_starter/core/utils/constants/ui_constants.dart';
import 'package:app_starter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_starter/features/auth/presentation/bloc/auth_event.dart';
import 'package:app_starter/features/auth/presentation/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(titleText: 'Login', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppToast.error(
              context: context,
              title: 'Error',
              message: state.message,
            );
          } else if (state is AuthAuthenticated) {
            // Navigation handled by router
          } else if (state is AuthVerificationRequired) {
            // Navigate to OTP screen
            // Navigation handled by router
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
                  kVerticalGap32,
                  AppText(
                    'Welcome Back',
                    variant: AppTextVariant.heading2,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap8,
                  AppText(
                    'Sign in to continue',
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap48,
                  AppTextField.outlined(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  kVerticalGap8,
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton.ghost(
                      label: 'Forgot Password?',
                      onPressed: () {
                        context.pushNamed(AppRoutes.resetPassword.name);
                      },
                      size: AppButtonSize.small,
                    ),
                  ),
                  kVerticalGap24,
                  AppButton.primary(
                    label: 'Login',
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                  kVerticalGap16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        "Don't have an account? ",
                        variant: AppTextVariant.bodyMedium,
                      ),
                      AppButton.ghost(
                        label: 'Sign Up',
                        onPressed: () {
                          context.pushNamed(AppRoutes.signUp.name);
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
}
