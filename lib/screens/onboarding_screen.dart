import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/onboarding_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingNavigation) {
          // Navigate to next screen when navigation state is emitted
          Navigator.pushReplacementNamed(context, state.nextRoute);
        }
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          // Show loading indicator
          if (state is OnboardingLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Show loaded content
          if (state is OnboardingLoaded) {
            return GestureDetector(
              child: Scaffold(
                body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(
                    0xFFE8F7CB,
                  ), // Your specified background color
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 85, 227, 94),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 60,
                            color: Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ), // Dark green
                          ),
                        ),
                        const SizedBox(height: 25),
                        // App Name
                        Text(
                          state.appName,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ), // Dark green for contrast
                            letterSpacing: 1,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          state.tagline,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(
                              255,
                              67,
                              72,
                              67,
                            ), // Medium green for contrast
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Optional progress indicator
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(seconds: 3),
                          builder: (context, double value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Initial state
          return const Scaffold(body: Center(child: Text('Welcome')));
        },
      ),
    );
  }
}
