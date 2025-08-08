import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/authentication/auth_exception.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/models/executive_master_data.dart';
import 'package:lighting_company_app/pages/masters/utils/compact_form_field.dart';
import 'package:lighting_company_app/pages/masters/utils/password_form_field.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class ExecutiveMaster extends StatefulWidget {
  final String? executiveName;
  final bool isDisplayMode;
  const ExecutiveMaster({
    super.key,
    this.executiveName,
    this.isDisplayMode = false,
  });

  @override
  State<ExecutiveMaster> createState() => _ExecutiveMasterState();
}

class _ExecutiveMasterState extends State<ExecutiveMaster> {
  final FirebaseService firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  ExecutiveMasterData? _executiveMasterData;
  String? executiveNameFromArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          executiveNameFromArgs = args;
          _isEditing = !widget.isDisplayMode;
        });
        _fetchSupplierData(widget.executiveName!);
      } else if (widget.executiveName != null) {
        setState(() {
          _isEditing = !widget.isDisplayMode;
        });
        _fetchSupplierData(widget.executiveName!);
      }
    });
  }

  Future<void> _fetchSupplierData(String executiveName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await firebaseService.getExecutiveByExecutiveName(
        executiveName,
      );

      if (data != null) {
        setState(() {
          _executiveMasterData = data;
          _nameController.text = data.executiveName;
          _mobileController.text = data.mobileNumber;
          _userIdController.text = data.email;
          _passwordController.text = data.password;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Executive not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading executive: $e')));
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
        final executiveData = ExecutiveMasterData(
          executiveName: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _userIdController.text.trim(),
          password: _passwordController.text.trim(),
          createdAt: _executiveMasterData?.createdAt ?? Timestamp.now(),
        );

        bool success;

        if (_isEditing && _executiveMasterData != null) {
          // update existing supplier
          success = await firebaseService
              .updateExecutiveMasterDataByExecutiveName(
                _executiveMasterData!.executiveName,
                executiveData,
              );
        } else {
          // create new supplier - check if mobile number exists
          final existingSupplier = await firebaseService
              .getExecutiveByMobileNumber(executiveData.mobileNumber);

          if (existingSupplier != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Executive ${executiveData.executiveName} with ${executiveData.mobileNumber} already exists.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Also check if supplier name already exists
          final existingExecutiveByName = await firebaseService
              .getExecutiveByExecutiveName(executiveData.executiveName);

          if (existingExecutiveByName != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Executive ${executiveData.executiveName} already exists.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // create auth account first
          final authService = AuthService();
          await authService.createExecutiveAccount(
            ExecutiveSignUpData(
              email: executiveData.email,
              password: executiveData.password,
              name: executiveData.executiveName,
              mobileNumber: executiveData.mobileNumber,
            ),
          );

          success = await firebaseService.addExecutiveMasterData(executiveData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? (_isEditing ? 'Executive updated!' : 'Executive created!')
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
            _executiveMasterData = null;
            _formKey.currentState?.reset();

            if (_isEditing) {
              context.go('/cda_page', extra: 'executive');
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
              ? 'EXECUTIVE DETAILS: ${executiveNameFromArgs ?? widget.executiveName ?? ''}'
              : _isEditing
              ? 'EDIT EXECUTIVE: ${executiveNameFromArgs ?? widget.executiveName ?? ''}'
              : 'CREATE NEW EXECUTIVE',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'executive'),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Executive Name Field
                      CompactFormField(
                        controller: _nameController,
                        label: 'Executive Name',
                        icon: Icons.business,
                        hint: 'Enter executive name',
                        isReadOnly: widget.isDisplayMode && !_isEditing,
                        fieldWidth: 0.53, // 53% of width for input
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter executive name';
                          }
                          return null;
                        },
                      ),

                      // Mobile Number Field
                      CompactFormField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        hint: 'Enter mobile number',
                        keyboardType: TextInputType.phone,
                        isReadOnly: widget.isDisplayMode && !_isEditing,
                        fieldWidth: 0.53, // 53% of width for input
                        textAlign: TextAlign.left,
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

                      // User ID Field
                      CompactFormField(
                        controller: _userIdController,
                        label: 'Email',
                        icon: Icons.email,
                        hint: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        isReadOnly: widget.isDisplayMode && !_isEditing,
                        fieldWidth: 0.53, // 53% of width for input
                        textAlign: TextAlign.left,
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

                      // Password Field
                      PasswordFormField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        hint: 'Enter password',
                        isReadOnly: widget.isDisplayMode && !_isEditing,
                        initialObscureText:
                            true, // You can control this from parent
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

                      if (!widget.isDisplayMode) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submitForm,
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _isEditing
                                        ? 'UPDATE EXECUTIVE'
                                        : 'SAVE EXECUTIVE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
