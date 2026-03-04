import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_budget_screen.dart'; // Add this import
import 'cubit/expense_cubit.dart';
import 'cubit/budget_cubit.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide ExpenseCubit at the app level so all screens can access it
        BlocProvider<ExpenseCubit>(create: (context) => ExpenseCubit()),
        // Provide BudgetCubit at the app level for budget-related screens
        BlocProvider<BudgetCubit>(create: (context) => BudgetCubit()),
      ],
      child: MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/add_budget': (context) =>
              const AddBudgetScreen(), // Add this route if needed
        },
        // Handle undefined routes
        onGenerateRoute: (settings) {
          if (settings.name == '/add_budget') {
            return MaterialPageRoute(
              builder: (context) => const AddBudgetScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}
