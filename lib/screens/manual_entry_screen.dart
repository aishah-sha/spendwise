import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/widgets/in_app_notification_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import 'dashboard_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  final ReceiptModel? receipt;
  final bool isEditing;
  final ExpenseModel? expenseToEdit;
  final bool fromAddExpense;

  const ManualEntryScreen({
    super.key,
    this.receipt,
    this.isEditing = false,
    this.expenseToEdit,
    this.fromAddExpense = false,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen>
    with SingleTickerProviderStateMixin {
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color accentGreenLight = Color(0xFFE8F7CB);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late DateTime _selectedDate;
  final bool _isIncome = false;

  List<ReceiptItem> _items = [];
  String _establishmentType = 'General Retail';

  // Available Store Classifications
  final List<String> _establishmentTypes = [
    'General Retail',
    'Supermarket / Grocery',
    'Restaurant / F&B',
    'Cafe / Bakery',
    'Gas Station / Convenience',
    'Pharmacy / Medical',
    'Apparel / Fashion',
    'Electronics',
    'Entertainment / Leisure',
    'Online Marketplace',
    'Others',
  ];

  final List<String> _categories = [
    'Groceries',
    'Food',
    'Beverages',
    'Clothes',
    'Stationery',
    'Transport',
    'Entertainment',
    'Shopping',
    'Household',
    'Pet Food',
    'Health',
    'Snacks & Desserts',
    'Cooking Ingredients',
    'Baking',
    'Others',
  ];

  final TextEditingController _newItemNameController = TextEditingController();
  final TextEditingController _newItemPriceController = TextEditingController();
  String _newItemCategory = 'Food';

  File? _receiptImageFile;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    _amountController = TextEditingController();
    _vendorController = TextEditingController();
    _selectedDate = DateTime.now();

    if (widget.receipt != null) {
      if (widget.receipt!.imagePath != null &&
          widget.receipt!.imagePath!.isNotEmpty) {
        try {
          _receiptImageFile = File(widget.receipt!.imagePath!);
        } catch (e) {
          _receiptImageFile = null;
        }
      }

      if (widget.receipt!.items != null && widget.receipt!.items!.isNotEmpty) {
        _items = List.from(widget.receipt!.items!);
      } else {
        _items = [
          ReceiptItem(name: '', price: 0.0, quantity: 1, category: 'Food'),
        ];
      }

      _amountController.text = widget.receipt!.amount.toStringAsFixed(2);
      _vendorController.text = widget.receipt!.merchantName ?? 'Unknown Store';
      _selectedDate = widget.receipt!.date;

      // Ensure fallback if the scanned value isn't in our list definitions
      if (widget.receipt!.establishmentType.isNotEmpty) {
        _establishmentType =
            _establishmentTypes.contains(widget.receipt!.establishmentType)
            ? widget.receipt!.establishmentType
            : 'General Retail';
      }
    } else if (widget.expenseToEdit != null) {
      _items = [
        ReceiptItem(
          name: widget.expenseToEdit!.title,
          price: widget.expenseToEdit!.amount,
          quantity: 1,
          category: widget.expenseToEdit!.category,
        ),
      ];
      _amountController.text = widget.expenseToEdit!.amount.toStringAsFixed(2);
      _vendorController.text = widget.expenseToEdit!.title;
      _selectedDate = widget.expenseToEdit!.date;
    } else {
      _items = [
        ReceiptItem(name: '', price: 0.0, quantity: 1, category: 'Food'),
      ];
      _amountController.text = '0.00';
      _vendorController.text = '';
    }

    _updateCubitFields();
  }

  void _updateCubitFields() {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    addExpenseCubit.updateTitle(_vendorController.text);
    addExpenseCubit.updateAmount(
      double.tryParse(_amountController.text) ?? 0.0,
    );
    addExpenseCubit.updateDate(_selectedDate);
    addExpenseCubit.updateIsIncome(_isIncome);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _newItemNameController.dispose();
    _newItemPriceController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _updateTotal() {
    setState(() {
      _amountController.text = _calculateTotal().toStringAsFixed(2);
    });
    context.read<AddExpenseCubit>().updateAmount(_calculateTotal());
  }

  Future<void> _showAddItemDialog(bool isDarkMode) async {
    _newItemNameController.clear();
    _newItemPriceController.clear();
    _newItemCategory = 'Food';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [accentGreen, Color(0xFF2196F3)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add New Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildModernTextField(
                          controller: _newItemNameController,
                          label: 'Item Name',
                          icon: Icons.shopping_bag_outlined,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _newItemPriceController,
                          label: 'Price (RM)',
                          icon: Icons.attach_money,
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.number,
                          prefixText: 'RM ',
                        ),
                        const SizedBox(height: 16),
                        _buildModernDropdown(
                          value: _newItemCategory,
                          items: _categories,
                          label: 'Category',
                          icon: Icons.category_outlined,
                          isDarkMode: isDarkMode,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _newItemCategory = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? Colors.white70
                                : Colors.grey[600],
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_newItemNameController.text.isNotEmpty &&
                                _newItemPriceController.text.isNotEmpty) {
                              final price = double.tryParse(
                                _newItemPriceController.text,
                              );
                              if (price != null && price > 0) {
                                setState(() {
                                  _items.add(
                                    ReceiptItem(
                                      name: _newItemNameController.text,
                                      price: price,
                                      quantity: 1,
                                      category: _newItemCategory,
                                    ),
                                  );
                                  _updateTotal();
                                });
                                Navigator.pop(context);
                              } else {
                                _showSnackbar(
                                  'Please enter a valid price',
                                  isDarkMode,
                                );
                              }
                            } else {
                              _showSnackbar(
                                'Please fill all fields',
                                isDarkMode,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Add Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSnackbar(String message, bool isDarkMode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDarkMode ? Colors.red[400] : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFullScreenImage() {
    if (_receiptImageFile == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(_receiptImageFile!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.isEditing || widget.expenseToEdit != null;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        bool isDarkMode = (profileState is ProfileLoaded)
            ? profileState.user.isDarkMode
            : false;

        return Theme(
          data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            backgroundColor: isDarkMode ? Colors.black : accentGreenLight,
            appBar: _buildModernAppBar(isEditing, isDarkMode),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isEditing, isDarkMode),
                      const SizedBox(height: 20),
                      _buildReceiptImageSection(isDarkMode),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Expense Details',
                        Icons.receipt_outlined,
                        isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildModernCard(
                        isDarkMode: isDarkMode,
                        children: [
                          _buildModernTextField(
                            controller: _amountController,
                            label: 'Total Amount',
                            icon: Icons.attach_money,
                            isDarkMode: isDarkMode,
                            readOnly: true,
                            prefixText: 'RM ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: accentGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildModernDatePicker(isDarkMode),
                          const SizedBox(height: 12),
                          _buildModernTextField(
                            controller: _vendorController,
                            label: 'Merchant / Store',
                            icon: Icons.store_outlined,
                            isDarkMode: isDarkMode,
                            onChanged: (value) {
                              context.read<AddExpenseCubit>().updateTitle(
                                value,
                              );
                            },
                          ),
                          if (widget.receipt != null) ...[
                            const SizedBox(height: 12),
                            // Interactive Store Type Classification Dropdown
                            _buildModernDropdown(
                              value: _establishmentType,
                              items: _establishmentTypes,
                              label: 'Store Type Classification',
                              icon: Icons.label_important_outline,
                              isDarkMode: isDarkMode,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _establishmentType = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(
                            'Items',
                            Icons.shopping_cart_outlined,
                            isDarkMode,
                          ),
                          _buildAddItemButton(isDarkMode),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        _buildEmptyState(isDarkMode)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return _buildModernItemCard(index, isDarkMode);
                          },
                        ),
                      const SizedBox(height: 24),
                      _buildSaveButton(isEditing, isDarkMode),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isEditing, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accentGreen, Color(0xFF2196F3)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isEditing ? 'Edit Expense' : 'New Expense',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (widget.receipt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt, size: 14, color: accentGreen),
                const SizedBox(width: 4),
                const Text(
                  'Scanned',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isEditing, bool isDarkMode) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      title: Text(
        'SpendWise',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.grey[700],
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemButton(bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddItemDialog(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: accentGreen),
              const SizedBox(width: 4),
              const Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 13,
                  color: accentGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    Function(String)? onChanged,
    TextStyle? style,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style:
            style ??
            TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
            fontSize: 13,
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, size: 20, color: accentGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDatePicker(bool isDarkMode) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: accentGreen,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          context.read<AddExpenseCubit>().updateDate(picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: accentGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDarkMode ? Colors.white60 : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
        onChanged: onChanged,
        items: items.map((String val) {
          return DropdownMenuItem<String>(value: val, child: Text(val));
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, size: 20, color: accentGreen),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildReceiptImageSection(bool isDarkMode) {
    if (_receiptImageFile == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_receiptImageFile!, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                child: Row(
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tap to review scanned image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 40,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No items found',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard(int index, bool isDarkMode) {
    final item = _items[index];

    return Container(
      key: ValueKey('screenshot_style_item_${index}_${item.hashCode}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.category),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isEmpty ? 'New Item' : item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          item.category,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(item.category),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF333333)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                  child: TextFormField(
                    initialValue: item.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Item Name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (newName) {
                      setState(() {
                        _items[index] = ReceiptItem(
                          name: newName,
                          price: item.price,
                          quantity: item.quantity,
                          category: item.category,
                          unitPrice: item.unitPrice,
                        );
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF333333)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                  child: TextFormField(
                    initialValue: item.price > 0
                        ? item.price.toStringAsFixed(2)
                        : '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.grey[700],
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'RM',
                      prefixStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      hintText: '0.00',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      final parsedPrice = double.tryParse(val) ?? 0.0;
                      setState(() {
                        _items[index] = ReceiptItem(
                          name: item.name,
                          price: parsedPrice,
                          quantity: item.quantity,
                          category: item.category,
                          unitPrice: item.unitPrice,
                        );
                        _updateTotal();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF333333)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: item.quantity <= 1
                          ? null
                          : () {
                              setState(() {
                                _items[index] = ReceiptItem(
                                  name: item.name,
                                  price: item.price,
                                  quantity: item.quantity - 1,
                                  category: item.category,
                                  unitPrice: item.unitPrice,
                                );
                                _updateTotal();
                              });
                            },
                    ),
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14, color: accentGreen),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _items[index] = ReceiptItem(
                            name: item.name,
                            price: item.price,
                            quantity: item.quantity + 1,
                            category: item.category,
                            unitPrice: item.unitPrice,
                          );
                          _updateTotal();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF3d2323) : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _items.removeAt(index);
                      _updateTotal();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.8,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categories.contains(item.category)
                    ? item.category
                    : 'Others',
                isDense: true,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
                dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                onChanged: (String? newCategory) {
                  if (newCategory != null) {
                    setState(() {
                      _items[index] = ReceiptItem(
                        name: item.name,
                        price: item.price,
                        quantity: item.quantity,
                        category: newCategory,
                        unitPrice: item.unitPrice,
                      );
                    });
                  }
                },
                items: _categories.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(value),
                          size: 16,
                          color: _getCategoryColor(value),
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Complete _saveForm method with proper refresh
  void _saveForm() async {
    final enteredVendor = _vendorController.text.trim();
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;

    // Validation
    if (enteredVendor.isEmpty) {
      _showSnackbar(
        'Please enter a valid merchant name',
        Theme.of(context).brightness == Brightness.dark,
      );
      return;
    }

    if (totalAmount <= 0) {
      _showSnackbar(
        'Please add at least one valid item with a price',
        Theme.of(context).brightness == Brightness.dark,
      );
      return;
    }

    if (_items.isEmpty || _items.every((item) => item.price <= 0)) {
      _showSnackbar(
        'Please add at least one valid item',
        Theme.of(context).brightness == Brightness.dark,
      );
      return;
    }

    // Determine primary fallback category for the expense
    final String chosenCategory = _items.isNotEmpty
        ? _items.first.category
        : 'Others';

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Saving expense...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      if (widget.isEditing && widget.expenseToEdit != null) {
        final updatedExpense = widget.expenseToEdit!.copyWith(
          amount: totalAmount,
          date: _selectedDate,
          category: chosenCategory,
        );
        await context.read<ExpenseCubit>().updateExpense(updatedExpense);

        if (mounted) {
          _showSuccessSnackbar('Expense updated successfully!');
        }
      } else {
        // Generate the receipt data model for recent local history tracking
        final generatedReceipt = ReceiptModel(
          id: widget.receipt?.id ?? const Uuid().v4(),
          date: _selectedDate,
          amount: totalAmount,
          merchantName: enteredVendor,
          category: chosenCategory,
          establishmentType: _establishmentType,
          items: _items,
          imagePath: widget.receipt?.imagePath,
          receiptType: widget.receipt?.receiptType ?? 'manual',
        );

        // Add to recent uploads if the method exists
        try {
          context.read<AddExpenseCubit>().addToRecentUploads(generatedReceipt);
        } catch (e) {
          debugPrint('AddExpenseCubit.addToRecentUploads not available: $e');
        }

        // Commit the receipt data into ExpenseCubit so it writes to Supabase
        final mappedExpense = ExpenseModel(
          id: generatedReceipt.id,
          title: enteredVendor,
          amount: totalAmount,
          category: chosenCategory,
          date: _selectedDate,
          isIncome: _isIncome,
        );

        await context.read<ExpenseCubit>().addExpense(mappedExpense);

        if (mounted) {
          _showSuccessSnackbar('Expense saved successfully!');
        }
      }

      // CRITICAL FIX: Force refresh the ExpenseCubit to reload from database
      // This ensures the expense appears immediately in all screens
      await context.read<ExpenseCubit>().refreshExpenses();

      // Wait a moment for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Pop with true to indicate success and trigger refresh in previous screen
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving expense: $e');
      if (mounted) {
        _showSnackbar(
          'Error saving expense: ${e.toString()}',
          Theme.of(context).brightness == Brightness.dark,
        );
      }
    }
  }

  Widget _buildSaveButton(bool isEditing, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saveForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Text(
          isEditing ? 'Update Changes' : 'Confirm & Save Expense',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':
        return Icons.local_grocery_store_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Clothes':
        return Icons.checkroom_outlined;
      case 'Stationery':
        return Icons.edit_note_outlined;
      case 'Transport':
        return Icons.directions_car_filled_outlined;
      case 'Entertainment':
        return Icons.confirmation_number_outlined;
      case 'Shopping':
        return Icons.local_mall_outlined;
      case 'Household':
        return Icons.home_outlined;
      case 'Pet Food':
        return Icons.pets_outlined;
      case 'Health':
        return Icons.health_and_safety_outlined;
      case 'Snacks & Desserts':
        return Icons.icecream_outlined;
      case 'Cooking Ingredients':
        return Icons.kitchen_outlined;
      case 'Baking':
        return Icons.cake_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries':
        return const Color(0xFF4CAF50);
      case 'Food':
        return const Color(0xFFFF9800);
      case 'Beverages':
        return const Color(0xFF2196F3);
      case 'Clothes':
        return const Color(0xFF9C27B0);
      case 'Stationery':
        return const Color(0xFF009688);
      case 'Transport':
        return const Color(0xFF795548);
      case 'Entertainment':
        return const Color(0xFFE91E63);
      case 'Shopping':
        return const Color(0xFF673AB7);
      case 'Household':
        return const Color(0xFF00BCD4);
      case 'Pet Food':
        return const Color(0xFF8BC34A);
      case 'Health':
        return const Color(0xFFE57373);
      case 'Snacks & Desserts':
        return const Color(0xFFFF8A80);
      case 'Cooking Ingredients':
        return const Color(0xFF4DB6AC);
      case 'Baking':
        return const Color(0xFFBA68C8);
      default:
        return Colors.blueGrey;
    }
  }
}
