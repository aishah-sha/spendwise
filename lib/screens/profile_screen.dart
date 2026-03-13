import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' show ImageFilter;

// Cubits
import '../cubit/budget_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../cubit/add_expense_cubit.dart';

// Screens
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'expense_history_screen.dart';
import 'add_expense_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color fabBorderColor = Color(0xFFD4E5B0);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit()..loadProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          bool isDarkMode = (state is ProfileLoaded)
              ? state.user.isDarkMode
              : false;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
            home: Builder(
              builder: (scaffoldContext) {
                return Scaffold(
                  backgroundColor: isDarkMode ? Colors.black : bgColor,
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerDocked,
                  floatingActionButton: _buildFab(scaffoldContext),
                  bottomNavigationBar: _buildBottomNavigation(scaffoldContext),
                  body: Column(
                    children: [
                      _buildTopHeader(scaffoldContext, isDarkMode),
                      Expanded(child: _ProfileContent(isDarkMode: isDarkMode)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- TOP HEADER: CHART & NOTIFICATIONS ---
  Widget _buildTopHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : headerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SpendWise',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : darkText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Chart icon - Navigates to Analytics Screen
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<ExpenseCubit>(),
                        child: const AnalyticsScreen(),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.bar_chart,
                  size: 28,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
              const SizedBox(width: 15),
              // Notifications icon
              GestureDetector(
                onTap: () {
                  _showNotificationsDialog(context);
                },
                child: Icon(
                  Icons.notifications,
                  size: 28,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      height: 70,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: fabBorderColor, width: 4),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => AddExpenseCubit(),
              child: const AddExpenseScreen(),
            ),
          ),
        ),
        child: const Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomAppBar(
      color: headerColor,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, Icons.home, 'Home', false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: BlocProvider.of<ExpenseCubit>(context),
                    child: const DashboardScreen(),
                  ),
                ),
              );
            }),
            _navItem(
              Icons.history_outlined,
              Icons.history,
              'History',
              false,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => BlocProvider.value(
                      value: context.read<ExpenseCubit>(),
                      child: const ExpenseHistoryScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 40), // Gap for FAB
            _navItem(
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider(create: (context) => BudgetCubit()),
                      ],
                      child: const BudgetScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.person_outline,
              Icons.person,
              'Profile',
              true,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? accentGreen : Colors.black54,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? accentGreen : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No new notifications',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for updates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final bool isDarkMode;

  const _ProfileContent({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildProfileHeader(context, state),
                const SizedBox(height: 35),
                _buildSection('PERSONAL INFORMATION', [
                  _buildTile(
                    Icons.person_outline,
                    'Full Name',
                    state.user.fullName,
                  ),
                  _buildTile(Icons.email_outlined, 'Email', state.user.email),
                ]),
                const SizedBox(height: 25),
                _buildSection('PREFERENCES', [
                  // Push Notifications Toggle
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    value: state.user.pushNotificationsEnabled,
                    onChanged: (value) {
                      context.read<ProfileCubit>().togglePushNotifications();
                      _showSnackBar(
                        context,
                        value
                            ? 'Push Notifications Enabled'
                            : 'Push Notifications Disabled',
                      );
                    },
                  ),

                  // Dark Mode Toggle
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    value: state.user.isDarkMode,
                    onChanged: (value) {
                      context.read<ProfileCubit>().toggleDarkMode();
                      _showSnackBar(
                        context,
                        value ? 'Dark Mode Enabled' : 'Light Mode Enabled',
                      );
                    },
                  ),

                  // Biometric Toggle
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Login',
                    value: state.user.biometricEnabled,
                    onChanged: (value) {
                      context.read<ProfileCubit>().toggleBiometric();
                      _showSnackBar(
                        context,
                        value
                            ? 'Biometric Login Enabled'
                            : 'Biometric Login Disabled',
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 25),
                _buildSection('CURRENCY SETTINGS', [
                  _buildCurrencySelector(context, state),
                ]),
                const SizedBox(height: 25),
                _buildSection('EXPENSE SETTINGS', [
                  _buildSmallExpensesLimit(context, state),
                ]),
                const SizedBox(height: 40),
                _buildLogoutButton(context),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: ProfileScreen.accentGreen),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileLoaded state) {
    return Column(
      children: [
        // Profile Picture with subtle border
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ProfileScreen.fabBorderColor, width: 2),
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundImage: NetworkImage(state.user.profileImageUrl),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.user.fullName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          ),
        ),
        Text(
          state.user.email,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),

        // Edit Profile Button
        OutlinedButton.icon(
          onPressed: () => _showEditProfileSheet(context, state),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text("Edit Profile"),
          style: OutlinedButton.styleFrom(
            foregroundColor: ProfileScreen.accentGreen,
            side: const BorderSide(color: ProfileScreen.accentGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ProfileScreen.accentGreen, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      activeColor: ProfileScreen.accentGreen,
      onChanged: onChanged,
    );
  }

  Widget _buildCurrencySelector(BuildContext context, ProfileLoaded state) {
    final List<String> currencies = ['RM', 'USD', 'EUR', 'GBP', 'SGD'];

    return Column(
      children: currencies.map((currency) {
        return RadioListTile<String>(
          title: Text(
            currency,
            style: TextStyle(
              color: isDarkMode ? Colors.white : ProfileScreen.darkText,
            ),
          ),
          value: currency,
          groupValue: state.user.currency,
          activeColor: ProfileScreen.accentGreen,
          onChanged: (value) {
            if (value != null) {
              context.read<ProfileCubit>().updateCurrency(value);
              _showSnackBar(context, 'Currency changed to $value');
            }
          },
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ProfileScreen.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              currency,
              style: TextStyle(
                color: ProfileScreen.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallExpensesLimit(BuildContext context, ProfileLoaded state) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.money_off,
          color: ProfileScreen.accentGreen,
          size: 20,
        ),
      ),
      title: Text(
        'Small Expenses Limit',
        style: TextStyle(
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Expenses below this amount are considered "small"',
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RM ${state.user.smallExpensesLimit.toStringAsFixed(0)}',
              style: const TextStyle(
                color: ProfileScreen.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _showLimitSlider(context, state);
              },
              child: const Icon(
                Icons.edit,
                size: 16,
                color: ProfileScreen.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitSlider(BuildContext context, ProfileLoaded state) {
    double currentLimit = state.user.smallExpensesLimit;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Small Expenses Limit",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Set the maximum amount for small expenses",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ProfileScreen.accentGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'RM ${currentLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ProfileScreen.accentGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Slider(
                    value: currentLimit,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: ProfileScreen.accentGreen,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        currentLimit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context
                                .read<ProfileCubit>()
                                .updateSmallExpensesLimit(currentLimit);
                            Navigator.pop(context);
                            _showSnackBar(
                              context,
                              'Small expenses limit updated to RM ${currentLimit.toStringAsFixed(0)}',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProfileScreen.accentGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, ProfileLoaded state) {
    final nameController = TextEditingController(text: state.user.fullName);
    final emailController = TextEditingController(text: state.user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 15,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
              ),
              const SizedBox(height: 25),

              // Change Picture
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(state.user.profileImageUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Add image picker logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image picker coming soon!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: ProfileScreen.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: ProfileScreen.accentGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: ProfileScreen.fabBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: ProfileScreen.fabBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: ProfileScreen.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: ProfileScreen.accentGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: ProfileScreen.fabBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: ProfileScreen.fabBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: ProfileScreen.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  context.read<ProfileCubit>().updateFullName(
                    nameController.text,
                  );
                  // Email update might need verification, so we'll just show a message
                  Navigator.pop(context);
                  _showSnackBar(context, 'Profile updated successfully!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen.accentGreen,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ProfileScreen.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey.shade800
                  : ProfileScreen.fabBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ProfileScreen.accentGreen, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<ProfileCubit>().logout();
          // Navigate to login screen or show logout message
          _showSnackBar(context, 'Logged out successfully');
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
