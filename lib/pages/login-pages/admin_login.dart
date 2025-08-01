import 'package:flutter/material.dart';
import 'package:lighting_company_app/authentication/auth_exception.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
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

  final AuthService _auth = AuthService();

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
      setState(() => _isLoading = true);

      try {
        if (_isSignUp) {
          await _auth.createAdminAccount(
            AdminSignUpData(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              username: _usernameController.text.trim(),
            ),
          );
        } else {
          await _auth.adminSignIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          // Save successful credentials
          await _saveCredentials();
        }

        if (mounted) {
          context.go('/admin_dashboard');
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
        if (mounted) setState(() => _isLoading = false);
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
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),

              // Credentials history dropdown
              if (!_isSignUp && _credentialsHistory.isNotEmpty) ...[
                OutlinedButton(
                  onPressed: () => setState(
                    () => _showCredentialsHistory = !_showCredentialsHistory,
                  ),
                  child: const Text('Show previous credentials'),
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
                        decoration: InputDecoration(
                          labelText: 'Admin Username',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Admin Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                          : Text(_isSignUp ? 'Create Admin' : 'Sign In'),
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
                  ),
                  TextButton(
                    onPressed: _toggleSignUp,
                    child: Text(_isSignUp ? 'Sign In' : 'Create Account'),
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
