import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lighting_company_app/models/customer_master_data.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ImportCustomer extends StatefulWidget {
  const ImportCustomer({super.key});

  @override
  State<ImportCustomer> createState() => _ImportCustomerState();
}

class _ImportCustomerState extends State<ImportCustomer> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  int _successCount = 0;
  int _errorCount = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _fileName;

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting Excel file...';
      _hasError = false;
      _successCount = 0;
      _errorCount = 0;
      _fileName = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No file selected';
        });
        return;
      }

      final file = result.files.single;
      setState(() => _fileName = file.name);

      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'File is empty or cannot be read';
          _hasError = true;
        });
        return;
      }

      await _processExcelFile(file.bytes!);
    } catch (e) {
      debugPrint('Import error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  Future<void> _processExcelFile(Uint8List bytes) async {
    setState(() => _statusMessage = 'Processing Excel file...');

    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      final table = decoder.tables.values.first;

      if (table.rows.length <= 1) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No data found in Excel sheet (only header row)';
          _hasError = true;
        });
        return;
      }

      final batch = _firestore.batch();
      final collectionRef = _firestore.collection('customer_master_data');

      for (int i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];
          if (row.length < 3) {
            // At least customer name, mobile, and email
            _errorCount++;
            continue;
          }

          final customerName = _parseString(row[0]);
          if (customerName.isEmpty) {
            _errorCount++;
            continue;
          }

          final mobileNumber = _parseString(row[1]);
          if (mobileNumber.isEmpty) {
            _errorCount++;
            continue;
          }

          final email = row.length > 2 ? _parseString(row[2]) : '';
          final createdAt = row.length > 3 && row[3] != null
              ? _parseTimestamp(row[3].toString())
              : Timestamp.now();

          final customer = CustomerMasterData(
            customerName: customerName,
            mobileNumber: mobileNumber,
            email: email,
            createdAt: createdAt,
          );

          // Using customer name as document ID (you might want to use a different unique identifier)
          String sanitizedId(String input) {
            return input.replaceAll(RegExp(r'[\/\.\$#\[\]]'), '_');
          }

          batch.set(
            collectionRef.doc(sanitizedId(customerName)),
            customer.toFirestore(),
          );
          _successCount++;

          if (i % 10 == 0 || i == table.rows.length - 1) {
            setState(() {
              _statusMessage = 'Processing row $i/${table.rows.length - 1}...';
            });
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          debugPrint('Error processing row $i: $e');
          _errorCount++;
        }
      }

      setState(() => _statusMessage = 'Uploading data to Firestore...');
      await batch.commit();

      setState(() {
        _isLoading = false;
        _statusMessage =
            '''
Import completed!
Successful: $_successCount
Failed: $_errorCount
Total: ${table.rows.length - 1}''';
        _hasError = _errorCount > 0;
      });
    } catch (e) {
      debugPrint('Excel processing error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error processing Excel file: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  Timestamp _parseTimestamp(String dateString) {
    try {
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd-MM-yyyy'),
      ];

      for (final format in formats) {
        try {
          return Timestamp.fromDate(format.parse(dateString));
        } catch (_) {}
      }
      return Timestamp.now();
    } catch (_) {
      return Timestamp.now();
    }
  }

  String _parseString(dynamic value) => value?.toString().trim() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Customer Data'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. Prepare an Excel file with the following columns in order:',
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Customer Name (required)'),
                          Text('• Mobile Number (required)'),
                          Text('• Email (optional)'),
                          Text('• Created At (optional date)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '2. The first row should be headers (will be skipped)',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fileName != null
                          ? 'Selected file: $_fileName'
                          : 'No file selected',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: _fileName != null ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Excel File'),
                onPressed: _isLoading ? null : _importData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Card(
                color: _hasError ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _hasError ? 'Import Status (Errors)' : 'Import Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _hasError
                              ? Colors.red[800]
                              : Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _hasError
                              ? Colors.red[800]
                              : Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
