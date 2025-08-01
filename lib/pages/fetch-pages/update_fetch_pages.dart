import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdateFetchPage extends StatefulWidget {
  final String masterType;

  const UpdateFetchPage({super.key, required this.masterType});

  @override
  State<UpdateFetchPage> createState() => _UpdateFetchPageState();
}

class _UpdateFetchPageState extends State<UpdateFetchPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> tables = [];

  bool isLoading = false;
  bool hasFetchedItems = false;
  bool hasFetchedSuppliers = false;
  bool hasFetchedTables = false;

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
        case 'supplier':
          await _fetchSuppliers();
          break;
        case 'table':
          await _fetchTables();
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

  Future<void> _fetchSuppliers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('supplier_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        suppliers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['supplier_name'] as String? ?? '',
            'contact': data['mobile_number'] as String? ?? '',
          };
        }).toList();
        hasFetchedSuppliers = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching suppliers: $e')));
    }
  }

  Future<void> _fetchTables() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('table_master_data')
          .get();

      if (!mounted) return;

      setState(() {
        tables = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'number': data['table_number'] as int? ?? 0,
            'capacity': data['table_capacity'] as int? ?? 0,
            'status': data['table_availability'] as bool? ?? false,
          };
        }).toList();
        hasFetchedTables = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching tables: $e')));
    }
  }

  void _navigateToUpdatePage(dynamic value) {
    switch (widget.masterType) {
      case 'item':
        context.go(
          '/item_master',
          extra: {'itemName': value, 'isDisplayMode': false},
        );
        break;
      case 'supplier':
        context.go(
          '/supplier_master',
          extra: {'supplierName': value, 'isDisplayMode': false},
        );
        break;
      case 'table':
        context.go(
          '/table_master',
          extra: {'tableNumber': value, 'isDisplayMode': false},
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
      case 'supplier':
        return 'SUPPLIER MASTER';
      case 'table':
        return 'TABLE MASTER';
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
      case 'supplier':
        return _buildMasterList(
          header: const ['Supplier Name', 'Contact'],
          data: suppliers,
          nameKey: 'name',
          secondaryKey: 'contact',
          icon: Icons.business,
        );
      case 'table':
        return _buildMasterList(
          header: const ['Table No.', 'Capacity', 'Status'],
          data: tables,
          nameKey: 'number',
          secondaryKey: 'capacity',
          tertiaryKey: 'status',
          icon: Icons.table_restaurant,
          valueFormatter: (value) => value ? 'Active' : 'Inactive',
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

    return Column(
      children: [
        // Header Row (unchanged)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              // First column (Code for items, otherwise nameKey)
              SizedBox(
                width: header.length > 2 ? 60 : null,
                child: Text(
                  header[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Second column (Item Name for items, otherwise secondaryKey)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: header.length > 2 ? 0 : 8.0),
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
                SizedBox(
                  width: 50,
                  child: Text(
                    header[2],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Fourth column (if exists)
              if (header.length > 3)
                SizedBox(
                  width: 70,
                  child: Text(
                    header[3],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Data List (modified to reorder for items)
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
                  onTap: () => _navigateToUpdatePage(item[nameKey]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        // First column (Code for items, otherwise nameKey)
                        SizedBox(
                          width: header.length > 2 ? 60 : null,
                          child: Text(
                            widget.masterType == 'item'
                                ? item[secondaryKey]
                                      .toString() // Show Code first
                                : item[nameKey].toString(),
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Second column (Item Name for items, otherwise secondaryKey)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: header.length > 2 ? 0 : 8.0,
                            ),
                            child: Text(
                              widget.masterType == 'item'
                                  ? item[nameKey]
                                        .toString() // Show Name second
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
                          SizedBox(
                            width: 50,
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
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Fourth column (if exists)
                        if (quaternaryKey != null)
                          SizedBox(
                            width: 70,
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
