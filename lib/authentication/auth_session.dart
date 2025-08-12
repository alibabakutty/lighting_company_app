import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';

class AuthSession {
  final AuthUser user;
  final DateTime loginTime;
  final String sessionToken;
  final bool isActive;
  final GeoPoint? loginLocation;

  AuthSession({
    required this.user,
    DateTime? loginTime,
    required this.sessionToken,
    this.isActive = true,
    this.loginLocation,
  }) : loginTime = loginTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': user.uid,
      'userEmail': user.email,
      'userRole': user.role.toString(),
      'loginTime': loginTime.toIso8601String(),
      'sessionToken': sessionToken,
      'isActive': isActive,
      'username': user.username,
      'executiveName': user.executiveName,
      'loginLocation': loginLocation,
    };
  }

  factory AuthSession.fromMap(Map<String, dynamic> map, AuthUser user) {
    return AuthSession(
      user: user,
      loginTime: DateTime.parse(map['loginTime']),
      sessionToken: map['sessionToken'],
      isActive: map['isActive'],
      loginLocation: map['loginLocation'] as GeoPoint?,
    );
  }
}
