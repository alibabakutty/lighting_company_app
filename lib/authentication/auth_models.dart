import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin, executive }

class AuthUser {
  final String uid;
  final String? username;
  final String? executiveName;
  final String? email;
  final String? mobileNumber;
  final UserRole role;
  final GeoPoint? lastLoginLocation;

  AuthUser({
    required this.uid,
    this.username,
    this.executiveName,
    this.email,
    this.mobileNumber,
    this.role = UserRole.user,
    this.lastLoginLocation,
  });

  factory AuthUser.fromMap(
    Map<String, dynamic> data,
    String uid,
    UserRole role,
  ) {
    return AuthUser(
      uid: uid,
      username: data['username']?.toString(),
      executiveName:
          data['executiveName']?.toString() ?? data['name']?.toString(),
      email: data['email']?.toString(),
      mobileNumber:
          data['mobileNumber']?.toString() ?? data['mobile_number']?.toString(),
      role: role,
      lastLoginLocation: data['lastLoginLocation'] as GeoPoint?,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isExecutive => role == UserRole.executive;
  bool get isRegularUser => role == UserRole.user;
}

class SignUpCredentials {
  final String email;
  final String password;
  final UserRole role;

  SignUpCredentials({
    required this.email,
    required this.password,
    required this.role,
  });
}

class AdminSignUpData extends SignUpCredentials {
  final String username;

  AdminSignUpData({
    required super.email,
    required super.password,
    required this.username,
  }) : super(role: UserRole.admin);
}

class ExecutiveSignUpData extends SignUpCredentials {
  final String name;
  final String mobileNumber;

  ExecutiveSignUpData({
    required super.email,
    required super.password,
    required this.name,
    required this.mobileNumber,
  }) : super(role: UserRole.executive);
}
