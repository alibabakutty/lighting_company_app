enum UserRole { user, admin, supplier }

class AuthUser {
  final String uid;
  final String? username;
  final String? supplierName;
  final String? email;
  final String? mobileNumber;
  final UserRole role;

  AuthUser({
    required this.uid,
    this.username,
    this.supplierName,
    this.email,
    this.mobileNumber,
    this.role = UserRole.user,
  });

  factory AuthUser.fromMap(
    Map<String, dynamic> data,
    String uid,
    UserRole role,
  ) {
    return AuthUser(
      uid: uid,
      username: data['username']?.toString(),
      supplierName:
          data['supplierName']?.toString() ?? data['name']?.toString(),
      email: data['email']?.toString(),
      mobileNumber:
          data['mobileNumber']?.toString() ?? data['mobile_number']?.toString(),
      role: role,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isSupplier => role == UserRole.supplier;
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

class SupplierSignUpData extends SignUpCredentials {
  final String name;
  final String mobileNumber;

  SupplierSignUpData({
    required super.email,
    required super.password,
    required this.name,
    required this.mobileNumber,
  }) : super(role: UserRole.supplier);
}
