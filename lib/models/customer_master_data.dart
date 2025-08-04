import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerMasterData {
  final String customerName;
  final String mobileNumber;
  final String email;
  final Timestamp createdAt;

  CustomerMasterData({
    required this.customerName,
    required this.mobileNumber,
    required this.email,
    required this.createdAt,
  });

  // convert data from firestore to customerName Master object
  factory CustomerMasterData.fromfirestore(Map<String, dynamic> data) {
    return CustomerMasterData(
      customerName: data['customer_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
    );
  }

  // convert Customer master data object to firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'customer_name': customerName,
      'mobile_number': mobileNumber,
      'email': email,
      'created_at': createdAt,
    };
  }
}
