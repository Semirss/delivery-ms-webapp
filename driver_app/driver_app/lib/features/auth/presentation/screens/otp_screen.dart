import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_ui/app_ui.dart';
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
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
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
      appBar: const AppAppBar(titleText: 'OTP Verification', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppModal.error<void>(
              context: context,
              title: 'Error',
              contentText: state.message,
            );
          } else if (state is AuthAuthenticated) {
            // Navigation handled by router
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AppContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kVerticalGap32,
                  const AppText(
                    'Verify OTP',
                    variant: AppTextVariant.heading2,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap8,
                  const AppText(
                    'Enter the 6-digit code sent to your email',
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap48,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fieldWidth =
                          ((constraints.maxWidth - AppSpacing.xs * 5) / 6)
                              .clamp(36.0, 50.0);
                      final rowWidth = fieldWidth * 6 + AppSpacing.xs * 5;

                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: rowWidth,
                          child: Row(
                            children: List.generate(11, (position) {
                              if (position.isOdd) {
                                return const SizedBox(width: AppSpacing.xs);
                              }

                              final index = position ~/ 2;
                              return SizedBox(
                                width: fieldWidth,
                                child: AppTextField.outlined(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) =>
                                      _handleOtpChanged(index, value),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                  kVerticalGap32,
                  AppButton.primary(
                    label: 'Verify',
                    onPressed: isLoading ? null : _submitOtp,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                  kVerticalGap16,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const AppText("Didn't receive the code? "),
                      AppButton.ghost(
                        label: 'Resend',
                        onPressed: isLoading ? null : _resendOtp,
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
