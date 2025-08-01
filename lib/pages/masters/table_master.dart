import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/models/table_master_data.dart';
import 'package:lighting_company_app/service/firebase_service.dart';

class TableMaster extends StatefulWidget {
  final int? tableNumber;
  final bool isDisplayMode;
  const TableMaster({super.key, this.tableNumber, this.isDisplayMode = false});

  @override
  State<TableMaster> createState() => _TableMasterState();
}

class _TableMasterState extends State<TableMaster> {
  final FirebaseService firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _tableSizeController = TextEditingController();
  bool _isTableAvailable = true;

  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isLoading = false;

  TableMasterData? _tableMasterData;

  @override
  void initState() {
    super.initState();
    if (widget.tableNumber != null) {
      _fetchTableData(widget.tableNumber!);
      _isEditing = !widget.isDisplayMode;
    }
  }

  Future<void> _fetchTableData(int tableNumber) async {
    setState(() => _isLoading = true);
    try {
      final data = await firebaseService.getTableByTableNumber(tableNumber);
      if (data != null) {
        setState(() {
          _tableMasterData = data;
          _tableNumberController.text = data.tableNumber.toString();
          _tableSizeController.text = data.tableCapacity.toString();
          _isTableAvailable = data.tableAvailability;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Table not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final tableData = TableMasterData(
        tableNumber: int.parse(_tableNumberController.text),
        tableCapacity: int.parse(_tableSizeController.text),
        tableAvailability: _isTableAvailable,
        createdAt: _tableMasterData?.createdAt ?? Timestamp.now(),
      );

      bool success;
      if (_isEditing && _tableMasterData != null) {
        success = await firebaseService.updateTableMasterDataByTableNumber(
          _tableMasterData!.tableNumber,
          tableData,
        );
      } else {
        final existing = await firebaseService.getTableByTableNumber(
          tableData.tableNumber,
        );
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Table number already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        success = await firebaseService.addTableMasterData(tableData);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Table updated!' : 'Table created!'),
            backgroundColor: Colors.green,
          ),
        );
        if (!_isEditing) _resetForm();
        if (_isEditing) context.go('/cda_page', extra: 'table');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _tableNumberController.clear();
    _tableSizeController.clear();
    setState(() {
      _isTableAvailable = true;
      _tableMasterData = null;
      _isEditing = false;
    });
    _formKey.currentState?.reset();
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _tableSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Master'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cda_page', extra: 'table'),
        ),
        actions: widget.isDisplayMode
            ? [
                IconButton(
                  icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
                  onPressed: _toggleEditMode,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      _isEditing
                          ? 'Edit Table'
                          : widget.isDisplayMode
                          ? 'Table Details'
                          : 'Add New Table',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Table Number Field
                    TextFormField(
                      controller: _tableNumberController,
                      decoration: InputDecoration(
                        labelText: 'Table Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.table_restaurant),
                      ),
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Table Size Field
                    TextFormField(
                      controller: _tableSizeController,
                      decoration: InputDecoration(
                        labelText: 'Table Size (Capacity)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.people),
                        suffixText: 'persons',
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: widget.isDisplayMode && !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        if (int.parse(value) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Table Availability Switch
                    SwitchListTile(
                      title: const Text('Table Available'),
                      subtitle: const Text('Toggle if ready for seating'),
                      value: _isTableAvailable,
                      onChanged: widget.isDisplayMode && !_isEditing
                          ? null
                          : (value) =>
                                setState(() => _isTableAvailable = value),
                      secondary: Icon(
                        _isTableAvailable ? Icons.check_circle : Icons.block,
                        color: _isTableAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Action Buttons
                    if (!widget.isDisplayMode || _isEditing)
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isEditing ? 'Update Table' : 'Save Table',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
