part of 'onboarding_cubit.dart';

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
