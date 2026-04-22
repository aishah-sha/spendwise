import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/budget_cubit.dart';

// Import states with a prefix to avoid naming conflicts
import '../cubit/budget_cubit.dart' as cubit;

class AddBudgetScreen extends StatefulWidget {
  final bool isAdding;

  const AddBudgetScreen({super.key, this.isAdding = false});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();

  // Theme colors
  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color darkText = Color(0xFF000000);

  // Controllers for budget inputs
  final _monthlyBudgetController = TextEditingController();

  // Track original spent amounts to preserve them when editing
  Map<String, double> _originalSpentAmounts = {};

  // Dynamic category budgets list
  List<Map<String, dynamic>> _categoryBudgets = [];

  // Controller for new category name
  final _newCategoryController = TextEditingController();
  final _newCategoryAmountController = TextEditingController();

  // Track if this is the first time setting budget
  bool _isFirstTimeBudget = false;

  // Flag to prevent recursive updates
  bool _isUpdatingFromMonthly = false;

  // Scroll controller for category list
  final ScrollController _scrollController = ScrollController();

  // Default categories to start with
  final List<String> _defaultCategories = [
    'Groceries',
    'Food',
    'Beverages',
    'Clothes',
    'Stationery',
    'Entertainment',
    'Transport',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCategoryBudgets();
    _loadExistingBudget();
    _monthlyBudgetController.addListener(_onMonthlyBudgetChanged);
  }

  void _initializeCategoryBudgets() {
    _categoryBudgets = [];
    for (var category in _defaultCategories) {
      _categoryBudgets.add({
        'name': category,
        'controller': TextEditingController(),
        'enabled': false,
        'originalAmount': 0.0,
        'isCustom': false,
      });
    }
  }

  void _onMonthlyBudgetChanged() {
    if (_isUpdatingFromMonthly) return;

    final monthlyText = _monthlyBudgetController.text;
    if (monthlyText.isNotEmpty) {
      final monthlyAmount = double.tryParse(monthlyText);
      if (monthlyAmount != null && monthlyAmount > 0) {
        _distributeBudgetEqually(monthlyAmount);
      }
    }
  }

  void _distributeBudgetEqually(double totalAmount) {
    final enabledCategories = _categoryBudgets
        .where((cat) => cat['enabled'] == true)
        .toList();

    if (enabledCategories.isEmpty) return;

    final equalShare = totalAmount / enabledCategories.length;

    _isUpdatingFromMonthly = true;
    for (var category in enabledCategories) {
      final controller = category['controller'] as TextEditingController;
      final currentText = controller.text;
      final currentAmount = currentText.isEmpty
          ? 0
          : double.tryParse(currentText) ?? 0;

      if ((currentAmount - equalShare).abs() > 0.01) {
        controller.text = equalShare.toStringAsFixed(2);
      }
    }
    _isUpdatingFromMonthly = false;
  }

  void _loadExistingBudget() {
    final state = context.read<BudgetCubit>().state;
    if (state is cubit.BudgetLoaded) {
      final budget = state.budget;

      if (!widget.isAdding) {
        _isFirstTimeBudget =
            budget.monthlyLimit == 0 &&
            budget.categories.every((cat) => cat.amount == 0);
      } else {
        _isFirstTimeBudget = false;
      }

      for (var category in budget.categories) {
        _originalSpentAmounts[category.name] = category.spent;
      }

      _categoryBudgets.clear();

      if (budget.categories.isNotEmpty) {
        for (var category in budget.categories) {
          final isCustom = !_defaultCategories.contains(category.name);
          _categoryBudgets.add({
            'name': category.name,
            'controller': TextEditingController(),
            'enabled': category.amount > 0,
            'originalAmount': category.amount,
            'isCustom': isCustom,
          });

          if (category.amount > 0) {
            _categoryBudgets.last['controller'].text = category.amount
                .toString();
          }
        }
      } else {
        _initializeCategoryBudgets();
      }

      if (!widget.isAdding && !_isFirstTimeBudget) {
        if (budget.monthlyLimit > 0) {
          _monthlyBudgetController.text = budget.monthlyLimit.toString();
        }
      } else {
        _monthlyBudgetController.clear();
        for (var category in _categoryBudgets) {
          category['enabled'] = false;
          category['controller'].clear();
        }
      }
      setState(() {});
    }
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newCategoryController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Electronics, Gifts, etc.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCategoryAmountController,
              decoration: const InputDecoration(
                labelText: 'Initial Budget (Optional)',
                hintText: '0.00',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newCategoryController.clear();
              _newCategoryAmountController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveNewCategory,
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveNewCategory() {
    final categoryName = _newCategoryController.text.trim();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final exists = _categoryBudgets.any(
      (cat) => cat['name'].toLowerCase() == categoryName.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$categoryName" already exists'),
          backgroundColor: Colors.red,
        ),
      );
      _newCategoryController.clear();
      _newCategoryAmountController.clear();
      return;
    }

    double initialAmount = 0;
    if (_newCategoryAmountController.text.isNotEmpty) {
      initialAmount = double.tryParse(_newCategoryAmountController.text) ?? 0;
    }

    setState(() {
      _categoryBudgets.add({
        'name': categoryName,
        'controller': TextEditingController(),
        'enabled': initialAmount > 0,
        'originalAmount': initialAmount,
        'isCustom': true,
      });

      if (initialAmount > 0) {
        _categoryBudgets.last['controller'].text = initialAmount.toString();
      }
    });

    final monthlyText = _monthlyBudgetController.text;
    if (monthlyText.isNotEmpty) {
      final monthlyAmount = double.tryParse(monthlyText);
      if (monthlyAmount != null && monthlyAmount > 0) {
        _distributeBudgetEqually(monthlyAmount);
      }
    }

    _newCategoryController.clear();
    _newCategoryAmountController.clear();
    Navigator.pop(context);

    // Scroll to bottom to show new category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category "$categoryName" added successfully'),
        backgroundColor: accentGreen,
      ),
    );
  }

  void _removeCategory(int index) {
    final category = _categoryBudgets[index];
    final categoryName = category['name'];
    final isCustom = category['isCustom'];

    if (!isCustom) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Remove Default Category'),
          content: Text(
            '"$categoryName" is a default category. You can disable it instead of removing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Category'),
        content: Text('Are you sure you want to remove "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                category['controller'].dispose();
                _categoryBudgets.removeAt(index);
              });

              final monthlyText = _monthlyBudgetController.text;
              if (monthlyText.isNotEmpty) {
                final monthlyAmount = double.tryParse(monthlyText);
                if (monthlyAmount != null && monthlyAmount > 0) {
                  _distributeBudgetEqually(monthlyAmount);
                }
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "$categoryName" removed'),
                  backgroundColor: accentGreen,
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _monthlyBudgetController.removeListener(_onMonthlyBudgetChanged);
    _monthlyBudgetController.dispose();
    for (var category in _categoryBudgets) {
      category['controller'].dispose();
    }
    _newCategoryController.dispose();
    _newCategoryAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isAdding ? 'Add to Budget' : 'Set Budget',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        centerTitle: true,
        // Removed the actions button since we have Add Category button below
      ),
      body: BlocConsumer<BudgetCubit, cubit.BudgetState>(
        listener: (context, state) {
          if (state is cubit.BudgetSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: accentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Navigator.pop(context, true);
          } else if (state is cubit.BudgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Budget Section
                      _buildMonthlyBudgetSection(),
                      const SizedBox(height: 20),
                      // Category Budgets Section
                      _buildCategoryBudgetsSection(),
                      const SizedBox(height: 20),
                      // Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 16),

                      // Info texts
                      if (_isFirstTimeBudget && !widget.isAdding) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.info,
                          color: Colors.blue,
                          message:
                              'First time setup: Please set both Monthly Budget and at least one Category Budget',
                        ),
                      ] else if (widget.isAdding) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.add_circle,
                          color: accentGreen,
                          message:
                              'Adding mode: Enter amount and select categories to distribute equally',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state is cubit.BudgetLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: accentGreen),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 11, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBudgetSection() {
    return Container(
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.isAdding ? 'Additional Amount' : 'Monthly Budget',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monthlyBudgetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black, fontSize: 20),
            decoration: InputDecoration(
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final number = double.tryParse(value);
                if (number == null) return 'Please enter a valid number';
                if (number <= 0) return 'Amount must be greater than 0';
              }

              if (_isFirstTimeBudget && !widget.isAdding) {
                if (value == null || value.isEmpty) {
                  return 'Monthly budget is required for first time setup';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAdding
                ? 'Enter amount to add. It will be divided equally among selected categories'
                : _isFirstTimeBudget
                ? 'Set your total monthly spending limit (required)'
                : 'Set your total monthly spending limit. Amount will be divided equally among selected categories',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.category, color: accentGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Category Budgets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addNewCategory,
                icon: const Icon(Icons.add, color: accentGreen, size: 16),
                label: const Text(
                  'Add Category',
                  style: TextStyle(color: accentGreen, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.isAdding
                ? 'Select categories and the amount will be distributed equally'
                : _isFirstTimeBudget
                ? 'Set spending limits for specific categories (at least one required)'
                : 'Select categories to automatically divide monthly budget equally',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Category list - each category takes full width
          Column(
            children: _categoryBudgets
                .asMap()
                .entries
                .map((entry) => _buildCategoryCard(entry.value, entry.key))
                .toList(),
          ),

          const SizedBox(height: 12),

          // Info text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: accentGreen, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isAdding
                        ? 'Tip: Enter amount, select categories for equal distribution'
                        : 'Tip: Enter monthly budget, select categories for auto-distribution',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final isCustom = category['isCustom'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: category['enabled'] == true
              ? accentGreen.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with checkbox, category name, and delete button
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: category['enabled'],
                    activeColor: accentGreen,
                    onChanged: (value) {
                      setState(() {
                        category['enabled'] = value;
                        if (value == false) {
                          category['controller'].clear();
                        } else {
                          final monthlyText = _monthlyBudgetController.text;
                          if (monthlyText.isNotEmpty) {
                            final monthlyAmount = double.tryParse(monthlyText);
                            if (monthlyAmount != null && monthlyAmount > 0) {
                              _distributeBudgetEqually(monthlyAmount);
                            }
                          }
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: category['enabled'] == true
                                ? darkText
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (isCustom) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 10,
                              color: accentGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isCustom)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _removeCategory(index),
                          tooltip: 'Remove Category',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount input field
            TextFormField(
              controller: category['controller'],
              enabled: category['enabled'] == true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                prefixText: 'RM ',
                hintText: '0.00',
                prefixStyle: const TextStyle(fontSize: 14),
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.5),
                  fontSize: 14,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: category['enabled'] == true
                        ? accentGreen.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: category['enabled'] == true
                        ? accentGreen.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: accentGreen, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                filled: true,
                fillColor: category['enabled'] == true
                    ? Colors.white
                    : Colors.grey.shade50,
              ),
              validator: (value) {
                if (category['enabled'] == true) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final number = double.tryParse(value);
                  if (number == null) return 'Invalid number';
                  if (number <= 0) return 'Must be > 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saveBudget,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          widget.isAdding ? 'Add to Budget' : 'Save Budget',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      double monthlyAmount = 0;
      if (_monthlyBudgetController.text.isNotEmpty) {
        monthlyAmount = double.parse(_monthlyBudgetController.text);
      }

      final categoryBudgets = <String, double>{};
      double totalCategoryAmount = 0;

      for (var category in _categoryBudgets) {
        if (category['enabled'] == true &&
            category['controller'].text.isNotEmpty) {
          final amount = double.parse(category['controller'].text);
          if (amount > 0) {
            categoryBudgets[category['name']] = amount;
            totalCategoryAmount += amount;
          }
        }
      }

      if (_isFirstTimeBudget && !widget.isAdding) {
        if (monthlyAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monthly budget is required for first time setup'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (categoryBudgets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please set at least one category budget'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      if (!widget.isAdding && monthlyAmount > 0 && categoryBudgets.isNotEmpty) {
        if ((monthlyAmount - totalCategoryAmount).abs() > 0.01) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Budget Mismatch'),
              content: Text(
                'Total category budgets (RM ${totalCategoryAmount.toStringAsFixed(2)}) '
                'is different from monthly budget (RM ${monthlyAmount.toStringAsFixed(2)}).\n\n'
                'Do you want to proceed with these amounts?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSave(monthlyAmount, categoryBudgets);
                  },
                  child: const Text('Proceed'),
                ),
              ],
            ),
          );
          return;
        }
      }

      _performSave(monthlyAmount, categoryBudgets);
    }
  }

  void _performSave(double monthlyAmount, Map<String, double> categoryBudgets) {
    if (widget.isAdding && monthlyAmount <= 0 && categoryBudgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount to add'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<BudgetCubit>().saveBudget(
      monthlyLimit: monthlyAmount,
      categoryBudgets: categoryBudgets,
      isAdditional: widget.isAdding,
    );
  }
}
