import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/models/order_item_data.dart';
import 'package:lighting_company_app/models/supplier_master_data.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseService();

  // add item master data to firestore
  Future<bool> addItemMasterData(ItemMasterData itemMasterData) async {
    try {
      await _db
          .collection('item_master_data')
          .add(itemMasterData.toFirestore());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding item master data: $e');
      return false;
    }
  }

  // add supplier master data to firestore
  Future<bool> addSupplierMasterData(
    SupplierMasterData supplierMasterData,
  ) async {
    try {
      await _db
          .collection('supplier_master_data')
          .add(supplierMasterData.toFirestore());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding supplier master data: $e');
      return false;
    }
  }

  // add table master data to firestore
  Future<bool> addCustomerMasterData(
    CustomerMasterData customerMasterData,
  ) async {
    try {
      await _db
          .collection('customer_master_data')
          .add(customerMasterData.toFirestore());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding customer master data: $e');
      return false;
    }
  }

  // Add complete order with items to Firestore
  Future<bool> addOrderMasterData({
    required List<OrderItem> orderItems,
    required String orderNumber,
    required double totalQty,
    required double totalAmount,
    required String userName, // 👈 New parameter
  }) async {
    try {

      DocumentReference orderRef = await _db.collection('orders').add({
        'order_number': orderNumber,
        'username': userName, // 👈 Save to Firestore
        'total_quantity': totalQty,
        'total_amount': totalAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (OrderItem item in orderItems) {
        // calculate net amount before storing
        double netAmount = item.quantity * item.itemRateAmount;
        // Get the base item data
        Map<String, dynamic> itemData = item.toFirestore();
        // override the netamount
        itemData['itemNetAmount'] = netAmount;
        // now store in firestore
        await orderRef.collection('items').add(itemData);
      }

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding full order data: $e');
      return false;
    }
  }

  // fetch itemmasterdata by itemcode
  Future<ItemMasterData?> getItemByItemCode(int itemCode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('item_master_data')
        .where('item_code', isEqualTo: itemCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ItemMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch itemmasterdata by itemname
  Future<ItemMasterData?> getItemByItemName(String itemName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('item_master_data')
        .where('item_name', isEqualTo: itemName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ItemMasterData.fromFirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch suppliermasterdata by suppliername
  Future<SupplierMasterData?> getSupplierBySupplierName(
    String supplierName,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('supplier_master_data')
        .where('supplier_name', isEqualTo: supplierName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SupplierMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch suppliermasterdata by mobileNumber
  Future<SupplierMasterData?> getSupplierByMobileNumber(
    String mobileNumber,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('supplier_master_data')
        .where('mobile_number', isEqualTo: mobileNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SupplierMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch tablemasterdata by tablenumber
  Future<CustomerMasterData?> getCustomerByCustomerName(
    String customerName,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('customer_master_data')
        .where('customer_name', isEqualTo: customerName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return CustomerMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // Update return type and conversion
  Future<List<Map<String, dynamic>>> getOrdersByDate(String dateString) async {
    final date = DateTime.parse(dateString);
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id, // Include the document ID
        ...data,
      };
    }).toList();
  }

  // Similarly update the other methods
  Future<List<Map<String, dynamic>>> getOrdersByDateRange(
    String startDateString,
    String endDateString,
  ) async {
    try {
      DateTime startDate = DateTime.parse(startDateString);
      DateTime endDate = DateTime.parse(endDateString);
      DateTime adjustedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: adjustedEndDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching orders by date range: $e');
      return [];
    }
  }

  // Fetch orders by supplier name
  Future<List<Map<String, dynamic>>> getOrdersBySupplierName(
    String supplierName,
  ) async {
    try {
      // Attempt server-side sorted query first
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('supplier_name', isEqualTo: supplierName)
          .orderBy('timestamp', descending: true)
          .get(const GetOptions(source: Source.server));

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Fallback to client-side sorting if index is missing
        // ignore: avoid_print
        print('Index missing, falling back to client-side sorting');
        return _getOrdersBySupplierWithClientSort(supplierName);
      }
      // ignore: avoid_print
      print('Error fetching orders by supplier: $e');
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Unexpected error: $e');
      return [];
    }
  }

  /// Fallback method with client-side sorting
  Future<List<Map<String, dynamic>>> _getOrdersBySupplierWithClientSort(
    String supplierName,
  ) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('supplier_name', isEqualTo: supplierName)
          .get();

      final orders =
          snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList()..sort((a, b) {
            final aTime = a['timestamp'] as Timestamp;
            final bTime = b['timestamp'] as Timestamp;
            return bTime.compareTo(aTime); // Newest first
          });

      return orders;
    } catch (e) {
      // ignore: avoid_print
      print('Error in client-side sort fallback: $e');
      return [];
    }
  }

  // Fetch orders with items by table number
  Future<List<Map<String, dynamic>>> getOrdersWithItemsByTableNumber(
    int tableNumber,
  ) async {
    try {
      // Remove the server-side orderBy to avoid index requirement
      QuerySnapshot ordersSnapshot = await _db
          .collection('orders')
          .where('table_number', isEqualTo: tableNumber)
          .get();

      // Sort client-side (descending by timestamp)
      final sortedOrders =
          ordersSnapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList()..sort((a, b) {
            final aTime = a['timestamp'] as Timestamp;
            final bTime = b['timestamp'] as Timestamp;
            return bTime.compareTo(aTime); // Newest first
          });

      // Fetch items for each order
      for (final order in sortedOrders) {
        final itemsSnapshot = await _db
            .collection('orders')
            .doc(order['id'])
            .collection('items')
            .get();
        order['items'] = itemsSnapshot.docs.map((doc) => doc.data()).toList();
      }

      return sortedOrders;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching orders with items by table number: $e');
      return [];
    }
  }

  // Add this to your firebase_service.dart
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw 'Error fetching order items: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getOrdersByItemName(
    String itemName,
  ) async {
    try {
      // Get all orders first
      final ordersSnapshot = await _db.collection('orders').get();

      final List<Map<String, dynamic>> matchingOrders = [];

      // Check each order's items subcollection
      for (final orderDoc in ordersSnapshot.docs) {
        final itemsSnapshot = await orderDoc.reference
            .collection('items')
            .where('itemName', isEqualTo: itemName)
            .get();

        if (itemsSnapshot.docs.isNotEmpty) {
          final orderData = orderDoc.data();
          orderData['id'] = orderDoc.id;

          // Get only matching items
          orderData['items'] = itemsSnapshot.docs
              .map((doc) => doc.data())
              .toList();

          matchingOrders.add(orderData);
        }
      }

      // Sort by timestamp (newest first)
      matchingOrders.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp;
        final bTime = b['timestamp'] as Timestamp;
        return bTime.compareTo(aTime);
      });

      return matchingOrders;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching orders by item name: $e');
      return [];
    }
  }

  // Fetch order with items by order number
  Future<List<Map<String, dynamic>>> getOrdersWithItemsByOrderNumber(
    String orderNumber,
  ) async {
    try {
      // Get the order(s) with matching order number
      QuerySnapshot ordersSnapshot = await _db
          .collection('orders')
          .where('order_number', isEqualTo: orderNumber)
          .get();

      List<Map<String, dynamic>> orders = [];

      for (var orderDoc in ordersSnapshot.docs) {
        // Get order data
        Map<String, dynamic> orderData =
            orderDoc.data() as Map<String, dynamic>;
        orderData['id'] = orderDoc.id;

        // Get items for this order
        QuerySnapshot itemsSnapshot = await orderDoc.reference
            .collection('items')
            .get();
        List<Map<String, dynamic>> items = itemsSnapshot.docs
            .map((itemDoc) => itemDoc.data() as Map<String, dynamic>)
            .toList();

        orderData['items'] = items;
        orders.add(orderData);
      }

      return orders;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching orders with items by order number: $e');
      return [];
    }
  }

  // Add this to your FirebaseService class
  Future<List<Map<String, dynamic>>> getOrdersByNumberPrefixAndDate(
    String prefix,
    String dateString,
  ) async {
    try {
      final date = DateTime.parse(dateString);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _db
          .collection('orders')
          .where('order_number', isGreaterThanOrEqualTo: prefix)
          .where(
            'order_number',
            isLessThan: '${prefix}z',
          ) // This ensures we get all with the prefix
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching orders by prefix and date: $e');
      return [];
    }
  }

  // fetch all Items
  Future<List<ItemMasterData>> getAllItems() async {
    try {
      QuerySnapshot snapshot = await _db.collection('item_master_data').get();

      return snapshot.docs
          .map(
            (doc) => ItemMasterData.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching all items: $e');
      return [];
    }
  }

  // fetch all Suppliers
  Future<List<SupplierMasterData>> getAllSuppliers() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .get();

      return snapshot.docs
          .map(
            (doc) => SupplierMasterData.fromfirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // fetch all tables
  Future<List<CustomerMasterData>> getAllCustomers() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('customer_master_data')
          .get();

      return snapshot.docs
          .map(
            (doc) => CustomerMasterData.fromfirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch all orders from Firestore
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .orderBy('timestamp', descending: true) // Most recent first
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Fetch all orders with their items
  Future<List<Map<String, dynamic>>> getAllOrdersWithItems() async {
    try {
      QuerySnapshot ordersSnapshot = await _db
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> orders = [];

      for (var orderDoc in ordersSnapshot.docs) {
        // Get order data
        Map<String, dynamic> orderData =
            orderDoc.data() as Map<String, dynamic>;
        orderData['id'] = orderDoc.id;

        // Get items for this order
        QuerySnapshot itemsSnapshot = await orderDoc.reference
            .collection('items')
            .get();
        List<Map<String, dynamic>> items = itemsSnapshot.docs
            .map((itemDoc) => itemDoc.data() as Map<String, dynamic>)
            .toList();

        orderData['items'] = items;
        orders.add(orderData);
      }

      return orders;
    } catch (e) {
      return [];
    }
  }

  // update item master data by item code
  Future<bool> updateItemMasterDataByItemCode(
    String oldItemCode,
    ItemMasterData updatedData,
  ) async {
    try {
      // First check if the new no is already taken by another item
      // ignore: unrelated_type_equality_checks
      if (oldItemCode != updatedData.itemCode) {
        QuerySnapshot duplicateCheck = await _db
            .collection('item_master_data')
            .where('item_code', isEqualTo: updatedData.itemCode)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // FInd the document by the old item code
      QuerySnapshot snapshot = await _db
          .collection('item_master_data')
          .where('item_code', isEqualTo: oldItemCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('item_master_data').doc(docId).update({
          'item_code': updatedData.itemCode,
          'item_name': updatedData.itemName,
          'item_rate_amount': updatedData.itemRateAmount,
          'item_status': updatedData.itemStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // update item master data
  Future<bool> updateItemMasterDataByItemName(
    String oldItemName,
    ItemMasterData updatedData,
  ) async {
    try {
      // First check if the new no is already taken by another item
      if (oldItemName != updatedData.itemName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('item_master_data')
            .where('item_name', isEqualTo: updatedData.itemName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // FInd the document by the old name
      QuerySnapshot snapshot = await _db
          .collection('item_master_data')
          .where('item_name', isEqualTo: oldItemName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('item_master_data').doc(docId).update({
          'item_code': updatedData.itemCode,
          'item_name': updatedData.itemName,
          'item_rate_amount': updatedData.itemRateAmount,
          'item_status': updatedData.itemStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // update supplier master data by supplier name
  Future<bool> updateSupplierMasterDataBySupplierName(
    String oldSupplierName,
    SupplierMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another supplier
      if (oldSupplierName != updatedData.supplierName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('supplier_master_data')
            .where('supplier_name', isEqualTo: updatedData.supplierName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // Find the document by the old supplier name
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .where('supplier_name', isEqualTo: oldSupplierName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('supplier_master_data').doc(docId).update({
          'supplier_name': updatedData.supplierName,
          'mobile_number': updatedData.mobileNumber,
          'email': updatedData.email,
          'password': updatedData.password,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // update supplier master data by mobile number
  Future<bool> updateSupplierMasterDataByMobileNumber(
    String oldMobileNumber,
    SupplierMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another supplier
      if (oldMobileNumber != updatedData.mobileNumber) {
        QuerySnapshot duplicateCheck = await _db
            .collection('supplier_master_data')
            .where('mobile_number', isEqualTo: updatedData.mobileNumber)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // Find the document by the old supplier name
      QuerySnapshot snapshot = await _db
          .collection('supplier_master_data')
          .where('mobile_number', isEqualTo: oldMobileNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('supplier_master_data').doc(docId).update({
          'supplier_name': updatedData.supplierName,
          'mobile_number': updatedData.mobileNumber,
          'email': updatedData.email,
          'password': updatedData.password,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // update table master data by table number
  Future<bool> updateCustomerMasterDataByCustomerName(
    String oldCustomerName,
    CustomerMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another table number
      if (oldCustomerName != updatedData.customerName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('customer_master_data')
            .where('customer_name', isEqualTo: updatedData.customerName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // Find the document by the old table number
      QuerySnapshot snapshot = await _db
          .collection('customer_master_data')
          .where('customer_name', isEqualTo: oldCustomerName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('customer_master_data').doc(docId).update({
          'customer_name': updatedData.customerName,
          'mobile_number': updatedData.mobileNumber,
          'email': updatedData.email,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
