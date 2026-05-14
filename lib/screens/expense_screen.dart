import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../core/localization_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    });
  }

  void _showExpenseDialog([ExpenseModel? expense]) {
    final bool isEditing = expense != null;
    final TextEditingController amountController = TextEditingController(
      text: isEditing ? expense.amount.toString() : '',
    );
    final TextEditingController notesController = TextEditingController(
      text: isEditing ? expense.notes : '',
    );
    DateTime selectedDate = isEditing ? expense.date : DateTime.now();
    String? selectedCategory = isEditing ? expense.category : 'others';

    final loc = Provider.of<LocalizationService>(context, listen: false);

    final List<String> categories = [
      'rent',
      'fuel',
      'wages',
      'electricity',
      'others',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? loc.translate('edit')
                    : loc.translate('add_expense'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: loc.translate('category'),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(loc.translate(cat)),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedCategory = val),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: loc.translate('total'),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: Text(loc.translate('date')),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: loc.translate('notes'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (amountController.text.isEmpty) return;
                    final amt = double.tryParse(amountController.text) ?? 0;
                    final newExpense = ExpenseModel(
                      id: expense?.id,
                      category: selectedCategory ?? 'others',
                      amount: amt,
                      date: selectedDate,
                      notes: notesController.text,
                    );

                    final provider = Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    );
                    if (isEditing) {
                      provider.updateExpense(newExpense);
                    } else {
                      provider.addExpense(newExpense);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(loc.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('expenses'))),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                final expense = provider.expenses[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getIconForCategory(expense.category)),
                  ),
                  title: Text(loc.translate(expense.category)),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(expense.date)),
                  trailing: Text(
                    '₹ ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () => _showExpenseDialog(expense),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(loc.translate('delete')),
                        content: Text(loc.translate('confirm_delete')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(loc.translate('cancel')),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteExpense(expense.id!);
                              Navigator.pop(ctx);
                            },
                            child: Text(loc.translate('delete')),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'rent':
        return Icons.home;
      case 'fuel':
        return Icons.local_gas_station;
      case 'wages':
        return Icons.people;
      case 'electricity':
        return Icons.electrical_services;
      default:
        return Icons.more_horiz;
    }
  }
}
