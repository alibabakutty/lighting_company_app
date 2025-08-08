import 'package:lighting_company_app/models/order_item_data.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

extension OrderItemExtension on OrderItem {
  static OrderItem empty() => OrderItem(
    customerName: '', // Default to empty string
    itemCode: '',
    itemName: '',
    itemRateAmount: 0.0,
    quantity: 1,
    uom: '',
    itemNetAmount: 0.0,
  );
}

String getDisplayName(String name) =>
    name.length <= 12 ? name : '${name.substring(0, 12)}...';
