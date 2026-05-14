class ExpenseModel {
  int? id;
  String category;
  double amount;
  DateTime date;
  String? notes;

  ExpenseModel({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'] ?? 0.0,
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }
}
