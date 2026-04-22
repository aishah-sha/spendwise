import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore_service.dart';

// ============ STATES ============
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Authenticated && other.user.uid == user.uid;
  }

  @override
  int get hashCode => user.uid.hashCode;
}

class Unauthenticated extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSuccess && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthFailure && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;
}

// ============ CUBIT ============
class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  GoogleSignIn? _googleSignIn;

  bool _isListenerSet = false;

  AuthCubit() : super(AuthInitial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize GoogleSignIn - FIXED for all versions
    try {
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      // If the above fails, try with scopes
      try {
        _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      } catch (e) {
        // If all fails, initialize without parameters
        _googleSignIn = GoogleSignIn();
      }
    }

    // Set up auth state listener
    if (!_isListenerSet) {
      _isListenerSet = true;
      _auth.authStateChanges().listen((User? user) {
        if (!isClosed) {
          if (user != null) {
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        }
      });
    }

    checkAuthStatus();
  }

  // ============ AUTH STATUS ============

  void checkAuthStatus() {
    if (isClosed) return;

    final user = _auth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ============ EMAIL & PASSWORD AUTH ============

  Future<void> signInWithEmail(String email, String password) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (!isClosed) {
        emit(Authenticated(result.user!));
        emit(AuthSuccess(message: 'Signed in successfully'));
      }
    } on FirebaseAuthException catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getFirebaseErrorMessage(e)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user?.updateDisplayName(name);
      await result.user?.reload();

      await _firestoreService.createUserProfile(
        userId: result.user!.uid,
        email: email,
        name: name,
      );

      if (!isClosed) {
        emit(Authenticated(result.user!));
        emit(AuthSuccess(message: 'Account created successfully'));
      }
    } on FirebaseAuthException catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getFirebaseErrorMessage(e)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  // ============ GOOGLE SIGN IN - COMPATIBLE VERSION ============

  Future<void> signInWithGoogle() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      if (_googleSignIn == null) {
        if (!isClosed) {
          emit(AuthFailure(error: 'Google Sign-In not initialized'));
        }
        return;
      }

      // Try to sign in - this works with both old and new versions
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        if (!isClosed) {
          emit(AuthFailure(error: 'Google Sign-In cancelled'));
        }
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential - this is the correct way
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if this is a new user
      if (result.additionalUserInfo?.isNewUser == true) {
        await _firestoreService.createUserProfile(
          userId: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'User',
        );
      }

      if (!isClosed) {
        emit(Authenticated(result.user!));
        emit(AuthSuccess(message: 'Signed in with Google successfully'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: 'Google Sign-In failed: ${e.toString()}'));
      }
    }
  }

  // ============ FACEBOOK SIGN IN ============

  Future<void> signInWithFacebook() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      final fb.LoginResult loginResult = await fb.FacebookAuth.instance.login();

      if (loginResult.status == fb.LoginStatus.cancelled) {
        if (!isClosed) {
          emit(AuthFailure(error: 'Facebook Sign-In cancelled'));
        }
        return;
      }

      if (loginResult.status == fb.LoginStatus.failed) {
        if (!isClosed) {
          emit(
            AuthFailure(
              error: 'Facebook Sign-In failed: ${loginResult.message}',
            ),
          );
        }
        return;
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.tokenString,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.additionalUserInfo?.isNewUser == true) {
        await _firestoreService.createUserProfile(
          userId: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? 'User',
        );
      }

      if (!isClosed) {
        emit(Authenticated(result.user!));
        emit(AuthSuccess(message: 'Signed in with Facebook successfully'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  // ============ GMAIL SIGN IN ============

  Future<void> signInWithGmail() async {
    await signInWithGoogle();
  }

  // ============ SIGN OUT ============

  Future<void> signOut() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _auth.signOut();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      await fb.FacebookAuth.instance.logOut();

      if (!isClosed) {
        emit(Unauthenticated());
        emit(AuthSuccess(message: 'Signed out successfully'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  // ============ NAVIGATION HELPERS ============

  void getStarted() {
    if (isClosed) return;

    final user = _auth.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  void haveAccount() {
    if (!isClosed) {
      emit(Unauthenticated());
    }
  }

  // ============ PASSWORD RESET ============

  Future<void> resetPassword(String email) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      if (!isClosed) {
        emit(
          AuthSuccess(message: 'Password reset email sent. Check your inbox.'),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: _getFirebaseErrorMessage(e)));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  // ============ EMAIL VERIFICATION ============

  Future<void> sendEmailVerification() async {
    if (isClosed) return;

    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        if (!isClosed) {
          emit(
            AuthSuccess(message: 'Verification email sent. Check your inbox.'),
          );
        }
      } catch (e) {
        if (!isClosed) {
          emit(AuthFailure(error: e.toString()));
        }
      }
    }
  }

  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ============ DELETE ACCOUNT ============

  Future<void> deleteAccount() async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.deleteAllUserData();
        await user.delete();
        if (_googleSignIn != null) {
          await _googleSignIn!.signOut();
        }
        await fb.FacebookAuth.instance.logOut();

        if (!isClosed) {
          emit(Unauthenticated());
          emit(AuthSuccess(message: 'Account deleted successfully'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(AuthFailure(error: e.toString()));
      }
    }
  }

  // ============ HELPER METHODS ============

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
