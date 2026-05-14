class Customer {
  int? id;
  String name;
  String? mobile;
  String? address;
  String? gstNo;

  Customer({
    this.id,
    required this.name,
    this.mobile,
    this.address,
    this.gstNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'gst_no': gstNo,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      address: map['address'],
      gstNo: map['gst_no'],
    );
  }
}
