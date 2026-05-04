import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Import OAuth provider
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

// ============ STATES ============
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User? user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});
}

// ============ CUBIT ============
class AuthCubit extends Cubit<AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  AuthCubit() : super(AuthInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      if (!isClosed) {
        final session = data.session;
        if (session != null) {
          emit(Authenticated(session.user));
        } else {
          emit(Unauthenticated());
        }
      }
    });
    checkAuthStatus();
  }

  void checkAuthStatus() {
    if (isClosed) return;
    final user = _supabase.auth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  // SIGN IN with Email
  Future<void> signInWithEmail(String email, String password) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (!isClosed) {
        emit(Authenticated(response.user));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getErrorMessage(e)));
      }
    }
  }

  // SIGN UP with Email
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        // Profile will be auto-created by database trigger
        await _supabase.auth.signOut();
        if (!isClosed) {
          emit(AuthSuccess(message: 'Account created! Please login.'));
        }
      } else {
        if (!isClosed) {
          emit(AuthFailure(error: 'Sign up failed. Please try again.'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getErrorMessage(e)));
      }
    }
  }

  // SIGN IN with Google
  Future<void> signInWithGoogle() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://callback-callback/',
      );
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: 'Google Sign-In failed: ${e.toString()}'));
      }
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _supabase.auth.signOut();
      if (!isClosed) {
        emit(Unauthenticated());
      }
    } catch (e) {
      if (!isClosed) {
        emit(Unauthenticated());
      }
    }
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      if (!isClosed) {
        emit(
          AuthSuccess(message: 'Password reset email sent. Check your inbox.'),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getErrorMessage(e)));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('email') && errorStr.contains('already')) {
      return 'This email is already registered. Please sign in instead.';
    } else if (errorStr.contains('invalid') && errorStr.contains('email')) {
      return 'Please enter a valid email address.';
    } else if (errorStr.contains('password')) {
      return 'Password should be at least 6 characters.';
    } else if (errorStr.contains('user') && errorStr.contains('found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
