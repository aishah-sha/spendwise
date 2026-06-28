import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/cubit/budget_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';

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

  // UPDATED: More specific item categories - removed "Groceries" as it's too broad
  final List<String> _categories = [
    'Fresh Vegetables',
    'Fresh Meat & Seafood',
    'Cooking Ingredients',
    'Baking Ingredients',
    'Instant Food & Drinks',
    'Beverages',
    'Snacks',
    'Desserts',
    'Household/Groceries',
    'Pet Supplies',
    'Health & Medical',
    'Stationery',
    'Transport',
    'Food',
    'Clothes',
    'Entertainment',
    'Shopping',
    'Bills',
    'Rent',
    'Others',
  ];

  final TextEditingController _newItemNameController = TextEditingController();
  final TextEditingController _newItemPriceController = TextEditingController();
  String _newItemCategory = 'Fresh Vegetables';

  File? _receiptImageFile;

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
    _selectedDate = widget.receipt?.date ?? DateTime.now();

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
          ReceiptItem(
            name: '',
            price: 0.0,
            quantity: 1,
            category: 'Fresh Vegetables',
          ),
        ];
      }

      _amountController.text = widget.receipt!.amount.toStringAsFixed(2);
      _vendorController.text = widget.receipt!.merchantName ?? 'Unknown Store';
      _selectedDate = widget.receipt!.date;

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
        ReceiptItem(
          name: '',
          price: 0.0,
          quantity: 1,
          category: 'Fresh Vegetables',
        ),
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
    _newItemCategory = 'Fresh Vegetables';

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
                            _buildModernDropdown(
                              value: _establishmentType,
                              items: _establishmentTypes,
                              label: 'Store Type Classification',
                              icon: Icons.label_important_outline,
                              isDarkMode: isDarkMode,
                              onChanged: (value) {
                                if (value != null)
                                  setState(() => _establishmentType = value);
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
                          itemBuilder: (context, index) =>
                              _buildModernItemCard(index, isDarkMode),
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
        items: items
            .map(
              (String val) =>
                  DropdownMenuItem<String>(value: val, child: Text(val)),
            )
            .toList(),
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

  // UPDATED: Item card with better category handling
  Widget _buildModernItemCard(int index, bool isDarkMode) {
    final item = _items[index];

    return Container(
      key: ValueKey('item_${index}_${item.hashCode}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF262626) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and delete
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            decoration: BoxDecoration(
              color: _getCategoryColor(item.category).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(
                          item.category,
                        ).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categories.contains(item.category)
                            ? item.category
                            : 'Others',
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: _getCategoryColor(item.category),
                        ),
                        dropdownColor: isDarkMode
                            ? Colors.grey[850]
                            : Colors.white,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
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
                            _updateTotal();
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
                                  size: 18,
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
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
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
          ),

          // Item name and price row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Item Name field
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: item.name)
                      ..selection = TextSelection.collapsed(
                        offset: item.name.length,
                      ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Item name (e.g., Chicken Rice)',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white38 : Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: accentGreen,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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

                const SizedBox(height: 12),

                // Price and Quantity row
                Row(
                  children: [
                    // Price field
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: TextField(
                          controller: TextEditingController(
                            text: item.price > 0
                                ? item.price.toStringAsFixed(2)
                                : '',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: accentGreen,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixText: 'RM ',
                            prefixStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.grey[600],
                            ),
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
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

                    const SizedBox(width: 12),

                    // Quantity controls
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (item.quantity > 1) {
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
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
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
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentGreen.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Subtotal display
                if (item.quantity > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Subtotal: RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Complete category icon mapping
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fresh Vegetables':
        return Icons.agriculture_outlined;
      case 'Fresh Meat & Seafood':
        return Icons.set_meal_outlined;
      case 'Cooking Ingredients':
        return Icons.kitchen_outlined;
      case 'Baking Ingredients':
        return Icons.cake_outlined;
      case 'Instant Food & Drinks':
        return Icons.fastfood_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      case 'Desserts':
        return Icons.icecream_outlined;
      case 'Household/Groceries':
        return Icons.home_outlined;
      case 'Pet Supplies':
        return Icons.pets_outlined;
      case 'Health & Medical':
        return Icons.health_and_safety_outlined;
      case 'Stationery':
        return Icons.edit_note_outlined;
      case 'Transport':
        return Icons.directions_car_filled_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Clothes':
        return Icons.checkroom_outlined;
      case 'Entertainment':
        return Icons.confirmation_number_outlined;
      case 'Shopping':
        return Icons.local_mall_outlined;
      case 'Bills':
        return Icons.receipt_outlined;
      case 'Rent':
        return Icons.home_work_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  // Update _getCategoryColor:
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Fresh Vegetables':
        return const Color(0xFF66BB6A);
      case 'Fresh Meat & Seafood':
        return const Color(0xFFEF5350);
      case 'Cooking Ingredients':
        return const Color(0xFF4DB6AC);
      case 'Baking Ingredients':
        return const Color(0xFFBA68C8);
      case 'Instant Food & Drinks':
        return const Color(0xFFFF7043);
      case 'Beverages':
        return const Color(0xFF2196F3);
      case 'Snacks':
        return const Color(0xFFFF8A80);
      case 'Desserts':
        return const Color(0xFFF06292);
      case 'Household/Groceries':
        return const Color(0xFF4CAF50);
      case 'Pet Supplies':
        return const Color(0xFF8BC34A);
      case 'Health & Medical':
        return const Color(0xFFE57373);
      case 'Stationery':
        return const Color(0xFF009688);
      case 'Transport':
        return const Color(0xFF795548);
      case 'Food':
        return const Color(0xFFFF9800);
      case 'Clothes':
        return const Color(0xFF9C27B0);
      case 'Entertainment':
        return const Color(0xFFE91E63);
      case 'Shopping':
        return const Color(0xFF673AB7);
      case 'Bills':
        return const Color(0xFF607D8B);
      case 'Rent':
        return const Color(0xFF3F51B5);
      default:
        return Colors.blueGrey;
    }
  }

  void _saveForm() async {
    final enteredVendor = _vendorController.text.trim();
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;

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

    // Check if this is editing an existing expense
    if (widget.isEditing && widget.expenseToEdit != null) {
      // UPDATE existing expense
      await _updateExistingExpense();
      return;
    }

    // NEW: Save only when button is pressed
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
      final expenseCubit = context.read<ExpenseCubit>();
      final addExpenseCubit = context.read<AddExpenseCubit>();
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final String chosenCategory = _items.isNotEmpty
          ? _items.first.category
          : 'Others';
      final expenseId = const Uuid().v4();

      if (userId == null) throw Exception('User not logged in');

      // Save to transactions table
      await supabase.from('transactions').insert({
        'id': expenseId,
        'user_id': userId,
        'amount': totalAmount,
        'category': chosenCategory,
        'type': 'expense',
        'description': enteredVendor,
        'title': enteredVendor,
        'note': enteredVendor,
        'date': _selectedDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // Save to receipts table
      await supabase.from('receipts').insert({
        'id': expenseId,
        'user_id': userId,
        'merchant_name': enteredVendor,
        'amount': totalAmount,
        'category': chosenCategory,
        'date': _selectedDate.toIso8601String(),
        'receipt_type': widget.receipt?.receiptType ?? 'manual',
        'image_path': widget.receipt?.imagePath,
        'items': _items.map((item) => item.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
      });

      final generatedReceipt = ReceiptModel(
        id: expenseId,
        date: _selectedDate,
        amount: totalAmount,
        merchantName: enteredVendor,
        category: chosenCategory,
        establishmentType: 'General Retail',
        items: _items,
        imagePath: widget.receipt?.imagePath,
        receiptType: widget.receipt?.receiptType ?? 'manual',
      );

      addExpenseCubit.addToRecentUploads(generatedReceipt);
      await expenseCubit.refreshExpenses();
      await context.read<BudgetCubit>().loadBudget(forceRefresh: true);

      _showSuccessSnackbar('Expense saved successfully!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        _showSnackbar(
          'Error saving expense: ${e.toString()}',
          Theme.of(context).brightness == Brightness.dark,
        );
    }
  }

  // NEW: Method to update existing expense
  Future<void> _updateExistingExpense() async {
    final enteredVendor = _vendorController.text.trim();
    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final expenseId = widget.expenseToEdit!.id;

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
            Text('Updating expense...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final expenseCubit = context.read<ExpenseCubit>();
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final String chosenCategory = _items.isNotEmpty
          ? _items.first.category
          : 'Others';

      if (userId == null) throw Exception('User not logged in');

      // Update transactions table
      await supabase
          .from('transactions')
          .update({
            'amount': totalAmount,
            'category': chosenCategory,
            'description': enteredVendor,
            'title': enteredVendor,
            'note': enteredVendor,
            'date': _selectedDate.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId)
          .eq('user_id', userId);

      // Update receipts table
      await supabase
          .from('receipts')
          .update({
            'merchant_name': enteredVendor,
            'amount': totalAmount,
            'category': chosenCategory,
            'date': _selectedDate.toIso8601String(),
            'items': _items.map((item) => item.toJson()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId)
          .eq('user_id', userId);

      await expenseCubit.refreshExpenses();
      await context.read<BudgetCubit>().loadBudget(forceRefresh: true);

      _showSuccessSnackbar('Expense updated successfully!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        _showSnackbar(
          'Error updating expense: ${e.toString()}',
          Theme.of(context).brightness == Brightness.dark,
        );
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
}
