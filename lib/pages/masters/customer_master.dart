import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class CustomerMaster extends StatefulWidget {
  final String? customerName;
  final bool isDisplayMode;
  const CustomerMaster({
    super.key,
    this.customerName,
    this.isDisplayMode = false,
  });

  @override
  State<CustomerMaster> createState() => _CustomerMasterState();
}

class _CustomerMasterState extends State<CustomerMaster> {
  final FirebaseService firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  CustomerMasterData? _customerMasterData;

  @override
  void initState() {
    super.initState();
    if (widget.customerName != null) {
      _fetchCustomerData(widget.customerName!);
      _isEditing = !widget.isDisplayMode;
    }
  }

  Future<void> _fetchCustomerData(String customerName) async {
    setState(() => _isLoading = true);
    try {
      final data = await firebaseService.getCustomerByCustomerName(
        customerName,
      );
      if (data != null) {
        setState(() {
          _customerMasterData = data;
          _customerNameController.text = data.customerName;
          _mobileNumberController.text = data.mobileNumber;
          _emailController.text = data.email;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Customer not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final customerData = CustomerMasterData(
        customerName: _customerNameController.text,
        mobileNumber: _mobileNumberController.text,
        email: _emailController.text,
        createdAt: _customerMasterData?.createdAt ?? Timestamp.now(),
      );

      bool success;
      if (_isEditing && _customerMasterData != null) {
        success = await firebaseService.updateCustomerMasterDataByCustomerName(
          _customerMasterData!.customerName,
          customerData,
        );
      } else {
        final existing = await firebaseService.getCustomerByCustomerName(
          customerData.customerName,
        );
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer name already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        success = await firebaseService.addCustomerMasterData(customerData);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Customer updated!' : 'Customer created!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (!_isEditing) _resetForm();
        if (_isEditing) context.go('/cda_page', extra: 'customer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _customerNameController.clear();
    _mobileNumberController.clear();
    setState(() {
      _customerMasterData = null;
      _isEditing = false;
    });
    _formKey.currentState?.reset();
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Master'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'customer'),
        ),
        actions: widget.isDisplayMode
            ? [
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                  onPressed: _toggleEditMode,
                ),
              ]
            : null,
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
                    Text(
                      _isEditing
                          ? 'Edit Customer'
                          : widget.isDisplayMode
                          ? 'Customer Details'
                          : 'Add New Customer',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Customer Name Field
                    TextFormField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mobile Number Field
                    TextFormField(
                      controller: _mobileNumberController,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Action Buttons
                    if (!widget.isDisplayMode || _isEditing)
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isEditing
                                    ? 'Update Customer'
                                    : 'Save Customer',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
