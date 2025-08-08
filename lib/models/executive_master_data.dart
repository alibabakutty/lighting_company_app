import 'package:cloud_firestore/cloud_firestore.dart';

class ExecutiveMasterData {
  final String executiveName;
  final String mobileNumber;
  final String email;
  final String password;
  final Timestamp createdAt;

  ExecutiveMasterData({
    required this.executiveName,
    required this.mobileNumber,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // convert data from firestore to ExecutiveName Master object
  factory ExecutiveMasterData.fromfirestore(Map<String, dynamic> data) {
    return ExecutiveMasterData(
      executiveName: data['executive_name'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
    );
  }

  // convert Executive master data object to firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'executive_name': executiveName,
      'mobile_number': mobileNumber,
      'email': email,
      'password': password,
      'created_at': createdAt,
    };
  }
}
