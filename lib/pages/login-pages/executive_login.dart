import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lighting_company_app/authentication/auth_exception.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/service/location_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class ExecutiveLogin extends StatefulWidget {
  const ExecutiveLogin({super.key});

  @override
  State<ExecutiveLogin> createState() => _ExecutiveLoginState();
}

class _ExecutiveLoginState extends State<ExecutiveLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
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
    super.dispose();
  }

  Future<void> _loadCredentialsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('executive_credentials_history') ?? [];

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
    final history = prefs.getStringList('executive_credentials_history') ?? [];

    // Add new credentials if not already present
    if (!history.contains(credentials)) {
      history.add(credentials);
      // Keep only last 3 credentials
      if (history.length > 3) {
        history.removeAt(0);
      }
      await prefs.setStringList('executive_credentials_history', history);
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
        await authProvider.supplierSignIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          loginLocation: loginLocation,
        );

        // Save successful credentials
        await _saveCredentials();

        // On successful login, navigate to executive dashboard
        if (mounted) {
          context.go('/order_master');
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'An unexpected error occurred. Please try again.',
              ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo and title
              Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Executive Portal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to take order',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Credentials history dropdown
              if (_credentialsHistory.isNotEmpty) ...[
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
                              'executive_credentials_history',
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
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(fontSize: 18),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Executive ID',
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
                    // Password field
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
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
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

                    const SizedBox(height: 8),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          await _handleForgotPassword();
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to reset password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
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
            content: Text('Failed to send reset email. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
