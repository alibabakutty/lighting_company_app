import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CdaPage extends StatelessWidget {
  final String masterType;

  const CdaPage({super.key, required this.masterType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${masterType.capitalize()} Master'),
        leading: IconButton(
          onPressed: () {
            context.go('/admin_dashboard');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          20.0,
        ), // Add padding to prevent edge-to-edge buttons
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Create Button
              _buildActionButton(
                context: context,
                icon: Icons.add,
                label: 'Create',
                color: Colors.green.shade600,
                onPressed: () {
                  switch (masterType) {
                    case 'item':
                      context.go(
                        '/item_master',
                        extra: {'isDisplayMode': false},
                      );
                      break;
                    case 'supplier':
                      context.go('/supplier_master');
                      break;
                    case 'table':
                      context.go('/table_master');
                      break;
                    default:
                  }
                },
              ),
              const SizedBox(height: 20),
              // Display Button
              _buildActionButton(
                context: context,
                icon: Icons.visibility,
                label: 'Display',
                color: Colors.blue.shade600,
                onPressed: () {
                  context.go('/display_fetch', extra: masterType);
                },
              ),
              const SizedBox(height: 20),
              // Update Button
              _buildActionButton(
                context: context,
                icon: Icons.edit,
                label: 'Update',
                color: Colors.orange.shade600,
                onPressed: () {
                  context.go('/update_fetch', extra: masterType);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size.fromHeight(50), // Set minimum height
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
