import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/receipt_cubit.dart';
import '../cubit/add_expense_cubit.dart';
import '../models/receipt_model.dart';
import 'manual_entry_screen.dart';

class ReceiptScannerPage extends StatefulWidget {
  final bool fromAddExpense;

  const ReceiptScannerPage({super.key, this.fromAddExpense = false});

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  static const _green = Color(0xFF4CAF50);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _orange = Color(0xFFFF9800);
  static const _red = Color(0xFFF44336);

  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<ReceiptCubit>().initializeCamera();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptCubit, ReceiptState>(
      listener: (context, state) {
        if (state.status == ReceiptStatus.success &&
            state.receiptModel != null &&
            !_sheetOpen) {
          _sheetOpen = true;
          _showConfirmationSheet(context, state.receiptModel!);
        } else if (state.status == ReceiptStatus.error &&
            state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
          // Reset error after showing
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.read<ReceiptCubit>().clearError();
          });
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

  void _showConfirmationSheet(BuildContext context, ReceiptModel receipt) {
    final receiptCubit = context.read<ReceiptCubit>();
    final addExpenseCubit = context.read<AddExpenseCubit>();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ConfirmationSheet(
          receipt: receipt,
          onEdit: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            _goToManualEntry(context, addExpenseCubit, receipt);
          },
          onScanAgain: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            receiptCubit.resetAndRescan();
          },
          onConfirm: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            // Save the expense
            _saveExpense(context, addExpenseCubit, receipt);
          },
        );
      },
    ).whenComplete(() {
      if (mounted) _sheetOpen = false;
    });
  }

  void _saveExpense(
    BuildContext context,
    AddExpenseCubit cubit,
    ReceiptModel receipt,
  ) {
    // Add to recent uploads
    cubit.addToRecentUploads(receipt);
    print('✅ Scanner: Added to recent uploads');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Receipt processed successfully!'),
        backgroundColor: _green,
        duration: Duration(seconds: 2),
      ),
    );

    // Go back with the receipt
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context, receipt);
    });
  }

  void _goToManualEntry(
    BuildContext context,
    AddExpenseCubit addExpenseCubit,
    ReceiptModel? receipt,
  ) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: addExpenseCubit,
          child: ManualEntryScreen(
            receipt: receipt,
            fromAddExpense: widget.fromAddExpense,
          ),
        ),
      ),
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
            Text('Initializing camera...'),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerScreen(BuildContext context, ReceiptState state) {
    final cubit = context.read<ReceiptCubit>();
    final isProcessing = state.status == ReceiptStatus.scanning;
    final hasError = state.blurryCount > 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: _lightGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cubit.resetAndRescan(),
            tooltip: 'Reset scanner',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              if (state.detectedTexts.isNotEmpty) {
                _showDebugDialog(context, state.detectedTexts.join('\n'));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No text detected yet.')),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (cubit.controller != null && cubit.controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(cubit.controller!))
          else
            Positioned.fill(child: Container(color: Colors.black)),

          // Scanning overlay
          _buildScanOverlay(state, isProcessing, hasError),

          // Bottom instructions
          _buildBottomInstructions(
            context,
            state,
            cubit,
            isProcessing,
            hasError,
          ),

          // Processing indicator
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing receipt...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(
    ReceiptState state,
    bool isProcessing,
    bool hasError,
  ) {
    final borderColor = hasError ? _red : (isProcessing ? _orange : _green);
    final icon = hasError
        ? Icons.error_outline
        : (isProcessing ? Icons.hourglass_empty : Icons.camera_alt);
    final label = hasError
        ? 'Poor quality'
        : (isProcessing ? 'Scanning...' : 'Position receipt here');

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(16),
          color: Colors.black12,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: borderColor, size: 48),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: borderColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 8),
                const Text(
                  'Move to brighter area\nKeep receipt flat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInstructions(
    BuildContext context,
    ReceiptState state,
    ReceiptCubit cubit,
    bool isProcessing,
    bool hasError,
  ) {
    final addExpenseCubit = context.read<AddExpenseCubit>();

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasError
                  ? '❌ Having trouble reading the receipt'
                  : isProcessing
                  ? '⏳ Analyzing receipt data...'
                  : '📸 Auto-scan is active. Position receipt in the box.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),

            if (hasError) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => cubit.resetAndRescan(),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _goToManualEntry(context, addExpenseCubit, null),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Enter Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],

            if (!hasError && !isProcessing)
              const Text(
                '💡 Tips: Good lighting · Flat surface · Hold steady',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDebugDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw OCR Text'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
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

// Confirmation Sheet Widget
class _ConfirmationSheet extends StatefulWidget {
  final ReceiptModel receipt;
  final VoidCallback onEdit;
  final VoidCallback onScanAgain;
  final VoidCallback onConfirm;

  const _ConfirmationSheet({
    required this.receipt,
    required this.onEdit,
    required this.onScanAgain,
    required this.onConfirm,
  });

  @override
  State<_ConfirmationSheet> createState() => _ConfirmationSheetState();
}

class _ConfirmationSheetState extends State<_ConfirmationSheet> {
  late ReceiptModel _receipt;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  /// Helper to return specific icons for the establishment types
  IconData _getEstablishmentIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('restaurant') || t.contains('café') || t.contains('cafe')) {
      return Icons.restaurant_menu;
    } else if (t.contains('book') || t.contains('stationery')) {
      return Icons.menu_book;
    } else if (t.contains('supermarket') || t.contains('convenience')) {
      return Icons.local_grocery_store;
    } else if (t.contains('pharmacy') || t.contains('health')) {
      return Icons.local_pharmacy;
    }
    return Icons.storefront;
  }

  @override
  Widget build(BuildContext context) {
    final items = _receipt.items ?? [];
    final totalAmount = _receipt.amount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: Color(0xFF4CAF50),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // --- VISUAL UI BADGE FOR SUPERVISOR ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Detected: ${_receipt.establishmentType}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Establishment Type Row Card
                  _buildInfoCard(
                    title: 'Establishment Type',
                    value: _receipt.establishmentType,
                    icon: _getEstablishmentIcon(_receipt.establishmentType),
                    highlightColor: Colors.blue[700],
                  ),
                  const SizedBox(height: 12),

                  // Merchant
                  _buildInfoCard(
                    title: 'Merchant',
                    value: _receipt.merchantName ?? 'Unknown',
                    icon: Icons.store,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  _buildInfoCard(
                    title: 'Date',
                    value: _receipt.formattedDate,
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),

                  // Total Amount
                  _buildInfoCard(
                    title: 'Total Amount',
                    value: 'RM ${totalAmount.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    isAmount: true,
                  ),
                  const SizedBox(height: 20),

                  // Items Section
                  if (items.isNotEmpty) ...[
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => _buildItemCard(item)),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onScanAgain,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Scan Again'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            foregroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm & Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isAmount = false,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: highlightColor ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isAmount ? 20 : 16,
                    fontWeight: isAmount || highlightColor != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isAmount
                        ? const Color(0xFF4CAF50)
                        : (highlightColor ?? Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ReceiptItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.quantity > 1)
                      Text(
                        '${item.quantity}x ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    Text(
                      item.category,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'RM ${(item.price).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
