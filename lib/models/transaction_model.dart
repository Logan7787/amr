class TransactionModel {
  int? id;
  String type; // 'INVOICE' or 'QUOTE'
  String txnNumber;
  DateTime date;
  int? customerId;
  double totalAmount;
  double paidAmount;
  double balanceAmount;
  String status; // 'PAID', 'UNPAID', 'PARTIAL'
  String? notes;

  // List of items (not stored in same table, but useful for UI object)
  List<TransactionItem>? items;

  TransactionModel({
    this.id,
    required this.type,
    required this.txnNumber,
    required this.date,
    this.customerId,
    required this.totalAmount,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.status = 'PAID',
    this.notes,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'txn_number': txnNumber,
      'date': date.toIso8601String(),
      'customer_id': customerId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      txnNumber: map['txn_number'],
      date: DateTime.parse(map['date']),
      customerId: map['customer_id'],
      totalAmount: double.tryParse(map['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(map['paid_amount']?.toString() ?? '0') ?? 0.0,
      balanceAmount: double.tryParse(map['balance_amount']?.toString() ?? '0') ?? 0.0,
      status: map['status'] ?? 'PAID',
      notes: map['notes'],
    );
  }
}

class TransactionItem {
  int? id;
  int? txnId;
  int? itemId;
  String itemName;
  double qty;
  double rate;
  double amount;

  TransactionItem({
    this.id,
    this.txnId,
    this.itemId,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'txn_id': txnId,
      'item_id': itemId,
      'item_name': itemName,
      'qty': qty,
      'rate': rate,
      'amount': amount,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      txnId: map['txn_id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      qty: double.tryParse(map['qty']?.toString() ?? '0') ?? 0.0,
      rate: double.tryParse(map['rate']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
