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
                      _buildTopHeader(scaffoldContext),
                      Expanded(child: _ProfileContent()),
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
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: headerColor),
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
                const Text(
                  'SpendWise',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText,
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
                child: const Icon(Icons.bar_chart, size: 28, color: darkText),
              ),
              const SizedBox(width: 15),
              // Notifications icon
              GestureDetector(
                onTap: () {
                  _showNotificationsDialog(context);
                },
                child: const Icon(
                  Icons.notifications,
                  size: 28,
                  color: darkText,
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
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ProfileScreen.accentGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: ProfileScreen.accentGreen,
                        size: 20,
                      ),
                    ),
                    title: const Text('Push Notifications'),
                    value: state.user.pushNotificationsEnabled,
                    activeColor: ProfileScreen.accentGreen,
                    onChanged: (v) =>
                        context.read<ProfileCubit>().togglePushNotifications(),
                  ),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ProfileScreen.accentGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dark_mode_outlined,
                        color: ProfileScreen.accentGreen,
                        size: 20,
                      ),
                    ),
                    title: const Text('Dark Mode'),
                    value: state.user.isDarkMode,
                    activeColor: ProfileScreen.accentGreen,
                    onChanged: (v) =>
                        context.read<ProfileCubit>().toggleDarkMode(),
                  ),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ProfileScreen.darkText,
          ),
        ),
        Text(
          state.user.email,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
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

  void _showEditProfileSheet(BuildContext context, ProfileLoaded state) {
    final nameController = TextEditingController(text: state.user.fullName);
    final emailController = TextEditingController(text: state.user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ProfileScreen.darkText,
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
                decoration: InputDecoration(
                  labelText: "Full Name",
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
                decoration: InputDecoration(
                  labelText: "Email Address",
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
                  // Add save logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: ProfileScreen.accentGreen,
                      duration: Duration(seconds: 2),
                    ),
                  );
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
              color: Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ProfileScreen.fabBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: ProfileScreen.darkText,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => context.read<ProfileCubit>().logout(),
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
