class PurchaseModel {
  int? id;
  int? supplierId;
  String? txnNumber;
  DateTime date;
  double totalAmount;
  double paidAmount;
  double balanceAmount;
  String? notes;
  List<PurchaseItem>? items;

  PurchaseModel({
    this.id,
    this.supplierId,
    this.txnNumber,
    required this.date,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.notes,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'txn_number': txnNumber,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'notes': notes,
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'],
      supplierId: map['supplier_id'],
      txnNumber: map['txn_number'],
      date: DateTime.parse(map['date']),
      totalAmount: map['total_amount'] ?? 0.0,
      paidAmount: map['paid_amount'] ?? 0.0,
      balanceAmount: map['balance_amount'] ?? 0.0,
      notes: map['notes'],
    );
  }
}

class PurchaseItem {
  int? id;
  int? purchaseId;
  int? itemId;
  String itemName;
  double qty;
  double rate;
  double amount;

  PurchaseItem({
    this.id,
    this.purchaseId,
    this.itemId,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'item_id': itemId,
      'item_name': itemName,
      'qty': qty,
      'rate': rate,
      'amount': amount,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchase_id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      qty: map['qty'] ?? 0.0,
      rate: map['rate'] ?? 0.0,
      amount: map['amount'] ?? 0.0,
    );
  }
}
