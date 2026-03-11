import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/expense_cubit.dart';
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

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late DateTime _selectedDate;
  bool _isIncome = false;

  // List to hold items
  List<ReceiptItem> _items = [];

  // Categories - Added 'Beverages'
  final List<String> _categories = [
    'Food',
    'Beverages',
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

  // Controllers for adding new items
  final TextEditingController _newItemNameController = TextEditingController();
  final TextEditingController _newItemPriceController = TextEditingController();
  String _newItemCategory = 'Food';

  // Image file for receipt
  File? _receiptImageFile;

  @override
  void initState() {
    super.initState();
    print("🟢 ManualEntryScreen initState");

    _amountController = TextEditingController();
    _vendorController = TextEditingController();
    _selectedDate = DateTime.now();

    // Initialize with data
    if (widget.receipt != null) {
      print("🟢 Received receipt: ${widget.receipt!.merchantName}");
      print("🟢 Items from receipt: ${widget.receipt!.items?.length ?? 0}");

      // Load receipt image if available
      if (widget.receipt!.imagePath != null &&
          widget.receipt!.imagePath!.isNotEmpty) {
        try {
          _receiptImageFile = File(widget.receipt!.imagePath!);
          print("🟢 Receipt image loaded from: ${widget.receipt!.imagePath}");
        } catch (e) {
          print("🟢 Error loading receipt image: $e");
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

  void _showAddItemDialog() {
    _newItemNameController.clear();
    _newItemPriceController.clear();
    _newItemCategory = 'Food';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newItemNameController,
              decoration: const InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newItemPriceController,
              decoration: const InputDecoration(
                labelText: "Price (RM)",
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _newItemCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 16,
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _newItemCategory = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newItemNameController.text.isNotEmpty &&
                  _newItemPriceController.text.isNotEmpty) {
                final price = double.tryParse(_newItemPriceController.text);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
            child: const Text("Add"),
          ),
        ],
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
            Container(
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text('SpendWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Expense' : 'Manual Entry',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Receipt Image Section
            _buildReceiptImageSection(),
            const SizedBox(height: 20),

            // EXPENSE DETAILS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                'EXPENSE DETAILS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),

            // Total Amount (Read-only as it's calculated from items)
            _buildReadOnlyField('Total Amount', _amountController),
            const SizedBox(height: 10),

            // Date Field (Editable)
            _buildDateField(),
            const SizedBox(height: 10),

            // Vendor Field (Editable)
            _buildEditableField('Vendor', _vendorController, (value) {
              context.read<AddExpenseCubit>().updateTitle(value);
            }),
            const SizedBox(height: 20),

            // ITEMS SECTION HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITEMS (${_items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: Icon(Icons.add_circle, color: accentGreen, size: 18),
                  label: Text(
                    'Add Item',
                    style: TextStyle(color: accentGreen, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Items List (Editable)
            if (_items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text("No items. Tap 'Add Item' to add."),
                ),
              )
            else
              ListView.builder(
                key: ValueKey(_items.length),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildEditableItem(index);
                },
              ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _saveExpense(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Expense' : 'Save Expense',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  print("🟢 Close button pressed");
                  if (widget.fromAddExpense) {
                    // Return null to indicate cancellation
                    Navigator.pop(context, null);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Icon(Icons.close, size: 24),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImageSection() {
    if (_receiptImageFile != null) {
      return GestureDetector(
        onTap: _showFullScreenImage,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _receiptImageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
              // Receipt info overlay
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Receipt Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      height: 160,
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: accentGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No Receipt Image',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          if (widget.receipt?.merchantName != null)
            Text(
              widget.receipt!.merchantName!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (widget.receipt?.amount != null)
            Text(
              'RM ${widget.receipt!.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(int index) {
    if (index < 0 || index >= _items.length) return const SizedBox.shrink();

    ReceiptItem item = _items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 160,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // Item Name
                      TextFormField(
                        initialValue: item.name,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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
                      const SizedBox(height: 8),

                      // Price and Quantity Row
                      Row(
                        children: [
                          // Price
                          Expanded(
                            child: TextFormField(
                              initialValue: item.price.toStringAsFixed(2),
                              decoration: const InputDecoration(
                                labelText: 'Price (RM)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixText: 'RM ',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
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

                          // Quantity
                          Expanded(
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
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
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category Dropdown - Fixed with safety check
                      DropdownButtonFormField<String>(
                        value: _categories.contains(item.category)
                            ? item.category
                            : _categories.first,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
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
                                  size: 16,
                                  color: _getCategoryColor(category),
                                ),
                                const SizedBox(width: 8),
                                Text(category),
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

                      const SizedBox(height: 4),

                      // Item Total
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Total: RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delete Button
          if (_items.length > 1)
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  if (index < _items.length) {
                    setState(() {
                      _items.removeAt(index);
                      _updateTotal();
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'RM ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF32BA32),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Icon(Icons.calendar_today, color: accentGreen, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExpense(BuildContext context) {
    print("🟢 SAVE EXPENSE CALLED");
    print("🟢 fromAddExpense: ${widget.fromAddExpense}");

    // Validate at least one valid item
    bool hasValidItem = false;
    for (var item in _items) {
      if (item.name.isNotEmpty && item.price > 0) {
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

    // Validate vendor
    if (_vendorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a vendor name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String expenseId =
        widget.expenseToEdit?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Create expense model
    final expense = ExpenseModel(
      id: expenseId,
      title: _vendorController.text,
      category: _items.first.category ?? 'Food',
      amount: _calculateTotal(),
      date: _selectedDate,
      isIncome: _isIncome,
      note: '${_items.length} items',
    );

    print("🟢 Expense created: ${expense.title} - RM${expense.amount}");

    // Get cubits
    final expenseCubit = context.read<ExpenseCubit>();
    final addExpenseCubit = context.read<AddExpenseCubit>();

    if (widget.isEditing || widget.expenseToEdit != null) {
      // Update existing expense
      expenseCubit.updateExpense(expense);
      print("🟢 Expense updated");
    } else {
      // Add new expense
      expenseCubit.addExpense(expense);
      print("🟢 New expense added");
    }

    // Create receipt for recent uploads
    final receipt = ReceiptModel(
      id: expenseId,
      date: expense.date,
      amount: expense.amount,
      receiptType: 'manual',
      merchantName: expense.title,
      items: _items,
      imagePath: widget.receipt?.imagePath,
    );

    // Add to recent uploads
    addExpenseCubit.addReceipt(receipt);
    print("🟢 Receipt added to recent uploads");

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Expense updated successfully'
              : 'Expense saved successfully',
        ),
        backgroundColor: accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back based on where we came from
    if (widget.fromAddExpense) {
      print("🟢 Returning to add expense screen");
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, receipt);
      });
    } else {
      print("🟢 Navigating to dashboard");
      Future.delayed(const Duration(seconds: 1), () {
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
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'beverages':
        return Icons.local_cafe;
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
      case 'beverages':
        return Colors.blue;
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
}
