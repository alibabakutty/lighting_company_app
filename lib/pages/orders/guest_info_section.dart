import 'package:flutter/material.dart';

class GuestInfoSection extends StatefulWidget {
  final TextEditingController quantityController;
  final TextEditingController maleController;
  final TextEditingController femaleController;
  final TextEditingController kidsController;
  final Function() onTableAllocatePressed;
  final String? selectedTable;
  final int? totalMembers;
  final String? orderNumber;
  final Function(bool)? onExpansionChanged;

  const GuestInfoSection({
    super.key,
    required this.quantityController,
    required this.maleController,
    required this.femaleController,
    required this.kidsController,
    required this.onTableAllocatePressed,
    this.selectedTable,
    this.totalMembers,
    this.orderNumber,
    this.onExpansionChanged,
  });

  @override
  State<GuestInfoSection> createState() => _GuestInfoSectionState();
}

class _GuestInfoSectionState extends State<GuestInfoSection> {
  bool _isExpanded = true;
  bool _maleEntered = false;
  bool _femaleEntered = false;

  void _updateCounts({String? changedField}) {
    int male = int.tryParse(widget.maleController.text) ?? 0;
    int female = int.tryParse(widget.femaleController.text) ?? 0;
    final totalMembers = int.tryParse(widget.quantityController.text) ?? 0;

    if (changedField == 'male') {
      _maleEntered = widget.maleController.text.isNotEmpty;
    }
    if (changedField == 'female') {
      _femaleEntered = widget.femaleController.text.isNotEmpty;
    }

    if (_maleEntered && _femaleEntered) {
      int kids = totalMembers - male - female;
      widget.kidsController.text = kids >= 0 ? kids.toString() : '0';
      if (kids < 0) {
        widget.femaleController.text = (female + kids).toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onExpansionChanged?.call(_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (widget.orderNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Order: ${widget.orderNumber}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (widget.orderNumber != null) const SizedBox(width: 8),
                  if (widget.selectedTable != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Table: ${widget.selectedTable}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (widget.selectedTable != null) const SizedBox(width: 8),
                  if (widget.totalMembers != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Members: ${widget.totalMembers}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'GUEST',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildIconButton(
                    icon: Icons.table_restaurant,
                    color: Colors.teal.shade700,
                    onPressed: widget.onTableAllocatePressed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputWithIcon(
                      controller: widget.quantityController,
                      icon: Icons.group,
                      iconColor: Colors.blue.shade700,
                      label: 'Total',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputWithIcon(
                      controller: widget.maleController,
                      icon: Icons.man,
                      iconColor: Colors.blue.shade700,
                      label: 'Male',
                      onChanged: (_) => _updateCounts(changedField: 'male'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputWithIcon(
                      controller: widget.femaleController,
                      icon: Icons.woman,
                      iconColor: Colors.pink.shade600,
                      label: 'Female',
                      onChanged: (_) => _updateCounts(changedField: 'female'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputWithIcon(
                      controller: widget.kidsController,
                      icon: Icons.child_care,
                      iconColor: Colors.amber.shade800,
                      label: 'Kids',
                      isEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required Function() onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInputWithIcon({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isEnabled = true,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: iconColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              enabled: isEnabled,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              keyboardType: TextInputType.number,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
