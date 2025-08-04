import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/models/order_item_data.dart';
import 'package:lighting_company_app/pages/orders/order-master/order_item_row.dart';
import 'package:lighting_company_app/pages/orders/order-master/order_utils.dart';
import 'package:lighting_company_app/service/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderMaster extends StatefulWidget {
  final AuthService authService;
  const OrderMaster({super.key, required this.authService});

  @override
  State<OrderMaster> createState() => _OrderMasterState();
}

class _OrderMasterState extends State<OrderMaster> {
  String? supplierUsername;
  bool isLoading = true;
  List<OrderItem> orderItems = [OrderItemExtension.empty()];

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _kidsController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  List<ItemMasterData> _allItems = [];
  bool _isLoadingItems = false;

  // order number tracking
  int _orderCounter = 0;
  String _currentOrderNumber = '';
  DateTime? _lastResetDate;

  // Define these styles in your _OrderMasterState class
  final TextStyle headerStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.deepPurple[800],
  );

  final TextStyle totalTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.deepPurple[800],
  );

  final TextStyle amountTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.green[800],
  );

  @override
  void initState() {
    super.initState();
    _loadOrderCounter();
    _fetchSupplierData();
    _loadAllItems();
  }

  bool _isDuplicateItem(String itemCode) {
    return orderItems.where((item) => item.itemCode == itemCode).length > 1;
  }

  Future<void> _loadOrderCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetString = prefs.getString('lastResetDate');
    final savedCounter = prefs.getInt('orderCounter') ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }

    // Reset counter if it's a new day
    if (_lastResetDate == null || today.isAfter(_lastResetDate!)) {
      setState(() {
        _orderCounter = 0;
        _lastResetDate = today;
      });
      await prefs.setInt('orderCounter', 0);
      await prefs.setString('lastResetDate', today.toIso8601String());
    } else {
      setState(() {
        _orderCounter = savedCounter;
      });
    }
  }

  Future<void> _saveOrderCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('orderCounter', _orderCounter);
    if (_lastResetDate != null) {
      await prefs.setString('lastResetDate', _lastResetDate!.toIso8601String());
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Reset counter if it's a new day
    if (_lastResetDate == null || today.isAfter(_lastResetDate!)) {
      _orderCounter = 0;
      _lastResetDate = today;
      _saveOrderCounter();
    }
    _orderCounter++;
    _saveOrderCounter();
    return 'DINE-${_orderCounter.toString().padLeft(4, '0')}';
  }

  void _addNewRow() {
    // Only add if last item is not empty and not a duplicate
    if (orderItems.isNotEmpty &&
        orderItems.last.itemCode.isNotEmpty &&
        !_isDuplicateItem(orderItems.last.itemCode)) {
      setState(() {
        orderItems.add(OrderItem.empty());
      });
    }
  }

  Future<void> _fetchSupplierData() async {
    try {
      final authUser = await widget.authService.getCurrentAuthUser();
      if (authUser.role != UserRole.supplier) {
        if (mounted) context.go('/supplier_login');
        return;
      }

      setState(() {
        supplierUsername = authUser.supplierName ?? 'Supplier';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/supplier_login');
      }
    }
  }

  Future<void> _loadAllItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await _firebaseService.getAllItems();
      setState(() => _allItems = items);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.authService.signOut();
      if (mounted) context.go('/');
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      // Filter out empty items (where itemName is empty)
      final validOrderItems = orderItems
          .where((item) => item.itemName.isNotEmpty)
          .toList();

      if (validOrderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one valid item'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        // Generate order number after click submit button
        _currentOrderNumber = _generateOrderNumber();

        double totalQty = 0.0;
        double totalAmount = 0.0;
        for (var item in validOrderItems) {
          totalQty += item.quantity;
          totalAmount += item.quantity * item.itemRateAmount;
        }

        // Safely parse guest count fields
        final int maleCount = int.tryParse(_maleController.text.trim()) ?? 0;
        final int femaleCount =
            int.tryParse(_femaleController.text.trim()) ?? 0;
        final int kidsCount = int.tryParse(_kidsController.text.trim()) ?? 0;

        final success = await FirebaseService().addOrderMasterData(
          orderItems: validOrderItems, // Use the filtered list
          orderNumber: _currentOrderNumber,
          totalQty: totalQty,
          totalAmount: totalAmount,
          maleCount: maleCount,
          femaleCount: femaleCount,
          kidsCount: kidsCount,
          supplierName: supplierUsername!,
        );

        if (success) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order $_currentOrderNumber submitted successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          setState(() {
            orderItems = [OrderItemExtension.empty()];
            _quantityController.clear();
            _maleController.clear();
            _femaleController.clear();
            _kidsController.clear();
          });
        } else {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods to calculate totals
  double get _totalQuantity {
    return orderItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalAmount {
    return orderItems.fold(
      0,
      (sum, item) => sum + (item.itemRateAmount * item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORDER MANAGEMENT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              getDisplayName(supplierUsername ?? 'SUPPLIER').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple[700],
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TimeOfDay.now().format(context),
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Order Items Section
              const SizedBox(height: 2),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // **Table Header (Fixed - Scrolls Horizontally)**
                        SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal, // Allow horizontal scroll
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.deepPurple[500]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text('NO.', style: headerStyle),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: 87,
                                  child: Text('ITEM NAME', style: headerStyle),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 40,
                                  child: Text('QTY', style: headerStyle),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: Text('RATE', style: headerStyle),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: Text('AMOUNT', style: headerStyle),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // **Scrollable Order Items (Vertical + Horizontal)**
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection:
                                Axis.vertical, // Primary scroll (vertical)
                            child: SingleChildScrollView(
                              scrollDirection: Axis
                                  .horizontal, // Secondary scroll (horizontal)
                              child: Column(
                                children: [
                                  for (int i = 0; i < orderItems.length; i++)
                                    OrderItemRow(
                                      index: i,
                                      item: orderItems[i],
                                      allItems: _allItems,
                                      isLoadingItems: _isLoadingItems,
                                      onRemove: (index) => setState(
                                        () => orderItems.removeAt(index),
                                      ),
                                      onUpdate: (index, updatedItem) {
                                        setState(
                                          () => orderItems[index] = updatedItem,
                                        );
                                        if (_isDuplicateItem(
                                          updatedItem.itemCode,
                                        )) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Item "${updatedItem.itemName}" already added. And this is additional quantity!',
                                              ),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        }
                                      },
                                      onItemSelected: () => setState(() {
                                        if (i == orderItems.length - 1 &&
                                            orderItems[i].itemCode.isNotEmpty) {
                                          orderItems.add(
                                            OrderItemExtension.empty(),
                                          );
                                        }
                                      }),
                                      onAddNewRow: _addNewRow,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // **Totals & Submit Button (Fixed at Bottom)**
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced horizontal padding
                            vertical: 8, // Reduced vertical padding
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Smaller border radius
                            border: Border.all(color: Colors.deepPurple[100]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items:',
                                style: totalTextStyle.copyWith(fontSize: 13),
                              ), // Smaller text
                              Text(
                                _totalQuantity.toStringAsFixed(
                                  _totalQuantity % 1 == 0 ? 0 : 2,
                                ),
                                style: totalTextStyle.copyWith(fontSize: 13),
                              ), // Smaller text
                              Text(
                                'Amount:',
                                style: totalTextStyle.copyWith(fontSize: 13),
                              ), // Smaller text
                              Text(
                                '₹${_totalAmount.toStringAsFixed(2)}',
                                style: amountTextStyle.copyWith(fontSize: 13),
                              ), // Smaller text
                            ],
                          ),
                        ),
                        const SizedBox(height: 4), // Reduced spacing
                        SizedBox(
                          width: double.infinity,
                          height: 40, // Reduced height
                          child: ElevatedButton(
                            onPressed: _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  4,
                                ), // Smaller radius
                              ),
                              elevation: 0, // No elevation
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ), // Reduced padding
                              minimumSize: Size
                                  .zero, // Allows button to be as small as possible
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // Reduces touch target
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16, // Smaller icon
                                ),
                                SizedBox(width: 4), // Reduced spacing
                                Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    fontSize: 13, // Smaller font
                                    fontWeight:
                                        FontWeight.w500, // Medium weight
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _maleController.dispose();
    _femaleController.dispose();
    _kidsController.dispose();
    super.dispose();
  }
}
