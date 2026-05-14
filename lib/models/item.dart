class Item {
  int? id;
  String nameTa;
  String? nameEn;
  String? unit;
  double rate;
  double stockQuantity;
  double lowStockThreshold;

  Item({
    this.id,
    required this.nameTa,
    this.nameEn,
    this.unit,
    required this.rate,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ta': nameTa,
      'name_en': nameEn,
      'unit': unit,
      'rate': rate,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      nameTa: map['name_ta'],
      nameEn: map['name_en'],
      unit: map['unit'],
      rate: map['rate'],
      stockQuantity: map['stock_quantity'] ?? 0.0,
      lowStockThreshold: map['low_stock_threshold'] ?? 0.0,
    );
  }
}
