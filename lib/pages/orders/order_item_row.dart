import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/models/order_item_data.dart';

class OrderItemRow extends StatefulWidget {
  final int index;
  final OrderItem item;
  final List<CustomerMasterData> allCustomers;
  final List<ItemMasterData> allItems;
  final bool isLoadingCustomers;
  final bool isLoadingItems;
  final Function(int) onRemove;
  final Function(int, OrderItem) onUpdate;
  final VoidCallback onCustomerSelected;
  final VoidCallback onItemSelected;
  final VoidCallback onAddNewRow;

  const OrderItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.allCustomers,
    required this.allItems,
    required this.isLoadingCustomers,
    required this.isLoadingItems,
    required this.onRemove,
    required this.onUpdate,
    required this.onCustomerSelected,
    required this.onItemSelected,
    required this.onAddNewRow,
  });

  @override
  State<OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<OrderItemRow> {
  late FocusNode _itemSearchFocusNode;
  late TextEditingController _customerNameController;
  late TextEditingController _itemNameController;
  final TextEditingController _itemSearchController = TextEditingController();
  late TextEditingController _quantityController;
  late TextEditingController _uomController;
  late TextEditingController _netAmountController;

  @override
  void initState() {
    super.initState();
    _itemSearchFocusNode = FocusNode();
    _quantityController = TextEditingController(
      text: widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(2),
    );
    _uomController = TextEditingController(text: widget.item.uom);
    _netAmountController = TextEditingController(
      text:
          '₹${(widget.item.totalAmount * widget.item.quantity).toStringAsFixed(2)}',
    );
    _itemNameController = TextEditingController(text: widget.item.itemName);

    _quantityController.addListener(_updateAmount);
    _itemNameController.addListener(_handleNameChange);
  }

  void _handleNameChange() {
    if (_itemNameController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onUpdate(widget.index, OrderItem.empty());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onUpdate(
            widget.index,
            widget.item.copyWith(itemName: _itemNameController.text),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(OrderItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item != oldWidget.item) {
      if (widget.item.itemCode.isEmpty) {
        _itemSearchController.clear();
      } else {
        _itemNameController.text = widget.item.itemName;
      }
      _quantityController.text = widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toStringAsFixed(2);
      _uomController.text = widget.item.uom;
      _netAmountController.text = formatAmount(
        widget.item.totalAmount * widget.item.quantity,
      );
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateAmount);
    _itemNameController.removeListener(_handleNameChange);
    _quantityController.dispose();
    _uomController.dispose();
    _netAmountController.dispose();
    _customerNameController.dispose();
    _itemNameController.dispose();
    _itemSearchController.dispose();
    _itemSearchFocusNode.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final amount = quantity * widget.item.totalAmount;

    _netAmountController.text = formatAmount(amount);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onUpdate(widget.index, widget.item.copyWith(quantity: quantity));
      }
    });
  }

  void _handleItemSelected(ItemMasterData selectedItem) {
    final newItem = OrderItem(
      itemCode: selectedItem.itemCode.toString(),
      itemName: selectedItem.itemName,
      itemRateAmount: selectedItem.itemRateAmount,
      quantity: 1.0,
      uom: selectedItem.uom,
      gstRate: selectedItem.gstRate,
      gstAmount: selectedItem.gstAmount,
      totalAmount: selectedItem.totalAmount,
      mrpAmount: selectedItem.mrpAmount,
      itemNetAmount: selectedItem.totalAmount * 1.0,
    );

    _quantityController.text = '1';
    _netAmountController.text = formatAmount(selectedItem.totalAmount);
    _itemNameController.text = selectedItem.itemName;

    widget.onUpdate(widget.index, newItem);
    widget.onItemSelected();
    _itemSearchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First Row - S.No and Product Name
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          width:
              MediaQuery.of(context).size.width * 0.99, // 90% of screen width
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // S.No
              SizedBox(
                width: 40,
                height: 32,
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Product Name
              SizedBox(
                width: 280,
                height: 32,
                child: widget.item.itemCode.isEmpty
                    ? _buildItemSearchField()
                    : TextFormField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
              ),
            ],
          ),
        ),

        // Second Row - Qty, Rate, Amount, Buttons
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          width:
              MediaQuery.of(context).size.width * 0.99, // 90% of screen width

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 83),
              // Qty
              SizedBox(
                width: 40,
                height: 32,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _updateAmount(),
                ),
              ),
              const SizedBox(width: 4),
              // UOM
              SizedBox(
                width: 45,
                height: 32,
                child: TextFormField(
                  controller: _uomController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Rate
              SizedBox(
                width: 70,
                height: 32,
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: widget.item.totalAmount > 0
                        ? '₹${widget.item.totalAmount.toStringAsFixed(2)}'
                        : '₹0.00',
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Amount
              SizedBox(
                width: 70,
                height: 32,
                child: TextFormField(
                  readOnly: true,
                  controller: _netAmountController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Add button
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.green, size: 16),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    widget.onAddNewRow();
                  },
                ),
              ),
              const SizedBox(width: 2),
              // Delete button
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    widget.onRemove(widget.index);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemSearchField() {
    return RawAutocomplete<ItemMasterData>(
      focusNode: _itemSearchFocusNode,
      textEditingController: _itemSearchController,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (widget.isLoadingItems) return const Iterable.empty();

        return widget.allItems.where((item) {
          if (textEditingValue.text.isEmpty) return true;
          final searchTerm = textEditingValue.text.toLowerCase();
          return item.itemCode.toString().toLowerCase().contains(searchTerm) ||
              item.itemName.toLowerCase().contains(searchTerm);
        });
      },
      onSelected: _handleItemSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'SEARCH BY CODE/NAME',
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          keyboardType: TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: SizedBox(
            height: 180,
            child: widget.isLoadingItems
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options.elementAt(index);
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade800),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(
                            vertical: -4,
                          ), // Extremely compact
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                          ),
                          title: Text(
                            '${item.itemCode} - ${item.itemName} - ₹${item.totalAmount}',
                            style: const TextStyle(fontSize: 13, height: 1.1),
                          ),
                          onTap: () => onSelected(item),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

String formatAmount(double amount) {
  // Format with 2 decimal places and comma separators
  return '₹${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}
