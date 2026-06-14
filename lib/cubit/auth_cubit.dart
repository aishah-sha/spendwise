import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/supabase_service.dart';

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
  static AuthCubit? _instance;
  static AuthCubit? get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  late final GoogleSignIn _googleSignIn;

  AuthCubit() : super(AuthInitial()) {
    _instance = this;
    _initialize();
    _setupGoogleSignIn();
  }

  void _setupGoogleSignIn() {
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  Future<void> _initialize() async {
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (!isClosed) {
        final session = data.session;
        final currentState = state;

        // Skip state changes during signup flow
        if (currentState is AuthSuccess || currentState is AuthLoading) {
          print('⏸️ Skipping auth state change during signup flow');
          return;
        }

        if (session != null) {
          if (currentState is! Authenticated) {
            emit(Authenticated(session.user));
            await syncDeviceNotificationToken();
          }
        } else {
          if (currentState is! Unauthenticated) {
            emit(Unauthenticated());
          }
        }
      }
    });
    checkAuthStatus();
  }

  void checkAuthStatus() async {
    if (isClosed) return;

    final currentState = state;
    if (currentState is AuthSuccess || currentState is AuthLoading) {
      print('⏸️ Skipping auth status check during signup flow');
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user != null) {
      if (currentState is! Authenticated) {
        emit(Authenticated(user));
        await syncDeviceNotificationToken();
      }
    } else {
      if (currentState is! Unauthenticated) {
        emit(Unauthenticated());
      }
    }
  }

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

      await FirebaseMessaging.instance.requestPermission();
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
        await syncDeviceNotificationToken();
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getErrorMessage(e)));
      }
    }
  }

  // SIGN UP with Email - FIXED
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
        // Try to create profile, but don't fail if it already exists
        try {
          await _supabaseService.createUserProfile(
            userId: response.user!.id,
            email: email.trim(),
            name: name,
          );
        } catch (profileError) {
          // Profile might already exist from Supabase trigger
          print('Profile creation note: $profileError');
          // Continue with signup success - this isn't critical
        }

        print('✅ User signed up: ${response.user!.id}');

        if (!isClosed) {
          final requiresConfirmation = response.user?.confirmedAt == null;

          if (requiresConfirmation) {
            emit(
              AuthSuccess(
                message:
                    'Account created! Please check your email to confirm your account before logging in.',
              ),
            );
          } else {
            emit(
              AuthSuccess(
                message: 'Account created successfully! You can now log in.',
              ),
            );
          }
        }
      } else {
        if (!isClosed) {
          emit(AuthFailure(error: 'Sign up failed. Please try again.'));
        }
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      if (!isClosed) {
        // Check if it's just a profile duplicate error
        if (e.toString().contains('duplicate key')) {
          // This means auth succeeded but profile creation failed due to duplicate
          // The user might still be created, so show success message
          emit(
            AuthSuccess(
              message:
                  'Account created! Please check your email to confirm your account.',
            ),
          );
        } else {
          emit(AuthFailure(error: _getErrorMessage(e)));
        }
      }
    }
  }

  // SIGN IN with Google
  Future<void> signInWithGoogle() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _googleSignIn.signOut();

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

  Future<void> resendConfirmationEmail(String email) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
      if (!isClosed) {
        emit(
          AuthSuccess(
            message: 'Confirmation email resent! Please check your inbox.',
          ),
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
    } else if (errorStr.contains('email not confirmed')) {
      return 'Please confirm your email address before logging in. Check your inbox.';
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
