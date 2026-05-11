import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit()..startOnboardingTimer(),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({Key? key}) : super(key: key);

  Future<void> _completeOnboarding(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      print('Onboarding marked as completed');
    } catch (e) {
      print('Error saving onboarding status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) async {
        if (state is OnboardingNavigation) {
          // Save onboarding completion status
          await _completeOnboarding(context);

          // Navigate to welcome screen when onboarding completes
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, state.nextRoute);
          }
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          // Show loading indicator
          if (state is OnboardingLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF32BA32)),
              ),
            );
          }

          // Show loaded content
          if (state is OnboardingLoaded) {
            return Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFE8F7CB),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF32BA32),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // App Name with fade-in animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeIn,
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          state.appName,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                            letterSpacing: 1,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Tagline with fade-in animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeIn,
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          state.tagline,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF434843),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Progress indicator with percentage text
                      Column(
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(seconds: 3),
                            builder: (context, double value, child) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: 250,
                                    child: LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: Colors.white,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF32BA32),
                                          ),
                                      borderRadius: BorderRadius.circular(10),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${(value * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF32BA32),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Skip button
                      TextButton(
                        onPressed: () {
                          context.read<OnboardingCubit>().skipOnboarding();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF32BA32),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Initial state - show loading
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF32BA32)),
            ),
          );
        },
      ),
    );
  }
}
