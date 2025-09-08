import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lighting_company_app/service/firebase_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

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

  // Text filters
  final TextEditingController _orderNoController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  // Totals
  double _totalQuantity = 0;
  double _totalCalculationAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _orderNoController.dispose();
    _userController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  String formatPercentage(double percentage) {
    return '${percentage.round()}%';
  }

  // Helper function to create a row of CellValues from an order
  List<excel.CellValue> _createRow(Map<String, dynamic> order) {
    final item = order['itemData'] as Map<String, dynamic>?;

    // Calculate GST amount if needed
    double gstAmount = item?['gstAmount'] ?? 0.0;
    if (gstAmount == 0 &&
        item?['gstRate'] != null &&
        item?['itemRateAmount'] != null) {
      gstAmount =
          (item!['itemRateAmount'] * item['gstRate'] / 100) *
          (item['quantity'] ?? 1);
    }

    // Calculate discount deducted amount
    double discountDeductedAmount = item?['discountDeductedAmount'] ?? 0.0;
    if (discountDeductedAmount == 0 &&
        item?['itemRateAmount'] != null &&
        item?['discount'] != null) {
      final discountAmount = item!['itemRateAmount'] * item['discount'] / 100;
      discountDeductedAmount = item['itemRateAmount'] - discountAmount;
    }

    return [
      excel.TextCellValue(
        DateFormat('dd-MM-yyyy').format(order['createdAt'].toDate()),
      ),
      excel.TextCellValue(order['order_number']?.toString() ?? 'N/A'),
      excel.TextCellValue(order['username'] ?? 'N/A'),
      excel.TextCellValue(order['customer_name']?.toString() ?? 'N/A'),
      excel.TextCellValue(item?['itemCode']?.toString() ?? 'N/A'),
      excel.TextCellValue(item?['itemName']?.toString() ?? 'N/A'),
      excel.DoubleCellValue(item?['quantity']?.toDouble() ?? 0.0),
      excel.TextCellValue(item?['uom']?.toString() ?? 'Nos'),
      excel.DoubleCellValue(item?['itemRateAmount']?.toDouble() ?? 0.0),
      excel.TextCellValue(
        item?['discount'] != null
            ? formatPercentage(item!['discount'].toDouble())
            : '0%',
      ),
      excel.DoubleCellValue(discountDeductedAmount),
      excel.TextCellValue(
        item?['gstRate'] != null
            ? formatPercentage(item!['gstRate'].toDouble())
            : '0%',
      ),
      excel.DoubleCellValue(gstAmount),
      excel.DoubleCellValue(item?['totalAmount']?.toDouble() ?? 0.0),
      excel.DoubleCellValue(item?['mrpAmount']?.toDouble() ?? 0.0),
      excel.DoubleCellValue(item?['itemNetAmount']?.toDouble() ?? 0.0),
    ];
  }

  Future<void> _exportToExcel() async {
    if (_flattenedOrders.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    try {
      // Create Excel workbook
      final excel.Excel workbook = excel.Excel.createExcel();
      final sheet = workbook['Order Report'];

      // Define headers
      final headers = [
        'Date',
        'Order #',
        'User',
        'Customer',
        'Item Code',
        'Item Name',
        'Quantity',
        'UOM',
        'Rate',
        'Disc %',
        'Disc Amt',
        'GST %',
        'GST Amount',
        'Rate (GST)',
        'MRP',
        'Net Amount',
      ];

      // Add header row
      sheet.appendRow(headers.map((h) => excel.TextCellValue(h)).toList());

      // Add data rows
      for (var order in _flattenedOrders) {
        try {
          final row = _createRow(order);
          sheet.appendRow(row);
        } catch (e) {
          debugPrint(
            'Error creating row for order ${order['order_number']}: $e',
          );
        }
      }

      // Add totals row
      final totalsRow = [
        '',
        '',
        '',
        '',
        '',
        'TOTAL',
        _totalQuantity,
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        _totalCalculationAmount,
      ];
      sheet.appendRow(
        totalsRow
            .map(
              (v) => v is num
                  ? excel.DoubleCellValue(v.toDouble())
                  : excel.TextCellValue(v.toString()),
            )
            .toList(),
      );

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/orders_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final excelBytes = workbook.encode();
      if (excelBytes == null) {
        throw Exception('Excel encode returned null');
      }

      final file = File(filePath);
      await file.writeAsBytes(excelBytes, flush: true);

      if (await file.exists()) {
        await OpenFile.open(filePath);
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Report saved to $filePath')));
      } else {
        throw Exception('File was not created');
      }
    } catch (e) {
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));
    }
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
    String? orderNo,
    String? username,
    String? customerName,
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

      // Apply text filters
      if (orderNo != null && orderNo.isNotEmpty) {
        orders = orders.where((order) {
          final orderNumber = order['order_number']?.toString() ?? '';
          return orderNumber.toLowerCase().contains(orderNo.toLowerCase());
        }).toList();
      }

      if (username != null && username.isNotEmpty) {
        orders = orders.where((order) {
          final user = order['username']?.toString() ?? '';
          return user.toLowerCase().contains(username.toLowerCase());
        }).toList();
      }

      if (customerName != null && customerName.isNotEmpty) {
        orders = orders.where((order) {
          final customer = order['customer_name']?.toString() ?? '';
          return customer.toLowerCase().contains(customerName.toLowerCase());
        }).toList();
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
            // Date filter type dropdown
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                initialValue: _useSpecificDate ? 'specific' : 'range',
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
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
                isExpanded: true,
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
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(_startDate!)
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
                                    ? DateFormat('dd-MM-yyyy').format(_endDate!)
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
                onPressed: _applyFilters,
                child: Text('Search', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFilterField(
    String label,
    TextEditingController controller,
    String hintText,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        isDense: true,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 16),
                onPressed: () {
                  controller.clear();
                  _applyFilters();
                },
              )
            : null,
      ),
      style: TextStyle(fontSize: 12),
      onSubmitted: (_) => _applyFilters(),
    );
  }

  void _applyFilters() {
    if (_useSpecificDate && _specificDate != null) {
      _fetchOrders(
        dateString: _specificDate.toString(),
        orderNo: _orderNoController.text,
        username: _userController.text,
        customerName: _customerController.text,
      );
    } else if (!_useSpecificDate && _startDate != null && _endDate != null) {
      _fetchOrders(
        startDateString: _startDate.toString(),
        endDateString: _endDate.toString(),
        orderNo: _orderNoController.text,
        username: _userController.text,
        customerName: _customerController.text,
      );
    } else {
      // If no date selected, use today's date
      _fetchOrders(
        dateString: DateTime.now().toString(),
        orderNo: _orderNoController.text,
        username: _userController.text,
        customerName: _customerController.text,
      );
    }
  }

  Widget _buildTextFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildTextFilterField(
            'Order #',
            _orderNoController,
            'Filter by order number',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildTextFilterField(
            'User',
            _userController,
            'Filter by username',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildTextFilterField(
            'Customer',
            _customerController,
            'Filter by customer name',
          ),
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

  Widget _buildDataTable() {
    final TextStyle headerTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    final TextStyle cellTextStyle = TextStyle(
      fontSize: 14,
      color: Colors.black87,
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
              // Customer Name
              DataCell(
                _buildCell(
                  order['customer_name']?.toString() ?? 'N/A',
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
              // Rate Amount - NEW COLUMN
              DataCell(
                _buildCell(
                  item?['itemRateAmount'] != null
                      ? formatAmount(item!['itemRateAmount'].toDouble())
                      : 'N/A',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // Discount - NEW COLUMN
              DataCell(
                _buildCell(
                  item?['discount'] != null
                      ? formatPercentage(item!['discount'].toDouble())
                      : '0%',
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              DataCell(
                _buildCell(
                  item?['discountDeductedAmount'] != null
                      ? formatAmount(item!['discountDeductedAmount'].toDouble())
                      : (item?['itemRateAmount'] != null &&
                                item?['discount'] != null
                            ? formatAmount(
                                (item!['itemRateAmount'] -
                                        (item['itemRateAmount'] *
                                            item['discount'] /
                                            100))
                                    .toDouble(),
                              )
                            : 'N/A'),
                  cellTextStyle,
                  Alignment.centerRight,
                ),
              ),
              // GST Rate
              DataCell(
                _buildCell(
                  item?['gstRate'] != null
                      ? formatPercentage(item!['gstRate'].toDouble())
                      : '0%',
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

    return SingleChildScrollView(
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
                'Customer',
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
              label: _buildHeaderCell('UOM', headerTextStyle, Alignment.center),
            ),
            // New columns
            DataColumn(
              label: _buildHeaderCell(
                'Rate',
                headerTextStyle,
                Alignment.centerRight,
              ),
            ),
            DataColumn(
              label: _buildHeaderCell(
                'Disc %',
                headerTextStyle,
                Alignment.centerRight,
              ),
            ),
            DataColumn(
              label: _buildHeaderCell(
                'Disc Amt',
                headerTextStyle,
                Alignment.centerRight,
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
                'Net Amt (GST)',
                headerTextStyle,
                Alignment.centerRight,
              ),
            ),
          ],
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildTotalsFooter() {
    return Container(
      width: double.infinity,
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueGrey.shade200, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTALS:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade800,
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200, width: 0.8),
                ),
                child: Text(
                  'Qty: ${_totalQuantity.toStringAsFixed(_totalQuantity % 1 == 0 ? 0 : 2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200, width: 0.8),
                ),
                child: Text(
                  'Amount: ${formatAmount(_totalCalculationAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORDER REPORT'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export to Excel',
            onPressed: _flattenedOrders.isEmpty ? null : _exportToExcel,
          ),
        ],
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
                child: Column(
                  children: [
                    _buildDateInputs(),
                    SizedBox(height: 12),
                    _buildTextFilters(),
                  ],
                ),
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
                  : Column(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildDataTable(),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        _buildTotalsFooter(),
                        SizedBox(height: 50),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatAmount(double amount) {
  return '₹ ${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}
