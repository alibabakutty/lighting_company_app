import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool isReadOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final double fieldWidth;
  final bool initialObscureText;

  const PasswordFormField({
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
    this.initialObscureText = true,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.initialObscureText;
  }

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
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          // Input field container (50% width)
          SizedBox(
            width: MediaQuery.of(context).size.width * widget.fieldWidth,
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType ?? TextInputType.visiblePassword,
              readOnly: widget.isReadOnly,
              textAlign: widget.textAlign,
              obscureText: _obscureText,
              style: const TextStyle(fontSize: 15, height: 1.1),
              decoration: InputDecoration(
                hintText: widget.hint,
                isDense: true,
                contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                prefixIcon: Icon(widget.icon, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                suffixIcon: !widget.isReadOnly
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
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
                fillColor: widget.isReadOnly ? Colors.grey.shade50 : Colors.white,
              ),
              validator: widget.validator,
            ),
          ),
        ],
      ),
    );
  }
}