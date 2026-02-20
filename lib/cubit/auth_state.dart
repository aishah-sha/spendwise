part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String email;
  AuthSuccess(this.email);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
