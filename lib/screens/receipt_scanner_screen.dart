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

  // Thresholds for blur UI states
  static const _blurWarningThreshold = 2; // Show warning + focus button
  static const _blurFailThreshold = 5; // Show "Enter Manually" escape hatch

  // Prevents the result sheet from being shown more than once per scan
  bool _sheetOpen = false;

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
            state.receiptModel != null &&
            !_sheetOpen) {
          _sheetOpen = true;
          _showResultSheet(context, state.receiptModel!);
        } else if (state.status == ReceiptStatus.error) {
          _showErrorDialog(context, state.errorMessage ?? 'Unknown error');
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

  // ─────────────────────────────────────────────────────────────────────────
  // Show the "Receipt Scanned Successfully" result sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showResultSheet(BuildContext context, ReceiptModel receipt) {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    final receiptCubit = context.read<ReceiptCubit>();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ResultSheet(
          receipt: receipt,

          // "Scan Again" — close sheet and reset cubit so scanning resumes
          onScanAgain: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            receiptCubit.closeDialog();
          },

          // "Edit" — go to ManualEntryScreen with the scanned data pre-filled
          onEdit: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            receiptCubit.closeDialog();
            _goToManualEntry(context, addExpenseCubit, receipt);
          },

          // "Save & Continue" — same as Edit (ManualEntryScreen handles saving)
          onSaveAndContinue: () {
            Navigator.pop(sheetContext);
            _sheetOpen = false;
            receiptCubit.closeDialog();
            _goToManualEntry(context, addExpenseCubit, receipt);
          },
        );
      },
    ).whenComplete(() {
      if (mounted) _sheetOpen = false;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Loading screen while camera initializes
  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────────────
  // Main scanner screen
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScannerScreen(BuildContext context, ReceiptState state) {
    final cubit = context.read<ReceiptCubit>();
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
            icon: const Icon(Icons.center_focus_strong),
            onPressed: cubit.focusAndCapture,
            tooltip: 'Manual focus',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              if (state.detectedTexts.isNotEmpty) {
                _showDebugDialog(context, state.detectedTexts.last);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (cubit.controller != null)
            Positioned.fill(child: CameraPreview(cubit.controller!)),
          _buildScanOverlay(state),
          _buildBottomInstructions(context, state, cubit),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scan overlay box — changes colour and icon based on blur state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildScanOverlay(ReceiptState state) {
    final isBlurry = state.blurryCount > _blurWarningThreshold;
    final isFailing = state.blurryCount > _blurFailThreshold;

    final Color borderColor = isFailing
        ? Colors.red
        : isBlurry
        ? _orange
        : _green;

    final IconData icon = isFailing
        ? Icons.error_outline
        : isBlurry
        ? Icons.warning_amber
        : Icons.camera_alt;

    final String label = isFailing
        ? 'Cannot read receipt'
        : isBlurry
        ? 'Adjust focus...'
        : 'Scanning...';

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: borderColor, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: borderColor,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom instructions — adapts to blur severity
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomInstructions(
    BuildContext context,
    ReceiptState state,
    ReceiptCubit cubit,
  ) {
    final isBlurry = state.blurryCount > _blurWarningThreshold;
    final isFailing = state.blurryCount > _blurFailThreshold;
    final addExpenseCubit = context.read<AddExpenseCubit>();

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.black54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Status message ──────────────────────────────────────────────
            Text(
              isFailing
                  ? '❌ Receipt cannot be read. Try better lighting\nor enter details manually.'
                  : isBlurry
                  ? '⚠️ Receipt is blurry. Hold camera steady or tap focus.'
                  : 'Position receipt within the green box\nAuto-scanning every 2 seconds...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),

            const SizedBox(height: 10),

            // ── Focus button (shown when blurry) ────────────────────────────
            if (isBlurry)
              TextButton.icon(
                onPressed: cubit.focusAndCapture,
                icon: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                ),
                label: const Text(
                  'Tap to refocus',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // ── Tips carousel for blurry state ─────────────────────────────
            if (isBlurry && !isFailing) ...[
              const SizedBox(height: 4),
              const Text(
                '💡 Tips: Lay receipt flat · Avoid shadows · Move closer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],

            // ── Manual entry escape hatch (shown when failing) ──────────────
            if (isFailing) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retry: reset blur count and try again
                  OutlinedButton.icon(
                    onPressed: () {
                      cubit.focusAndCapture();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Manual entry
                  ElevatedButton.icon(
                    onPressed: () =>
                        _goToManualEntry(context, addExpenseCubit, null),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Enter Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Debug dialog — shows raw OCR output
  // ─────────────────────────────────────────────────────────────────────────
  void _showDebugDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: Raw OCR Text'),
        content: SizedBox(
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ReceiptCubit>().clearError();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result bottom sheet widget
// ─────────────────────────────────────────────────────────────────────────────
class _ResultSheet extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback onScanAgain;
  final VoidCallback onEdit;
  final VoidCallback onSaveAndContinue;

  const _ResultSheet({
    required this.receipt,
    required this.onScanAgain,
    required this.onEdit,
    required this.onSaveAndContinue,
  });

  static const _green = Color(0xFF4CAF50);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    final items = receipt.items ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_box,
                          color: _green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Receipt Scanned\nSuccessfully',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Items found badge ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Found ${items.length} item${items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Merchant + Total card ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          label: 'Merchant:',
                          value: receipt.merchantName ?? 'Unknown Store',
                          valueBold: true,
                        ),
                        const Divider(height: 20, thickness: 0.8),
                        _infoRow(
                          label: 'Total Amount:',
                          value: 'RM ${receipt.amount.toStringAsFixed(2)}',
                          valueColor: _green,
                          valueBold: true,
                          valueFontSize: 18,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Items list ───────────────────────────────────────────
                  if (items.isNotEmpty) ...[
                    Text(
                      'Items (${items.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...items.map((item) => _ItemCard(item: item)),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No individual items detected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Secondary actions row ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onScanAgain,
                        child: const Text(
                          'Scan Again',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, color: _green, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Primary CTA ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onSaveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    bool valueBold = false,
    Color? valueColor,
    double valueFontSize = 15,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual item card in the result sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ReceiptItem item;

  const _ItemCard({required this.item});

  static const _green = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Green left accent bar
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Name + category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.category != null && item.category!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.category!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Price
          Text(
            'RM ${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
