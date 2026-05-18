import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  late final GoogleSignIn _googleSignIn;

  AuthCubit() : super(AuthInitial()) {
    _initialize();
    _setupGoogleSignIn();
  }

  void _setupGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId:
          '265157656052-8qn65l77ps423er6srsgqrpsm2j7ku4c.apps.googleusercontent.com',
    );
  }

  Future<void> _initialize() async {
    // Listen to auth state changes dynamically
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (!isClosed) {
        final session = data.session;

        // Check if onboarding was completed before emitting authentication routes
        final prefs = await SharedPreferences.getInstance();
        final bool hasSeenOnboarding =
            prefs.getBool('has_seen_onboarding') ?? false;

        if (session != null) {
          if (hasSeenOnboarding) {
            emit(Authenticated(session.user));
          } else {
            // Keep state as unauthenticated so main gateway falls back to onboarding route
            emit(Unauthenticated());
          }
        } else {
          emit(Unauthenticated());
        }
      }
    });
    checkAuthStatus();
  }

  void checkAuthStatus() async {
    if (isClosed) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding =
        prefs.getBool('has_seen_onboarding') ?? false;
    final user = _supabase.auth.currentUser;

    if (user != null && hasSeenOnboarding) {
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
        data: {'full_name': name, 'name': name, 'email': email.trim()},
      );

      if (response.user != null) {
        await _supabaseService.createUserProfile(
          userId: response.user!.id,
          email: email.trim(),
          name: name,
        );

        print('✅ Profile created for user: ${response.user!.id}');
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
      print('Sign up error: $e');
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
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (!isClosed) {
          emit(Unauthenticated());
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken ?? '',
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        final existingProfile = await _supabaseService.getUserProfile();

        if (existingProfile == null) {
          await _supabaseService.createUserProfile(
            userId: response.user!.id,
            email: response.user!.email ?? googleUser.email,
            name:
                response.user!.userMetadata?['full_name'] ??
                response.user!.userMetadata?['name'] ??
                googleUser.displayName ??
                googleUser.email.split('@').first,
          );
        }
      }

      if (!isClosed) {
        emit(Authenticated(response.user));
      }
    } catch (e) {
      print('Google Sign-In error: $e');
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
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_budget_$currentUserId');
        await prefs.remove('user_data');
      }

      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      if (!isClosed) {
        emit(Unauthenticated());
      }
    } catch (e) {
      print('Sign out error: $e');
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
}
