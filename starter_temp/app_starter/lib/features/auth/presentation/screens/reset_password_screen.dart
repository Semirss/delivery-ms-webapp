import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_ui/app_ui.dart';
import '../../../../core/utils/constants/ui_constants.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        ResetPasswordEvent(email: _emailController.text.trim()),
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
          } else if (state is ResetPasswordSuccess) {
            AppToast.success(
              context: context,
              title: 'Success',
              message: 'Password reset email sent',
            );
            context.pop();
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
                    'Reset Password',
                    variant: AppTextVariant.heading2,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap8,
                  AppText(
                    'Enter your email to receive a password reset code',
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap48,
                  AppTextField.outlined(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  kVerticalGap24,
                  AppButton.primary(
                    label: 'Send Reset Code',
                    onPressed: isLoading ? null : _handleResetPassword,
                    isLoading: isLoading,
                    fullWidth: true,
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
