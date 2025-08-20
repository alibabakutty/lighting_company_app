import 'package:flutter/material.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';

class CustomerInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final double fieldWidth;
  final List<CustomerMasterData> allCustomers;
  final bool isLoadingCustomers;
  final Function(CustomerMasterData) onCustomerSelected;
  final VoidCallback onCustomerCleared;

  const CustomerInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.textAlign = TextAlign.left,
    this.fieldWidth = 0.53,
    required this.allCustomers,
    required this.isLoadingCustomers,
    required this.onCustomerSelected,
    required this.onCustomerCleared,
  });

  @override
  State<CustomerInputField> createState() => _CustomerInputFieldState();
}

class _CustomerInputFieldState extends State<CustomerInputField> {
  late FocusNode _customerSearchFocusNode;
  late TextEditingController _searchController;
  CustomerMasterData? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _customerSearchFocusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(CustomerInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.text != oldWidget.controller.text) {
      _searchController.text = widget.controller.text;
    }
  }

  @override
  void dispose() {
    _customerSearchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleCustomerSelected(CustomerMasterData selectedCustomer) {
    setState(() {
      _selectedCustomer = selectedCustomer;
      widget.controller.text = selectedCustomer.customerName;
      _searchController.text = selectedCustomer.customerName;
    });
    widget.onCustomerSelected(selectedCustomer);
    FocusScope.of(context).unfocus();
  }

  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomer = null;
      widget.controller.clear();
      _searchController.clear();
    });
    widget.onCustomerCleared();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label container (20% width)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            padding: const EdgeInsets.only(right: 4.0), // reduce right padding
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          // Input field container (50% width)
          SizedBox(
            width: MediaQuery.of(context).size.width * widget.fieldWidth,
            height: 40,
            child: _selectedCustomer == null
                ? _buildCustomerSearchField()
                : _buildSelectedCustomerField(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSearchField() {
    return SizedBox(
      height: 30,
      child: RawAutocomplete<CustomerMasterData>(
        focusNode: _customerSearchFocusNode,
        textEditingController: _searchController,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (widget.isLoadingCustomers) return const Iterable.empty();

          return widget.allCustomers.where((customer) {
            if (textEditingValue.text.isEmpty) return true;
            final searchTerm = textEditingValue.text.toLowerCase();
            return customer.customerCode.toString().toLowerCase().contains(
                  searchTerm,
                ) ||
                customer.customerName.toLowerCase().contains(searchTerm);
          });
        },
        onSelected: _handleCustomerSelected,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return SizedBox(
            height: 30,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: widget.hint ?? '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 0.8,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          maxHeight: 20,
                          minWidth: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.controller.clear();
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 13, height: 1.0),
              validator: widget.validator,
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Material(
            elevation: 4.0,
            child: SizedBox(
              height: 180,
              child: widget.isLoadingCustomers
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final customer = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          minVerticalPadding: 4,
                          title: Text(
                            '${customer.customerCode} - ${customer.customerName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => onSelected(customer),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCustomerField() {
    return SizedBox(
      height: 30,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        readOnly: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 0.8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxHeight: 20, minWidth: 20),
            onPressed: _clearCustomerSelection,
          ),
        ),
        style: const TextStyle(fontSize: 13, height: 1.0),
      ),
    );
  }
}
