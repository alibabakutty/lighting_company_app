import 'package:flutter/material.dart';

class CompactFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool isReadOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final double fieldWidth;

  const CompactFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.isReadOnly = false,
    this.keyboardType,
    this.validator,
    this.textAlign = TextAlign.left,
    this.fieldWidth = 0.53,
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
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          // Input field container (50% width)
          SizedBox(
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
                prefixIcon: Icon(icon, size: 18),
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
}