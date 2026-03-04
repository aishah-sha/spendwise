import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/budget_cubit.dart';
import '../models/budget_model.dart';
import 'budget_screen.dart';

// Import states with a prefix to avoid naming conflicts
import '../cubit/budget_cubit.dart' as cubit;

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

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

  // Category budget controllers
  final List<Map<String, dynamic>> _categoryBudgets = [
    {
      'name': 'Groceries',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {'name': 'Food', 'controller': TextEditingController(), 'enabled': false},
    {
      'name': 'Beverages',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {
      'name': 'Clothes',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {
      'name': 'Stationery',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {
      'name': 'Entertainment',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {
      'name': 'Transport',
      'controller': TextEditingController(),
      'enabled': false,
    },
    {
      'name': 'Shopping',
      'controller': TextEditingController(),
      'enabled': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Load existing budget if available
    _loadExistingBudget();
  }

  void _loadExistingBudget() {
    final state = context.read<BudgetCubit>().state;
    if (state is cubit.BudgetLoaded) {
      final budget = state.budget;
      if (budget.monthlyLimit > 0) {
        _monthlyBudgetController.text = budget.monthlyLimit.toString();
      }

      for (var category in _categoryBudgets) {
        try {
          final existingCategory = budget.categories.firstWhere(
            (BudgetCategory c) => c.name == category['name'],
          );
          if (existingCategory.amount > 0) {
            category['enabled'] = true;
            category['controller'].text = existingCategory.amount.toString();
          }
        } catch (e) {
          // Category not found, keep default
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _monthlyBudgetController.dispose();
    for (var category in _categoryBudgets) {
      category['controller'].dispose();
    }
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
        title: const Text(
          'Set Budget',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        centerTitle: true,
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

            // Navigate to budget screen and remove all previous routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<BudgetCubit>(),
                  child: const BudgetScreen(),
                ),
              ),
              (route) => false, // Remove all previous routes
            );
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
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Budget Section
                      _buildMonthlyBudgetSection(),
                      const SizedBox(height: 24),
                      // Category Budgets Section
                      _buildCategoryBudgetsSection(),
                      const SizedBox(height: 30),
                      // Save Button
                      _buildSaveButton(),
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

  Widget _buildMonthlyBudgetSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 126, 223, 106),
            Color.fromARGB(255, 24, 143, 0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _monthlyBudgetController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 24,
            ),
            decoration: InputDecoration(
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                color: const Color.fromARGB(
                  255,
                  114,
                  114,
                  114,
                ).withOpacity(0.5),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(
                color: const Color.fromARGB(
                  255,
                  114,
                  114,
                  114,
                ).withOpacity(0.5),
                fontSize: 24,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter monthly budget';
              }
              final number = double.tryParse(value);
              if (number == null) {
                return 'Please enter a valid number';
              }
              if (number <= 0) {
                return 'Budget must be greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Set your total monthly spending limit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(Icons.category, color: accentGreen, size: 24),
              SizedBox(width: 12),
              Text(
                'Category Budgets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Set spending limits for specific categories (optional)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Category budget inputs
          ..._categoryBudgets
              .map((category) => _buildCategoryRow(category))
              .toList(),

          const SizedBox(height: 16),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Category budgets will be subtracted from your monthly budget',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Enable toggle
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
                  }
                });
              },
            ),
          ),
          // Category name
          SizedBox(
            width: 100,
            child: Text(
              category['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: category['enabled'] == true ? darkText : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Amount input
          Expanded(
            child: TextFormField(
              controller: category['controller'],
              enabled: category['enabled'] == true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'RM ',
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: const Color.fromARGB(
                    255,
                    114,
                    114,
                    114,
                  ).withOpacity(0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: category['enabled'] == true
                        ? accentGreen.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: accentGreen, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: category['enabled'] == true ? darkText : Colors.grey,
              ),
              validator: (value) {
                if (category['enabled'] == true) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Invalid number';
                  }
                  if (number <= 0) {
                    return 'Must be > 0';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveBudget,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Save Budget',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      // Get monthly budget
      final monthlyBudget = double.parse(_monthlyBudgetController.text);

      // Get enabled category budgets
      final categoryBudgets = <String, double>{};
      for (var category in _categoryBudgets) {
        if (category['enabled'] == true &&
            category['controller'].text.isNotEmpty) {
          final amount = double.parse(category['controller'].text);
          if (amount > 0) {
            categoryBudgets[category['name']] = amount;
          }
        }
      }

      // Create category objects
      final categories = categoryBudgets.entries.map((entry) {
        return BudgetCategory(name: entry.key, amount: entry.value, spent: 0);
      }).toList();

      // Create budget object
      final newBudget = Budget(
        monthlyLimit: monthlyBudget,
        totalSpent: 0,
        categories: categories,
      );

      // Save budget using cubit
      context.read<BudgetCubit>().saveBudget(
        monthlyLimit: monthlyBudget,
        categoryBudgets: categoryBudgets,
      );
    }
  }
}
