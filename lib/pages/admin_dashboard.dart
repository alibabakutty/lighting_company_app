import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/authentication/auth_models.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  final AuthService authService;

  const AdminDashboard({super.key, required this.authService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? adminUsername;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      final authUser = await widget.authService.getCurrentAuthUser();

      if (authUser.role != UserRole.admin) {
        if (mounted) context.go('/admin_login');
        return;
      }

      setState(() {
        adminUsername = authUser.username ?? 'Admin';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/admin_login');
      }
    }
  }

  Future<void> _logout() async {
    try {
      await widget.authService.signOut();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDisplayName(String name) {
    const maxLength = 12;
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 2)}..';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (adminUsername != null)
            Tooltip(
              message: adminUsername!,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Hi, ${_getDisplayName(adminUsername!)}!',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Hotel Order Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Manage your hotel arrangements',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  // Item Master Card
                  _buildMasterCard(
                    context,
                    title: 'Item Master',
                    subtitle: 'Manage all inventory items',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.indigo,
                    onTap: () {
                      context.go('/cda_page', extra: 'item');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Supplier Master Card
                  _buildMasterCard(
                    context,
                    title: 'Supplier Master',
                    subtitle: 'Manage your suppliers',
                    icon: Icons.people_alt_outlined,
                    color: Colors.teal,
                    onTap: () {
                      context.go('/cda_page', extra: 'supplier');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Table Master Card
                  _buildMasterCard(
                    context,
                    title: 'Table Master',
                    subtitle: 'Manage your tables',
                    icon: Icons.table_restaurant_outlined,
                    color: Colors.orange.shade700,
                    onTap: () {
                      context.go('/cda_page', extra: 'table');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Table Master Card
                  _buildMasterCard(
                    context,
                    title: 'Import Items via Excel',
                    subtitle: 'Import your items',
                    icon: Icons.upload_file_outlined,
                    color: Colors.green.shade700,
                    onTap: () {
                      context.go('/import_item');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Table Master Card
                  _buildMasterCard(
                    context,
                    title: 'Orders History',
                    subtitle: 'Preview all orders',
                    icon: Icons.history_outlined,
                    color: Colors.purple.shade700,
                    onTap: () {
                      context.go('/order_history');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Table Master Card
                  // _buildMasterCard(
                  //   context,
                  //   title: 'Export Excel Orders',
                  //   subtitle: 'Export all orders to Excel',
                  //   icon: Icons.download_outlined,
                  //   color: Colors.green.shade700,
                  //   onTap: () {
                  //     context.go('/export_excel_orders');
                  //   },
                  // ),

                  // Spacer to push content up
                  const Spacer(),

                  // Footer
                  Text(
                    'Last sync: ${DateTime.now().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMasterCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        // ignore: deprecated_member_use
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron Icon
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
