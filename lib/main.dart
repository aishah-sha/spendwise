import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'cubit/expense_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide ExpenseCubit at the app level so all screens can access it
        BlocProvider(create: (context) => ExpenseCubit()),
      ],
      child: MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}
