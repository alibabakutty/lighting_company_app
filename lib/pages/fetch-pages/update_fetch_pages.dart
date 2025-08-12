import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdateFetchPages extends StatefulWidget {
  final String masterType;

  const UpdateFetchPages({super.key, required this.masterType});

  @override
  State<UpdateFetchPages> createState() => _DisplayFetchPageState();
}

class _DisplayFetchPageState extends State<UpdateFetchPages> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> executives = [];
  List<Map<String, dynamic>> customers = [];

  bool isLoading = false;
  bool hasFetchedItems = false;
  bool hasFetchedExecutives = false;
  bool hasFetchedCustomers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      switch (widget.masterType) {
        case 'item':
          await _fetchItems();
          break;
        case 'executive':
          await _fetchExecutives();
          break;
        case 'customer':
          await _fetchCustomers();
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('item_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'code': data['item_code'] as int? ?? 0, // Now first
            'name': data['item_name'] as String? ?? '', // Now second
            'uom': data['uom'] as String? ?? 'Nos', // Add this field
            'amount': data['item_rate_amount'] as double? ?? 0.0,
            'status': data['item_status'] as bool? ?? false,
          };
        }).toList();
        hasFetchedItems = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching items: $e')));
    }
  }

  Future<void> _fetchExecutives() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('executive_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        executives = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['executive_name'] as String? ?? '',
            'contact': data['mobile_number'] as String? ?? '',
          };
        }).toList();
        hasFetchedExecutives = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching executives: $e')));
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customer_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        customers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['customer_name'] as String? ?? '',
            'mobile': data['mobile_number'] as String? ?? '',
            'email': data['email'] as String? ?? '',
          };
        }).toList();
        hasFetchedCustomers = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching customers: $e')));
    }
  }

  void _navigateToViewPage(dynamic value) {
    switch (widget.masterType) {
      case 'item':
        context.go(
          '/item_master',
          extra: {'itemName': value, 'isDisplayMode': false},
        );
        break;
      case 'executive':
        context.go(
          '/executive_master',
          extra: {'executiveName': value, 'isDisplayMode': false},
        );
        break;
      case 'customer':
        context.go(
          '/customer_master',
          extra: {'customer_name': value, 'isDisplayMode': false},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: widget.masterType),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
    );
  }

  String _getPageTitle() {
    switch (widget.masterType) {
      case 'item':
        return 'ITEM MASTER';
      case 'executive':
        return 'EXECUTIVE MASTER';
      case 'customer':
        return 'CUSTOMER MASTER';
      default:
        return 'Master Data';
    }
  }

  Widget _buildContent() {
    switch (widget.masterType) {
      case 'item':
        return _buildMasterList(
          header: const ['Code', 'Item Name', 'UOM', 'Rate'],
          data: items,
          nameKey: 'name',
          secondaryKey: 'code',
          tertiaryKey: 'uom',
          quaternaryKey: 'amount', // Add this for fourth column
          statusKey: 'status',
          icon: Icons.fastfood,
          valueFormatter: (value) => '₹ ${value.toStringAsFixed(2)}',
        );
      case 'executive':
        return _buildMasterList(
          header: const ['Executive Name', 'Contact'],
          data: executives,
          nameKey: 'name',
          secondaryKey: 'contact',
          icon: Icons.business,
        );
      case 'customer':
        return _buildMasterList(
          header: const ['Customer Name', 'Mobile', 'Email'],
          data: customers,
          nameKey: 'name',
          secondaryKey: 'mobile',
          tertiaryKey: 'email',
          icon: Icons.person,
        );
      default:
        return const Center(child: Text('Select a master type'));
    }
  }

  Widget _buildMasterList({
    required List<String> header,
    required List<Map<String, dynamic>> data,
    required String nameKey,
    required String secondaryKey,
    String? tertiaryKey,
    String? quaternaryKey,
    String? statusKey,
    required IconData icon,
    String Function(dynamic)? valueFormatter,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${widget.masterType}s available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
    }

    // Determine column flex values based on master type
    final int firstFlex = widget.masterType == 'item' ? 1 : 2;
    final int secondFlex = widget.masterType == 'item' ? 3 : 2;
    final int thirdFlex = widget.masterType == 'customer' ? 3 : 1;
    final int fourthFlex = 1;

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              // First column
              Flexible(
                flex: firstFlex,
                child: Text(
                  header[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Second column
              Flexible(
                flex: secondFlex,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    header[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Third column (if exists)
              if (header.length > 2)
                Flexible(
                  flex: thirdFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      header[2],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              // Fourth column (if exists)
              if (header.length > 3)
                Flexible(
                  flex: fourthFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      header[3],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data List
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isActive = statusKey != null
                  ? (item[statusKey] as bool? ?? false)
                  : true;

              return Container(
                margin: const EdgeInsets.only(bottom: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: InkWell(
                  onTap: () => _navigateToViewPage(item[nameKey]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        // First column
                        Flexible(
                          flex: firstFlex,
                          child: Text(
                            widget.masterType == 'item'
                                ? item[secondaryKey].toString()
                                : item[nameKey].toString(),
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Second column
                        Flexible(
                          flex: secondFlex,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              widget.masterType == 'item'
                                  ? item[nameKey].toString()
                                  : item[secondaryKey].toString(),
                              style: TextStyle(
                                color: isActive ? Colors.black : Colors.grey,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Third column (if exists)
                        if (tertiaryKey != null)
                          Flexible(
                            flex: thirdFlex,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                header.length > 3
                                    ? item[tertiaryKey].toString()
                                    : valueFormatter != null
                                    ? valueFormatter(item[tertiaryKey])
                                    : item[tertiaryKey].toString(),
                                style: TextStyle(
                                  color: isActive ? Colors.black : Colors.grey,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        // Fourth column (if exists)
                        if (quaternaryKey != null)
                          Flexible(
                            flex: fourthFlex,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                valueFormatter != null
                                    ? valueFormatter(item[quaternaryKey])
                                    : item[quaternaryKey].toString(),
                                style: TextStyle(
                                  color: isActive ? Colors.black : Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
