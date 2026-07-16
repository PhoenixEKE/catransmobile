import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/screens/staff/pages/staff_home_page.dart';
import 'package:catrans_app/screens/staff/pages/staff_placeholder_page.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
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
  String _selectedId = 'home';

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null || user.isCustomer) {
      return const StaffAccessDeniedPage();
    }

    final menuItems = StaffMenuItem.forUser(user);
    final selectedItem = menuItems.firstWhere(
      (item) => item.id == _selectedId,
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
                      setState(() => _selectedId = id);
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
                  onSelected: (id) => setState(() => _selectedId = id),
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
      return StaffHomePage(user: user, menuItems: menuItems);
    }

    return StaffPlaceholderPage(user: user, item: selectedItem);
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
