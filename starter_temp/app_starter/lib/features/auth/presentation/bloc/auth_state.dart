import '../../../../../core/base/base_bloc.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends BaseState {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthVerificationRequired extends AuthState {
  final String verificationKey;

  const AuthVerificationRequired({required this.verificationKey});

  @override
  List<Object> get props => [verificationKey];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class ResetPasswordSuccess extends AuthState {
  const ResetPasswordSuccess();
}

class ResetPasswordVerified extends AuthState {
  const ResetPasswordVerified();
}

