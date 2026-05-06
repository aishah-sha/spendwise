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
    // Configure Google Sign-In to request ID token
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      // For Android, you need to add your web client ID
      // Get this from Google Cloud Console > Credentials > Web Client ID
      serverClientId:
          '265157656052-8qn65l77ps423er6srsgqrpsm2j7ku4c.apps.googleusercontent.com',
    );
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

  // SIGN IN with Google - FIXED FOR ANDROID
  Future<void> signInWithGoogle() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      // First, sign out from any previous Google account
      await _googleSignIn.signOut();

      // Trigger Google Sign-In with requested scopes
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (!isClosed) {
          emit(Unauthenticated());
        }
        return;
      }

      // Get authentication details - this should now include idToken
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print(
        'Access Token: ${googleAuth.accessToken != null ? "Got token" : "No token"}',
      );
      print(
        'ID Token: ${googleAuth.idToken != null ? "Got ID token" : "No ID token"}',
      );

      // If no ID token, try using Firebase approach
      if (googleAuth.idToken == null) {
        print('No ID token received. Trying alternative method...');

        // Alternative: Use access token to get user info
        if (googleAuth.accessToken != null) {
          // You can still proceed with access token only
          print('Proceeding with access token only');
        } else {
          if (!isClosed) {
            emit(
              AuthFailure(
                error:
                    'Failed to get Google credentials. Please check your Google Sign-In configuration.',
              ),
            );
          }
          return;
        }
      }

      // Exchange for Supabase session
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken ?? '', // Empty string if null
        accessToken: googleAuth.accessToken,
      );

      print('Supabase sign in successful: ${response.user?.email}');

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

  // SIGN OUT - Also sign out from Google and clear local data
  Future<void> signOut() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      // Clear local SharedPreferences data for this user
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_budget_$currentUserId');
        await prefs.remove('user_data'); // Clear profile cache
        print('Cleared user data for: $currentUserId');
      }

      // Sign out from Google as well
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

  @override
  Future<void> close() {
    return super.close();
  }
}
