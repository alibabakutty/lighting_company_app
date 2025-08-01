import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/authentication/auth_exception.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/models/supplier_master_data.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class SupplierMaster extends StatefulWidget {
  final String? supplierName;
  final bool isDisplayMode;
  const SupplierMaster({
    super.key,
    this.supplierName,
    this.isDisplayMode = false,
  });

  @override
  State<SupplierMaster> createState() => _SupplierMasterState();
}

class _SupplierMasterState extends State<SupplierMaster> {
  final FirebaseService firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  SupplierMasterData? _supplierMasterData;
  String? supplierNameFromArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          supplierNameFromArgs = args;
          _isEditing = !widget.isDisplayMode;
        });
        _fetchSupplierData(widget.supplierName!);
      } else if (widget.supplierName != null) {
        setState(() {
          _isEditing = !widget.isDisplayMode;
        });
        _fetchSupplierData(widget.supplierName!);
      }
    });
  }

  Future<void> _fetchSupplierData(String supplierName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await firebaseService.getSupplierBySupplierName(
        supplierName,
      );

      if (data != null) {
        setState(() {
          _supplierMasterData = data;
          _nameController.text = data.supplierName;
          _mobileController.text = data.mobileNumber;
          _userIdController.text = data.email;
          _passwordController.text = data.password;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Supplier not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading supplier: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final supplierData = SupplierMasterData(
          supplierName: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _userIdController.text.trim(),
          password: _passwordController.text.trim(),
          createdAt: _supplierMasterData?.createdAt ?? Timestamp.now(),
        );

        bool success;

        if (_isEditing && _supplierMasterData != null) {
          // update existing supplier
          success = await firebaseService
              .updateSupplierMasterDataBySupplierName(
                _supplierMasterData!.supplierName,
                supplierData,
              );
        } else {
          // create new supplier - check if mobile number exists
          final existingSupplier = await firebaseService
              .getSupplierByMobileNumber(supplierData.mobileNumber);

          if (existingSupplier != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Supplier with mobile number already exists.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Also check if supplier name already exists
          final existingSupplierByName = await firebaseService
              .getSupplierBySupplierName(supplierData.supplierName);

          if (existingSupplierByName != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Supplier with this name already exists.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // create auth account first
          final authService = AuthService();
          await authService.createSupplierAccount(
            SupplierSignUpData(
              email: supplierData.email,
              password: supplierData.password,
              name: supplierData.supplierName,
              mobileNumber: supplierData.mobileNumber,
            ),
          );

          success = await firebaseService.addSupplierMasterData(supplierData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? (_isEditing ? 'Supplier updated!' : 'Supplier created!')
                    : 'Operation failed!',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );

          if (success) {
            // clear all fields after successful save
            _nameController.clear();
            _mobileController.clear();
            _userIdController.clear();
            _passwordController.clear();
            _supplierMasterData = null;
            _formKey.currentState?.reset();

            if (_isEditing) {
              context.go('/cda_page', extra: 'supplier');
            }
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
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDisplayMode
              ? 'Supplier Details: ${supplierNameFromArgs ?? widget.supplierName ?? ''}'
              : _isEditing
              ? 'Edit Supplier: ${supplierNameFromArgs ?? widget.supplierName ?? ''}'
              : 'Create New Supplier',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'supplier'),
        ),
        actions: [
          if (widget.isDisplayMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!widget.isDisplayMode && _isEditing)
            IconButton(
              onPressed: _isSubmitting ? null : _submitForm,
              icon: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Supplier Registration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Supplier Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Supplier Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter supplier name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mobile Number Field
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (!RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // User ID Field
                    TextFormField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.email),
                        hintText: 'Enter email address',
                      ),
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: widget.isDisplayMode && !_isEditing
                            ? null
                            : IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                      ),
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (!widget.isDisplayMode &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter a password';
                        }
                        if (!widget.isDisplayMode && value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    if (!widget.isDisplayMode)
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register Supplier',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    if (widget.isDisplayMode && _isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  // Reset to original values
                                  if (_supplierMasterData != null) {
                                    _nameController.text =
                                        _supplierMasterData!.supplierName;
                                    _mobileController.text =
                                        _supplierMasterData!.mobileNumber;
                                    _userIdController.text =
                                        _supplierMasterData!.email;
                                    _passwordController.text =
                                        _supplierMasterData!.password;
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 18),
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
