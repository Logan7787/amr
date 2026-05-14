import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../data/repository.dart';

class CustomerProvider with ChangeNotifier {
  final DataRepository _repository = DataRepository();
  List<Customer> _customers = [];

  List<Customer> get customers => _customers;

  Future<void> loadCustomers() async {
    _customers = await _repository.getCustomers();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    await _repository.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _repository.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _repository.deleteCustomer(id);
    await loadCustomers();
  }
}
