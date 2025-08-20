import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lighting_company_app/authentication/auth_exception.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/service/location_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false;
  List<Map<String, String>> _credentialsHistory = [];
  bool _showCredentialsHistory = false;
  // Location related state
  Position? _loginPosition;
  String _locationAddress = '';
  String _locationError = '';
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCredentialsHistory();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentialsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('admin_credentials_history') ?? [];

    setState(() {
      _credentialsHistory = history.map((e) {
        final parts = e.split('|');
        return {
          'email': parts[0],
          'password': parts.length > 1 ? parts[1] : '',
        };
      }).toList();
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final credentials = '${_emailController.text}|${_passwordController.text}';

    // Get current history
    final history = prefs.getStringList('admin_credentials_history') ?? [];

    // Add new credentials if not already present
    if (!history.contains(credentials)) {
      history.add(credentials);
      // Keep only last 3 credentials
      if (history.length > 3) {
        history.removeAt(0);
      }
      await prefs.setStringList('admin_credentials_history', history);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _isLocationLoading = true;
        _locationError = '';
      });

      try {
        // Step 1: Get current location
        _loginPosition = await LocationService.getCurrentLocation();

        if (_loginPosition == null) {
          setState(() {
            _locationError =
                'Could not verify your location. Please enable location services.';
            _isLoading = false;
            _isLocationLoading = false;
          });
          return;
        }

        // Step 2: Verify if within authorized area

        // Step 3: Get address for display
        _locationAddress = await LocationService.getAddressFromPosition(
          _loginPosition!,
        );

        // Step 4: Convert Position to GeoPoint
        final loginLocation = GeoPoint(
          _loginPosition!.latitude,
          _loginPosition!.longitude,
        );

        // Step 5: Proceed with authentication
        // ignore: use_build_context_synchronously
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (_isSignUp) {
          // create new admin account
          final signUpData = AdminSignUpData(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            username: _usernameController.text.trim(),
          );

          await authProvider.createAdminAccount(signUpData);

          // After creating account, automatically signin
          await authProvider.adminSignIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            loginLocation: loginLocation,
          );

          await _saveCredentials();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Admin account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // navigate to admin dashboard
            context.go('/admin_dashboard');
          }
        } else {
          // Sign in to existing account
          await authProvider.adminSignIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            loginLocation: loginLocation,
          );

          await _saveCredentials();

          if (mounted) {
            context.go('/admin_dashboard');
          }
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLocationLoading = false;
          });
        }
      }
    }
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
      if (!_isSignUp) _usernameController.clear();
    });
  }

  void _useCredential(Map<String, String> credential) {
    setState(() {
      _emailController.text = credential['email'] ?? '';
      _passwordController.text = credential['password'] ?? '';
      _showCredentialsHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                _isSignUp ? 'Create Admin Account' : 'Admin Login',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Create a new admin account'
                    : 'Sign in to access admin dashboard',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Credentials history dropdown
              if (!_isSignUp && _credentialsHistory.isNotEmpty) ...[
                OutlinedButton(
                  onPressed: () => setState(
                    () => _showCredentialsHistory = !_showCredentialsHistory,
                  ),
                  child: const Text(
                    'Show previous credentials',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_showCredentialsHistory) ...[
                  const SizedBox(height: 10),
                  ..._credentialsHistory.reversed.map(
                    (credential) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: Text(credential['email'] ?? ''),
                        subtitle: Text('••••••••'),
                        onTap: () => _useCredential(credential),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final updatedHistory = _credentialsHistory
                                .where((c) => c['email'] != credential['email'])
                                .toList();
                            await prefs.setStringList(
                              'admin_credentials_history',
                              updatedHistory
                                  .map((c) => '${c['email']}|${c['password']}')
                                  .toList(),
                            );
                            _loadCredentialsHistory();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Admin Username',
                          labelStyle: TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter username'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(fontSize: 18),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Admin Email',
                        labelStyle: TextStyle(fontSize: 16),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(fontSize: 18),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(fontSize: 16),
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // Location verification UI
                    if (_isLocationLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text(
                        'Verifying your location...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                    if (_locationError.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _locationError,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_loginPosition != null &&
                        _locationAddress.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verified Location:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(_locationAddress),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates: ${_loginPosition!.latitude.toStringAsFixed(6)}, '
                                '${_loginPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (!_isSignUp) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              _isSignUp ? 'Create Admin' : 'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? "Already have an admin account?"
                        : "Need to create an admin account?",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _toggleSignUp,
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Create Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
