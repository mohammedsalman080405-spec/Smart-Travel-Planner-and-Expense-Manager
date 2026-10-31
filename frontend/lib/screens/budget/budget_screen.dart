import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/expense_chart.dart';
import '../../widgets/loading_widget.dart';

class BudgetScreen extends StatefulWidget {
  final int tripId;

  const BudgetScreen({super.key, required this.tripId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<BudgetProvider>().fetchBudget(widget.tripId);
    context.read<ExpenseProvider>().fetchExpenses(widget.tripId);
  }

  void _showEditBudgetDialog(BudgetSummary summary) {
    final b = summary.budget;
    final accomCtrl = TextEditingController(text: b.accommodationBudget.toStringAsFixed(0));
    final transCtrl = TextEditingController(text: b.transportBudget.toStringAsFixed(0));
    final foodCtrl = TextEditingController(text: b.foodBudget.toStringAsFixed(0));
    final actCtrl = TextEditingController(text: b.activitiesBudget.toStringAsFixed(0));
    final shopCtrl = TextEditingController(text: b.shoppingBudget.toStringAsFixed(0));
    final otherCtrl = TextEditingController(text: b.otherBudget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Configure Category Budgets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNumberField(accomCtrl, 'Accommodation Budget (\$)'),
                const SizedBox(height: 10),
                _buildNumberField(transCtrl, 'Transportation Budget (\$)'),
                const SizedBox(height: 10),
                _buildNumberField(foodCtrl, 'Food & Dining Budget (\$)'),
                const SizedBox(height: 10),
                _buildNumberField(actCtrl, 'Activities & Sightseeing (\$)'),
                const SizedBox(height: 10),
                _buildNumberField(shopCtrl, 'Shopping Budget (\$)'),
                const SizedBox(height: 10),
                _buildNumberField(otherCtrl, 'Other Expenses (\$)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<BudgetProvider>().updateBudget(
                tripId: widget.tripId,
                accommodationBudget: double.tryParse(accomCtrl.text) ?? 0,
                transportBudget: double.tryParse(transCtrl.text) ?? 0,
                foodBudget: double.tryParse(foodCtrl.text) ?? 0,
                activitiesBudget: double.tryParse(actCtrl.text) ?? 0,
                shoppingBudget: double.tryParse(shopCtrl.text) ?? 0,
                otherBudget: double.tryParse(otherCtrl.text) ?? 0,
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Budgets'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  void _showAddExpenseDialog() {
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Food';
    DateTime expDate = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Record New Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: AppTheme.cardNavy,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Expense Category'),
                    items: const [
                      DropdownMenuItem(value: 'Accommodation', child: Text('Accommodation')),
                      DropdownMenuItem(value: 'Transportation', child: Text('Transportation')),
                      DropdownMenuItem(value: 'Food', child: Text('Food & Dining')),
                      DropdownMenuItem(value: 'Activities', child: Text('Activities & Sightseeing')),
                      DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                      DropdownMenuItem(value: 'Other', child: Text('Other Expenses')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Amount (\$)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Description (e.g. Royal dinner banquet)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amtCtrl.text);
                  if (amt != null && amt > 0) {
                    await context.read<ExpenseProvider>().addExpense(
                      tripId: widget.tripId,
                      category: category,
                      amount: amt,
                      expenseDate: fmt.format(expDate),
                      description: descCtrl.text.trim(),
                    );
                    // Refresh budget financial summary
                    context.read<BudgetProvider>().fetchBudget(widget.tripId);
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Expense'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    if (budgetProvider.isLoading && budgetProvider.summary == null) {
      return const Scaffold(
        backgroundColor: AppTheme.darkNavy,
        body: LoadingWidget(message: 'Calculating travel budgets and real-time expenditure...'),
      );
    }

    if (budgetProvider.errorMessage != null && budgetProvider.summary == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkNavy,
        body: CustomErrorWidget(message: budgetProvider.errorMessage!, onRetry: _loadData),
      );
    }

    final summary = budgetProvider.summary;

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'TRAVEL BUDGET & EXPENSE TRACKER',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Budget Targets'),
                onPressed: () => _showEditBudgetDialog(summary),
              ),
            ),
        ],
      ),
      body: summary == null
          ? const Center(child: Text('No budget available.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. FINANCIAL SUMMARY KPI CARDS
                      Row(
                        children: [
                          _buildKpiCard(
                            title: 'TOTAL PLANNED BUDGET',
                            value: '\$${summary.totalBudget.toStringAsFixed(2)}',
                            color: AppTheme.accentCyan,
                            icon: Icons.account_balance,
                          ),
                          const SizedBox(width: 14),
                          _buildKpiCard(
                            title: 'ACTUAL EXPENSES',
                            value: '\$${summary.totalSpent.toStringAsFixed(2)}',
                            color: AppTheme.accentGold,
                            icon: Icons.shopping_cart,
                          ),
                          const SizedBox(width: 14),
                          _buildKpiCard(
                            title: 'REMAINING BALANCE',
                            value: '\$${summary.remainingBalance.toStringAsFixed(2)}',
                            color: summary.remainingBalance >= 0 ? AppTheme.accentEmerald : AppTheme.accentRose,
                            icon: Icons.savings,
                          ),
                          const SizedBox(width: 14),
                          _buildKpiCard(
                            title: 'BUDGET UTILIZED',
                            value: '${summary.percentageUsed}%',
                            color: summary.percentageUsed > 90 ? AppTheme.accentRose : AppTheme.accentBlue,
                            icon: Icons.pie_chart,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // 2. CATEGORY BUDGET COMPARISON & EXPENSE CHART
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Category Bars
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppTheme.cardNavy,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderNavy),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CATEGORY-WISE EXPENDITURE & BUDGETS',
                                    style: TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 18),
                                  ...summary.categoryBudgets.entries.map((entry) {
                                    final cat = entry.key;
                                    final budgetAmt = entry.value;
                                    final spentAmt = summary.categorySpending[cat] ?? 0.0;
                                    final progress = budgetAmt > 0 ? (spentAmt / budgetAmt).clamp(0.0, 1.0) : 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                              Text(
                                                '\$${spentAmt.toStringAsFixed(0)} / \$${budgetAmt.toStringAsFixed(0)}',
                                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 8,
                                              backgroundColor: const Color(0xFF13203C),
                                              color: progress > 0.9 ? AppTheme.accentRose : AppTheme.accentCyan,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // Right: fl_chart Visualizer
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppTheme.cardNavy,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderNavy),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXPENSE SHARE BREAKDOWN',
                                    style: TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: 18),
                                  ExpenseChart(
                                    categorySpending: summary.categorySpending,
                                    categoryBudgets: summary.categoryBudgets,
                                    currency: summary.currency,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 3. EXPENSE LOG RECORDS & ADD EXPENSE ACTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ITEMIZED EXPENSES RECORD',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Expense'),
                            onPressed: _showAddExpenseDialog,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (expenseProvider.expenses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          alignment: Alignment.center,
                          child: const Text('No expenses logged for this trip yet.', style: TextStyle(color: AppTheme.textMuted)),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderNavy),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expenseProvider.expenses.length,
                            separatorBuilder: (_, __) => const Divider(color: AppTheme.borderNavy, height: 1),
                            itemBuilder: (context, idx) {
                              final exp = expenseProvider.expenses[idx];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13203C),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt_long, color: AppTheme.accentCyan, size: 20),
                                ),
                                title: Text(
                                  exp.description != null && exp.description!.isNotEmpty ? exp.description! : exp.category,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${exp.category} • ${exp.expenseDate}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${exp.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                                      onPressed: () async {
                                        await context.read<ExpenseProvider>().deleteExpense(exp.expenseId);
                                        context.read<BudgetProvider>().fetchBudget(widget.tripId);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildKpiCard({required String title, required String value, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderNavy),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
