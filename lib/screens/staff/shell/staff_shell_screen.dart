import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_dashboard_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_operations_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/admin_users_home_screen.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_screen.dart';
import 'package:catrans_app/screens/staff/dashboard/station_dashboard_screen.dart';
import 'package:catrans_app/screens/staff/departures/station_departures_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/screens/staff/pages/staff_home_page.dart';
import 'package:catrans_app/screens/staff/pages/staff_placeholder_page.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_screen.dart';
import 'package:catrans_app/screens/staff/counter/counter_search_screen.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/screens/staff/shell/staff_navigation_request.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/widgets/staff/staff_sidebar.dart';
import 'package:catrans_app/widgets/staff/staff_topbar.dart';

class StaffShellScreen extends StatefulWidget {
  const StaffShellScreen({super.key});

  @override
  State<StaffShellScreen> createState() => _StaffShellScreenState();
}

class _StaffShellScreenState extends State<StaffShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedId;
  String? _initializedUserId;
  StaffNavigationRequest? _navigationRequest;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null || user.isCustomer) {
      return const StaffAccessDeniedPage();
    }

    final menuItems = StaffMenuItem.forUser(user);
    if (menuItems.isEmpty) {
      return const StaffAccessDeniedPage();
    }

    _ensureInitialSelection(user, menuItems);

    final selectedId = _selectedId ?? menuItems.first.id;
    final selectedItem = menuItems.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => menuItems.first,
    );
    final content = _contentFor(user, selectedItem, menuItems);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F6FA),
          drawer: showSidebar
              ? null
              : Drawer(
                  child: StaffSidebar(
                    user: user,
                    items: menuItems,
                    selectedId: selectedItem.id,
                    onSelected: (id) {
                      Navigator.pop(context);
                      _selectMenu(id);
                    },
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar)
                StaffSidebar(
                  user: user,
                  items: menuItems,
                  selectedId: selectedItem.id,
                  onSelected: _selectMenu,
                ),
              Expanded(
                child: Column(
                  children: [
                    StaffTopbar(
                      user: user,
                      title: selectedItem.title,
                      onOpenMenu: showSidebar
                          ? null
                          : () => _scaffoldKey.currentState?.openDrawer(),
                      onLogout: () => _logout(context),
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contentFor(
    User user,
    StaffMenuItem selectedItem,
    List<StaffMenuItem> menuItems,
  ) {
    if (selectedItem.id == 'home') {
      if (user.internalProfile?.role == InternalRole.station_manager) {
        return StationDashboardScreen(
          user: user,
          onNavigate: _navigate,
        );
      }

      return StaffHomePage(user: user, menuItems: menuItems);
    }

    if (selectedItem.id == 'admin_dashboard') {
      return AdminDashboardHomeScreen(user: user);
    }

    if (selectedItem.id == 'admin_users') {
      return AdminUsersHomeScreen(user: user);
    }

    if (selectedItem.id == 'admin_transport') {
      return AdminTransportHomeScreen(user: user);
    }

    if (selectedItem.id == 'admin_operations') {
      return AdminOperationsHomeScreen(user: user);
    }

    if (selectedItem.id == 'reservation_search') {
      return const CounterSearchScreen();
    }

    if (selectedItem.id == 'station_reservations') {
      return const CounterSearchScreen(supervisionMode: true);
    }

    if (selectedItem.id == 'boarding') {
      final request = _navigationRequestFor('boarding');
      return BoardingScreen(
        initialDepartureId: request?.departureId,
        onInitialDepartureConsumed: _clearNavigationRequest,
      );
    }

    if (selectedItem.id == 'departures') {
      final request = _navigationRequestFor('departures');
      return StationDeparturesScreen(
        user: user,
        initialDepartureId: request?.departureId,
        onInitialDepartureConsumed: _clearNavigationRequest,
        onNavigate: _navigate,
      );
    }

    if (selectedItem.id == 'reports') {
      return StationReportsScreen(user: user);
    }

    return StaffPlaceholderPage(user: user, item: selectedItem);
  }

  void _ensureInitialSelection(User user, List<StaffMenuItem> menuItems) {
    if (_initializedUserId == user.id && _selectedId != null) {
      if (menuItems.any((item) => item.id == _selectedId)) return;
    }

    _initializedUserId = user.id;
    _navigationRequest = null;
    _selectedId = _resolveInitialStaffMenuId(user, menuItems);
  }

  String _resolveInitialStaffMenuId(User user, List<StaffMenuItem> menuItems) {
    return resolveInitialStaffMenuId(
          menuItems: menuItems,
          scopes: user.scopes.toSet(),
          role: user.internalProfile?.role,
        ) ??
        menuItems.first.id;
  }

  StaffNavigationRequest? _navigationRequestFor(String menuId) {
    final request = _navigationRequest;
    if (request == null || request.menuId != menuId) return null;
    return request;
  }

  void _selectMenu(String id) {
    setState(() {
      _selectedId = id;
      _navigationRequest = null;
    });
  }

  void _navigate(StaffNavigationRequest request) {
    setState(() {
      _selectedId = request.menuId;
      _navigationRequest = request.hasDepartureContext ? request : null;
    });
  }

  void _clearNavigationRequest() {
    if (_navigationRequest == null) return;
    setState(() => _navigationRequest = null);
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }
}
