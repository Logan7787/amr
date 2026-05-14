import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/supplier.dart';

class SupplierProvider extends ChangeNotifier {
  final DataRepository _repository = DataRepository();
  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();
    _suppliers = await _repository.getSuppliers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier) async {
    await _repository.insertSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _repository.updateSupplier(supplier);
    await loadSuppliers();
  }

  Future<void> deleteSupplier(int id) async {
    await _repository.deleteSupplier(id);
    await loadSuppliers();
  }
}
