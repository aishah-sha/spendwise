import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/receipt_cubit.dart';
import '../cubit/add_expense_cubit.dart';
import '../models/expense_model.dart';
import '../models/receipt_model.dart';
import 'manual_entry_screen.dart';

class ReceiptScannerPage extends StatefulWidget {
  final bool fromAddExpense;

  const ReceiptScannerPage({super.key, this.fromAddExpense = false});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReceiptCubit>().initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptCubit, ReceiptState>(
      listener: (context, state) {
        if (state.status == ReceiptStatus.success &&
            state.receiptModel != null) {
          _showResultDialog(context, state.receiptModel!);
        } else if (state.status == ReceiptStatus.error) {
          _showErrorDialog(context, state.errorMessage ?? "Unknown error");
        }
      },
      builder: (context, state) {
        if (!state.isCameraInitialized) {
          return _buildLoadingScreen();
        }

        return _buildScannerScreen(context, state);
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Initializing camera..."),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerScreen(BuildContext context, ReceiptState state) {
    final cubit = context.read<ReceiptCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Receipt"),
        backgroundColor: const Color(0xFFE8F5E9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.fromAddExpense) {
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: cubit.focusAndCapture,
            tooltip: "Manual focus",
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              if (state.detectedTexts.isNotEmpty) {
                _showDebugDialog(context, state.detectedTexts.last);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: cubit.focusAndCapture,
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(cubit.controller!),
          _buildScanOverlay(state),
          _buildBottomInstructions(state),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(ReceiptState state) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          border: Border.all(
            color: state.blurryCount > 2
                ? Colors.orange
                : const Color(0xFF66BB6A),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.blurryCount > 2 ? Icons.warning_amber : Icons.camera_alt,
                color: state.blurryCount > 2
                    ? Colors.orange
                    : const Color(0xFF66BB6A),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                state.blurryCount > 2 ? "Adjust focus..." : "Scanning...",
                style: TextStyle(
                  color: state.blurryCount > 2
                      ? Colors.orange
                      : const Color(0xFF66BB6A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInstructions(ReceiptState state) {
    final cubit = context.read<ReceiptCubit>();

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black54,
        child: Column(
          children: [
            Text(
              state.blurryCount > 2
                  ? "⚠️ Receipt is blurry. Hold camera steady or tap focus button."
                  : "Position receipt within the green box\nAuto-scanning every 2 seconds",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (state.blurryCount > 2)
              TextButton.icon(
                onPressed: cubit.focusAndCapture,
                icon: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                ),
                label: const Text(
                  "Tap to focus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, ReceiptModel receipt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("✅ Receipt Scanned Successfully"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQualityIndicator(receipt),
                const SizedBox(height: 16),
                _buildMerchantCard(receipt),
                const SizedBox(height: 16),
                _buildItemsHeader(receipt),
                const SizedBox(height: 8),
                _buildItemsList(receipt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print("🔵 Scan Again button pressed");
                Navigator.of(dialogContext).pop();
                context.read<ReceiptCubit>().closeDialog();
              },
              child: const Text("Scan Again"),
            ),
            TextButton.icon(
              onPressed: () async {
                print("🔵 EDIT BUTTON PRESSED");
                print("🔵 fromAddExpense: ${widget.fromAddExpense}");
                print("🔵 Receipt being passed: ${receipt.merchantName}");
                print("🔵 Items count: ${receipt.items?.length ?? 0}");

                // Close the dialog first
                Navigator.of(dialogContext).pop();
                context.read<ReceiptCubit>().closeDialog();

                await Future.delayed(const Duration(milliseconds: 100));

                print("🔵 Navigating to ManualEntryScreen");

                // Get the AddExpenseCubit from parent
                final addExpenseCubit = context.read<AddExpenseCubit>();

                // Navigate to manual entry screen with the cubit
                final editedReceipt = await Navigator.push<ReceiptModel?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: addExpenseCubit),
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                      ],
                      child: ManualEntryScreen(
                        receipt: receipt,
                        fromAddExpense: widget.fromAddExpense,
                      ),
                    ),
                  ),
                );

                print(
                  "🔵 Returned from ManualEntryScreen with: $editedReceipt",
                );

                if (editedReceipt != null && mounted) {
                  // Create expense from edited receipt and save it
                  final expense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: editedReceipt.merchantName ?? 'Unknown Store',
                    category: editedReceipt.items?.first.category ?? 'Food',
                    amount: editedReceipt.amount,
                    date: editedReceipt.date,
                    isIncome: false,
                    note: '${editedReceipt.items?.length ?? 0} items',
                  );

                  // Save to ExpenseCubit (for Dashboard and History)
                  context.read<ExpenseCubit>().addExpense(expense);

                  // Save to AddExpenseCubit (for Recent Uploads)
                  context.read<AddExpenseCubit>().addReceipt(editedReceipt);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense saved successfully'),
                      backgroundColor: Color(0xFF32BA32),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Navigate back
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pop(context, editedReceipt);
                  });
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit"),
            ),
            ElevatedButton(
              onPressed: () {
                print("🔵 Save & Continue button pressed");

                Navigator.of(dialogContext).pop();
                context.read<ReceiptCubit>().closeDialog();

                if (widget.fromAddExpense) {
                  print("🔵 Returning receipt to add expense");

                  // Create expense from receipt and save it directly
                  final expense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: receipt.merchantName ?? 'Unknown Store',
                    category: receipt.items?.first.category ?? 'Food',
                    amount: receipt.amount,
                    date: receipt.date,
                    isIncome: false,
                    note: '${receipt.items?.length ?? 0} items',
                  );

                  // Save to ExpenseCubit (for Dashboard and History)
                  context.read<ExpenseCubit>().addExpense(expense);

                  // Save to AddExpenseCubit (for Recent Uploads)
                  context.read<AddExpenseCubit>().addReceipt(receipt);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense saved successfully'),
                      backgroundColor: Color(0xFF32BA32),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Navigate back to Add Expense screen with success
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pop(context, receipt);
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
              ),
              child: const Text("Save & Continue"),
            ),
          ],
        );
      },
    ).then((_) {
      print("🔵 Dialog closed");
      context.read<ReceiptCubit>().closeDialog();
    });
  }

  Widget _buildQualityIndicator(ReceiptModel receipt) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_camera, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Found ${receipt.items?.length ?? 0} items",
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(ReceiptModel receipt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Merchant:",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            receipt.merchantName ?? "Unknown",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                "RM ${receipt.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsHeader(ReceiptModel receipt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Items (${receipt.items?.length ?? 0})",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildItemsList(ReceiptModel receipt) {
    if (receipt.items == null || receipt.items!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("No items found"),
        ),
      );
    }

    return Column(
      children: receipt.items!.map((item) => _buildItemTile(item)).toList(),
    );
  }

  Widget _buildItemTile(ReceiptItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildCategoryChip(item.category ?? "Uncategorized"),
                    if (item.quantity > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          "x${item.quantity}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _buildPriceColumn(item),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 10, color: Color(0xFF66BB6A)),
      ),
    );
  }

  Widget _buildPriceColumn(ReceiptItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "RM ${item.price.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (item.quantity > 1)
          Text(
            "(@ RM ${item.price.toStringAsFixed(2)})",
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
      ],
    );
  }

  void _showDebugDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug: Raw OCR Text"),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ReceiptCubit>().clearError();
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
