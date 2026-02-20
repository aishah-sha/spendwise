import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'cubit/expense_cubit.dart'; // Ensure this import is correct

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        // The OnboardingScreen manages its own Cubit internally
        '/': (context) => const OnboardingScreen(),

        // The Dashboard MUST have access to ExpenseCubit to build
        '/dashboard': (context) => BlocProvider(
          create: (context) => ExpenseCubit(),
          child: const DashboardScreen(),
        ),
      },
    );
  }
}
