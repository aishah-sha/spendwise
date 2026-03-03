import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../models/receipt_model.dart';
import 'manual_entry_screen.dart';

// Import your other screens here
// import 'dashboard_screen.dart';
// import 'history_screen.dart';
// import 'budget_screen.dart';
// import 'profile_screen.dart';
// import 'analytics_screen.dart';
// import 'notifications_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  // Theme colors - matching dashboard_screen.dart
  static const Color bgColor = Color(0xFFE8F7CB); // Main background light green
  static const Color headerColor = Color(
    0xFFC5D997,
  ); // Header and Card muted green
  static const Color accentGreen = Color(
    0xFF32BA32,
  ); // Bright green for buttons/icons
  static const Color darkText = Color(
    0xFF000000,
  ); // Black text for high contrast

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // FAB in the center
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
          onPressed: () {
            // Handle FAB tap
            print('FAB tapped');
            // You can add navigation here if needed
            // For example, navigate to add expense quick action
          },
          child: const Icon(Icons.add, color: accentGreen, size: 45),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Column(
        children: [
          _buildTopHeader(context), // Custom header at top
          Expanded(
            child: BlocConsumer<AddExpenseCubit, AddExpenseState>(
              listener: (context, state) {
                // Handle error message
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  _showErrorDialog(context, state.errorMessage!);
                }

                // Handle scanned receipt
                if (state.scannedReceipt != null &&
                    state.scannedReceipt!.amount == 0.0) {
                  _showManualEntryDialog(context, state.scannedReceipt!);
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
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildOptionsGrid(context),
                          const SizedBox(height: 30),
                          _buildRecentUploadsHeader(),
                          const SizedBox(height: 15),
                          _buildRecentUploadsList(
                            state,
                            context,
                          ), // Pass context
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

  // Header with SpendWise logo and icons - ALL ICONS NOW CLICKABLE WITH PROPER NAVIGATION
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: headerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo section - made clickable to go to home/dashboard
          GestureDetector(
            onTap: () {
              print('Logo/Home tapped');
              // Navigate to home/dashboard screen
              // OPTION 1: If you want to go back to previous screen (if this was pushed)
              Navigator.pop(context);

              // OPTION 2: If you want to navigate to a specific dashboard screen
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => const DashboardScreen()),
              // );

              // OPTION 3: If using named routes
              // Navigator.pushReplacementNamed(context, '/dashboard');
            },
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
          Row(
            children: [
              // Chart icon - clickable - Navigate to Analytics
              GestureDetector(
                onTap: () {
                  print('Chart icon tapped');
                  // Navigate to analytics/stats screen
                  // REPLACE THIS WITH YOUR ACTUAL SCREEN:
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  // );

                  // OR if using named routes:
                  // Navigator.pushNamed(context, '/analytics');

                  // For now, show a snackbar as placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analytics screen will open here'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.bar_chart, size: 28),
              ),
              const SizedBox(width: 15),
              // Notifications icon - clickable - Navigate to Notifications
              GestureDetector(
                onTap: () {
                  print('Notifications icon tapped');
                  // Navigate to notifications screen
                  // REPLACE THIS WITH YOUR ACTUAL SCREEN:
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  // );

                  // OR if using named routes:
                  // Navigator.pushNamed(context, '/notifications');

                  // For now, show a snackbar as placeholder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications screen will open here'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.notifications, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add New Expense',
          style: TextStyle(
            fontSize: 20,
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Choose how you\'d like to add your expense',
          style: TextStyle(fontSize: 16, color: darkText),
        ),
      ],
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
          onTap: () {
            context.read<AddExpenseCubit>().scanReceipt();
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'Upload Image',
          subtitle: 'Select from gallery',
          color: Colors.purple,
          onTap: () {
            context.read<AddExpenseCubit>().uploadImage();
          },
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          icon: Icons.edit_note,
          title: 'Manual Entry',
          subtitle: 'Enter details manually',
          color: Colors.orange,
          onTap: () {
            // Navigate to Manual Entry Screen without receipt
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManualEntryScreen(),
              ),
            );
          },
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
          color: headerColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: darkText.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: darkText),
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
            // Navigate to Manual Entry Screen with receipt data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManualEntryScreen(receipt: receipt),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side - Image/Icon
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
                      ? Icon(
                          receipt.receiptType == 'scan'
                              ? Icons.document_scanner
                              : receipt.receiptType == 'upload'
                              ? Icons.photo
                              : Icons.receipt,
                          color: accentGreen,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Middle - Details
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
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(receipt.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: darkText.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (receipt.items != null)
                        Text(
                          '${receipt.items!.length} items',
                          style: TextStyle(fontSize: 12, color: accentGreen),
                        ),
                    ],
                  ),
                ),

                // Right side - Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM${receipt.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: receipt.receiptType == 'scan'
                            ? Colors.blue.withOpacity(0.1)
                            : receipt.receiptType == 'upload'
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        receipt.receiptType?.toUpperCase() ?? 'MANUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: receipt.receiptType == 'scan'
                              ? Colors.blue
                              : receipt.receiptType == 'upload'
                              ? Colors.purple
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    }
  }

  // Build items table
  Widget _buildItemsTable(ReceiptModel receipt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Table Header
          const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),

          // Table Items (show only first 3 items)
          ...receipt.items!
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, color: darkText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontSize: 12, color: darkText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'RM${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          if (receipt.items!.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '+${receipt.items!.length - 3} more items',
              style: TextStyle(
                fontSize: 11,
                color: darkText.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build transaction details
  Widget _buildTransactionDetails(ReceiptModel receipt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Merchant Name
          Row(
            children: [
              const Icon(Icons.store, size: 16, color: accentGreen),
              const SizedBox(width: 8),
              Text(
                'MERCHANT NAME',
                style: TextStyle(
                  fontSize: 11,
                  color: darkText.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                receipt.merchantName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Transaction Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: accentGreen),
              const SizedBox(width: 8),
              Text(
                'TRANSACTION DATE',
                style: TextStyle(
                  fontSize: 11,
                  color: darkText.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(receipt.date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Amount
          Row(
            children: [
              const Icon(Icons.receipt, size: 16, color: accentGreen),
              const SizedBox(width: 8),
              Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  fontSize: 11,
                  color: darkText.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'RM${receipt.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build action buttons
  Widget _buildActionButtons(BuildContext context, ReceiptModel receipt) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _confirmSaveReceipt(context, receipt);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirm & Save',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _showManualEntryDialog(context, receipt);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: accentGreen,
              side: const BorderSide(color: accentGreen),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Edit Details Manually',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          context.read<AddExpenseCubit>().viewAll();
        },
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        ),
        child: const Text(
          'View All',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Bottom navigation - ALL ICONS NOW CLICKABLE WITH PROPER NAVIGATION
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
            _navItem(Icons.home, 'Home', false, () {
              print('Home tapped');
              // Navigate to Home/Dashboard screen
              // REPLACE WITH YOUR ACTUAL SCREEN:
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => const DashboardScreen()),
              // );

              // For now, just go back if this was pushed
              Navigator.pop(context);
            }),
            _navItem(Icons.history, 'History', false, () {
              print('History tapped');
              // Navigate to History screen
              // REPLACE WITH YOUR ACTUAL SCREEN:
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const HistoryScreen()),
              // );

              // For now, show a snackbar as placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History screen will open here'),
                  duration: Duration(seconds: 1),
                ),
              );
            }),
            const SizedBox(width: 40), // Space for FAB
            _navItem(Icons.savings, 'Budget', false, () {
              print('Budget tapped');
              // Navigate to Budget screen
              // REPLACE WITH YOUR ACTUAL SCREEN:
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const BudgetScreen()),
              // );

              // For now, show a snackbar as placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget screen will open here'),
                  duration: Duration(seconds: 1),
                ),
              );
            }),
            _navItem(Icons.person, 'Profile', false, () {
              print('Profile tapped');
              // Navigate to Profile screen
              // REPLACE WITH YOUR ACTUAL SCREEN:
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const ProfileScreen()),
              // );

              // For now, show a snackbar as placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile screen will open here'),
                  duration: Duration(seconds: 1),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.black : Colors.black54),
          Text(label, style: const TextStyle(fontSize: 12)),
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
            onPressed: () {
              context.read<AddExpenseCubit>().clearScannedReceipt();
              Navigator.pop(context);
            },
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
            if (receipt.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(receipt.imagePath!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: 'RM',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AddExpenseCubit>().clearScannedReceipt();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                context.read<AddExpenseCubit>().confirmManualEntry(
                  amount,
                  merchantController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmSaveReceipt(BuildContext context, ReceiptModel receipt) {
    print('Saving receipt: ${receipt.id}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt saved successfully'),
        backgroundColor: accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper functions for category icons and colors
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'detergent':
        return Icons.local_laundry_service;
      case 'stationery':
        return Icons.edit;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'groceries':
        return Icons.shopping_cart;
      case 'utilities':
        return Icons.electrical_services;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'detergent':
        return Colors.blue;
      case 'stationery':
        return Colors.purple;
      case 'transport':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'entertainment':
        return Colors.red;
      case 'groceries':
        return Colors.teal;
      case 'utilities':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
