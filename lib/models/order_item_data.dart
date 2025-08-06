class OrderItem {
  final String customerName; // Added customerName field
  final String itemCode;
  final String itemName;
  final double quantity;
  final String uom;
  final double itemRateAmount;
  final double itemNetAmount;

  OrderItem({
    this.customerName = '', // Default to empty string if not provided
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.uom,
    required this.itemRateAmount,
    required this.itemNetAmount,
  });

  // Empty constructor with default quantity 1
  factory OrderItem.empty() => OrderItem(
    customerName: '', // Default to empty string
    itemCode: '',
    itemName: '',
    quantity: 1.0,
    uom: '',
    itemRateAmount: 0.0,
    itemNetAmount: 0.0,
  );

  // CopyWith method for immutable updates
  OrderItem copyWith({
    String? customerName,
    String? itemCode,
    String? itemName,
    double? quantity,
    String? uom,
    double? itemRateAmount,
    double? itemNetAmount,
  }) {
    return OrderItem(
      customerName:
          customerName ??
          this.customerName, // Preserve the original customerName
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      uom: uom ?? this.uom,
      quantity: quantity ?? this.quantity,
      itemRateAmount: itemRateAmount ?? this.itemRateAmount,
      itemNetAmount:
          itemNetAmount ??
          this.itemNetAmount, // Preserve the original itemNetAmount
    );
  }

  // Convert to Map for serialization
  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName, // Include customerName in serialization
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'uom': uom,
      'itemRateAmount': itemRateAmount,
      'itemNetAmount': itemNetAmount,
    };
  }

  // Create from Map for deserialization
  static OrderItem fromFirestore(Map<String, dynamic> map) {
    return OrderItem(
      customerName: map['customerName'],
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      uom: map['uom'] ?? '',
      itemRateAmount: map['itemRateAmount']?.toDouble() ?? 0.0,
      itemNetAmount: map['itemNetAmount']?.toDouble() ?? 0.0,
    );
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        customerName == other.customerName &&
        other.itemCode == itemCode &&
        other.itemName == itemName &&
        other.quantity == quantity &&
        other.uom == uom &&
        other.itemRateAmount == itemRateAmount &&
        other.itemNetAmount == itemNetAmount;
  }

  // Hashcode implementation
  @override
  int get hashCode {
    return Object.hash(
      customerName,
      itemCode.hashCode,
      itemName.hashCode,
      quantity.hashCode,
      uom.hashCode,
      itemRateAmount.hashCode,
      itemNetAmount.hashCode,
    );
  }

  // For debugging/logging (shows all fields)
  @override
  String toString() {
    return 'OrderItem('
        'customerName: $customerName, '
        'itemCode: $itemCode, '
        'itemName: $itemName, '
        'quantity: $quantity, '
        'uom: $uom, '
        'itemNetAmount: $itemNetAmount, '
        'itemRateAmount: $itemRateAmount)';
  }

  // For UI display (shows just the name)
  String toDisplayString() {
    return itemName;
  }

  // Calculated property for total amount
  double get totalAmount => quantity * itemRateAmount;

  // Formatted string for amount display
  String get formattedAmount => '₹${totalAmount.toStringAsFixed(2)}';
}
