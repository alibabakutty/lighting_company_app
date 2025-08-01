import 'package:flutter/material.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/pages/admin_dashboard.dart';
import 'package:lighting_company_app/pages/orders/order-master/order_master.dart';
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isAuthenticated) {
      return const WelcomePage();
    }

    if (authProvider.isAdmin) {
      return AdminDashboard(
        authService: Provider.of<AuthService>(context, listen: false),
      );
    }

    if (authProvider.isSupplier) {
      return OrderMaster(
        authService: Provider.of<AuthService>(context, listen: false),
      );
    }

    return const WelcomePage();
  }
}
