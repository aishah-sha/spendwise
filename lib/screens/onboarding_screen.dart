import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  final String? nextRoute;

  const OnboardingScreen({super.key, this.nextRoute});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit()..startOnboardingTimer(),
      child: OnboardingView(nextRoute: nextRoute),
    );
  }
}

class OnboardingView extends StatelessWidget {
  final String? nextRoute;

  const OnboardingView({super.key, this.nextRoute});

  Future<void> _completeOnboarding(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Stop unauthenticated users from seeing it repeatedly before the Welcome screen
      await prefs.setBool('has_seen_onboarding', true);
      
      // Keep this true so authenticated launches continue showing it before the dashboard
      await prefs.setBool('show_onboarding_every_launch', true);
      
      debugPrint('Onboarding preference states synchronized safely.');
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) async {
        if (state is OnboardingNavigation) {
          await _completeOnboarding(context);

          if (context.mounted) {
            // Priority given to the explicitly passed nextRoute property
            final route = nextRoute ?? state.nextRoute;
            Navigator.pushReplacementNamed(context, route);
          }
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          if (state is OnboardingLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFFE8F7CB),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF32BA32)),
              ),
            );
          }

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

                      const SizedBox(height: 30),

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

          return const Scaffold(
            backgroundColor: Color(0xFFE8F7CB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF32BA32)),
            ),
          );
        },
      ),
    );
  }
}