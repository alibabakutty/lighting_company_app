import 'package:cloud_firestore/cloud_firestore.dart';

class TableMasterData {
  final int tableNumber;
  final int tableCapacity;
  final bool tableAvailability;
  final Timestamp createdAt;

  TableMasterData({
    required this.tableNumber,
    required this.tableCapacity,
    required this.tableAvailability,
    required this.createdAt,
  });

  // convert data from firestore to table master data
  factory TableMasterData.fromfirestore(Map<String, dynamic> data) {
    return TableMasterData(
      tableNumber: data['table_number'] ?? 0,
      tableCapacity: data['table_capacity'] ?? 0,
      tableAvailability: data['table_availability'] ?? false,
      createdAt: data['created_at'] ?? Timestamp.now(),
    );
  }

  // convert table master object to firestore data
  Map<String, dynamic> tofirestore() {
    return {
      'table_number': tableNumber,
      'table_capacity': tableCapacity,
      'table_availability': tableAvailability,
      'created_at': createdAt,
    };
  }
}
