import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spendwise/screens/signup_screen.dart';
import 'package:spendwise/screens/welcome_screen.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'cubit/expense_cubit.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/profile_cubit.dart';
import 'cubit/profile_state.dart';
import 'cubit/notification_cubit.dart';
import 'cubit/auth_cubit.dart';
import 'screens/login_screen.dart';

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
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<ExpenseCubit>(create: (context) => ExpenseCubit()),
        BlocProvider<BudgetCubit>(create: (context) => BudgetCubit()),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit()..loadProfile(),
        ),
      ],
      child: const AppRoot(),
    );
  }
}

// Separate widget to handle theme without rebuilding everything
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Use select to only rebuild when isDarkMode changes, not on every ProfileLoaded change
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) {
        if (state is ProfileLoaded) {
          return state.user.isDarkMode;
        }
        return false;
      },
      builder: (context, isDarkMode) {
        return MaterialApp(
          title: 'SpendWise',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Poppins',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Color(0xFFC5D997),
              foregroundColor: Colors.black,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFE8F7CB),
            extensions: const [
              CustomColors(
                bgColor: Color(0xFFE8F7CB),
                headerColor: Color(0xFFC5D997),
                accentGreen: Color(0xFF32BA32),
                darkText: Color(0xFF000000),
                fabBorderColor: Color(0xFFD4E5B0),
              ),
            ],
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'Poppins',
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade800,
            ),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            extensions: const [
              CustomColors(
                bgColor: Colors.black,
                headerColor: Color(0xFF1A1A1A),
                accentGreen: Color(0xFF32BA32),
                darkText: Colors.white,
                fabBorderColor: Color(0xFF2A2A2A),
              ),
            ],
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
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
        );
      },
    );
  }
}

// Custom theme extension
class CustomColors extends ThemeExtension<CustomColors> {
  final Color bgColor;
  final Color headerColor;
  final Color accentGreen;
  final Color darkText;
  final Color fabBorderColor;

  const CustomColors({
    required this.bgColor,
    required this.headerColor,
    required this.accentGreen,
    required this.darkText,
    required this.fabBorderColor,
  });

  @override
  ThemeExtension<CustomColors> copyWith({
    Color? bgColor,
    Color? headerColor,
    Color? accentGreen,
    Color? darkText,
    Color? fabBorderColor,
  }) {
    return CustomColors(
      bgColor: bgColor ?? this.bgColor,
      headerColor: headerColor ?? this.headerColor,
      accentGreen: accentGreen ?? this.accentGreen,
      darkText: darkText ?? this.darkText,
      fabBorderColor: fabBorderColor ?? this.fabBorderColor,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
    covariant ThemeExtension<CustomColors>? other,
    double t,
  ) {
    if (other is! CustomColors) return this;
    return CustomColors(
      bgColor: Color.lerp(bgColor, other.bgColor, t)!,
      headerColor: Color.lerp(headerColor, other.headerColor, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      darkText: Color.lerp(darkText, other.darkText, t)!,
      fabBorderColor: Color.lerp(fabBorderColor, other.fabBorderColor, t)!,
    );
  }
}

// Auth Wrapper
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
          return const DashboardScreen();
        }

        if (state is Unauthenticated) {
          return const OnboardingScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}
