import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:lighting_company_app/models/item_master_data.dart';
import 'package:lighting_company_app/models/order_item_data.dart';
import 'package:lighting_company_app/models/executive_master_data.dart';

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

  // add executive master data to firestore
  Future<bool> addExecutiveMasterData(
    ExecutiveMasterData executiveMasterData,
  ) async {
    try {
      await _db
          .collection('executive_master_data')
          .add(executiveMasterData.toFirestore());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding executive master data: $e');
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
  // In your FirebaseService class
  Future<bool> addOrderMasterData({
    required List<OrderItem> orderItems,
    required String orderNumber,
    required double totalQty,
    required double totalCalculationAmount,
    required String userName,
    String? customerId, // Add optional customerId parameter for admin/executive
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Determine the customer ID - use provided one or current user's UID
      final orderCustomerId = customerId ?? user.uid;

      // Create the order document
      final orderData = {
        'order_number': orderNumber,
        'customerId': orderCustomerId, // Use determined customer ID
        'username': userName,
        'total_quantity': totalQty,
        'total_calculation_amount': totalCalculationAmount,
        'status': 'pending', // Add status field as required by security rules
        'createdAt': FieldValue.serverTimestamp(), // Required by security rules
        'updatedAt': FieldValue.serverTimestamp(),
      };

      DocumentReference orderRef = await _db
          .collection('orders')
          .add(orderData);

      // Add order items to subcollection
      for (OrderItem item in orderItems) {
        double netAmount = item.quantity * item.itemRateAmount;
        Map<String, dynamic> itemData = item.toFirestore();
        itemData['itemNetAmount'] = netAmount;
        await orderRef.collection('items').add(itemData);
      }

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error adding order: $e');
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

  // fetch executivemasterdata by executivename
  Future<ExecutiveMasterData?> getExecutiveByExecutiveName(
    String executiveName,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('executive_master_data')
        .where('executive_name', isEqualTo: executiveName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ExecutiveMasterData.fromfirestore(snapshot.docs.first.data());
    }
    return null;
  }

  // fetch Executivemasterdata by mobileNumber
  Future<ExecutiveMasterData?> getExecutiveByMobileNumber(
    String mobileNumber,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('executive_master_data')
        .where('mobile_number', isEqualTo: mobileNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ExecutiveMasterData.fromfirestore(snapshot.docs.first.data());
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

  // Fetch orders by executive name
  Future<List<Map<String, dynamic>>> getOrdersByExecutiveName(
    String executiveName,
  ) async {
    try {
      // Attempt server-side sorted query first
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('executive_name', isEqualTo: executiveName)
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
        return _getOrdersByExecutiveWithClientSort(executiveName);
      }
      // ignore: avoid_print
      print('Error fetching orders by executive: $e');
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Unexpected error: $e');
      return [];
    }
  }

  /// Fallback method with client-side sorting
  Future<List<Map<String, dynamic>>> _getOrdersByExecutiveWithClientSort(
    String executiveName,
  ) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orders')
          .where('executive_name', isEqualTo: executiveName)
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

  // fetch all Executives
  Future<List<ExecutiveMasterData>> getAllExecutives() async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('executive_master_data')
          .get();

      return snapshot.docs
          .map(
            (doc) => ExecutiveMasterData.fromfirestore(
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

  // update executive master data by executive name
  Future<bool> updateExecutiveMasterDataByExecutiveName(
    String oldExecutiveName,
    ExecutiveMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another executive
      if (oldExecutiveName != updatedData.executiveName) {
        QuerySnapshot duplicateCheck = await _db
            .collection('executive_master_data')
            .where('executive_name', isEqualTo: updatedData.executiveName)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // Find the document by the old executive name
      QuerySnapshot snapshot = await _db
          .collection('executive_master_data')
          .where('executive_name', isEqualTo: oldExecutiveName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('executive_master_data').doc(docId).update({
          'executive_name': updatedData.executiveName,
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

  // update executive master data by mobile number
  Future<bool> updateExecutiveMasterDataByMobileNumber(
    String oldMobileNumber,
    ExecutiveMasterData updatedData,
  ) async {
    try {
      // first check if the new no is already taken by another executive
      if (oldMobileNumber != updatedData.mobileNumber) {
        QuerySnapshot duplicateCheck = await _db
            .collection('executive_master_data')
            .where('mobile_number', isEqualTo: updatedData.mobileNumber)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          return false;
        }
      }

      // Find the document by the old executive name
      QuerySnapshot snapshot = await _db
          .collection('executive_master_data')
          .where('mobile_number', isEqualTo: oldMobileNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        await _db.collection('executive_master_data').doc(docId).update({
          'executive_name': updatedData.executiveName,
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
