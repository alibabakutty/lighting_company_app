import 'package:flutter/material.dart';

class CompactDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String label;
  final bool isReadOnly;
  final void Function(String?) onChanged;
  final double fieldWidth;

  const CompactDropdown({
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
          SizedBox(
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
