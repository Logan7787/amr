import 'package:flutter/material.dart';
import '../models/item.dart';
import '../data/repository.dart';

class ItemProvider with ChangeNotifier {
  final DataRepository _repository = DataRepository();
  List<Item> _items = [];

  List<Item> get items => _items;

  Future<void> loadItems() async {
    _items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> addItem(Item item) async {
    await _repository.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteItem(id);
    await loadItems();
  }
}
