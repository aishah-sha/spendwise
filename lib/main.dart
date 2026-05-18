import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'package:spendwise/screens/signup_screen.dart';
import 'package:spendwise/screens/welcome_screen.dart';
import 'package:spendwise/screens/onboarding_screen.dart';
import 'package:spendwise/screens/dashboard_screen.dart';
import 'package:spendwise/screens/add_budget_screen.dart';
import 'package:spendwise/screens/profile_screen.dart';
import 'package:spendwise/screens/notification_screen.dart';
import 'package:spendwise/screens/login_screen.dart';

// Cubits
import 'cubit/expense_cubit.dart';
import 'cubit/budget_cubit.dart';
import 'cubit/profile_cubit.dart';
import 'cubit/notification_cubit.dart';
import 'cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception("Missing Supabase credentials in .env file");
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding =
        prefs.getBool('has_seen_onboarding') ?? false;
    final bool showOnboardingEveryLaunch =
        prefs.getBool('show_onboarding_every_launch') ??
        true; // Track if onboarding should show on every launch

    runApp(
      MyApp(
        hasSeenOnboarding: hasSeenOnboarding,
        showOnboardingEveryLaunch: showOnboardingEveryLaunch,
      ),
    );
  } catch (e) {
    debugPrint("Initialization error: $e");
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text("App Initialization Failed"))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool showOnboardingEveryLaunch;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.showOnboardingEveryLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<ExpenseCubit>(create: (context) => ExpenseCubit()),
        BlocProvider<BudgetCubit>(create: (context) => BudgetCubit()),
        BlocProvider<ProfileCubit>(create: (context) => ProfileCubit()),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFE8F7CB),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          extensions: const <ThemeExtension<dynamic>>[
            CustomColors(
              bgColor: Color(0xFFE8F7CB),
              headerColor: Color(0xFFC5D997),
              accentGreen: Color(0xFF32BA32),
              darkText: Color(0xFF000000),
              fabBorderColor: Color(0xFFC5D997),
            ),
          ],
        ),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/add_budget': (context) => const AddBudgetScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/notification': (context) => const NotificationScreen(),
        },
        home: AppHomeGateway(
          hasSeenOnboarding: hasSeenOnboarding,
          showOnboardingEveryLaunch: showOnboardingEveryLaunch,
        ),
      ),
    );
  }
}

class AppHomeGateway extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool showOnboardingEveryLaunch;

  const AppHomeGateway({
    super.key,
    required this.hasSeenOnboarding,
    required this.showOnboardingEveryLaunch,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we need to show onboarding
    final shouldShowOnboarding =
        !hasSeenOnboarding && showOnboardingEveryLaunch;

    if (shouldShowOnboarding) {
      // Show onboarding before any authentication check
      return OnboardingScreen(nextRoute: '/auth_gateway');
    }

    // After onboarding, check authentication state
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFE8F7CB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF32BA32)),
            ),
          );
        }

        if (state is Authenticated) {
          // Show onboarding before dashboard for authenticated users
          return OnboardingScreen(nextRoute: '/dashboard');
        } else {
          // Show onboarding before welcome screen for unauthenticated users
          return OnboardingScreen(nextRoute: '/welcome');
        }
      },
    );
  }
}

// Add a temporary gateway route handler
class AuthGatewayScreen extends StatelessWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFE8F7CB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF32BA32)),
            ),
          );
        }

        if (state is Authenticated) {
          return const DashboardScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}

// Custom Theme Design Class Extension
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
