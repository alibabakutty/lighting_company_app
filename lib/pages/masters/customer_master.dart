import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:lighting_company_app/pages/masters/utils/compact_form_field.dart';
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
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  CustomerMasterData? _customerMasterData;
  String? customerNameFromArgs;

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
          _mobileNumberController.text = data.mobileNumber ?? '';
          _emailController.text = data.email ?? '';
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
        customerCode: _customerCodeController.text,
        customerName: _customerNameController.text,
        mobileNumber: _mobileNumberController.text,
        email: _emailController.text,
        createdAt: _customerMasterData?.createdAt ?? Timestamp.now(),
      );

      bool success;
      if (_isEditing && _customerMasterData != null) {
        // update existing customer
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
              SnackBar(
                content: Text(
                  'Customer name ${customerData.customerName} already exists',
                ),
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
              success
                  ? (_isEditing ? 'Customer updated!' : 'Customer created!')
                  : 'Failed to save customer',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (!_isEditing) _resetForm();
        if (_isEditing) context.go('/cda_page', extra: 'customer');
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
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _customerNameController.clear();
    _mobileNumberController.clear();
    _emailController.clear();
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
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDisplayMode
              ? 'CUSTOMER DETAILS: ${widget.customerName ?? ''}'
              : _isEditing
              ? 'EDIT CUSTOMER: ${widget.customerName ?? ''}'
              : 'CREATE NEW CUSTOMER',
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1565C0), // Royal Blue
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Customer Code Field
                      CompactFormField(
                        controller: _customerCodeController,
                        label: 'Customer Code',
                        icon: Icons.code,
                        isReadOnly: widget.isDisplayMode || _isEditing,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer code';
                          }
                          return null;
                        },
                      ),

                      // Customer Name Field
                      CompactFormField(
                        controller: _customerNameController,
                        label: 'Customer Name',
                        icon: Icons.person,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter customer name';
                          }
                          return null;
                        },
                      ),

                      // Mobile Number Field
                      CompactFormField(
                        controller: _mobileNumberController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                      ),

                      // Email Field
                      CompactFormField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.53,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      // Action Buttons
                      if (!widget.isDisplayMode) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1565C0), // Royal Blue
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
                                        ? 'UPDATE CUSTOMER'
                                        : 'SAVE CUSTOMER',
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
