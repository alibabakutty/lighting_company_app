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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Light Order Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Control your Light Order Management',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
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

                  // Customer Master Card
                  _buildMasterCard(
                    context,
                    title: 'Customer Master',
                    subtitle: 'Manage your customers',
                    icon: Icons.people_alt_outlined,
                    color: Colors.teal,
                    onTap: () {
                      context.go('/cda_page', extra: 'customer');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Executive Master Card
                  _buildMasterCard(
                    context,
                    title: 'Executive Master',
                    subtitle: 'Manage your executives',
                    icon: Icons.person_outline,
                    color: Colors.blue.shade700,
                    onTap: () {
                      context.go('/cda_page', extra: 'executive');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Import Item Master Card
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
                  // Order Master Card
                  _buildMasterCard(
                    context,
                    title: 'Order Master',
                    subtitle: 'Manage your Orders',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.orange.shade700,
                    onTap: () {
                      context.go('/order_master');
                    },
                  ),
                  const SizedBox(height: 5),
                  // Report Card
                  _buildMasterCard(
                    context,
                    title: 'Orders Report',
                    subtitle: 'Report for all orders',
                    icon: Icons.history_outlined,
                    color: Colors.purple.shade700,
                    onTap: () {
                      context.go('/order_report');
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
      elevation: 2, // Reduced elevation for subtle shadow
      margin: const EdgeInsets.symmetric(
        vertical: 4,
      ), // Tighter vertical spacing
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Slightly smaller radius
        side: BorderSide(
          color: Colors.grey.shade200, // Add subtle border
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        // ignore: deprecated_member_use
        splashColor: color.withOpacity(0.1), // More subtle splash effect
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Row(
            children: [
              // Icon Container - made more compact
              Container(
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.1), // More subtle background
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 24, // Smaller icon
                  color: color,
                ),
              ),
              const SizedBox(width: 12), // Reduced spacing
              // Text Content - more compact layout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16, // Slightly smaller
                        fontWeight:
                            FontWeight.w600, // Semi-bold instead of bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13, // Smaller
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Chevron Icon - made smaller
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
