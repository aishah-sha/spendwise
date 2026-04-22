import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'cubit/expense_cubit.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/profile_cubit.dart';
import 'cubit/notification_cubit.dart';
import 'cubit/auth_cubit.dart'; // We'll create this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Core app-level cubits that need to persist throughout the app
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<ExpenseCubit>(create: (context) => ExpenseCubit()),
        BlocProvider<BudgetCubit>(create: (context) => BudgetCubit()),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(),
        ),
        BlocProvider<ProfileCubit>(create: (context) => ProfileCubit()),
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
          '/': (context) => const AuthWrapper(), // Changed to AuthWrapper
          '/dashboard': (context) => const DashboardScreen(),
          '/add_budget': (context) => const AddBudgetScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/add_budget') {
            return MaterialPageRoute(
              builder: (context) => const AddBudgetScreen(),
            );
          }
          if (settings.name == '/profile') {
            return MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            );
          }
          if (settings.name == '/notifications') {
            return MaterialPageRoute(
              builder: (context) => const NotificationScreen(),
            );
          }
          return null;
        },
      ),
    );
  }
}

// Auth Wrapper to handle navigation based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Authenticated) {
          // User is logged in, go to dashboard
          return const DashboardScreen();
        }

        if (state is Unauthenticated) {
          // User is not logged in, show onboarding
          return const OnboardingScreen();
        }

        // Default case
        return const OnboardingScreen();
      },
    );
  }
}
