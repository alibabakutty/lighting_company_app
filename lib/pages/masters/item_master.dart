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
  final TextEditingController _gstRateController = TextEditingController();
  final TextEditingController _gstAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _mrpAmountController = TextEditingController();
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
          _gstRateController.text = data.gstRate.toString();
          _gstAmountController.text = data.gstAmount.toString();
          _totalAmountController.text = data.totalAmount.toString();
          _mrpAmountController.text = data.mrpAmount.toString();
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
          gstRate: double.parse(_gstRateController.text.trim()),
          gstAmount: double.parse(_gstAmountController.text.trim()),
          totalAmount: double.parse(_totalAmountController.text.trim()),
          mrpAmount: double.parse(_mrpAmountController.text.trim()),
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
    _gstRateController.dispose();
    _gstAmountController.dispose();
    _totalAmountController.dispose();
    _mrpAmountController.dispose();
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Item Code Field
                      _buildCompactFormField(
                        controller: _itemCodeController,
                        label: 'Item Code',
                        icon: Icons.tag,
                        isReadOnly: widget.isDisplayMode || _isEditing,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),

                      // Item Name Field
                      _buildCompactFormField(
                        controller: _itemNameController,
                        label: 'Item Name',
                        icon: Icons.inventory,
                        isReadOnly: widget.isDisplayMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      // UOM Field
                      _buildCompactFormField(
                        controller: _uomController,
                        label: 'Unit of Measurement',
                        hint: 'Nos',
                        icon: Icons.straighten,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.25,
                      ),

                      // Amount Field
                      _buildCompactFormField(
                        controller: _itemRateAmountController,
                        label: 'Amount (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),

                      // GST Rate Field
                      _buildCompactFormField(
                        controller: _gstRateController,
                        label: 'GST Rate (%)',
                        icon: Icons.percent,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),

                      // GST Amount Field
                      _buildCompactFormField(
                        controller: _gstAmountController,
                        label: 'GST Amount (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),

                      // Total Amount Field
                      _buildCompactFormField(
                        controller: _totalAmountController,
                        label: 'Total Amount (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),

                      // MRP Amount Field
                      _buildCompactFormField(
                        controller: _mrpAmountController,
                        label: 'MRP Amount (₹)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),

                      // Status Dropdown
                      _buildCompactDropdown(
                        value: _selectedStatus,
                        items: ['Active', 'Inactive'],
                        label: 'Status',
                        isReadOnly: widget.isDisplayMode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                              // ignore: avoid_print
                              print('Status changed to: $value'); // Debug print
                            });
                          }
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
                                : const Text(
                                    'SAVE ITEM',
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

  Widget _buildCompactFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isReadOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextAlign textAlign = TextAlign.left,
    double fieldWidth = 0.5, // 50% width for label and input
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Label container (50% width)
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          // Input field container (50% width)
          Container(
            width: MediaQuery.of(context).size.width * fieldWidth,
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: isReadOnly,
              textAlign: textAlign,
              style: const TextStyle(fontSize: 15, height: 1.1),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                // ignore: unnecessary_null_comparison
                prefixIcon: icon != null ? Icon(icon, size: 18) : null,
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                filled: true,
                fillColor: isReadOnly ? Colors.grey.shade50 : Colors.white,
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required bool isReadOnly,
    required void Function(String?) onChanged,
    double fieldWidth = 0.25, // 50% width for label and dropdown
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Label container (50% width)
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          // Dropdown container (50% width)
          Container(
            width: MediaQuery.of(context).size.width * fieldWidth,
            child: DropdownButtonFormField<String>(
              value: value,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: isReadOnly ? null : onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                filled: true,
                fillColor: isReadOnly ? Colors.grey.shade50 : Colors.white,
              ),
              hint: const Text('Select'),
              disabledHint: Text(value ?? ''),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }
}
