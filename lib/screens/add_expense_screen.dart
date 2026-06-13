import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendwise/cubit/budget_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
                                // CRITICAL FIX: Use BlocBuilder directly, don't pass state
                                const _RecentUploadsList(),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => AddExpenseCubit(),
                child: const AddExpenseScreen(),
              ),
            ),
          );

          if (result == true && context.mounted) {
            await context.read<ExpenseCubit>().refreshExpenses();
            await context.read<budget_cubit.BudgetCubit>().loadBudget(
              forceRefresh: true,
            );
          }
        },
        child: const Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
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
              addExpenseCubit.addToRecentUploads(scannedReceipt);

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

              if (result != null && context.mounted) {
                await context.read<ExpenseCubit>().refreshExpenses();
                await context.read<budget_cubit.BudgetCubit>().loadBudget(
                  forceRefresh: true,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            }
          },
        ),
        const SizedBox(height: 12),
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

            if (result != null && context.mounted) {
              await context.read<ExpenseCubit>().refreshExpenses();
              await context.read<budget_cubit.BudgetCubit>().loadBudget(
                forceRefresh: true,
              );
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            }
          },
        ),
      ],
    );
  }

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

    addExpenseCubit.setLoading(true);

    try {
      final receipt = await mlKitService.processReceiptImage(
        File(pickedFile.path),
        context: context,
      );

      print(
        '📸 Receipt processed: ${receipt.merchantName} - RM${receipt.amount}',
      );

      // CRITICAL: Save to database immediately
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final expenseId = const Uuid().v4();

        // Save to receipts table
        await supabase.from('receipts').insert({
          'id': expenseId,
          'user_id': userId,
          'merchant_name': receipt.merchantName,
          'amount': receipt.amount,
          'category': receipt.category,
          'date': receipt.date.toIso8601String(),
          'receipt_type': 'image',
          'image_path': receipt.imagePath,
          'items': receipt.items?.map((i) => i.toJson()).toList() ?? [],
          'created_at': DateTime.now().toIso8601String(),
        });

        // ALSO save to transactions table so it appears in Dashboard
        await supabase.from('transactions').insert({
          'id': expenseId,
          'user_id': userId,
          'amount': receipt.amount,
          'category': receipt.category,
          'type': 'expense',
          'description': receipt.merchantName,
          'title': receipt.merchantName,
          'note': receipt.merchantName,
          'date': receipt.date.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ Auto-saved to both tables');
      }

      addExpenseCubit.setLoading(false);
      addExpenseCubit.addToRecentUploads(receipt);

      // Navigate to manual entry for editing
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: addExpenseCubit,
            child: ManualEntryScreen(receipt: receipt, fromAddExpense: true),
          ),
        ),
      );

      if (result != null && context.mounted) {
        await context.read<ExpenseCubit>().refreshExpenses();
        await context.read<BudgetCubit>().loadBudget(forceRefresh: true);
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      addExpenseCubit.setLoading(false);
      _showErrorDialog(context, 'Failed to process image: $e');
    }
  }

  Future<void> _handleUploadMultiple(BuildContext context) async {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    final mlKitService = MLKitService();

    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 90,
    );

    if (pickedFiles.isEmpty) return;

    addExpenseCubit.setLoading(true);

    try {
      for (final file in pickedFiles) {
        final receipt = await mlKitService.processReceiptImage(
          File(file.path),
          context: context,
        );
        addExpenseCubit.addToRecentUploads(receipt);
      }

      addExpenseCubit.setLoading(false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} receipts uploaded!'),
            backgroundColor: accentGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      addExpenseCubit.setLoading(false);
      _showErrorDialog(context, 'Failed to process images: $e');
    }
  }

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

// ============================================================
// SEPARATE WIDGET FOR RECENT UPLOADS WITH ITS OWN BLOC BUILDER
// ============================================================
class _RecentUploadsList extends StatelessWidget {
  const _RecentUploadsList();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ProfileCubit>().state is ProfileLoaded
        ? (context.read<ProfileCubit>().state as ProfileLoaded).user.isDarkMode
        : false;

    return BlocBuilder<AddExpenseCubit, AddExpenseState>(
      builder: (context, state) {
        print(
          '🟡 _RecentUploadsList BLOC BUILDER - Count: ${state.recentUploads.length}',
        );

        if (state.recentUploads.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[850]
                  : AddExpenseScreen.headerColor,
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
            return _RecentUploadItem(receipt: receipt, isDarkMode: isDarkMode);
          }).toList(),
        );
      },
    );
  }
}

class _RecentUploadItem extends StatelessWidget {
  final ReceiptModel receipt;
  final bool isDarkMode;

  const _RecentUploadItem({required this.receipt, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
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
            _buildThumbnail(),
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
                      color: isDarkMode
                          ? Colors.white
                          : AddExpenseScreen.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receipt.categorySummary,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white60
                          : AddExpenseScreen.darkText.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receipt.formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode
                          ? Colors.white38
                          : AddExpenseScreen.darkText.withOpacity(0.4),
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
                    color: AddExpenseScreen.accentGreen,
                  ),
                ),
                if (receipt.items != null && receipt.items!.isNotEmpty)
                  Text(
                    '${receipt.totalItemCount} items',
                    style: TextStyle(
                      fontSize: 10,
                      color: AddExpenseScreen.darkText.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final path = receipt.imagePath;
    if (path != null && File(path).existsSync()) {
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
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AddExpenseScreen.accentGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.receipt,
        color: AddExpenseScreen.accentGreen,
        size: 30,
      ),
    );
  }
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
