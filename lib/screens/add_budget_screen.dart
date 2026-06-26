// screens/add_budget_screen.dart - COMPLETE FIXED VERSION

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendwise/models/budget_model.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class AddBudgetScreen extends StatefulWidget {
  final bool isAdding;

  const AddBudgetScreen({super.key, this.isAdding = false});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color lightBgColor = Color(0xFFE8F7CB);
  static const Color darkBgColor = Color(0xFF121212);
  static const Color lightSurfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFFE8F5E9);
  static const Color lightTextDark = Color(0xFF1B2519);
  static const Color darkTextDark = Colors.white;
  static const Color lightTextMuted = Color(0xFF687765);
  static const Color darkTextMuted = Color(0xFF9E9E9E);

  final _monthlyBudgetController = TextEditingController();
  final Map<String, double> _originalSpentAmounts = {};
  final List<Map<String, dynamic>> _categoryBudgets = [];

  final _newCategoryController = TextEditingController();
  final _newCategoryAmountController = TextEditingController();

  bool _isFirstLoad = true;

  // Date range controllers
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasDateRange = true;
  String? _budgetPeriodLabel;

  final List<String> _predefinedCategories = [
    'Groceries',
    'Pet Food',
    'Household',
    'Beverages',
    'Baking',
    'Cooking Ingredients',
    'Snacks & Desserts',
    'Health',
    'Transport',
    'Clothing',
    'Stationery',
    'Rent',
    'Food',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _hasDateRange = true;
    _budgetPeriodLabel = '${_monthName(now)} ${now.year}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetCubit>().loadBudget(forceRefresh: true);
    });
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  @override
  void dispose() {
    _monthlyBudgetController.dispose();
    _newCategoryController.dispose();
    _newCategoryAmountController.dispose();
    for (var cat in _categoryBudgets) {
      (cat['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  bool _isDarkMode(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      return profileState.user.isDarkMode;
    }
    return false;
  }

  Color _getBgColor(BuildContext context) =>
      _isDarkMode(context) ? darkBgColor : lightBgColor;

  Color _getSurfaceColor(BuildContext context) =>
      _isDarkMode(context) ? darkSurfaceColor : lightSurfaceColor;

  Color _getTextColor(BuildContext context) =>
      _isDarkMode(context) ? darkTextDark : lightTextDark;

  Color _getMutedTextColor(BuildContext context) =>
      _isDarkMode(context) ? darkTextMuted : lightTextMuted;

  void _populateFromBudget(Budget budget) {
    _isFirstLoad = false;
    if (!widget.isAdding && budget.monthlyLimit > 0) {
      _monthlyBudgetController.text = budget.monthlyLimit.toStringAsFixed(2);
      _categoryBudgets.clear();

      if (budget.hasDateRange) {
        _startDate = budget.startDate;
        _endDate = budget.endDate;
        _hasDateRange = true;
        _budgetPeriodLabel = budget.budgetPeriodLabel;
      }

      for (var category in budget.categories) {
        _originalSpentAmounts[category.name] = category.spent;
        _categoryBudgets.add({
          'name': category.name,
          'controller': TextEditingController(
            text: category.amount.toStringAsFixed(2),
          ),
          'spent': category.spent,
        });
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) {
        if (previous is ProfileLoaded && current is ProfileLoaded) {
          return previous.user.isDarkMode != current.user.isDarkMode;
        }
        return false;
      },
      listener: (context, state) {},
      child: Scaffold(
        backgroundColor: _getBgColor(context),
        appBar: AppBar(
          title: Text(
            widget.isAdding ? 'Add to Budget' : 'Set Budget Limit',
            style: TextStyle(
              color: _getTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: _getTextColor(context)),
        ),
        body: BlocConsumer<BudgetCubit, BudgetState>(
          listener: (context, state) {
            if (state is BudgetLoaded && _isFirstLoad) {
              _populateFromBudget(state.budget);
            }
            if (state is BudgetSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.isAdding
                        ? 'Amount added successfully!'
                        : 'Budget limits saved successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context);
            }
            if (state is BudgetError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if ((state is BudgetLoading || state is BudgetInitial) &&
                _isFirstLoad) {
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateRangeCard(context),
                    const SizedBox(height: 20),
                    _buildCard(
                      context,
                      title: widget.isAdding
                          ? 'ADD TO MONTHLY BUDGET'
                          : 'TOTAL MONTHLY LIMIT',
                      subtitle: widget.isAdding
                          ? 'Enter the amount you want to inject into your overall budget.'
                          : 'Set your overall maximum spending target across all activities.',
                      child: TextFormField(
                        controller: _monthlyBudgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: _getTextColor(context),
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'RM ',
                          prefixStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: primaryGreen,
                          ),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: _getMutedTextColor(context).withOpacity(0.4),
                          ),
                          filled: true,
                          fillColor: _getBgColor(context).withOpacity(0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (widget.isAdding) {
                            if (value != null && value.isNotEmpty) {
                              final val = double.tryParse(value);
                              if (val == null || val < 0) {
                                return 'Enter a valid amount';
                              }
                            }
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a monthly limit';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      context,
                      title: widget.isAdding
                          ? 'ADD TO CATEGORY BUDGETS'
                          : 'CATEGORY BUDGET LIMITS',
                      subtitle:
                          'Leave values at 0.00 to automatically distribute the remaining monthly limit among them.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_categoryBudgets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 48,
                                    color: _getMutedTextColor(
                                      context,
                                    ).withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No category limits configured yet.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _getMutedTextColor(
                                        context,
                                      ).withOpacity(0.6),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _categoryBudgets.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final cat = _categoryBudgets[index];
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getBgColor(
                                      context,
                                    ).withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                          ),
                                          child: Text(
                                            cat['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _getTextColor(context),
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: TextFormField(
                                          controller:
                                              cat['controller']
                                                  as TextEditingController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: _getTextColor(context),
                                          ),
                                          textAlign: TextAlign.end,
                                          decoration: InputDecoration(
                                            prefixText: 'RM ',
                                            prefixStyle: TextStyle(
                                              color: _getMutedTextColor(
                                                context,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            hintText: 'Auto Split',
                                            hintStyle: TextStyle(
                                              color: _getMutedTextColor(
                                                context,
                                              ).withOpacity(0.5),
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            filled: true,
                                            fillColor: _getSurfaceColor(
                                              context,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value != null &&
                                                value.trim().isNotEmpty) {
                                              final val = double.tryParse(
                                                value,
                                              );
                                              if (val == null || val < 0) {
                                                return 'Invalid';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            (cat['controller']
                                                    as TextEditingController)
                                                .dispose();
                                            _categoryBudgets.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _showAddCategorySheet(context),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add Category Allocation'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryGreen,
                              side: const BorderSide(
                                color: primaryGreen,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isAdding
                            ? 'Confirm Addition'
                            : 'Save Budget Settings',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Date Range Card Widget
  Widget _buildDateRangeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getTextColor(context).withOpacity(0.03),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUDGET PERIOD',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: primaryGreen,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set the date range for this budget',
            style: TextStyle(
              color: _getMutedTextColor(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  context: context,
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _selectStartDate(),
                  isDarkMode: _isDarkMode(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerField(
                  context: context,
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _selectEndDate(),
                  isDarkMode: _isDarkMode(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasDateRange && _startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_budgetPeriodLabel ?? ''} · ${_getDaysBetween()} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryGreen,
                        fontWeight: FontWeight.w500,
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

  // Date picker field - FIXED: removed duplicate context parameter
  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : (isDarkMode ? Colors.white54 : Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Start date picker - NO parameters, uses context from widget
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _hasDateRange = true;
        _updatePeriodLabel();
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 30));
        }
      });
    }
  }

  // FIXED: End date picker - NO parameters, uses context from widget
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _hasDateRange = true;
        _updatePeriodLabel();
      });
    }
  }

  void _updatePeriodLabel() {
    if (_startDate != null && _endDate != null) {
      final start = _startDate!;
      final end = _endDate!;
      if (start.month == end.month && start.year == end.year) {
        _budgetPeriodLabel = '${_monthName(start)} ${start.year}';
      } else if (start.year == end.year) {
        _budgetPeriodLabel =
            '${_monthName(start)} - ${_monthName(end)} ${start.year}';
      } else {
        _budgetPeriodLabel = '${start.year} - ${end.year}';
      }
    }
  }

  int _getDaysBetween() {
    if (_startDate == null || _endDate == null) return 0;
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return end.difference(start).inDays + 1;
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getTextColor(context).withOpacity(0.03),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: primaryGreen,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: _getMutedTextColor(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    String? selectedPredefCategory = _predefinedCategories.first;
    bool isCustom = false;

    _newCategoryController.clear();
    _newCategoryAmountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _getSurfaceColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _getMutedTextColor(context).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Category Limit',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: _getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Preset List')),
                            selected: !isCustom,
                            onSelected: (val) =>
                                setSheetState(() => isCustom = !val),
                            selectedColor: accentGreen,
                            labelStyle: TextStyle(
                              color: !isCustom
                                  ? primaryGreen
                                  : _getMutedTextColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Custom Name')),
                            selected: isCustom,
                            onSelected: (val) =>
                                setSheetState(() => isCustom = val),
                            selectedColor: accentGreen,
                            labelStyle: TextStyle(
                              color: isCustom
                                  ? primaryGreen
                                  : _getMutedTextColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!isCustom) ...[
                      Text(
                        'Choose Category',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _getBgColor(context).withOpacity(0.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPredefCategory,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _getMutedTextColor(context),
                            ),
                            items: _predefinedCategories.map((String cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _getTextColor(context),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setSheetState(
                              () => selectedPredefCategory = value,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Custom Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newCategoryController,
                        style: TextStyle(color: _getTextColor(context)),
                        decoration: InputDecoration(
                          hintText: 'e.g., Subscriptions',
                          hintStyle: TextStyle(
                            color: _getMutedTextColor(context),
                          ),
                          filled: true,
                          fillColor: _getBgColor(context).withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Budget Value (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newCategoryAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        prefixStyle: TextStyle(
                          color: _getMutedTextColor(context),
                        ),
                        hintText: '0.00 (Leaves for Auto-Split)',
                        hintStyle: TextStyle(
                          color: _getMutedTextColor(context),
                        ),
                        filled: true,
                        fillColor: _getBgColor(context).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final catName = isCustom
                            ? _newCategoryController.text.trim()
                            : selectedPredefCategory;
                        if (catName == null || catName.isEmpty) return;

                        if (_categoryBudgets.any(
                          (e) =>
                              e['name'].toString().toLowerCase() ==
                              catName.toLowerCase(),
                        )) {
                          Navigator.pop(context);
                          return;
                        }

                        final initialAmount =
                            double.tryParse(
                              _newCategoryAmountController.text,
                            ) ??
                            0.0;
                        setState(() {
                          _categoryBudgets.add({
                            'name': catName,
                            'controller': TextEditingController(
                              text: initialAmount > 0
                                  ? initialAmount.toStringAsFixed(2)
                                  : '',
                            ),
                            'spent': _originalSpentAmounts[catName] ?? 0.0,
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Add to List',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final monthlyAmount =
          double.tryParse(_monthlyBudgetController.text) ?? 0.0;
      final Map<String, double> categoryBudgets = {};

      double totalManualAmount = 0.0;
      List<String> autoSplitCategories = [];

      for (var cat in _categoryBudgets) {
        final name = cat['name'] as String;
        final controller = cat['controller'] as TextEditingController;
        final amount = double.tryParse(controller.text) ?? 0.0;

        if (amount > 0) {
          categoryBudgets[name] = amount;
          totalManualAmount += amount;
        } else {
          autoSplitCategories.add(name);
        }
      }

      if (autoSplitCategories.isNotEmpty && monthlyAmount > totalManualAmount) {
        final remainingPool = monthlyAmount - totalManualAmount;
        final splitValue = remainingPool / autoSplitCategories.length;

        for (var name in autoSplitCategories) {
          categoryBudgets[name] = double.parse(splitValue.toStringAsFixed(2));
        }
      } else if (autoSplitCategories.isNotEmpty &&
          monthlyAmount <= totalManualAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot Auto-Split! Manual category limits meet or exceed total budget.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      double absoluteTotalCategoryAmount = categoryBudgets.values.fold(
        0.0,
        (sum, item) => sum + item,
      );

      if (!widget.isAdding &&
          monthlyAmount > 0 &&
          absoluteTotalCategoryAmount > 0) {
        if ((absoluteTotalCategoryAmount - monthlyAmount).abs() > 0.10) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: _getSurfaceColor(context),
              title: Text(
                'Limit Balance Check',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _getTextColor(context),
                ),
              ),
              content: Text(
                'Total allocations (RM ${absoluteTotalCategoryAmount.toStringAsFixed(2)}) '
                'differ slightly from your overall limit due to rounding (RM ${monthlyAmount.toStringAsFixed(2)}).\n\n'
                'Proceed anyway?',
                style: TextStyle(color: _getTextColor(context)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: _getMutedTextColor(context)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSave(monthlyAmount, categoryBudgets);
                  },
                  child: const Text(
                    'Proceed',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
      return;
    }

    context.read<BudgetCubit>().saveBudget(
      monthlyLimit: monthlyAmount,
      categoryBudgets: categoryBudgets,
      isAdditional: widget.isAdding,
      startDate: _hasDateRange ? _startDate : null,
      endDate: _hasDateRange ? _endDate : null,
      budgetPeriodLabel: _hasDateRange ? _budgetPeriodLabel : null,
    );
  }
}
