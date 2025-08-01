import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class ItemMaster extends StatefulWidget {
  final String? itemName;
  final bool isDisplayMode;
  const ItemMaster({super.key, this.itemName, this.isDisplayMode = false});

  @override
  State<ItemMaster> createState() => _ItemMasterState();
}

class _ItemMasterState extends State<ItemMaster> {
  final FirebaseService firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _uomController = TextEditingController(
    text: 'Nos',
  );
  final TextEditingController _itemRateAmountController =
      TextEditingController();
  String? _selectedStatus;

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  ItemMasterData? _itemMasterData;
  String? itemNameFromArgs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          itemNameFromArgs = args;
          _isEditing = !widget.isDisplayMode;
        });
        _fetchItemData(args);
      } else if (widget.itemName != null) {
        setState(() {
          itemNameFromArgs = widget.itemName;
          _isEditing = !widget.isDisplayMode;
        });
        _fetchItemData(widget.itemName!);
      }
    });
  }

  Future<void> _fetchItemData(String itemName) async {
    setState(() => _isLoading = true);

    try {
      final data = await firebaseService.getItemByItemName(itemName);
      if (data != null) {
        setState(() {
          _itemMasterData = data;
          _itemCodeController.text = data.itemCode.toString();
          _itemNameController.text = data.itemName;
          _uomController.text = data.uom;
          _itemRateAmountController.text = data.itemRateAmount.toString();
          _selectedStatus = data.itemStatus ? 'Active' : 'Inactive';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading item: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedStatus != null) {
      setState(() => _isSubmitting = true);

      try {
        final itemData = ItemMasterData(
          itemCode: int.parse(_itemCodeController.text.trim()),
          itemName: _itemNameController.text.trim(),
          uom: _uomController.text.trim().isNotEmpty
              ? _uomController.text.trim()
              : 'Nos',
          itemRateAmount: double.parse(_itemRateAmountController.text.trim()),
          itemStatus: _selectedStatus == 'Active',
          timestamp: _itemMasterData?.timestamp ?? Timestamp.now(),
        );

        bool success;

        if (_isEditing && _itemMasterData != null) {
          // Update existing item
          success = await firebaseService.updateItemMasterDataByItemName(
            _itemMasterData!.itemName,
            itemData,
          );
        } else {
          // Create new item - check if item code exists
          final existingItem = await firebaseService.getItemByItemCode(
            itemData.itemCode,
          );
          if (existingItem != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Item code ${itemData.itemCode} already exists',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          success = await firebaseService.addItemMasterData(itemData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? (_isEditing ? 'Item updated!' : 'Item created!')
                    : 'Operation failed',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );

          if (success) {
            // clear all fields after successful save
            _itemCodeController.clear();
            _itemNameController.clear();
            _uomController.text = 'Nos';
            _itemRateAmountController.clear();
            _itemMasterData = null;
            _formKey.currentState?.reset();

            if (_isEditing) {
              context.go('/cda_page', extra: 'item');
            }
          }
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
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _uomController.dispose();
    _itemRateAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDisplayMode
              ? 'Item Details: ${itemNameFromArgs ?? ''}'
              : _isEditing
              ? 'Edit Item: ${itemNameFromArgs ?? ''}'
              : 'Create New Item',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'item'),
        ),
        actions: [
          if (!widget.isDisplayMode)
            IconButton(
              icon: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
              onPressed: _isSubmitting ? null : _submitForm,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Item Code Field
                      TextFormField(
                        controller: _itemCodeController,
                        decoration: InputDecoration(
                          labelText: 'Item Code',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        readOnly: widget.isDisplayMode || _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Item Name Field
                      TextFormField(
                        controller: _itemNameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          prefixIcon: const Icon(Icons.inventory),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        readOnly: widget.isDisplayMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // UOM Field
                      TextFormField(
                        controller: _uomController,
                        decoration: InputDecoration(
                          labelText: 'Unit of Measurement (UOM)',
                          hintText: 'Nos',
                          prefixIcon: const Icon(Icons.straighten),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        readOnly: widget.isDisplayMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            _uomController.text = 'Nos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Amount Field
                      TextFormField(
                        controller: _itemRateAmountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        readOnly: widget.isDisplayMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: ['Active', 'Inactive'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: widget.isDisplayMode
                            ? null
                            : (value) =>
                                  setState(() => _selectedStatus = value),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.toggle_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (!widget.isDisplayMode &&
                              (value == null || value.isEmpty)) {
                            return 'Please select status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      if (!widget.isDisplayMode)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _submitForm,
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Save Item',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
