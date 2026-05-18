import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use existing AuthCubit from parent, don't create a new one
    return BlocProvider.value(
      value: context.read<AuthCubit>(),
      child: const WelcomeView(),
    );
  }
}

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is Authenticated) {
          // User is already logged in, go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFE5F4D7),
            body: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Top Logo and Name
                          Row(
                            children: [
                              Image.asset(
                                'assets/spendwise_logo.png',
                                height: 30,
                                width: 30,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SpendWise',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Main Illustration
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: Image.asset(
                              'assets/FYP1.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC8E6C9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    size: 80,
                                    color: Color(0xFF2E7D32),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Welcome Message
                          const Text(
                            'WELCOME, USER!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Your journey to financial freedom starts\nhere.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 50),
                          // Get Started Button - Goes to Sign Up
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.login_rounded),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // I have an account button - Goes to Login
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/login');
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'I have an account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // OR LOG IN WITH
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.black26)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "OR LOG IN WITH",
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.black26)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Social Icons - Updated for Supabase
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Sign In
                              _buildSocialIcon(
                                context,
                                'assets/google.png',
                                () {
                                  if (state is! AuthLoading) {
                                    context
                                        .read<AuthCubit>()
                                        .signInWithGoogle();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Info about social login
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Google sign-in available. For Facebook/Gmail, please use email sign up.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Footer text
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'By continuing, you agree to our Terms of Service and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // Loading overlay
                if (state is AuthLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialIcon(
    BuildContext context,
    String assetPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          height: 30,
          width: 30,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.login, size: 30, color: Color(0xFF2E7D32));
          },
        ),
      ),
    );
  }
}
