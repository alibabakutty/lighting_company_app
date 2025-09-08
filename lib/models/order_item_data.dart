class OrderItem {
  final String itemCode;
  final String itemName;
  final double quantity;
  final String uom;
  final double itemRateAmount;
  final double discount;
  final double discountDeductedAmount;
  final double gstRate;
  final double gstAmount;
  final double totalAmount;
  final double mrpAmount;
  final double itemNetAmount;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.uom,
    required this.itemRateAmount,
    required this.discount,
    required this.discountDeductedAmount,
    required this.gstRate,
    required this.gstAmount,
    required this.totalAmount,
    required this.mrpAmount,
    required this.itemNetAmount,
  });

  // Empty constructor with default quantity 1
  factory OrderItem.empty() => OrderItem(
    itemCode: '',
    itemName: '',
    quantity: 1.0,
    uom: '',
    itemRateAmount: 0.0,
    discount: 0.0,
    discountDeductedAmount: 0.0,
    gstRate: 0.0,
    gstAmount: 0.0,
    totalAmount: 0.0,
    mrpAmount: 0.0,
    itemNetAmount: 0.0,
  );

  // CopyWith method for immutable updates
  OrderItem copyWith({
    String? itemCode,
    String? itemName,
    double? quantity,
    String? uom,
    double? itemRateAmount,
    double? discount,
    double? discountDeductedAmount,
    double? gstRate,
    double? gstAmount,
    double? totalAmount,
    double? mrpAmount,
    double? itemNetAmount,
  }) {
    return OrderItem(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      uom: uom ?? this.uom,
      quantity: quantity ?? this.quantity,
      itemRateAmount: itemRateAmount ?? this.itemRateAmount,
      discount: discount ?? this.discount,
      discountDeductedAmount:
          discountDeductedAmount ?? this.discountDeductedAmount,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      mrpAmount: mrpAmount ?? this.mrpAmount,
      itemNetAmount:
          itemNetAmount ??
          this.itemNetAmount, // Preserve the original itemNetAmount
    );
  }

  // Convert to Map for serialization
  Map<String, dynamic> toFirestore() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'uom': uom,
      'itemRateAmount': itemRateAmount,
      'discount': discount,
      'discountDeductedAmount': discountDeductedAmount,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'mrpAmount': mrpAmount,
      'itemNetAmount': itemNetAmount,
    };
  }

  // Create from Map for deserialization
  static OrderItem fromFirestore(Map<String, dynamic> map) {
    return OrderItem(
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      uom: map['uom'] ?? '',
      itemRateAmount: map['itemRateAmount']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      discountDeductedAmount: map['discountDeductedAmount']?.toDouble() ?? 0.0,
      gstRate: map['gstRate']?.toDouble() ?? 0.0,
      gstAmount: map['gstAmount']?.toDouble() ?? 0.0,
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      mrpAmount: map['mrpAmount']?.toDouble() ?? 0.0,
      itemNetAmount: map['itemNetAmount']?.toDouble() ?? 0.0,
    );
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.itemCode == itemCode &&
        other.itemName == itemName &&
        other.quantity == quantity &&
        other.uom == uom &&
        other.itemRateAmount == itemRateAmount &&
        other.discount == discount &&
        other.discountDeductedAmount == discountDeductedAmount &&
        other.gstRate == gstRate &&
        other.gstAmount == gstAmount &&
        other.totalAmount == totalAmount &&
        other.mrpAmount == mrpAmount &&
        other.itemNetAmount == itemNetAmount;
  }

  // Hashcode implementation
  @override
  int get hashCode {
    return Object.hash(
      itemCode.hashCode,
      itemName.hashCode,
      quantity.hashCode,
      uom.hashCode,
      itemRateAmount.hashCode,
      discount.hashCode,
      discountDeductedAmount.hashCode,
      gstRate.hashCode,
      gstAmount.hashCode,
      totalAmount.hashCode,
      mrpAmount.hashCode,
      itemNetAmount.hashCode,
    );
  }

  // For debugging/logging (shows all fields)
  @override
  String toString() {
    return 'OrderItem('
        'itemCode: $itemCode, '
        'itemName: $itemName, '
        'quantity: $quantity, '
        'uom: $uom, '
        'itemNetAmount: $itemNetAmount, '
        'discount: $discount, '
        'discountDeductedAmount: $discountDeductedAmount, '
        'gstRate: $gstRate, '
        'gstAmount: $gstAmount, '
        'totalAmount: $totalAmount, '
        'mrpAmount: $mrpAmount, '
        'itemRateAmount: $itemRateAmount)';
  }

  // For UI display (shows just the name)
  String toDisplayString() {
    return itemName;
  }

  // Calculated property for total amount
  double get totalCalculationAmount => quantity * totalAmount;

  // Formatted string for amount display
  String get formattedAmount => '₹${totalCalculationAmount.toStringAsFixed(2)}';
}
