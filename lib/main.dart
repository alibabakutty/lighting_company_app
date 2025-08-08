import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lighting_company_app/auth_redirect.dart';
import 'package:lighting_company_app/authentication/auth_provider.dart';
import 'package:lighting_company_app/authentication/auth_service.dart';
import 'package:lighting_company_app/firebase_options.dart';
import 'package:lighting_company_app/pages/admin_dashboard.dart';
import 'package:lighting_company_app/pages/cda_page.dart';
import 'package:lighting_company_app/pages/fetch-pages/display_fetch_pages.dart';
import 'package:lighting_company_app/pages/fetch-pages/update_fetch_pages.dart';
import 'package:lighting_company_app/pages/import_item.dart';
import 'package:lighting_company_app/pages/login-pages/admin_login.dart';
import 'package:lighting_company_app/pages/login-pages/supplier_login.dart';
import 'package:lighting_company_app/pages/masters/customer_master.dart';
import 'package:lighting_company_app/pages/masters/item_master.dart';
import 'package:lighting_company_app/pages/masters/supplier_master.dart';
import 'package:lighting_company_app/pages/order_report.dart';
import 'package:lighting_company_app/pages/orders/order_master.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const FoodOrderApp(),
    ),
  );
}

final _router = GoRouter(
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoading) {
      return null;
    }

    final isLoggedIn = authProvider.isAuthenticated;
    final isAdmin = authProvider.isAdmin;
    final isLoginRoute =
        state.matchedLocation == '/admin_login' ||
        state.matchedLocation == '/supplier_login';

    // If not logged in and trying to access protected route
    if (!isLoggedIn && !isLoginRoute && state.matchedLocation != '/') {
      return '/';
    }

    // If logged in and trying to access login page
    if (isLoggedIn && isLoginRoute) {
      return isAdmin ? '/admin_dashboard' : '/order_master';
    }

    // Check order master access
    if (state.matchedLocation == '/order_master' &&
        !authProvider.canAccessOrderMaster) {
      return '/admin_dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthRedirect(),
      routes: [
        GoRoute(
          path: 'admin_login',
          builder: (context, state) => const AdminLogin(),
        ),
        GoRoute(
          path: 'supplier_login',
          builder: (context, state) => const SupplierLogin(),
        ),
        GoRoute(
          path: 'admin_dashboard',
          builder: (context, state) => AdminDashboard(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
        GoRoute(
          path: 'order_master',
          builder: (context, state) => OrderMaster(
            authService: Provider.of<AuthService>(context, listen: false),
          ),
        ),
        GoRoute(
          path: 'cda_page',
          builder: (context, state) {
            final masterType = state.extra as String;
            return CdaPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'display_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return DisplayFetchPage(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'update_fetch',
          builder: (context, state) {
            final masterType = state.extra as String;
            return UpdateFetchPages(masterType: masterType);
          },
        ),
        GoRoute(
          path: 'item_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return ItemMaster(
              itemName: args['itemName'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'supplier_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return SupplierMaster(
              supplierName: args['supplierName'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'customer_master',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return CustomerMaster(
              customerName: args['customer_name'],
              isDisplayMode: args['isDisplayMode'] ?? false,
            );
          },
        ),
        GoRoute(
          path: 'import_item',
          builder: (context, state) => const ImportItem(),
        ),
        // GoRoute(
        //   path: 'export_excel_orders',
        //   builder: (context, state) => const ExportExcelOrders(),
        // ),
        GoRoute(
          path: 'order_report',
          builder: (context, state) => const OrderReport(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Error: ${state.error}'))),
);

class FoodOrderApp extends StatelessWidget {
  const FoodOrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Order Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Aptos Display',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Aptos Display',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
