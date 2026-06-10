import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging Package
import '../services/supabase_service.dart';

// Import OAuth provider

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
  // ─── CRITICAL BLOC FIX: Static instance setup for main.dart to reference ───
  static AuthCubit? _instance;
  static AuthCubit? get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  late final GoogleSignIn _googleSignIn;

  AuthCubit() : super(AuthInitial()) {
    _instance =
        this; // Capture running provider context instance upon initialization
    _initialize();
    _setupGoogleSignIn();
  }

  void _setupGoogleSignIn() {
    // FIX: Double check package matching constructor syntax initialization explicitly
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  Future<void> _initialize() async {
    // Listen to auth state changes dynamically
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (!isClosed) {
        final session = data.session;

        // ─── CRITICAL FIX: If a valid session exists, immediately authenticate! ───
        // Removing onboarding check locks here avoids loops where user stays stuck on Welcome Screen
        if (session != null) {
          emit(Authenticated(session.user));
          // Sync token immediately on positive session hook detection
          await syncDeviceNotificationToken();
        } else {
          emit(Unauthenticated());
        }
      }
    });
    checkAuthStatus();
  }

  void checkAuthStatus() async {
    if (isClosed) return;

    // ─── CRITICAL FIX: Check authentication state natively on launch ───
    final user = _supabase.auth.currentUser;

    if (user != null) {
      emit(Authenticated(user));
      // Sync token if user is already logged in on application launch
      await syncDeviceNotificationToken();
    } else {
      emit(Unauthenticated());
    }
  }

  // ─── STREAM HOOK METHODS REQUIRED BY MAIN.DART ───
  void emitAuthenticated(User user) {
    if (!isClosed) emit(Authenticated(user));
  }

  void emitUnauthenticated() {
    if (!isClosed) emit(Unauthenticated());
  }

  Future<void> syncDeviceNotificationToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // FIX: Initialize Firebase Messaging first
      await FirebaseMessaging.instance.requestPermission();

      // Extract raw Firebase Push routing address key from mobile OS hardware stack
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await _supabase.from('user_tokens').upsert({
          'user_id': userId,
          'fcm_token': fcmToken,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ FCM Token successfully synced with Supabase Infrastructure.');
      }
    } catch (e) {
      print('❌ Failed to bind notification token sync parameters: $e');
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
        // Sync token right after successful manual email login
        await syncDeviceNotificationToken();
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

        print('fake account profile synced: ${response.user!.id}');
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
      // Force sign out to ensure fresh login
      await _googleSignIn.signOut();

      // Add timeout
      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign-in timeout');
        },
      );

      if (googleUser == null) {
        if (!isClosed) {
          emit(Unauthenticated());
        }
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        if (!isClosed) {
          emit(AuthFailure(error: 'Failed to get Google authentication token'));
        }
        return;
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
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

        if (!isClosed) {
          emit(Authenticated(response.user));
          await syncDeviceNotificationToken();
        }
      } else {
        if (!isClosed) {
          emit(AuthFailure(error: 'Google Sign-In failed: No user returned'));
        }
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      if (!isClosed) {
        String errorMessage = 'Google Sign-In failed: ';
        if (e.toString().contains('network')) {
          errorMessage += 'Check your internet connection';
        } else if (e.toString().contains('canceled')) {
          errorMessage += 'Sign-in was cancelled';
        } else {
          errorMessage += e.toString();
        }
        emit(AuthFailure(error: errorMessage));
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

        // Safety design: Remove token entry from Supabase on sign out
        try {
          await _supabase
              .from('user_tokens')
              .delete()
              .eq('user_id', currentUserId);
        } catch (_) {}
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

  @override
  Future<void> close() {
    if (_instance == this) {
      _instance = null;
    }
    return super.close();
  }
}
