import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:driver_ui/app_ui.dart';
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
  static const _supportPhone = '+251 931 323 328';

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_phoneController.text.trim().isEmpty) {
      AppModal.error<void>(
        context: context,
        title: 'Error',
        contentText: 'Please enter your phone number',
      );
      return;
    }

    context.read<AuthBloc>().add(
      ResetPasswordEvent(phone: _phoneController.text.trim()),
    );
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
            AppToast.success(
              context: context,
              title: 'Success',
              message: 'If the phone number matches, your password was sent by SMS.',
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
                    'Enter your phone number. If it matches your driver account, your password will be sent by SMS.',
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap48,
                  AppTextField.outlined(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    label: 'Phone number',
                    hint: 'Enter your phone number',
                    prefixIcon: Icons.phone_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  kVerticalGap16,
                  AppText(
                    'Need help? Contact us: $_supportPhone',
                    variant: AppTextVariant.bodyMedium,
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap24,
                  AppButton.primary(
                    label: 'Send Password',
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
