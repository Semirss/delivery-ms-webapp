import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client_app/core/utils/constants/ui_constants.dart';
import 'package:client_app/core/utils/functions/base_functions/ethiopian_phone.dart';
import 'package:client_app/core/utils/functions/base_functions/validators.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/auth/presentation/widgets/auth_form_notice.dart';
import 'package:client_ui/app_ui.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasSubmitted = false;
  String? _formError;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
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
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    setState(() {
      _hasSubmitted = true;
      _clearAuthErrorsWithoutSetState();
    });

    if (!_formKey.currentState!.validate()) {
      _focusFirstLocalSignUpError();
      return;
    }

    context.read<AuthBloc>().add(
      SignUpEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: normalizeEthiopianPhone(_phoneController.text),
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
    String? passwordError;
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
    } else if (lower.contains('email') &&
        (lower.contains('valid') || lower.contains('required'))) {
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
    } else if (lower.contains('phone') &&
        (lower.contains('09') ||
            lower.contains('ethiopian') ||
            lower.contains('required'))) {
      formError = 'Check the highlighted phone number.';
      phoneError = message;
      focusNode = _phoneFocusNode;
    } else if (lower.contains('password')) {
      formError = 'Check the highlighted password.';
      passwordError = message;
      focusNode = _passwordFocusNode;
    }

    setState(() {
      _formError = formError;
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _emailError = emailError;
      _phoneError = phoneError;
      _passwordError = passwordError;
      _confirmPasswordError = null;
    });

    _focusAfterFrame(focusNode);
  }

  void _clearAuthErrors({
    bool firstName = false,
    bool lastName = false,
    bool email = false,
    bool phone = false,
    bool password = false,
    bool confirmPassword = false,
    bool all = false,
  }) {
    if (_formError == null &&
        _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
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
    _passwordError = null;
    _confirmPasswordError = null;
  }

  String _cleanAuthMessage(String rawMessage) {
    return rawMessage.replaceFirst('Exception: ', '').trim();
  }

  void _focusFirstLocalSignUpError() {
    if (_validateFirstName(_firstNameController.text) != null) {
      _focusAfterFrame(_firstNameFocusNode);
      return;
    }
    if (_validateLastName(_lastNameController.text) != null) {
      _focusAfterFrame(_lastNameFocusNode);
      return;
    }
    if (_validateEmail(_emailController.text) != null) {
      _focusAfterFrame(_emailFocusNode);
      return;
    }
    if (_validatePhone(_phoneController.text) != null) {
      _focusAfterFrame(_phoneFocusNode);
      return;
    }
    if (_validatePassword(_passwordController.text) != null) {
      _focusAfterFrame(_passwordFocusNode);
      return;
    }
    if (_validateConfirmPassword(_confirmPasswordController.text) != null) {
      _focusAfterFrame(_confirmPasswordFocusNode);
    }
  }

  void _focusAfterFrame(FocusNode? focusNode) {
    if (focusNode == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    return validateEthiopianPhone(value);
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (!isValidPassword(password)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Confirm your password';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _submitSignUpFromKeyboard(String _) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    _handleSignUp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(titleText: 'Sign Up', centerTitle: true),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _applySignUpError(state.message);
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
              autovalidateMode: _hasSubmitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kVerticalGap32,
                  AppText(
                    'Create Account',
                    variant: AppTextVariant.heading2,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalGap8,
                  AppText(
                    'Sign up to get started',
                    variant: AppTextVariant.bodyMedium,
                    color: context.appTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                  if (_formError != null) ...[
                    kVerticalGap24,
                    AuthFormNotice(message: _formError!),
                  ],
                  kVerticalGap48,
                  AppTextField.outlined(
                    controller: _firstNameController,
                    focusNode: _firstNameFocusNode,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    errorText: _firstNameError,
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(firstName: true),
                    validator: _validateFirstName,
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
                    validator: _validateLastName,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: 'Email',
                    hint: 'Enter your email',
                    errorText: _emailError,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(email: true),
                    validator: _validateEmail,
                  ),
                  kVerticalGap16,
                  AppTextField.outlined(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    label: 'Phone',
                    hint: '0912345678',
                    errorText: _phoneError,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearAuthErrors(phone: true),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    'Start with 09. Do not use +251.',
                    variant: AppTextVariant.bodySmall,
                    color: context.appTextSecondary,
                  ),
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
                    suffixIcon: _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onSuffixPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onChanged: (_) => _clearAuthErrors(password: true),
                    validator: _validatePassword,
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
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onSuffixPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    onChanged: (_) => _clearAuthErrors(confirmPassword: true),
                    onSubmitted: _submitSignUpFromKeyboard,
                    validator: _validateConfirmPassword,
                  ),
                  kVerticalGap24,
                  AppButton.primary(
                    label: 'Sign Up',
                    onPressed: isLoading ? null : _handleSignUp,
                    isLoading: isLoading,
                    fullWidth: true,
                  ),
                  kVerticalGap16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        'Already have an account? ',
                        variant: AppTextVariant.bodyMedium,
                      ),
                      AppButton.ghost(
                        label: 'Login',
                        onPressed: () {
                          _clearAuthErrors(all: true);
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
}
