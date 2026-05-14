import '../models/customer.dart';
import '../models/item.dart';
import '../models/transaction_model.dart';
import '../models/supplier.dart';
import '../models/purchase_model.dart';
import '../models/expense_model.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import '../core/supabase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();

  // --- Customers ---
  Future<int> insertCustomer(Customer customer) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('customers').insert(customer.toMap()).select().single();
      int id = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      customer.id = id;
      return id;
    }
    final db = await _dbHelper.database;
    int id = await db.insert('customers', customer.toMap());
    customer.id = id;
    _supabaseService.syncCustomers(); // Non-blocking sync
    return id;
  }

  Future<List<Customer>> getCustomers() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('customers').select();
      return List.generate(response.length, (i) => Customer.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<int> updateCustomer(Customer customer) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('customers').update(customer.toMap()).eq('id', customer.id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    int count = await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    _supabaseService.syncCustomers();
    return count;
  }

  Future<int> deleteCustomer(int id) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('customers').delete().eq('id', id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Items ---
  Future<int> insertItem(Item item) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('items').insert(item.toMap()).select().single();
      int id = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      item.id = id;
      return id;
    }
    final db = await _dbHelper.database;
    int id = await db.insert('items', item.toMap());
    item.id = id;
    _supabaseService.syncItems();
    return id;
  }

  Future<List<Item>> getItems() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('items').select();
      return List.generate(response.length, (i) => Item.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<int> updateItem(Item item) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('items').update(item.toMap()).eq('id', item.id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    int count = await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    _supabaseService.syncItems();
    return count;
  }

  Future<int> deleteItem(int id) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('items').delete().eq('id', id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Transactions ---
  Future<int> createTransaction(TransactionModel txn) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transactions').insert(txn.toMap()).select().single();
      int txnId = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      
      if (txn.items != null) {
        for (var item in txn.items!) {
          item.txnId = txnId;
          await Supabase.instance.client.from('transaction_items').insert(item.toMap());
          
          if (txn.type == 'INVOICE' && item.itemId != null) {
            final itemData = await Supabase.instance.client.from('items').select('stock_quantity').eq('id', item.itemId as Object).single();
            double currentStock = double.tryParse(itemData['stock_quantity']?.toString() ?? '0') ?? 0.0;
            await Supabase.instance.client.from('items').update({'stock_quantity': currentStock - (item.qty)}).eq('id', item.itemId as Object);
          }
        }
      }
      return txnId;
    }
    final db = await _dbHelper.database;
    int txnId = await db.insert('transactions', txn.toMap());

    if (txn.items != null) {
      for (var item in txn.items!) {
        item.txnId = txnId;
        await db.insert('transaction_items', item.toMap());

        // Deduct stock if it's an Invoice
        if (txn.type == 'INVOICE' && item.itemId != null) {
          await db.rawUpdate(
            'UPDATE items SET stock_quantity = stock_quantity - ? WHERE id = ?',
            [item.qty, item.itemId],
          );
        }
      }
    }
    _supabaseService.syncTransactions();
    return txnId;
  }

  Future<List<TransactionModel>> getTransactions() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transactions').select().order('date', ascending: false);
      return List.generate(response.length, (i) => TransactionModel.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionItem>> getTransactionItems(int txnId) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transaction_items').select().eq('txn_id', txnId as Object);
      return List.generate(response.length, (i) => TransactionItem.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_items',
      where: 'txn_id = ?',
      whereArgs: [txnId],
    );
    return List.generate(maps.length, (i) => TransactionItem.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> getCustomerTransactions(int customerId) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transactions').select().eq('customer_id', customerId as Object).order('date', ascending: false);
      return List.generate(response.length, (i) => TransactionModel.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<Item>> getLowStockItems() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('items').select();
      final items = List.generate(response.length, (i) => Item.fromMap(response[i]));
      return items.where((i) => (i.stockQuantity ?? 0) <= (i.lowStockThreshold ?? 0)).toList();
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'stock_quantity <= low_stock_threshold',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('purchase_items').select().eq('purchase_id', purchaseId as Object);
      return List.generate(response.length, (i) => PurchaseItem.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return List.generate(maps.length, (i) => PurchaseItem.fromMap(maps[i]));
  }

  // --- Reports ---
  Future<double> getDailySales(DateTime date) async {
    if (kIsWeb) {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await Supabase.instance.client.from('transactions').select('total_amount').eq('type', 'INVOICE').like('date', '$dateStr%');
      double total = 0;
      for (var row in response) {
        total += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    }
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM transactions WHERE date LIKE ? AND type = "INVOICE"',
      ['$dateStr%'],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<double> getMonthlySales(DateTime date) async {
    if (kIsWeb) {
      final dateStr = date.toIso8601String().substring(0, 7); // YYYY-MM
      final response = await Supabase.instance.client.from('transactions').select('total_amount').eq('type', 'INVOICE').like('date', '$dateStr%');
      double total = 0;
      for (var row in response) {
        total += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    }
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().substring(0, 7); // YYYY-MM
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM transactions WHERE date LIKE ? AND type = "INVOICE"',
      ['$dateStr%'],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getSalesLast7Days() async {
    if (kIsWeb) {
      final List<Map<String, dynamic>> results = [];
      for (int i = 6; i >= 0; i--) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String dateStr = date.toIso8601String().split('T')[0];
        final response = await Supabase.instance.client.from('transactions').select('total_amount').eq('type', 'INVOICE').like('date', '$dateStr%');
        double total = 0;
        for (var row in response) {
          total += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
        }
        results.add({'date': dateStr, 'total': total});
      }
      return results;
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = [];

    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String dateStr = date.toIso8601String().split('T')[0];
      final res = await db.rawQuery(
        'SELECT SUM(total_amount) as total FROM transactions WHERE date LIKE ? AND type = "INVOICE"',
        ['$dateStr%'],
      );
      double total = 0;
      if (res.isNotEmpty && res.first['total'] != null) {
        total = res.first['total'] as double;
      }
      results.add({'date': dateStr, 'total': total});
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getExpensesLast7Days() async {
    if (kIsWeb) {
      final List<Map<String, dynamic>> results = [];
      for (int i = 6; i >= 0; i--) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String dateStr = date.toIso8601String().split('T')[0];
        final response = await Supabase.instance.client.from('expenses').select('amount').like('date', '$dateStr%');
        double total = 0;
        for (var row in response) {
          total += (row['amount'] as num?)?.toDouble() ?? 0.0;
        }
        results.add({'date': dateStr, 'total': total});
      }
      return results;
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = [];

    for (int i = 6; i >= 0; i--) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      String dateStr = date.toIso8601String().split('T')[0];
      final res = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE date LIKE ?',
        ['$dateStr%'],
      );
      double total = 0;
      if (res.isNotEmpty && res.first['total'] != null) {
        total = res.first['total'] as double;
      }
      results.add({'date': dateStr, 'total': total});
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getTopSellingItems() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transaction_items').select('item_name, qty');
      Map<String, double> qtys = {};
      for (var row in response) {
        String name = row['item_name']?.toString() ?? 'Unknown';
        double qty = (row['qty'] as num?)?.toDouble() ?? 0.0;
        qtys[name] = (qtys[name] ?? 0) + qty;
      }
      var list = qtys.entries.map((e) => {'item_name': e.key, 'total_qty': e.value}).toList();
      list.sort((a, b) => (b['total_qty'] as double).compareTo(a['total_qty'] as double));
      return list.take(5).toList();
    }
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT item_name, SUM(qty) as total_qty 
      FROM transaction_items 
      GROUP BY item_name 
      ORDER BY total_qty DESC 
      LIMIT 5
    ''');
  }

  // --- Suppliers ---
  Future<int> insertSupplier(Supplier supplier) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('suppliers').insert(supplier.toMap()).select().single();
      int id = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      supplier.id = id;
      return id;
    }
    final db = await _dbHelper.database;
    int id = await db.insert('suppliers', supplier.toMap());
    supplier.id = id;
    _supabaseService.syncSuppliers();
    return id;
  }

  Future<List<Supplier>> getSuppliers() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('suppliers').select();
      return List.generate(response.length, (i) => Supplier.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('suppliers');
    return List.generate(maps.length, (i) => Supplier.fromMap(maps[i]));
  }

  Future<int> updateSupplier(Supplier supplier) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('suppliers').update(supplier.toMap()).eq('id', supplier.id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('suppliers').delete().eq('id', id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Purchases ---
  Future<int> createPurchase(PurchaseModel purchase) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('purchases').insert(purchase.toMap()).select().single();
      int purchaseId = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      if (purchase.items != null) {
        for (var item in purchase.items!) {
          item.purchaseId = purchaseId;
          await Supabase.instance.client.from('purchase_items').insert(item.toMap());
          if (item.itemId != null) {
            final itemData = await Supabase.instance.client.from('items').select('stock_quantity').eq('id', item.itemId as Object).single();
            double currentStock = double.tryParse(itemData['stock_quantity']?.toString() ?? '0') ?? 0.0;
            await Supabase.instance.client.from('items').update({'stock_quantity': currentStock + (item.qty)}).eq('id', item.itemId as Object);
          }
        }
      }
      return purchaseId;
    }
    final db = await _dbHelper.database;
    int purchaseId = await db.insert('purchases', purchase.toMap());

    if (purchase.items != null) {
      for (var item in purchase.items!) {
        item.purchaseId = purchaseId;
        await db.insert('purchase_items', item.toMap());

        // Increase stock if it's a purchase of a known item
        if (item.itemId != null) {
          await db.rawUpdate(
            'UPDATE items SET stock_quantity = stock_quantity + ? WHERE id = ?',
            [item.qty, item.itemId],
          );
        }
      }
    }
    _supabaseService.syncPurchases();
    return purchaseId;
  }

  Future<List<PurchaseModel>> getPurchases() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('purchases').select().order('date', ascending: false);
      return List.generate(response.length, (i) => PurchaseModel.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('purchases');
    return List.generate(maps.length, (i) => PurchaseModel.fromMap(maps[i]));
  }

  // --- Expenses ---
  Future<int> insertExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('expenses').insert(expense.toMap()).select().single();
      int id = int.tryParse(response['id']?.toString() ?? '0') ?? 0;
      expense.id = id;
      return id;
    }
    final db = await _dbHelper.database;
    int id = await db.insert('expenses', expense.toMap());
    expense.id = id;
    _supabaseService.syncExpenses();
    return id;
  }

  Future<List<ExpenseModel>> getExpenses() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('expenses').select().order('date', ascending: false);
      return List.generate(response.length, (i) => ExpenseModel.fromMap(response[i]));
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => ExpenseModel.fromMap(maps[i]));
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('expenses').update(expense.toMap()).eq('id', expense.id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('expenses').delete().eq('id', id as Object);
      return 1;
    }
    final db = await _dbHelper.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('expenses').select('amount').gte('date', start.toIso8601String()).lte('date', end.toIso8601String());
      double total = 0;
      for (var row in response) {
        total += (row['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    }
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<double> getTotalPurchases(DateTime start, DateTime end) async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('purchases').select('total_amount').gte('date', start.toIso8601String()).lte('date', end.toIso8601String());
      double total = 0;
      for (var row in response) {
        total += (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    }
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM purchases WHERE date BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getCollectionData() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('transactions').select('customer_id, balance_amount, customers(name, mobile)').gt('balance_amount', 0);
      Map<int, Map<String, dynamic>> collections = {};
      for (var row in response) {
        int cid = row['customer_id'];
        double bal = (row['balance_amount'] as num?)?.toDouble() ?? 0.0;
        var cust = row['customers'];
        if (cust != null) {
          if (!collections.containsKey(cid)) {
            collections[cid] = {
              'name': cust['name'],
              'mobile': cust['mobile'],
              'pending_balance': 0.0,
            };
          }
          collections[cid]!['pending_balance'] += bal;
        }
      }
      var list = collections.values.toList();
      list.sort((a, b) => (b['pending_balance'] as double).compareTo(a['pending_balance'] as double));
      return list;
    }
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT c.name, c.mobile, SUM(t.balance_amount) as pending_balance
      FROM customers c
      JOIN transactions t ON c.id = t.customer_id
      WHERE t.balance_amount > 0
      GROUP BY c.id
      ORDER BY pending_balance DESC
    ''');
  }

  // --- Settings ---
  Future<void> updateSetting(String key, String value) async {
    if (kIsWeb) {
      await Supabase.instance.client.from('settings').upsert({'key': key, 'value': value});
      return;
    }
    final db = await _dbHelper.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _supabaseService.syncSettings(); // Non-blocking sync
  }

  Future<Map<String, String>> getSettings() async {
    if (kIsWeb) {
      final response = await Supabase.instance.client.from('settings').select();
      return {for (var m in response) m['key'] as String: m['value'] as String};
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    return {for (var m in maps) m['key'] as String: m['value'] as String};
  }
}
