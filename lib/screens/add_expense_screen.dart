// lib/screens/add_expense_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../models/receipt_model.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  // Theme colors
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color cardColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context), // Pass context to appBar
      body: BlocConsumer<AddExpenseCubit, AddExpenseState>(
        listener: (context, state) {
          // Handle error message with proper null checks
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _showErrorDialog(context, state.errorMessage!);
          }

          // Handle scanned receipt with proper null check
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
                    _buildRecentUploadsTable(state),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Add context parameter
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: cardColor,
      elevation: 0,
      title: const Text(
        'Add New Expense',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: darkText),
        onPressed: () {
          Navigator.pop(context); // Now context is available
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            context.read<AddExpenseCubit>().manualEntry();
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
          color: cardColor,
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

  Widget _buildRecentUploadsTable(AddExpenseState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: darkText.withOpacity(0.2), width: 1),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Merchant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          ...state.recentUploads
              .map(
                (receipt) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkText.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            _getReceiptTypeIcon(receipt.receiptType),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(receipt.date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: darkText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          receipt.merchantName ?? 'Unknown',
                          style: const TextStyle(fontSize: 14, color: darkText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '\$${receipt.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: darkText,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _getReceiptTypeIcon(String? type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'scan':
        iconData = Icons.camera_alt;
        iconColor = Colors.blue;
        break;
      case 'upload':
        iconData = Icons.photo;
        iconColor = Colors.purple;
        break;
      case 'manual':
        iconData = Icons.edit;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.receipt;
        iconColor = Colors.grey;
    }

    return Icon(iconData, size: 16, color: iconColor);
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 'Home', false),
            _buildNavItem(Icons.history, 'History', false),
            _buildNavItem(Icons.add_circle, 'Add', true),
            _buildNavItem(Icons.pie_chart, 'Budget', false),
            _buildNavItem(Icons.person, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? accentGreen : Colors.grey,
          size: isSelected ? 28 : 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? accentGreen : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
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
                prefixText: '\$',
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
}
