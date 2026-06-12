import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../cubit/receipt_cubit.dart';
import '../models/receipt_model.dart';
import '../widgets/notification_badge.dart';
import '../services/ml_kit_service.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'manual_entry_screen.dart';
import 'expense_history_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'receipt_scanner_screen.dart';
import '../cubit/budget_cubit.dart' as budget_cubit;

class AddExpenseScreen extends StatelessWidget {
  final String? editingExpenseId;

  const AddExpenseScreen({super.key, this.editingExpenseId});

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        bool isDarkMode = (profileState is ProfileLoaded)
            ? profileState.user.isDarkMode
            : false;

        return Theme(
          data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            backgroundColor: isDarkMode ? Colors.black : bgColor,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: _buildFab(context, isDarkMode),
            bottomNavigationBar: _buildBottomNavigation(
              context,
              isDarkMode,
              accentGreen,
            ),
            body: Column(
              children: [
                _buildTopHeader(context, isDarkMode),
                Expanded(
                  child: BlocConsumer<AddExpenseCubit, AddExpenseState>(
                    listener: (context, state) {
                      if (state.errorMessage != null &&
                          state.errorMessage!.isNotEmpty) {
                        _showErrorDialog(context, state.errorMessage!);
                      }

                      if (state.expenseSavedSuccessfully) {
                        context.read<AddExpenseCubit>().resetSavedFlag();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense added successfully!'),
                            backgroundColor: accentGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      }

                      if (state.expenseEditedSuccessfully) {
                        context.read<AddExpenseCubit>().resetEditedFlag();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense updated successfully!'),
                            backgroundColor: accentGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      }

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
                                _buildHeader(context, state, isDarkMode),
                                const SizedBox(height: 20),
                                _buildOptionsGrid(context, isDarkMode),
                                const SizedBox(height: 30),
                                _buildRecentUploadsHeader(isDarkMode),
                                const SizedBox(height: 15),
                                _buildRecentUploadsList(
                                  state,
                                  context,
                                  isDarkMode,
                                ),
                                const SizedBox(height: 20),
                                _buildViewAllButton(context, isDarkMode),
                              ],
                            ),
                          ),
                          if (state.isLoading)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: accentGreen,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFab(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      height: 70,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFD4E5B0), width: 4),
        ),
        onPressed: () => debugPrint('FAB tapped'),
        child: const Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        // ── Scan Receipt (camera) ──────────────────────────────────────────
        _buildOptionCard(
          icon: Icons.camera_alt,
          title: 'Scan Receipt',
          subtitle: 'Use camera to capture receipt',
          color: Colors.blue,
          isDarkMode: isDarkMode,
          onTap: () async {
            final addExpenseCubit = context.read<AddExpenseCubit>();

            final scannedReceipt = await Navigator.push<ReceiptModel?>(
              context,
              MaterialPageRoute(
                builder: (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (context) => ReceiptCubit()),
                    BlocProvider.value(value: addExpenseCubit),
                  ],
                  child: const ReceiptScannerPage(fromAddExpense: true),
                ),
              ),
            );

            if (scannedReceipt != null && context.mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: addExpenseCubit,
                    child: ManualEntryScreen(
                      receipt: scannedReceipt,
                      fromAddExpense: true,
                    ),
                  ),
                ),
              );

              // Update recent uploads if a receipt was confirmed/saved
              if (result != null) {
                if (result is ReceiptModel) {
                  addExpenseCubit.addToRecentUploads(result);
                } else {
                  addExpenseCubit.addToRecentUploads(scannedReceipt);
                }
                if (context.mounted) Navigator.pop(context);
              }
            }
          },
        ),

        const SizedBox(height: 12),

        // ── Upload Single Image ────────────────────────────────────
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'Upload Image',
          subtitle: 'Select single image from gallery',
          color: Colors.purple,
          isDarkMode: isDarkMode,
          onTap: () async {
            await _handleUploadSingle(context);
          },
        ),

        const SizedBox(height: 12),

        // ── Upload Multiple Images ─────────────────────────────────
        _buildOptionCard(
          icon: Icons.photo_library_outlined,
          title: 'Upload Multiple',
          subtitle: 'Select multiple receipts at once',
          color: Colors.teal,
          isDarkMode: isDarkMode,
          onTap: () async {
            await _handleUploadMultiple(context);
          },
        ),

        const SizedBox(height: 12),

        // ── Manual Entry ───────────────────────────────────────────────────
        _buildOptionCard(
          icon: Icons.edit_note,
          title: 'Manual Entry',
          subtitle: 'Enter details manually',
          color: Colors.orange,
          isDarkMode: isDarkMode,
          onTap: () async {
            final cubit = context.read<AddExpenseCubit>();
            final expenseToEdit = cubit.state.expenseToEdit;

            final fallbackReceipt = expenseToEdit != null
                ? ReceiptModel(
                    id: expenseToEdit.id,
                    date: expenseToEdit.date,
                    amount: expenseToEdit.amount,
                    receiptType: 'manual',
                    merchantName: expenseToEdit.title,
                  )
                : null;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: ManualEntryScreen(
                    receipt: fallbackReceipt,
                    isEditing: expenseToEdit != null,
                    expenseToEdit: expenseToEdit,
                    fromAddExpense: true,
                  ),
                ),
              ),
            );

            if (result != null) {
              if (result is ReceiptModel) {
                cubit.addToRecentUploads(result);
              } else if (fallbackReceipt != null) {
                cubit.addToRecentUploads(fallbackReceipt);
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD SINGLE IMAGE — pick → OCR → parse → ManualEntryScreen
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleUploadSingle(BuildContext context) async {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    final mlKitService = MLKitService();

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (pickedFile == null) return;

    if (context.mounted) {
      addExpenseCubit.setLoading(true);
    }

    try {
      final receipt = await mlKitService.processReceiptImage(
        File(pickedFile.path),
        context: context,
      );

      if (context.mounted) {
        addExpenseCubit.setLoading(false);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: addExpenseCubit,
              child: ManualEntryScreen(receipt: receipt, fromAddExpense: true),
            ),
          ),
        );

        // Capture confirmed execution and add to UI list state
        if (result != null) {
          if (result is ReceiptModel) {
            addExpenseCubit.addToRecentUploads(result);
          } else {
            addExpenseCubit.addToRecentUploads(receipt);
          }
          addExpenseCubit.clearScannedReceipt();
          if (context.mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        addExpenseCubit.setLoading(false);
        _showErrorDialog(context, 'Failed to process image: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD MULTIPLE IMAGES — pick → OCR each → show dialog
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleUploadMultiple(BuildContext context) async {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    final mlKitService = MLKitService();

    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 90,
    );

    if (pickedFiles.isEmpty) return;

    if (context.mounted) {
      addExpenseCubit.setLoading(true);
    }

    try {
      final List<ReceiptModel> receipts = [];

      for (final file in pickedFiles) {
        final receipt = await mlKitService.processReceiptImage(
          File(file.path),
          context: context,
        );
        receipts.add(receipt);
      }

      if (context.mounted) {
        addExpenseCubit.setLoading(false);

        if (receipts.isNotEmpty) {
          if (receipts.length == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: addExpenseCubit,
                  child: ManualEntryScreen(
                    receipt: receipts.first,
                    fromAddExpense: true,
                  ),
                ),
              ),
            );

            if (result != null) {
              if (result is ReceiptModel) {
                addExpenseCubit.addToRecentUploads(result);
              } else {
                addExpenseCubit.addToRecentUploads(receipts.first);
              }
              if (context.mounted) Navigator.pop(context);
            }
          } else {
            _showMultipleReceiptsDialog(context, receipts);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        addExpenseCubit.setLoading(false);
        _showErrorDialog(context, 'Failed to process images: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────

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
              IconTheme(
                data: IconThemeData(
                  color: isDarkMode ? Colors.white : darkText,
                ),
                child: BlocProvider(
                  create: (context) => NotificationCubit(),
                  child: const NotificationBadge(iconSize: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AddExpenseState state,
    bool isDarkMode,
  ) {
    final isEditing = state.expenseToEdit != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Edit Expense' : 'Add New Expense',
          style: TextStyle(
            fontSize: 20,
            color: isDarkMode ? Colors.white : darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEditing
              ? 'Update your expense details'
              : 'Choose how you\'d like to add your expense',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : darkText,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDarkMode,
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
              color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.3),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUploadsHeader(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.white24 : Colors.black26,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Uploads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : darkText,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDarkMode ? Colors.white24 : Colors.black26,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUploadsList(
    AddExpenseState state,
    BuildContext context,
    bool isDarkMode,
  ) {
    if (state.recentUploads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : headerColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            'No recent uploads',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white60 : Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      children: state.recentUploads.map((receipt) {
        return GestureDetector(
          onTap: () async {
            final cubit = context.read<AddExpenseCubit>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: ManualEntryScreen(receipt: receipt, isEditing: false),
                ),
              ),
            );
            if (result != null && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildThumbnail(receipt),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName ?? 'Unknown Merchant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        receipt.categorySummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white60
                              : darkText.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        receipt.formattedDate,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode
                              ? Colors.white38
                              : darkText.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    if (receipt.items != null && receipt.items!.isNotEmpty)
                      Text(
                        '${receipt.totalItemCount} items',
                        style: TextStyle(
                          fontSize: 10,
                          color: darkText.withOpacity(0.4),
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

  Widget _buildThumbnail(ReceiptModel receipt) {
    final path = receipt.imagePath;

    if (path != null) {
      return FutureBuilder<bool>(
        future: File(path).exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbnailFallback(),
              ),
            );
          }
          return _thumbnailFallback();
        },
      );
    }

    return _thumbnailFallback();
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.receipt, color: accentGreen, size: 30),
    );
  }

  Widget _buildViewAllButton(BuildContext context, bool isDarkMode) {
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

  Widget _buildBottomNavigation(
    BuildContext context,
    bool isDarkMode,
    Color activeColor,
  ) {
    return BottomAppBar(
      color: isDarkMode ? Colors.grey[900] : headerColor,
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
              isDarkMode,
              activeColor,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(
                          value: context.read<budget_cubit.BudgetCubit>(),
                        ),
                        BlocProvider.value(value: context.read<ProfileCubit>()),
                      ],
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
              isDarkMode,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(
                          value: context.read<budget_cubit.BudgetCubit>(),
                        ),
                        BlocProvider.value(value: context.read<ProfileCubit>()),
                      ],
                      child: const ExpenseHistoryScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 40),
            _navItem(
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              isDarkMode,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(
                          value: context.read<budget_cubit.BudgetCubit>(),
                        ),
                        BlocProvider.value(value: context.read<ProfileCubit>()),
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
              false,
              isDarkMode,
              activeColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider.value(value: context.read<ProfileCubit>()),
                      ],
                      child: const ProfileScreen(),
                    ),
                  ),
                );
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
    bool isDarkMode,
    Color activeColor,
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
            color: active
                ? activeColor
                : (isDarkMode ? Colors.white70 : Colors.black54),
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active
                  ? activeColor
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs & Root Operations
// ─────────────────────────────────────────────────────────────────────────────

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

void _showMultipleReceiptsDialog(
  BuildContext context,
  List<ReceiptModel> receipts,
) {
  const accentGreen = AddExpenseScreen.accentGreen;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Multiple Receipts Detected'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Successfully processed ${receipts.length} receipts!',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            'Would you like to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...receipts.map(
            (receipt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: accentGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      receipt.merchantName ?? 'Unknown Merchant',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    'RM${receipt.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            final cubit = context.read<AddExpenseCubit>();
            if (cubit.state.multipleReceipts.isNotEmpty) {
              cubit.clearScannedReceipt();
            }
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await _processMultipleReceipts(context, receipts);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Process Now'),
        ),
      ],
    ),
  );
}

Future<void> _processMultipleReceipts(
  BuildContext context,
  List<ReceiptModel> receipts,
) async {
  final addExpenseCubit = context.read<AddExpenseCubit>();
  const accentGreen = AddExpenseScreen.accentGreen;

  for (int i = 0; i < receipts.length; i++) {
    final receipt = receipts[i];

    if (receipts.length > 1 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing receipt ${i + 1} of ${receipts.length}...'),
          duration: const Duration(seconds: 1),
          backgroundColor: accentGreen,
        ),
      );
    }

    if (!context.mounted) break;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: addExpenseCubit,
          child: ManualEntryScreen(receipt: receipt, fromAddExpense: true),
        ),
      ),
    );

    // Save actual updated data back if structural object is returned
    if (result != null) {
      if (result is ReceiptModel) {
        addExpenseCubit.addToRecentUploads(result);
      } else {
        addExpenseCubit.addToRecentUploads(receipt);
      }
    }

    if (result != null && i == receipts.length - 1 && context.mounted) {
      Navigator.pop(context);
    }
  }
}
