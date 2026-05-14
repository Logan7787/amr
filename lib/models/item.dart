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
      rate: double.tryParse(map['rate']?.toString() ?? '0') ?? 0.0,
      stockQuantity: double.tryParse(map['stock_quantity']?.toString() ?? '0') ?? 0.0,
      lowStockThreshold: double.tryParse(map['low_stock_threshold']?.toString() ?? '0') ?? 0.0,
    );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
