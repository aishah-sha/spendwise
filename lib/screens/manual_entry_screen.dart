import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  final ReceiptModel? receipt;
  final bool isEditing;
  final ExpenseModel? expenseToEdit;

  const ManualEntryScreen({
    super.key,
    this.receipt,
    this.isEditing = false,
    this.expenseToEdit,
  });

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
  bool _isIncome = false;

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
    'Supplies',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Check if we're editing an existing expense
    if (widget.expenseToEdit != null) {
      _initializeFromExpense(widget.expenseToEdit!);
    }
    // Check if we have a receipt from scan/upload
    else if (widget.receipt != null) {
      _initializeFromReceipt(widget.receipt!);
    } else {
      _initializeEmpty();
    }

    // Update the AddExpenseCubit form fields
    _updateCubitFields();
  }

  void _initializeFromExpense(ExpenseModel expense) {
    // Create a single item from the expense
    _items = [
      ReceiptItem(
        name: expense.title,
        price: expense.amount,
        quantity: 1,
        category: expense.category,
      ),
    ];

    _initializeItemControllers();

    _amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );

    _vendorController = TextEditingController(text: expense.title);

    _selectedDate = expense.date;
    _isIncome = expense.isIncome ?? false;
  }

  void _initializeFromReceipt(ReceiptModel receipt) {
    if (receipt.items != null && receipt.items!.isNotEmpty) {
      _items = List.from(receipt.items!);
    } else {
      _items = [ReceiptItem(name: '', price: 0.0, quantity: 1)];
    }

    _initializeItemControllers();

    _amountController = TextEditingController(
      text: receipt.amount.toStringAsFixed(2),
    );

    _vendorController = TextEditingController(text: receipt.merchantName ?? '');

    _selectedDate = receipt.date;
  }

  void _initializeEmpty() {
    _items = [ReceiptItem(name: '', price: 0.0, quantity: 1)];
    _initializeItemControllers();
    _amountController = TextEditingController(text: '0.00');
    _vendorController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  void _initializeItemControllers() {
    _itemNameControllers = _items
        .map((item) => TextEditingController(text: item.name ?? ''))
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

  void _updateCubitFields() {
    final addExpenseCubit = context.read<AddExpenseCubit>();
    addExpenseCubit.updateTitle(_vendorController.text);
    addExpenseCubit.updateAmount(
      double.tryParse(_amountController.text) ?? 0.0,
    );
    addExpenseCubit.updateDate(_selectedDate);
    addExpenseCubit.updateIsIncome(_isIncome);

    if (_items.isNotEmpty) {
      addExpenseCubit.updateCategory(_itemCategories.first);
    }
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
    context.read<AddExpenseCubit>().updateAmount(_calculateTotal());
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
    final bool isEditing = widget.isEditing || widget.expenseToEdit != null;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 25),
        height: 70,
        width: 70,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _buildTopHeader(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), // Reduced from 20 to 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dynamic title - REDUCED FONT SIZE
            Text(
              isEditing ? 'Edit Expense' : 'Manual Entry',
              style: const TextStyle(
                fontSize: 22, // Reduced from 28 to 22
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20 to 16
            // Receipt Image
            _buildReceiptImage(),

            const SizedBox(height: 20), // Reduced from 24 to 20
            // EXPENSE DETAILS SECTION
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ), // Reduced from 8 to 6
              child: const Text(
                'EXPENSE DETAILS',
                style: TextStyle(
                  fontSize: 14, // Reduced from 16 to 14
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ),

            const SizedBox(height: 6), // Reduced from 8 to 6
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
                    fontSize: 13, // Reduced from 14 to 13
                  ),
                  prefixText: 'RM ',
                  prefixStyle: const TextStyle(
                    fontSize: 15, // Reduced from 16 to 15
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
                    horizontal: 14, // Reduced from 16 to 14
                    vertical: 14, // Reduced from 16 to 14
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15, // Reduced from 16 to 15
                  fontWeight: FontWeight.bold,
                  color: accentGreen,
                ),
              ),
            ),

            const SizedBox(height: 10), // Reduced from 12 to 10
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
                    context.read<AddExpenseCubit>().updateDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, // Reduced from 16 to 14
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
                                fontSize: 13, // Reduced from 14 to 13
                                color: darkText.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15, // Reduced from 16 to 15
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: accentGreen,
                        size: 18,
                      ), // Reduced from 20 to 18
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10), // Reduced from 12 to 10
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
                    fontSize: 13, // Reduced from 14 to 13
                  ),
                  hintText: 'Store name',
                  hintStyle: TextStyle(
                    color: darkText.withOpacity(0.4),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, // Reduced from 16 to 14
                    vertical: 14, // Reduced from 16 to 14
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: darkText,
                ), // Reduced from 16 to 15
                onChanged: (value) {
                  context.read<AddExpenseCubit>().updateTitle(value);
                },
              ),
            ),

            const SizedBox(height: 10), // Reduced from 12 to 10
            // Income/Expense Toggle
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
            ),

            const SizedBox(height: 20), // Reduced from 24 to 20
            // ITEMS LIST SECTION
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ), // Reduced from 8 to 6
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ITEMS',
                    style: TextStyle(
                      fontSize: 14, // Reduced from 16 to 14
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewItem,
                    icon: Icon(
                      Icons.add_circle,
                      color: accentGreen,
                      size: 18,
                    ), // Reduced from 20 to 18
                    label: Text(
                      'Add Item',
                      style: TextStyle(
                        color: accentGreen,
                        fontSize: 13,
                      ), // Added fontSize
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6), // Reduced from 8 to 6
            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ), // Reduced from 16 to 12
                  padding: const EdgeInsets.all(12), // Reduced from 16 to 12
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
                                padding: const EdgeInsets.all(
                                  4,
                                ), // Reduced from 6 to 4
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    _itemCategories[index],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    4,
                                  ), // Reduced from 6 to 4
                                ),
                                child: Icon(
                                  _getCategoryIcon(_itemCategories[index]),
                                  size: 12, // Reduced from 14 to 12
                                  color: _getCategoryColor(
                                    _itemCategories[index],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6), // Reduced from 8 to 6
                              Text(
                                'Item ${index + 1}',
                                style: TextStyle(
                                  fontSize: 13, // Reduced from 14 to 13
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
                                size: 18, // Reduced from 20 to 18
                              ),
                              onPressed: () => _removeItem(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity
                                  .compact, // Make button more compact
                            ),
                        ],
                      ),
                      const SizedBox(height: 8), // Reduced from 12 to 8
                      // Item Name Field
                      TextField(
                        controller: _itemNameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: TextStyle(
                            color: darkText.withOpacity(0.6),
                            fontSize: 11, // Reduced from 12 to 11
                          ),
                          hintText: 'e.g., Imperial Roll',
                          hintStyle: TextStyle(
                            color: darkText.withOpacity(0.4),
                            fontSize: 11, // Reduced from 12 to 11
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Reduced from 8 to 6
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, // Reduced from 12 to 10
                            vertical: 10, // Reduced from 12 to 10
                          ),
                          isDense: true, // Make text field more compact
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: darkText,
                        ), // Reduced from 14 to 13
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
                      const SizedBox(height: 8), // Reduced from 10 to 8
                      // Category Dropdown for each item
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(
                            6,
                          ), // Reduced from 8 to 6
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _itemCategories[index],
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(
                              color: darkText.withOpacity(0.6),
                              fontSize: 11, // Reduced from 12 to 11
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                6,
                              ), // Reduced from 8 to 6
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, // Reduced from 12 to 10
                              vertical: 2, // Reduced from 4 to 2
                            ),
                            isDense: true,
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 12, // Reduced from 14 to 12
                                    color: _getCategoryColor(category),
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ), // Reduced from 6 to 4
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12, // Reduced from 13 to 12
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _itemCategories[index] = value;
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
                              // Update cubit with first item's category (for main expense)
                              if (index == 0) {
                                context.read<AddExpenseCubit>().updateCategory(
                                  value,
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: accentGreen,
                            size: 16, // Reduced from 18 to 16
                          ),
                          dropdownColor: headerColor,
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkText,
                          ), // Reduced from 13 to 12
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced from 10 to 8
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
                                  fontSize: 11, // Reduced from 12 to 11
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    6,
                                  ), // Reduced from 8 to 6
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, // Reduced from 12 to 10
                                  vertical: 8, // Reduced from 12 to 8
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13, // Reduced from 14 to 13
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
                          const SizedBox(width: 6), // Reduced from 8 to 6
                          // Price
                          Expanded(
                            child: TextField(
                              controller: _itemPriceControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price',
                                labelStyle: TextStyle(
                                  color: darkText.withOpacity(0.6),
                                  fontSize: 11, // Reduced from 12 to 11
                                ),
                                prefixText: 'RM ',
                                prefixStyle: TextStyle(
                                  fontSize: 13, // Reduced from 14 to 13
                                  color: accentGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    6,
                                  ), // Reduced from 8 to 6
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.7),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, // Reduced from 12 to 10
                                  vertical: 8, // Reduced from 12 to 8
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontSize: 13, // Reduced from 14 to 13
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

                      const SizedBox(height: 6), // Reduced from 8 to 6
                      // Item Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Item Total: ',
                            style: TextStyle(
                              fontSize: 11, // Reduced from 12 to 11
                              color: darkText.withOpacity(0.6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, // Reduced from 8 to 6
                              vertical: 1, // Reduced from 2 to 1
                            ),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Reduced from 12 to 10
                            ),
                            child: Text(
                              'RM ${((double.tryParse(_itemPriceControllers[index].text) ?? 0.0) * (int.tryParse(_itemQuantityControllers[index].text) ?? 1)).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11, // Reduced from 12 to 11
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

            const SizedBox(height: 20), // Reduced from 24 to 20
            // Save Expense Button
            SizedBox(
              width: double.infinity,
              height: 48, // Reduced from 55 to 48
              child: ElevatedButton(
                onPressed: () {
                  _saveExpense(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Reduced from 12 to 10
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ), // Reduced from 16 to 15
                ),
              ),
            ),

            const SizedBox(height: 16), // Reduced from 20 to 16
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptImage() {
    if (widget.receipt?.imagePath != null) {
      return Container(
        width: double.infinity,
        height: 160, // Reduced from 200 to 160
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.circular(12), // Reduced from 16 to 12
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, // Reduced from 10 to 8
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Reduced from 16 to 12
          child: Image.file(
            File(widget.receipt!.imagePath!),
            width: double.infinity,
            height: 160, // Reduced from 200 to 160
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildNoImagePlaceholder();
            },
          ),
        ),
      );
    } else {
      return _buildNoImagePlaceholder();
    }
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 160, // Reduced from 200 to 160
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12), // Reduced from 16 to 12
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reduced from 10 to 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48, // Reduced from 60 to 48
            color: accentGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 8), // Reduced from 12 to 8
          Text(
            'No Receipt Image',
            style: TextStyle(
              fontSize: 14, // Reduced from 16 to 14
              fontWeight: FontWeight.w500,
              color: darkText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4 to 2
          Text(
            widget.expenseToEdit != null
                ? 'Editing existing expense'
                : 'Receipt preview not available',
            style: TextStyle(
              fontSize: 11,
              color: darkText.withOpacity(0.4),
            ), // Reduced from 12 to 11
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
                  // Typically an X icon is used to close/pop the screen
                  Navigator.pop(context);
                  print('Close icon tapped');
                },
                child: const Icon(
                  Icons.close, // Changed from Icons.bar_chart to Icons.close
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

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
      case 'supplies':
        return Icons.inventory;
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
      case 'supplies':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _saveExpense(BuildContext context) {
    // Validate at least one item
    bool hasValidItem = false;
    String firstCategory = 'Food';

    for (int i = 0; i < _items.length; i++) {
      if (_itemNameControllers[i].text.isNotEmpty &&
          double.tryParse(_itemPriceControllers[i].text) != null &&
          double.parse(_itemPriceControllers[i].text) > 0) {
        hasValidItem = true;
        if (i == 0) {
          firstCategory = _itemCategories[i];
        }
        break;
      }
    }

    if (!hasValidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid item'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create expense model
    final expense = ExpenseModel(
      id:
          widget.expenseToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _vendorController.text.isEmpty
          ? 'Unknown Vendor'
          : _vendorController.text,
      category: firstCategory,
      amount: _calculateTotal(),
      date: _selectedDate,
      isIncome: _isIncome,
      note: _items.length > 1 ? '${_items.length} items' : _items.first.name,
    );

    // Get cubits
    final expenseCubit = context.read<ExpenseCubit>();
    final addExpenseCubit = context.read<AddExpenseCubit>();

    if (widget.isEditing || widget.expenseToEdit != null) {
      // Update existing expense
      expenseCubit.updateExpense(expense);

      // Create receipt for recent uploads
      final receipt = ReceiptModel(
        id: expense.id,
        date: expense.date,
        amount: expense.amount,
        receiptType: 'manual',
        merchantName: expense.title,
        items: _items,
      );
      addExpenseCubit.addReceipt(receipt);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense updated successfully'),
          backgroundColor: accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Add new expense
      expenseCubit.addExpense(expense);

      // Create receipt for recent uploads
      final receipt = ReceiptModel(
        id: expense.id,
        date: expense.date,
        amount: expense.amount,
        receiptType: 'manual',
        merchantName: expense.title,
        items: _items,
        imagePath: widget.receipt?.imagePath,
      );
      addExpenseCubit.addReceipt(receipt);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense saved successfully'),
          backgroundColor: accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Navigate back after save
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }
}
