import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'package:spendwise/screens/signup_screen.dart';
import 'package:spendwise/screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/login_screen.dart';

// Cubits
import 'cubit/expense_cubit.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/profile_cubit.dart';
import 'cubit/profile_state.dart';
import 'cubit/notification_cubit.dart';
import 'cubit/auth_cubit.dart' as auth;

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Load environment variables
    // We specify the filename to be explicit
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // 3. Safety Check: Stop the "Null check operator" crash before it happens
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        "Missing keys in .env file. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are defined.",
      );
    }

    // 4. Initialize Supabase
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    runApp(const MyApp());
  } catch (e) {
    // 5. Fatal Error UI: Instead of a white screen/splash, show the user the error
    debugPrint("Initialization Error: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFE8F7CB),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Setup Error",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<auth.AuthCubit>(
          create: (context) => auth.AuthCubit()..checkAuthStatus(),
        ),
        BlocProvider<ExpenseCubit>(create: (context) => ExpenseCubit()),
        BlocProvider<BudgetCubit>(create: (context) => BudgetCubit()),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(),
        ),
        BlocProvider<ProfileCubit>(create: (context) => ProfileCubit()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, bool>(
      selector: (state) =>
          state is ProfileLoaded ? state.user.isDarkMode : false,
      builder: (context, isDarkMode) {
        return MaterialApp(
          title: 'SpendWise',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFE8F7CB),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFC5D997),
              foregroundColor: Colors.black,
              centerTitle: true,
            ),
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

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
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

          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/add_budget': (context) => const AddBudgetScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<auth.AuthCubit, auth.AuthState>(
      builder: (context, state) {
        // 1. User is Logged In
        if (state is auth.Authenticated) {
          return const DashboardScreen();
        }

        // 2. We are checking the session
        if (state is auth.AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF32BA32)),
            ),
          );
        }

        // 3. Fallback: If not logged in or any other state, start at Onboarding
        return const OnboardingScreen();
      },
    );
  }
}

// Theme Extension Class
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
