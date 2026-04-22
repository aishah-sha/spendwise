import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
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
          // Navigate to dashboard or login screen based on your flow
          // Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is Authenticated) {
          // User is already logged in, go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (state is Unauthenticated) {
          // User needs to login/signup, navigate to login screen
          // Navigator.pushReplacementNamed(context, '/login');
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
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Welcome Message
                          const Text(
                            'WELCOME, USER !',
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
                          // Get Started Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      context.read<AuthCubit>().getStarted();
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
                          // I have an account button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      context.read<AuthCubit>().haveAccount();
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
                          // Social Icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Gmail button - Show dialog to enter credentials
                              _buildSocialIcon(context, 'assets/gmail.png', () {
                                if (state is! AuthLoading) {
                                  context.read<AuthCubit>().signInWithGmail();
                                }
                              }),
                              const SizedBox(width: 40),
                              // Google button
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
                              const SizedBox(width: 40),
                              // Facebook button
                              _buildSocialIcon(
                                context,
                                'assets/facebook.png',
                                () {
                                  if (state is! AuthLoading) {
                                    context
                                        .read<AuthCubit>()
                                        .signInWithFacebook();
                                  }
                                },
                              ),
                            ],
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
      child: Image.asset(assetPath, height: 35),
    );
  }

  // Show dialog for email login
  void _showEmailLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLogin = true; // Toggle between login and signup

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isLogin ? 'Sign In with Email' : 'Create Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                // ignore: dead_code
                if (!isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Store name for signup
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter email and password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext);

                  await context.read<AuthCubit>().signInWithEmail(
                    email,
                    password,
                  );
                },
                child: Text(isLogin ? 'Sign In' : 'Sign Up'),
              ),
            ],
            actionsPadding: const EdgeInsets.all(16),
          );
        },
      ),
    );
  }
}
