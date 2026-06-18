import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_ui/app_ui.dart';
import '../../../../core/utils/constants/ui_constants.dart';
import '../../../../core/widgets/index.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String? verificationKey;

  const OtpScreen({super.key, this.verificationKey});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _verificationKey;

  @override
  void initState() {
    super.initState();
    _verificationKey = widget.verificationKey;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submitOtp() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && _verificationKey != null) {
      context.read<AuthBloc>().add(
        VerifyOtpEvent(verificationKey: _verificationKey!, otp: otp),
      );
    }
  }

  void _resendOtp() {
    if (_verificationKey != null) {
      context.read<AuthBloc>().add(
        ResendOtpEvent(verificationKey: _verificationKey!),
      );
      AppToast.success(
        context: context,
        title: 'Success',
        message: 'OTP resent successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(titleText: 'OTP Verification', centerTitle: true),
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
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AppContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                kVerticalGap32,
                AppText(
                  'Verify OTP',
                  variant: AppTextVariant.heading2,
                  textAlign: TextAlign.center,
                ),
                kVerticalGap8,
                AppText(
                  'Enter the 6-digit code sent to your email',
                  variant: AppTextVariant.bodyMedium,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                kVerticalGap48,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      child: AppTextField.outlined(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _handleOtpChanged(index, value),
                      ),
                    ),
                  ),
                ),
                kVerticalGap32,
                AppButton.primary(
                  label: 'Verify',
                  onPressed: isLoading ? null : _submitOtp,
                  isLoading: isLoading,
                  fullWidth: true,
                ),
                kVerticalGap16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      "Didn't receive the code? ",
                      variant: AppTextVariant.bodyMedium,
                    ),
                    AppButton.ghost(
                      label: 'Resend',
                      onPressed: isLoading ? null : _resendOtp,
                      size: AppButtonSize.small,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
