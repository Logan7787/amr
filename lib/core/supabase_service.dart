import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';
import '../models/transaction_model.dart';
import '../models/purchase_model.dart';
import '../data/db_helper.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: anonKey);
    }
  }

  final _supabase = Supabase.instance.client;
  DataRepository? _repository;

  DataRepository get repository => _repository ??= DataRepository();

  Future<void> syncAll() async {
    await syncSettings();
    await syncCustomers();
    await syncItems();
    await syncSuppliers();
    await syncExpenses();
    await syncTransactions();
    await syncPurchases();
  }

  Future<void> syncSettings() async {
    try {
      final settings = await repository.getSettings();
      for (var entry in settings.entries) {
        await _supabase.from('settings').upsert({
          'key': entry.key,
          'value': entry.value,
        });
      }
    } catch (e) {
      debugPrint('Sync Error (Settings): $e');
    }
  }

  Future<void> syncCustomers() async {
    try {
      final localCustomers = await repository.getCustomers();
      for (var customer in localCustomers) {
        // Upsert to Supabase
        await _supabase.from('customers').upsert(customer.toMap());
      }

      // Pull from Supabase
      // for (var data in remoteData) {
      //   // Sync remote to local
      // }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> syncItems() async {
    try {
      final items = await repository.getItems();
      for (var item in items) {
        await _supabase.from('items').upsert(item.toMap());
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> syncSuppliers() async {
    try {
      final suppliers = await repository.getSuppliers();
      for (var s in suppliers) {
        await _supabase.from('suppliers').upsert(s.toMap());
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> syncExpenses() async {
    try {
      final expenses = await repository.getExpenses();
      for (var e in expenses) {
        await _supabase.from('expenses').upsert(e.toMap());
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> syncTransactions() async {
    try {
      final transactions = await repository.getTransactions();
      for (var txn in transactions) {
        // 1. Sync Transaction Header
        await _supabase.from('transactions').upsert(txn.toMap());

        // 2. Sync Transaction Items
        final items = await repository.getTransactionItems(txn.id!);
        for (var item in items) {
          await _supabase.from('transaction_items').upsert(item.toMap());
        }
      }
    } catch (e) {
      debugPrint('Sync Error (Transactions): $e');
    }
  }

  Future<void> syncPurchases() async {
    try {
      final purchases = await repository.getPurchases();
      for (var p in purchases) {
        // 1. Sync Purchase Header
        await _supabase.from('purchases').upsert(p.toMap());

        // 2. Sync Purchase Items
        final items = await repository.getPurchaseItems(p.id!);
        for (var item in items) {
          await _supabase.from('purchase_items').upsert(item.toMap());
        }
      }
    } catch (e) {
      debugPrint('Sync Error (Purchases): $e');
    }
  }
}

