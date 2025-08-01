class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthErrorMessages {
  static const Map<String, String> _messages = {
    'user-not-found': 'No user found with this email',
    'wrong-password': 'The email or password is incorrect',
    'invalid-credential': 'The email or password is incorrect',
    'email-already-in-use': 'Email is already in use',
    'weak-password': 'Password is too weak',
    'invalid-email': 'Please enter a valid email address',
    'too-many-requests': 'Too many requests. Please try again later',
    'user-disabled': 'This account has been disabled',
    'operation-not-allowed': 'Email/password accounts are not enabled',
    'token-expired': 'Session expired. Please login again',
    'invalid-auth-token': 'Session expired. Please login again',
    'no-user': 'No user is currently signed in',
    'wrong-role': 'This account does not have the required permissions',
    'empty-credentials': 'Email and password cannot be empty',
  };

  static String getMessage(String code) =>
      _messages[code] ?? 'Authentication error occurred';
}
