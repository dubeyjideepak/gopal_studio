import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/business_setup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/billing/screens/new_bill_screen.dart';
import '../../features/billing/screens/bill_detail_screen.dart';
import '../../features/billing/screens/bill_preview_screen.dart';
import '../../features/customers/screens/customers_screen.dart';
import '../../features/customers/screens/customer_detail_screen.dart';
import '../../features/customers/screens/add_customer_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settlements/screens/settlement_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: false,
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),

      // Main Shell with Bottom Nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Billing
      GoRoute(
        path: '/bill/new',
        name: 'new-bill',
        builder: (context, state) => const NewBillScreen(),
      ),
      GoRoute(
        path: '/bill/:id',
        name: 'bill-detail',
        builder: (context, state) {
          final billId = state.pathParameters['id']!;
          return BillDetailScreen(billId: billId);
        },
      ),
      GoRoute(
        path: '/bill/:id/preview',
        name: 'bill-preview',
        builder: (context, state) {
          final billId = state.pathParameters['id']!;
          return BillPreviewScreen(billId: billId);
        },
      ),
      GoRoute(
        path: '/bill/:id/settle',
        name: 'settlement',
        builder: (context, state) {
          final billId = state.pathParameters['id']!;
          return SettlementScreen(billId: billId);
        },
      ),

      // Customers
      GoRoute(
        path: '/customers/add',
        name: 'add-customer',
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        name: 'customer-detail',
        builder: (context, state) {
          final customerId = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: customerId);
        },
      ),
    ],
  );
});
