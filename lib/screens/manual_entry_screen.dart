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

    return MultiBlocProvider(
      providers: [BlocProvider.value(value: context.read<ProfileCubit>())],
      child: BlocBuilder<ProfileCubit, ProfileState>(
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
      ),
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
                Icon(Icons.receipt, size: 14, color: accentGreen),
                const SizedBox(width: 4),
                Text(
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
              Icon(Icons.add, size: 16, color: accentGreen),
              const SizedBox(width: 4),
              Text(
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

  Widget _buildModernCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: Column(children: children),
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
                colorScheme: ColorScheme.light(
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
              Icon(Icons.calendar_today, size: 20, color: accentGreen),
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
        initialValue: value,
        dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.grey[600],
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, size: 20, color: accentGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(item),
                  size: 16,
                  color: _getCategoryColor(item),
                ),
                const SizedBox(width: 8),
                Text(
                  item,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernItemCard(int index, bool isDarkMode) {
    if (index < 0 || index >= _items.length) return const SizedBox.shrink();

    ReceiptItem item = _items[index];

    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getCategoryColor(item.category ?? 'Food'),
                              _getCategoryColor(
                                item.category ?? 'Food',
                              ).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(item.category ?? 'Food'),
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.isEmpty ? 'Unnamed Item' : item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  item.category ?? 'Food',
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category ?? 'Food',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getCategoryColor(
                                    item.category ?? 'Food',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentGreen,
                            ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              '${item.quantity} x RM ${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInlineTextField(
                          initialValue: item.name,
                          hint: 'Item name',
                          isDarkMode: isDarkMode,
                          onChanged: (value) {
                            if (index < _items.length) {
                              setState(() {
                                _items[index] = ReceiptItem(
                                  name: value,
                                  price: item.price,
                                  quantity: item.quantity,
                                  category: item.category ?? 'Food',
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: _buildInlineTextField(
                          initialValue: item.price.toStringAsFixed(2),
                          hint: 'Price',
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.number,
                          prefixText: 'RM',
                          onChanged: (value) {
                            if (index < _items.length) {
                              double newPrice =
                                  double.tryParse(value) ?? item.price;
                              setState(() {
                                _items[index] = ReceiptItem(
                                  name: item.name,
                                  price: newPrice,
                                  quantity: item.quantity,
                                  category: item.category ?? 'Food',
                                );
                                _updateTotal();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: _buildInlineTextField(
                          initialValue: item.quantity.toString(),
                          hint: 'Qty',
                          isDarkMode: isDarkMode,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (index < _items.length) {
                              int newQty = int.tryParse(value) ?? 1;
                              setState(() {
                                _items[index] = ReceiptItem(
                                  name: item.name,
                                  price: item.price,
                                  quantity: newQty,
                                  category: item.category ?? 'Food',
                                );
                                _updateTotal();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (_items.length > 1) {
                            setState(() {
                              _items.removeAt(index);
                              _updateTotal();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: isDarkMode ? Colors.white60 : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categories.contains(item.category)
                            ? item.category
                            : _categories.first,
                        isExpanded: true,
                        dropdownColor: isDarkMode
                            ? Colors.grey[850]
                            : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: isDarkMode ? Colors.white60 : Colors.grey[500],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 14,
                                  color: _getCategoryColor(category),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && index < _items.length) {
                            setState(() {
                              _items[index] = ReceiptItem(
                                name: item.name,
                                price: item.price,
                                quantity: item.quantity,
                                category: value,
                              );
                            });
                            if (index == 0) {
                              context.read<AddExpenseCubit>().updateCategory(
                                value,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineTextField({
    required String initialValue,
    required String hint,
    required bool isDarkMode,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(
        fontSize: 13,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white38 : Colors.grey[400],
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white60 : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentGreen),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildReceiptImageSection(bool isDarkMode) {
    if (_receiptImageFile != null) {
      return GestureDetector(
        onTap: _showFullScreenImage,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.file(
                  _receiptImageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Receipt',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.zoom_out_map,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: isDarkMode ? Colors.white30 : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No items added yet',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Item" to start',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _saveExpense(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEditing ? Icons.update : Icons.check_circle, size: 20),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Update Expense' : 'Save Expense',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense(BuildContext context) async {
    bool hasValidItem = false;
    for (var item in _items) {
      if (item.name.isNotEmpty && item.price > 0) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      _showSnackbar('Please add at least one valid item', false);
      return;
    }

    if (_vendorController.text.isEmpty) {
      _showSnackbar('Please enter a vendor name', false);
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      _showSnackbar('User not authenticated', false);
      return;
    }

    final String expenseId = widget.expenseToEdit?.id ?? const Uuid().v4();
    final double totalAmount = _calculateTotal();
    final String selectedCategory = _items.first.category ?? 'Food';

    final expense = ExpenseModel(
      id: expenseId,
      title: _vendorController.text,
      category: selectedCategory,
      amount: totalAmount,
      date: _selectedDate,
      isIncome: _isIncome,
      note: '${_items.length} items',
      userId: userId,
    );

    final expenseCubit = context.read<ExpenseCubit>();
    final addExpenseCubit = context.read<AddExpenseCubit>();

    // 1. CHECK BUDGET LIMITS HERE BEFORE SAVING & LEAVING THE SCREEN
    _checkBudgetLimitAndNotify(context, selectedCategory, totalAmount);

    if (widget.isEditing || widget.expenseToEdit != null) {
      await expenseCubit.updateExpense(expense);
    } else {
      await expenseCubit.addExpense(expense);
    }

    final receipt = ReceiptModel(
      id: expenseId,
      date: expense.date,
      amount: expense.amount,
      receiptType: 'manual',
      merchantName: expense.title,
      items: _items,
      imagePath: widget.receipt?.imagePath,
      userId: userId,
      processed: false,
    );

    await addExpenseCubit.addReceipt(receipt);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Expense updated successfully!'
                : 'Expense saved successfully!',
          ),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          if (widget.fromAddExpense) {
            Navigator.pop(context, receipt);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: expenseCubit,
                  child: const DashboardScreen(),
                ),
              ),
              (route) => false,
            );
          }
        }
      });
    }
  }

  // 2. ADD THIS NEW HELPER METHOD DIRECTLY UNDER _saveExpense
  void _checkBudgetLimitAndNotify(
    BuildContext context,
    String category,
    double newExpenseAmount,
  ) {
    // TODO: Connect this to your actual Budget Cubit/State management
    // For now, here is a mock test scenario:
    double typicalCategoryLimit = 500.00;
    double alreadySpentInMonth = 480.00;

    double simulatedTotalAfterSaving = alreadySpentInMonth + newExpenseAmount;

    // If the new total breaks the budget wall, show the floating notification card
    if (simulatedTotalAfterSaving > typicalCategoryLimit) {
      InAppNotificationOverlay.showOverLimit(
        context,
        category: category,
        spent: simulatedTotalAfterSaving,
        limit: typicalCategoryLimit,
        duration: const Duration(seconds: 6),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':
        return Icons.shopping_cart_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Clothes':
        return Icons.shopping_bag_outlined;
      case 'Stationery':
        return Icons.edit_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
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
        return const Color(0xFFF44336);
      case 'Snacks & Desserts':
        return const Color(0xFFFF5722);
      case 'Cooking Ingredients':
        return const Color(0xFFCDDC39);
      case 'Baking':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
