import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../models/receipt_model.dart';
import 'budget_screen.dart';
import 'manual_entry_screen.dart';
import 'expense_history_screen.dart';
import 'dashboard_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  // Theme colors
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 30),
        height: 70,
        width: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFFD4E5B0), width: 4),
          ),
          onPressed: () => print('FAB tapped'),
          child: const Icon(Icons.add, color: accentGreen, size: 45),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(
        context,
        headerColor,
        accentGreen,
      ),
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: BlocConsumer<AddExpenseCubit, AddExpenseState>(
              listener: (context, state) {
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  _showErrorDialog(context, state.errorMessage!);
                }

                if (state.scannedReceipt != null &&
                    state.scannedReceipt!.amount == 0.0) {
                  _showManualEntryDialog(context, state.scannedReceipt!);
                }

                // FIX: Pass Cubit to the Edit Screen via BlocProvider.value
                if (state.expenseToEdit != null) {
                  final cubit = context.read<AddExpenseCubit>();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: cubit,
                          child: ManualEntryScreen(
                            receipt: ReceiptModel(
                              id: state.expenseToEdit!.id,
                              date: state.expenseToEdit!.date,
                              amount: state.expenseToEdit!.amount,
                              receiptType: 'manual',
                              merchantName: state.expenseToEdit!.title,
                            ),
                            isEditing: true,
                            expenseToEdit: state.expenseToEdit,
                          ),
                        ),
                      ),
                    ).then((_) => cubit.clearScannedReceipt());
                  });
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, state),
                          const SizedBox(height: 20),
                          _buildOptionsGrid(context),
                          const SizedBox(height: 30),
                          _buildRecentUploadsHeader(),
                          const SizedBox(height: 15),
                          _buildRecentUploadsList(state, context),
                          const SizedBox(height: 20),
                          _buildViewAllButton(context),
                        ],
                      ),
                    ),
                    if (state.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: accentGreen),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.camera_alt,
          title: 'Scan Receipt',
          subtitle: 'Use camera to capture receipt',
          color: Colors.blue,
          onTap: () => context.read<AddExpenseCubit>().scanReceipt(),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'Upload Image',
          subtitle: 'Select from gallery',
          color: Colors.purple,
          onTap: () => context.read<AddExpenseCubit>().uploadImage(),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.edit_note,
          title: 'Manual Entry',
          subtitle: 'Enter details manually',
          color: Colors.orange,
          onTap: () {
            // FIX: Capture the current Cubit instance
            final cubit = context.read<AddExpenseCubit>();
            final expenseToEdit = cubit.state.expenseToEdit;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: ManualEntryScreen(
                    receipt: expenseToEdit != null
                        ? ReceiptModel(
                            id: expenseToEdit.id,
                            date: expenseToEdit.date,
                            amount: expenseToEdit.amount,
                            receiptType: 'manual',
                            merchantName: expenseToEdit.title,
                          )
                        : null,
                    isEditing: expenseToEdit != null,
                    expenseToEdit: expenseToEdit,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- UI Helper Methods ---

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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 28),
              SizedBox(width: 15),
              Icon(Icons.notifications, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AddExpenseState state) {
    final isEditing = state.expenseToEdit != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Edit Expense' : 'Add New Expense',
          style: const TextStyle(
            fontSize: 20,
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEditing
              ? 'Update your expense details'
              : 'Choose how you\'d like to add your expense',
          style: const TextStyle(fontSize: 16, color: darkText),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 126, 223, 106),
              Color.fromARGB(255, 24, 143, 0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUploadsHeader() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.black26, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Uploads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.black26, thickness: 1)),
      ],
    );
  }

  Widget _buildRecentUploadsList(AddExpenseState state, BuildContext context) {
    if (state.recentUploads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            'No recent uploads',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: state.recentUploads.map((receipt) {
        return GestureDetector(
          onTap: () {
            final cubit = context.read<AddExpenseCubit>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: ManualEntryScreen(receipt: receipt, isEditing: false),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 252, 252, 252),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    image: receipt.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(receipt.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: receipt.imagePath == null
                      ? const Icon(Icons.receipt, color: accentGreen, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName ?? 'Unknown Merchant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(receipt.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: darkText.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'RM${receipt.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => context.read<AddExpenseCubit>().viewAll(),
        child: const Text(
          'View All',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentGreen,
          ),
        ),
      ),
    );
  }

  // FIXED Bottom Navigation Bar
  Widget _buildBottomNavigation(
    BuildContext context,
    Color headerColor,
    Color activeColor,
  ) {
    return BottomAppBar(
      color: headerColor,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              Icons.home_outlined,
              Icons.home,
              'Home',
              false,
              activeColor,
              () {
                // Navigate to Dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<ExpenseCubit>(context),
                      child: const DashboardScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.history_outlined,
              Icons.history,
              'History',
              false,
              activeColor,
              () {
                // Navigate to History Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<ExpenseCubit>(context),
                      child: const ExpenseHistoryScreen(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 40), // Gap for the FAB notch
            _navItem(
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false, // Changed from true to false since we're on Add Expense screen
              activeColor,
              () {
                // Navigate to Budget Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<ExpenseCubit>(context),
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
              false,
              activeColor,
              () {
                print('Profile tapped');
              },
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
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Make entire area tappable
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? activeColor : Colors.black54,
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? activeColor : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context, ReceiptModel receipt) {
    final amountController = TextEditingController();
    final merchantController = TextEditingController(
      text: receipt.merchantName ?? '',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Receipt Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(labelText: 'Merchant Name'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'RM',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              context.read<AddExpenseCubit>().confirmManualEntry(
                amount,
                merchantController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
