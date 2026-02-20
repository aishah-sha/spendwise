import 'package:flutter_bloc/flutter_bloc.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> signInWithGmail() async {
    emit(AuthLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthSuccess(message: 'Signed in with Gmail successfully'));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthSuccess(message: 'Signed in with Google successfully'));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> signInWithFacebook() async {
    emit(AuthLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthSuccess(message: 'Signed in with Facebook successfully'));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  void getStarted() {
    emit(AuthLoading());
    // Simulate navigation or action
    Future.delayed(const Duration(milliseconds: 500), () {
      emit(AuthSuccess(message: 'Getting started...'));
    });
  }

  void haveAccount() {
    emit(AuthLoading());
    // Simulate navigation to login
    Future.delayed(const Duration(milliseconds: 500), () {
      emit(AuthSuccess(message: 'Navigating to login...'));
    });
  }
}
