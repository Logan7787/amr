import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/item.dart';
import '../data/repository.dart';

class TransactionProvider with ChangeNotifier {
  final DataRepository _repository = DataRepository();

  // Current Transaction State
  List<TransactionItem> _currentItems = [];
  double _totalAmount = 0.0;

  List<TransactionItem> get currentItems => _currentItems;
  double get totalAmount => _totalAmount;

  void addItem(Item item, double qty) {
    // Check if item already exists
    int index = _currentItems.indexWhere(
      (element) => element.itemId == item.id,
    );

    if (index != -1) {
      _currentItems[index].qty += qty;
      _currentItems[index].amount =
          _currentItems[index].qty * _currentItems[index].rate;
    } else {
      _currentItems.add(
        TransactionItem(
          itemId: item.id,
          itemName: item.nameTa, // Store Tamil name as snapshot
          qty: qty,
          rate: item.rate,
          amount: qty * item.rate,
        ),
      );
    }
    _calculateTotal();
    notifyListeners();
  }

  void updateItem(int index, double qty, double rate) {
    _currentItems[index].qty = qty;
    _currentItems[index].rate = rate;
    _currentItems[index].amount = qty * rate;
    _calculateTotal();
    notifyListeners();
  }

  void removeItem(int index) {
    _currentItems.removeAt(index);
    _calculateTotal();
    notifyListeners();
  }

  void _calculateTotal() {
    _totalAmount = _currentItems.fold(0, (sum, item) => sum + item.amount);
  }

  void clearTransaction() {
    _currentItems = [];
    _totalAmount = 0.0;
    notifyListeners();
  }

  Future<int> saveTransaction(TransactionModel txn) async {
    txn.items = _currentItems;
    txn.totalAmount = _totalAmount;
    int id = await _repository.createTransaction(txn);
    clearTransaction();
    return id;
  }
}
