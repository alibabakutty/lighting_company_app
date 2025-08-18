import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerMasterData {
  final String customerCode;
  final String customerName;
  final String? mobileNumber;
  final String? email;
  final Timestamp createdAt;

  CustomerMasterData({
    required this.customerCode,
    required this.customerName,
    this.mobileNumber,
    this.email,
    required this.createdAt,
  });

  // convert data from firestore to customerName Master object
  factory CustomerMasterData.fromfirestore(Map<String, dynamic> data) {
    return CustomerMasterData(
      customerCode: data['customer_code'] ?? '',
      customerName: data['customer_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] as String?,
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  String? get id => null;

  // convert Customer master data object to firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'customer_code': customerCode,
      'customer_name': customerName,
      if(mobileNumber != null) 'mobile_number': mobileNumber,
      if(email != null) 'email': email,
      'created_at': createdAt,
    };
  }
}
