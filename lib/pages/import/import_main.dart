import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImportMain extends StatefulWidget {
  const ImportMain({super.key});

  @override
  State<ImportMain> createState() => _ImportMainState();
}

class _ImportMainState extends State<ImportMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Master Datas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/import_customer');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'Import Customers',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/import_item');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              child: const Text('Import Items', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
