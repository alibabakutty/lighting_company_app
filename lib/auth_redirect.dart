import 'package:flutter/material.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/pages/admin_dashboard.dart';
import 'package:lighting_company_app/pages/orders/order_master.dart';
import 'package:lighting_company_app/pages/welcome_page.dart';
import 'package:provider/provider.dart';

class AuthRedirect extends StatefulWidget {
  const AuthRedirect({super.key});

  @override
  State<AuthRedirect> createState() => _AuthRedirectState();
}

class _AuthRedirectState extends State<AuthRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const WelcomePage();
    }

    // Handle navigation based on the current route
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // If admin is trying to access order master directly, allow it
    if (currentRoute == '/order_master' && authProvider.isAdmin) {
      return OrderMaster(
        authService: Provider.of<AuthService>(context, listen: false),
      );
    }

    // Default routing
    if (authProvider.isAdmin) {
      return AdminDashboard(
        authService: Provider.of<AuthService>(context, listen: false),
      );
    }

    // For suppliers
    return OrderMaster(
      authService: Provider.of<AuthService>(context, listen: false),
    );
  }
}
