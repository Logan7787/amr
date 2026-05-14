import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final DataRepository _repository = DataRepository();
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    _expenses = await _repository.getExpenses();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
  }

  Future<double> getPeriodTotal(DateTime start, DateTime end) async {
    return await _repository.getTotalExpenses(start, end);
  }
}
