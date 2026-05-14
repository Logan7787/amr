import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static DatabaseHelper get instance => _instance;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'amr_billing.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE items ADD COLUMN stock_quantity REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE items ADD COLUMN low_stock_threshold REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN status TEXT DEFAULT "PAID"',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN paid_amount REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN balance_amount REAL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transaction_items ADD COLUMN item_id INTEGER',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          mobile TEXT,
          address TEXT,
          gst_no TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_id INTEGER,
          txn_number TEXT,
          date TEXT NOT NULL,
          total_amount REAL,
          paid_amount REAL DEFAULT 0,
          balance_amount REAL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE purchase_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_id INTEGER,
          item_id INTEGER,
          item_name TEXT,
          qty REAL,
          rate REAL,
          amount REAL,
          FOREIGN KEY (purchase_id) REFERENCES purchases (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          notes TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT,
        address TEXT,
        gst_no TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_ta TEXT NOT NULL,
        name_en TEXT,
        unit TEXT,
        rate REAL,
        stock_quantity REAL DEFAULT 0,
        low_stock_threshold REAL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        txn_number TEXT NOT NULL,
        date TEXT NOT NULL,
        customer_id INTEGER,
        total_amount REAL,
        paid_amount REAL DEFAULT 0,
        balance_amount REAL DEFAULT 0,
        status TEXT DEFAULT "PAID",
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        txn_id INTEGER,
        item_id INTEGER,
        item_name TEXT,
        qty REAL,
        rate REAL,
        amount REAL,
        FOREIGN KEY (txn_id) REFERENCES transactions (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT,
        address TEXT,
        gst_no TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER,
        txn_number TEXT,
        date TEXT NOT NULL,
        total_amount REAL,
        paid_amount REAL DEFAULT 0,
        balance_amount REAL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER,
        item_id INTEGER,
        item_name TEXT,
        qty REAL,
        rate REAL,
        amount REAL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }
}
