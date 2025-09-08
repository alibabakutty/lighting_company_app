import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/pages/masters/utils/compact_dropdown.dart';
import 'package:lighting_company_app/pages/masters/utils/compact_form_field.dart';
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
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _discountDeductedAmountController =
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

  String formatToRounded(String value) {
    final number = double.tryParse(value);
    if (number == null) return value;
    return number.toStringAsFixed(0); // rounds to integer
  }

  // Add this method to your class
  void _formatDecimalInput(TextEditingController controller) {
    final value = double.tryParse(controller.text);
    if (value != null) {
      controller.text = value.toStringAsFixed(2);
    }
  }

  void _calculateAmounts() {
    final itemRate = double.tryParse(_itemRateAmountController.text) ?? 0;
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final gstRate = double.tryParse(_gstRateController.text) ?? 0;

    if (itemRate < 0) return;
    if (discountPercent < 0 || discountPercent > 100) return;
    if (gstRate < 0) return;

    final discountAmount = itemRate * discountPercent / 100;
    final discountedPrice = itemRate - discountAmount;
    final gstAmount = discountedPrice * gstRate / 100;
    final totalAmount = discountedPrice + gstAmount;

    setState(() {
      // update discount deducted amount (price after discount before GST)
      _discountDeductedAmountController.text = discountedPrice.toStringAsFixed(
        2,
      );
      // Update GST amount and total amount
      _gstAmountController.text = gstAmount.toStringAsFixed(2);
      _totalAmountController.text = totalAmount.toStringAsFixed(2);

      // Force rounding in UI for discount and GST rate
      if (_discountController.text.isNotEmpty) {
        _discountController.text = formatToRounded(_discountController.text);
        _discountController.selection = TextSelection.fromPosition(
          TextPosition(offset: _discountController.text.length),
        );
      }

      if (_gstRateController.text.isNotEmpty) {
        _gstRateController.text = formatToRounded(_gstRateController.text);
        _gstRateController.selection = TextSelection.fromPosition(
          TextPosition(offset: _gstRateController.text.length),
        );
      }

      if (_mrpAmountController.text.isEmpty ||
          double.tryParse(_mrpAmountController.text) == itemRate) {
        _mrpAmountController.text = totalAmount.toStringAsFixed(2);
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
          _itemRateAmountController.text = data.itemRateAmount.toStringAsFixed(
            2,
          );
          _discountController.text = data.discount.toString();
          _discountDeductedAmountController.text = data.discountDeductedAmount
              .toStringAsFixed(2);
          _gstRateController.text = data.gstRate.toString();
          _gstAmountController.text = data.gstAmount.toStringAsFixed(2);
          _totalAmountController.text = data.totalAmount.toStringAsFixed(2);
          _mrpAmountController.text = data.mrpAmount.toStringAsFixed(2);
          _selectedStatus = data.itemStatus ? 'Active' : 'Inactive';
        });

        _calculateAmounts();
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
          discount: double.parse(
            _discountController.text.trim().isEmpty
                ? '0'
                : _discountController.text.trim(),
          ),
          discountDeductedAmount: double.parse(
            _discountDeductedAmountController.text.trim().isEmpty
                ? '0'
                : _discountDeductedAmountController.text.trim(),
          ),
          gstRate: double.parse(_gstRateController.text.trim()),
          gstAmount: double.parse(_gstAmountController.text.trim()),
          totalAmount: double.parse(_totalAmountController.text.trim()),
          mrpAmount: double.parse(_mrpAmountController.text.trim()),
          itemStatus: _selectedStatus == 'Active',
          timestamp: _itemMasterData?.timestamp ?? Timestamp.now(),
        );

        bool success;

        if (_isEditing && _itemMasterData != null) {
          success = await firebaseService.updateItemMasterDataByItemName(
            _itemMasterData!.itemName,
            itemData,
          );
        } else {
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
            _itemCodeController.clear();
            _itemNameController.clear();
            _uomController.text = 'Nos';
            _itemRateAmountController.clear();
            _discountController.clear();
            _discountDeductedAmountController.clear();
            _gstRateController.clear();
            _gstAmountController.clear();
            _totalAmountController.clear();
            _mrpAmountController.clear();
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
    _discountController.dispose();
    _discountDeductedAmountController.dispose();
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
              ? 'ITEM DETAILS: ${itemNameFromArgs ?? ''}'
              : _isEditing
              ? 'EDIT ITEM: ${itemNameFromArgs ?? ''}'
              : 'CREATE NEW ITEM',
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
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
                      CompactFormField(
                        controller: _itemCodeController,
                        label: 'Item Code',
                        icon: Icons.tag,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.25,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      CompactFormField(
                        controller: _itemNameController,
                        label: 'Item Name',
                        icon: Icons.inventory,
                        isReadOnly: widget.isDisplayMode,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      CompactFormField(
                        controller: _uomController,
                        label: 'Unit of Measurement',
                        hint: 'Nos',
                        icon: Icons.straighten,
                        isReadOnly: widget.isDisplayMode,
                        fieldWidth: 0.25,
                      ),
                      CompactFormField(
                        controller: _itemRateAmountController,
                        label: 'Amount',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        onChanged: (_) => _calculateAmounts(),
                        onEditingComplete: () =>
                            _formatDecimalInput(_itemRateAmountController),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                      CompactFormField(
                        controller: _discountController,
                        label: 'Discount',
                        icon: Icons.discount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        isPercentage: true,
                        onChanged: (_) => _calculateAmounts(),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final discountValue = double.tryParse(value);
                          if (discountValue == null) return 'Invalid discount';
                          if (discountValue < 0 || discountValue > 100) {
                            return 'Must be 0-100';
                          }
                          return null;
                        },
                      ),
                      CompactFormField(
                        controller: _discountDeductedAmountController,
                        label: 'Discount Deducted Amount',
                        icon: Icons.discount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        onChanged: (_) => _calculateAmounts(),
                        onEditingComplete: () => _formatDecimalInput(
                          _discountDeductedAmountController,
                        ),
                      ),
                      CompactFormField(
                        controller: _gstRateController,
                        label: 'GST Rate',
                        icon: Icons.receipt,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        isPercentage: true,
                        onChanged: (_) => _calculateAmounts(),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      CompactFormField(
                        controller: _gstAmountController,
                        label: 'GST Amount',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: true,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        onEditingComplete: () =>
                            _formatDecimalInput(_gstAmountController),
                      ),
                      CompactFormField(
                        controller: _totalAmountController,
                        label: 'Total Amount',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: true,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        onEditingComplete: () =>
                            _formatDecimalInput(_totalAmountController),
                      ),
                      CompactFormField(
                        controller: _mrpAmountController,
                        label: 'MRP Amount',
                        icon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        isReadOnly: widget.isDisplayMode,
                        textAlign: TextAlign.right,
                        fieldWidth: 0.25,
                        onEditingComplete: () =>
                            _formatDecimalInput(_mrpAmountController),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid amount';
                          }
                          return null;
                        },
                      ),
                      CompactDropdown(
                        value: _selectedStatus,
                        items: ['Active', 'Inactive'],
                        label: 'Status',
                        isReadOnly: widget.isDisplayMode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
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
                                : Text(
                                    _isEditing ? 'UPDATE ITEM' : 'SAVE ITEM',
                                    style: const TextStyle(
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
