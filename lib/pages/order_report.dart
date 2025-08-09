import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class OrderReport extends StatefulWidget {
  const OrderReport({super.key});

  @override
  State<OrderReport> createState() => _OrderReportState();
}

class _OrderReportState extends State<OrderReport> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Map<String, dynamic>> _flattenedOrders = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Date filters
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _specificDate;
  bool _useSpecificDate = false;

  // Totals
  double _totalQuantity = 0;
  double _totalCalculationAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load today's orders by default
      await _fetchOrders(dateString: DateTime.now().toString());
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading initial data: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrders({
    String? dateString,
    String? startDateString,
    String? endDateString,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _flattenedOrders.clear();
      _totalQuantity = 0;
      _totalCalculationAmount = 0;
    });

    try {
      List<Map<String, dynamic>> orders;

      if (startDateString != null && endDateString != null) {
        orders = await _firebaseService.getOrdersByDateRange(
          startDateString,
          endDateString,
        );
      } else if (dateString != null) {
        orders = await _firebaseService.getOrdersByDate(dateString);
      } else {
        orders = await _firebaseService.getOrdersByDate(
          DateTime.now().toString(),
        );
      }

      // Flatten orders into item rows
      for (var order in orders) {
        final items = await _firebaseService.getOrderItems(
          order['id'] ?? order['order_number'].toString(),
        );

        if (items.isNotEmpty) {
          for (var item in items) {
            _flattenedOrders.add({...order, 'itemData': item});
          }
        } else {
          _flattenedOrders.add({...order, 'itemData': null});
        }

        // Calculate totals
        _totalQuantity += (order['total_quantity'] ?? 0).toDouble();
        _totalCalculationAmount += (order['total_calculation_amount'] ?? 0)
            .toDouble();
      }

      setState(() {
        if (_flattenedOrders.isEmpty) _errorMessage = 'No orders found';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching orders: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    bool isStartDate = true,
    bool isSpecificDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isSpecificDate
          ? _specificDate ?? DateTime.now()
          : isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSpecificDate) {
          _specificDate = picked;
          _useSpecificDate = true;
        } else if (isStartDate) {
          _startDate = picked;
          _useSpecificDate = false;
        } else {
          _endDate = picked;
          _useSpecificDate = false;
        }
      });
    }
  }

  Widget _buildDateInputs() {
    return Column(
      children: [
        Row(
          children: [
            // Date filter type dropdown - made thinner
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                value: _useSpecificDate ? 'specific' : 'range',
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4, // Reduced padding to make it thinner
                    horizontal: 8,
                  ),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'specific',
                    child: Text('Specific', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'range',
                    child: Text('Range', style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _useSpecificDate = value == 'specific';
                    if (!_useSpecificDate) {
                      _specificDate = null;
                    }
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, size: 16),
                style: TextStyle(fontSize: 12, color: Colors.black87),
                isExpanded: true, // Ensures dropdown takes full width
              ),
            ),

            // Date inputs
            Expanded(
              child: _useSpecificDate
                  ? InkWell(
                      onTap: () => _selectDate(context, isSpecificDate: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          isDense: true,
                        ),
                        child: Text(
                          _specificDate != null
                              ? DateFormat('dd-MM-yyyy').format(_specificDate!)
                              : 'Select date',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(context, isStartDate: true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                isDense: true,
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('dd-MM-yyyy').format(
                                        _startDate!,
                                      ) // Full date format
                                    : 'Select date',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(context, isStartDate: false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'To',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 6,
                                ),
                                isDense: true,
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('dd-MM-yyyy').format(
                                        _endDate!,
                                      ) // Full date format
                                    : 'Select date',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Search button
            SizedBox(width: 4),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () {
                  if (_useSpecificDate && _specificDate != null) {
                    _fetchOrders(dateString: _specificDate.toString());
                  } else if (!_useSpecificDate &&
                      _startDate != null &&
                      _endDate != null) {
                    _fetchOrders(
                      startDateString: _startDate.toString(),
                      endDateString: _endDate.toString(),
                    );
                  }
                },
                child: Text('Search', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(String text, TextStyle style, Alignment alignment) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: alignment,
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildHeaderCell(String text, TextStyle style, Alignment alignment) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: alignment,
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildDataTableWithTotals() {
    final TextStyle headerTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    final TextStyle cellTextStyle = TextStyle(
      fontSize: 14,
      color: Colors.black87,
    );

    final TextStyle totalTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey.shade800,
    );

    // Reset totals
    _totalQuantity = 0;
    _totalCalculationAmount = 0;

    // Group items by order number
    final Map<String, List<Map<String, dynamic>>> ordersMap = {};
    for (var order in _flattenedOrders) {
      final orderNumber = order['order_number']?.toString() ?? 'N/A';
      if (!ordersMap.containsKey(orderNumber)) {
        ordersMap[orderNumber] = [];
      }
      ordersMap[orderNumber]!.add(order);
    }

    // Build rows for each order
    List<DataRow> rows = [];
    ordersMap.forEach((orderNumber, orderItems) {
      for (var order in orderItems) {
        final item = order['itemData'] as Map<String, dynamic>?;

        // Calculate GST amount if not directly available
        double gstAmount = item?['gstAmount'] ?? 0.0;
        if (gstAmount == 0 &&
            item?['gstRate'] != null &&
            item?['itemRateAmount'] != null) {
          gstAmount =
              (item!['itemRateAmount'] * item['gstRate'] / 100) *
              (item['quantity'] ?? 1);
        }

        rows.add(
          DataRow(
            cells: [
              // Date
              DataCell(
                _buildCell(
                  DateFormat('dd-MM-yyyy').format(order['createdAt'].toDate()),
                  cellTextStyle,
                  Alignment.centerLeft,
                ),
              ),
              // Order #
              DataCell(
                _buildCell(
                  orderNumber,
                  cellTextStyle.copyWith(fontWeight: FontWeight.bold),
                  Alignment.centerLeft,
                ),
              ),
              // Username
              DataCell(
                _buildCell(
                  order['username'] ?? 'N/A',
                  cellTextStyle,
                  Alignment.centerLeft,
                ),
              ),
              // Item Code
              DataCell(
                _buildCell(
                  item?['itemCode']?.toString() ?? 'N/A',
                  cellTextStyle,
                  Alignment.centerLeft,
                ),
              ),
              // Item Name
              DataCell(
                _buildCell(
                  item?['itemName']?.toString() ?? 'N/A',
                  cellTextStyle,
                  Alignment.centerLeft,
                ),
              ),
              // Quantity
              DataCell(
                _buildCell(
                  item?['quantity']?.toString() ?? 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // UOM
              DataCell(
                _buildCell(
                  item?['uom']?.toString() ?? 'Nos',
                  cellTextStyle,
                  Alignment.center,
                ),
              ),
              // GST Rate
              DataCell(
                _buildCell(
                  item?['gstRate'] != null
                      ? '${item!['gstRate'].toStringAsFixed(2)}%'
                      : 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // GST Amount
              DataCell(
                _buildCell(
                  formatAmount(gstAmount),
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // Rate (Total Amount)
              DataCell(
                _buildCell(
                  item?['totalAmount'] != null
                      ? formatAmount(item!['totalAmount'].toDouble())
                      : 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // MRP Amount
              DataCell(
                _buildCell(
                  item?['mrpAmount'] != null
                      ? formatAmount(item!['mrpAmount'].toDouble())
                      : 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // Net Amount
              DataCell(
                _buildCell(
                  item?['itemNetAmount'] != null
                      ? formatAmount(item!['itemNetAmount'].toDouble())
                      : 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
            ],
          ),
        );

        // Update totals
        if (item != null) {
          _totalQuantity += (item['quantity'] ?? 0).toDouble();
          _totalCalculationAmount += (item['itemNetAmount'] ?? 0).toDouble();
        }
      }
    });

    // Add totals row
    // In your _buildDataTableWithTotals() method, modify the totals row like this:
    rows.add(
      DataRow(
        color: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => Colors.blueGrey.shade50,
        ),
        cells: [
          DataCell(Container()), // Date
          DataCell(Container()), // Order #
          DataCell(Container()), // Username
          DataCell(Container()), // Item Code
          DataCell(Container()), // Item Name
          // Quantity column - now properly placed
          DataCell(
            _buildCell(
              _totalQuantity.toStringAsFixed(_totalQuantity % 1 == 0 ? 0 : 2),
              totalTextStyle.copyWith(color: Colors.green.shade700),
              Alignment.centerRight,
            ),
          ),
          DataCell(Container()), // UOM (empty)
          DataCell(Container()), // GST Rate
          DataCell(Container()), // GST Amount
          DataCell(Container()), // Rate (Total Amount)
          DataCell(Container()), // MRP Amount
          DataCell(
            _buildCell(
              formatAmount(_totalCalculationAmount),
              totalTextStyle.copyWith(color: Colors.green.shade700),
              Alignment.centerRight,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 0,
                horizontalMargin: 0,
                headingRowHeight: 40,
                // ignore: deprecated_member_use
                dataRowHeight: 36,
                headingRowColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) => Colors.grey.shade200,
                ),
                columns: [
                  DataColumn(
                    label: _buildHeaderCell(
                      'Date',
                      headerTextStyle,
                      Alignment.centerLeft,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Order #',
                      headerTextStyle,
                      Alignment.centerLeft,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'User',
                      headerTextStyle,
                      Alignment.centerLeft,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Item Code',
                      headerTextStyle,
                      Alignment.centerLeft,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Item Name',
                      headerTextStyle,
                      Alignment.centerLeft,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Qty',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'UOM',
                      headerTextStyle,
                      Alignment.center,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'GST %',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'GST Amt',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Rate (GST)',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'MRP',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                  DataColumn(
                    label: _buildHeaderCell(
                      'Net Amt',
                      headerTextStyle,
                      Alignment.centerRight,
                    ),
                  ),
                ],
                rows: rows,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER REPORT'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildDateInputs(),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _flattenedOrders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildDataTableWithTotals(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatAmount(double amount) {
  // Format with 2 decimal places and comma separators (Indian numbering system)
  return '₹ ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}
