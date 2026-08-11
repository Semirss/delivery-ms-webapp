import 'dart:async';

import 'package:client_app/config/router/app_routes.dart';
import 'package:client_app/core/di/injection.dart';
import 'package:client_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:client_app/core/utils/functions/base_functions/validators.dart';
import 'package:client_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  StreamSubscription<dynamic>? _supabaseAuthSubscription;
  bool _obscurePassword = true;
  bool _handledPendingGoogleSession = false;
  String? _suggestedEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSuggestedEmail();
    _supabaseAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => _scheduleGoogleSessionCompletion());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _completePendingGoogleSession(context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_supabaseAuthSubscription?.cancel());
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleGoogleSessionCompletion();
    }
  }

  Future<void> _loadSuggestedEmail() async {
    try {
      final email = await getIt<AuthLocalDataSource>()
          .getCachedLastLoginEmail();
      if (!mounted || email == null) return;
      setState(() => _suggestedEmail = email);
    } catch (_) {
      // A missing cache should not block the login screen.
    }
  }

  bool get _shouldShowSuggestedEmail {
    final email = _suggestedEmail?.trim() ?? '';
    return email.isNotEmpty && _emailController.text.trim().isEmpty;
  }

  void _useSuggestedEmail() {
    final email = _suggestedEmail;
    if (email == null) return;

    setState(() {
      _emailController.text = email;
      _emailController.selection = TextSelection.collapsed(
        offset: email.length,
      );
    });
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

  void _goHomeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.goNamed(AppRoutes.home.name);
    });
  }

  void _scheduleGoogleSessionCompletion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _completePendingGoogleSession(context.read<AuthBloc>().state);
    });
  }

  void _completePendingGoogleSession(AuthState state) {
    if (_handledPendingGoogleSession ||
        state is AuthAuthenticated ||
        state is AuthLoading) {
      return;
    }

    final hasSupabaseSession =
        Supabase.instance.client.auth.currentUser != null ||
        Supabase.instance.client.auth.currentSession?.user != null;
    if (!hasSupabaseSession) return;

    _handledPendingGoogleSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(const LoginWithGoogleEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _handledPendingGoogleSession = false;
            AppModal.error<void>(
              context: context,
              title: 'Login Failed',
              contentText: state.message,
            );
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            _goHomeAfterFrame();
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          _completePendingGoogleSession(state);
          final isLoading = state is AuthLoading;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Header
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              ImageConstants.appLogo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'MotoBike',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fast delivery, live tracking',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const AppText(
                          'Welcome back!',
                          variant: AppTextVariant.heading2,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          'Sign in to manage deliveries',
                          variant: AppTextVariant.bodyMedium,
                          color: context.appTextSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        AppTextField.outlined(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'your@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Email is required';
                            if (!isValidEmail(v)) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        if (_shouldShowSuggestedEmail) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _PreviousEmailSuggestion(
                            email: _suggestedEmail!.trim(),
                            onTap: _useSuggestedEmail,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppTextField.outlined(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '********',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          onSuffixPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password is required';
                            if (v.length < 6) return 'Min. 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.pushNamed(AppRoutes.resetPassword.name),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton.primary(
                          label: isLoading ? 'Signing in...' : 'SIGN IN',
                          onPressed: isLoading ? null : _handleLogin,
                          isLoading: isLoading,
                          fullWidth: true,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const AppText(
                              "Don't have an account? ",
                              variant: AppTextVariant.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.pushNamed(AppRoutes.signUp.name),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreviousEmailSuggestion extends StatelessWidget {
  const _PreviousEmailSuggestion({required this.email, required this.onTap});

  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.alphaBlend(
        AppColors.primary.withValues(alpha: context.isAppDark ? 0.18 : 0.08),
        context.appSurface,
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Use previous email',
                        variant: AppTextVariant.labelSmall,
                        fontWeight: FontWeight.w800,
                        color: context.appTextSecondary,
                      ),
                      AppText(
                        email,
                        variant: AppTextVariant.bodySmall,
                        fontWeight: FontWeight.w900,
                        color: context.appTextPrimary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
