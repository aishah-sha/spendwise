import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

// States
abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingLoaded extends OnboardingState {
  final String appName;
  final String tagline;

  OnboardingLoaded({required this.appName, required this.tagline});
}

class OnboardingNavigation extends OnboardingState {
  final String nextRoute;

  OnboardingNavigation({required this.nextRoute});
}

// Cubit
class OnboardingCubit extends Cubit<OnboardingState> {
  Timer? _timer;

  OnboardingCubit() : super(OnboardingInitial());

  void startOnboardingTimer() {
    if (isClosed) return;

    emit(OnboardingLoading());

    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        emit(
          OnboardingLoaded(
            appName: 'SpendWise',
            tagline: 'Simplify your finances',
          ),
        );
      }
    });

    // Navigate after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        emit(OnboardingNavigation(nextRoute: '/welcome'));
      }
    });
  }

  void skipOnboarding() {
    _timer?.cancel();
    if (!isClosed) {
      emit(OnboardingNavigation(nextRoute: '/welcome'));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
