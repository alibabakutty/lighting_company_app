import 'package:flutter/material.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';

class CompactCustomerDropdown extends StatelessWidget {
  final CustomerMasterData? value;
  final List<CustomerMasterData> items;
  final String label;
  final bool isReadOnly;
  final void Function(CustomerMasterData?) onChanged;
  final double fieldWidth;

  const CompactCustomerDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.isReadOnly,
    required this.onChanged,
    this.fieldWidth = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Label container (20% width)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
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
          // Dropdown container (fieldWidth width)
          SizedBox(
            width: MediaQuery.of(context).size.width * fieldWidth,
            child: DropdownButtonFormField<CustomerMasterData>(
              value: value,
              items: items.map((CustomerMasterData customer) {
                return DropdownMenuItem<CustomerMasterData>(
                  value: customer,
                  child: Text(
                    customer.customerName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: isReadOnly ? null : onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
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
                fillColor: Colors.grey.shade50,
              ),
              hint: const Text('Select customer'),
              disabledHint: Text(value?.customerName ?? ''),
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }
}
