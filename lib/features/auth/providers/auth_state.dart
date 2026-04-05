import 'package:equatable/equatable.dart';
import '../../../data/models/user.dart';

/// Authentication state for the app
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking authentication status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - performing auth operation
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - no user logged in
class AuthUnauthenticated extends AuthState {
  /// True if user needs to register (first time)
  final bool needsRegistration;

  const AuthUnauthenticated({this.needsRegistration = false});

  @override
  List<Object?> get props => [needsRegistration];
}

/// Error state - auth operation failed
class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
