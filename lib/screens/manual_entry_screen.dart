import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../models/receipt_model.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart'; // Add this import
// Add other screen imports as needed

class ManualEntryScreen extends StatefulWidget {
  final ReceiptModel? receipt;

  const ManualEntryScreen({super.key, this.receipt});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late DateTime _selectedDate;

  // List of items
  late List<ReceiptItem> _items;
  late List<TextEditingController> _itemNameControllers;
  late List<TextEditingController> _itemPriceControllers;
  late List<TextEditingController> _itemQuantityControllers;
  late List<String> _itemCategories;
  late List<TextEditingController> _itemCategoryControllers;

  final List<String> _categories = [
    'Food',
    'Detergent',
    'Stationery',
    'Transport',
    'Shopping',
    'Entertainment',
    'Groceries',
    'Utilities',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize items from receipt or create empty list
    if (widget.receipt?.items != null && widget.receipt!.items!.isNotEmpty) {
      _items = List.from(widget.receipt!.items!);
    } else {
      _items = [ReceiptItem(name: '', price: 0.0, quantity: 1)];
    }

    // Initialize controllers for each item
    _initializeItemControllers();

    _amountController = TextEditingController(
      text: widget.receipt != null
          ? widget.receipt!.amount.toStringAsFixed(2)
          : _calculateTotal().toStringAsFixed(2),
    );

    _vendorController = TextEditingController(
      text: widget.receipt?.merchantName ?? '',
    );

    _selectedDate = widget.receipt?.date ?? DateTime.now();
  }

  void _initializeItemControllers() {
    _itemNameControllers = _items
        .map((item) => TextEditingController(text: item.name))
        .toList();

    _itemPriceControllers = _items
        .map(
          (item) => TextEditingController(text: item.price.toStringAsFixed(2)),
        )
        .toList();

    _itemQuantityControllers = _items
        .map((item) => TextEditingController(text: item.quantity.toString()))
        .toList();

    // Initialize categories for each item
    _itemCategories = _items.map((item) => item.category ?? 'Food').toList();

    _itemCategoryControllers = _items
        .map((item) => TextEditingController(text: item.category ?? 'Food'))
        .toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();

    // Dispose all item controllers
    for (var controller in _itemNameControllers) {
      controller.dispose();
    }
    for (var controller in _itemPriceControllers) {
      controller.dispose();
    }
    for (var controller in _itemQuantityControllers) {
      controller.dispose();
    }
    for (var controller in _itemCategoryControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  double _calculateTotal() {
    double total = 0.0;
    for (int i = 0; i < _items.length; i++) {
      double price = double.tryParse(_itemPriceControllers[i].text) ?? 0.0;
      int quantity = int.tryParse(_itemQuantityControllers[i].text) ?? 1;
      total += price * quantity;
    }
    return total;
  }

  void _updateTotal() {
    setState(() {
      _amountController.text = _calculateTotal().toStringAsFixed(2);
    });
  }

  void _addNewItem() {
    setState(() {
      _items.add(ReceiptItem(name: '', price: 0.0, quantity: 1));
      _itemNameControllers.add(TextEditingController());
      _itemPriceControllers.add(TextEditingController(text: '0.00'));
      _itemQuantityControllers.add(TextEditingController(text: '1'));
      _itemCategories.add('Food');
      _itemCategoryControllers.add(TextEditingController(text: 'Food'));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _itemNameControllers[index].dispose();
      _itemPriceControllers[index].dispose();
      _itemQuantityControllers[index].dispose();
      _itemCategoryControllers[index].dispose();

      _itemNameControllers.removeAt(index);
      _itemPriceControllers.removeAt(index);
      _itemQuantityControllers.removeAt(index);
      _itemCategories.removeAt(index);
      _itemCategoryControllers.removeAt(index);

      _updateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // Add FAB for consistency with other screens
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
            // Navigate to add expense screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => AddExpenseCubit(),
                  child: const AddExpenseScreen(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add, color: accentGreen, size: 45),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildTopHeader(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Manual Entry',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 20),

            // Receipt Image at the TOP - with placeholder if no image
            _buildReceiptImage(),

            const SizedBox(height: 24),

            // EXPENSE DETAILS SECTION (at the top)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'EXPENSE DETAILS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Total Amount Field
            Container(
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  labelStyle: TextStyle(
                    color: darkText.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  prefixText: 'RM ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: accentGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Date Field
            Container(
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
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
                            surface: headerColor,
                            onSurface: darkText,
                          ),
                          dialogBackgroundColor: headerColor,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkText.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.calendar_today, color: accentGreen, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Vendor Field
            Container(
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor',
                  labelStyle: TextStyle(
                    color: darkText.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  hintText: 'Store name',
                  hintStyle: TextStyle(color: darkText.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: darkText),
              ),
            ),

            const SizedBox(height: 24),

            // ITEMS LIST SECTION (below expense details)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ITEMS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewItem,
                    icon: Icon(Icons.add_circle, color: accentGreen, size: 20),
                    label: Text(
                      'Add Item',
                      style: TextStyle(color: accentGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: BorderRadius.circular(12),
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
                      // Item Header with remove button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    _itemCategories[index],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getCategoryIcon(_itemCategories[index]),
                                  size: 14,
                                  color: _getCategoryColor(
                                    _itemCategories[index],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Item ${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () => _removeItem(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Item Name Field
                      TextField(
                        controller: _itemNameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: TextStyle(
                            color: darkText.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          hintText: 'e.g., Imperial Roll Shrimp Springroll',
                          hintStyle: TextStyle(
                            color: darkText.withOpacity(0.4),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, color: darkText),
                        onChanged: (value) {
                          _items[index] = ReceiptItem(
                            name: value,
                            price:
                                double.tryParse(
                                  _itemPriceControllers[index].text,
                                ) ??
                                0.0,
                            quantity:
                                int.tryParse(
                                  _itemQuantityControllers[index].text,
                                ) ??
                                1,
                            category: _itemCategories[index],
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Category Dropdown for each item
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _itemCategories[index],
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(
                              color: darkText.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
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
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _itemCategories[index] = value!;
                              _itemCategoryControllers[index].text = value;
                              _items[index] = ReceiptItem(
                                name: _itemNameControllers[index].text,
                                price:
                                    double.tryParse(
                                      _itemPriceControllers[index].text,
                                    ) ??
                                    0.0,
                                quantity:
                                    int.tryParse(
                                      _itemQuantityControllers[index].text,
                                    ) ??
                                    1,
                                category: value,
                              );
                            });
                          },
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: accentGreen,
                            size: 18,
                          ),
                          dropdownColor: headerColor,
                          style: const TextStyle(fontSize: 13, color: darkText),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Item Price and Quantity Row
                      Row(
                        children: [
                          // Quantity
                          Expanded(
                            child: TextField(
                              controller: _itemQuantityControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Qty',
                                labelStyle: TextStyle(
                                  color: darkText.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkText,
                              ),
                              onChanged: (value) {
                                int qty = int.tryParse(value) ?? 1;
                                _items[index] = ReceiptItem(
                                  name: _itemNameControllers[index].text,
                                  price:
                                      double.tryParse(
                                        _itemPriceControllers[index].text,
                                      ) ??
                                      0.0,
                                  quantity: qty,
                                  category: _itemCategories[index],
                                );
                                _updateTotal();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Price
                          Expanded(
                            child: TextField(
                              controller: _itemPriceControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                labelStyle: TextStyle(
                                  color: darkText.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                prefixText: 'RM ',
                                prefixStyle: TextStyle(
                                  fontSize: 14,
                                  color: accentGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkText,
                              ),
                              onChanged: (value) {
                                double price = double.tryParse(value) ?? 0.0;
                                _items[index] = ReceiptItem(
                                  name: _itemNameControllers[index].text,
                                  price: price,
                                  quantity:
                                      int.tryParse(
                                        _itemQuantityControllers[index].text,
                                      ) ??
                                      1,
                                  category: _itemCategories[index],
                                );
                                _updateTotal();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Item Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Item Total: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: darkText.withOpacity(0.6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'RM ${(double.tryParse(_itemPriceControllers[index].text) ?? 0.0) * (int.tryParse(_itemQuantityControllers[index].text) ?? 1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentGreen,
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

            const SizedBox(height: 24),

            // Save Expense Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  _saveExpense(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // New method to build receipt image with placeholder
  Widget _buildReceiptImage() {
    // Check if image path exists
    if (widget.receipt?.imagePath != null) {
      // Try to load the image
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(widget.receipt!.imagePath!),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Show placeholder if image fails to load
              return _buildNoImagePlaceholder();
            },
          ),
        ),
      );
    } else {
      // Show placeholder if no image path
      return _buildNoImagePlaceholder();
    }
  }

  // No Image Placeholder Widget
  Widget _buildNoImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 60,
            color: accentGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Receipt Image',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: darkText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Receipt preview not available',
            style: TextStyle(fontSize: 12, color: darkText.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: headerColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to statistics screen
                  print('Chart icon tapped');
                  // TODO: Navigate to statistics screen
                },
                child: const Icon(Icons.bar_chart, size: 28),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  // Navigate to notifications screen
                  print('Notifications icon tapped');
                  // TODO: Navigate to notifications screen
                },
                child: const Icon(Icons.notifications, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated bottom navigation with working navigation
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
            // Home nav item
            _navItem(Icons.home, 'Home', false, () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            }),
            // History nav item
            _navItem(Icons.history, 'History', false, () {
              print('History tapped');
              // TODO: Navigate to history screen
            }),
            const SizedBox(width: 40), // Space for FAB
            // Budget nav item
            _navItem(Icons.savings, 'Budget', false, () {
              print('Budget tapped');
              // TODO: Navigate to budget screen
            }),
            // Profile nav item
            _navItem(Icons.person, 'Profile', false, () {
              print('Profile tapped');
              // TODO: Navigate to profile screen
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

  void _saveExpense(BuildContext context) {
    // Validate at least one item
    bool hasValidItem = false;
    for (int i = 0; i < _items.length; i++) {
      if (_itemNameControllers[i].text.isNotEmpty &&
          double.tryParse(_itemPriceControllers[i].text) != null &&
          double.parse(_itemPriceControllers[i].text) > 0) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense saved successfully'),
        backgroundColor: accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back after save
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }
}
