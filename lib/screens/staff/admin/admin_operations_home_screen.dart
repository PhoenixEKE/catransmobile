import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_operations_navigation.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_screen.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_screen.dart';
import 'package:catrans_app/screens/staff/admin/operations/layouts/admin_seat_layouts_screen.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seats_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminOperationsHomeScreen extends StatefulWidget {
  final User user;

  const AdminOperationsHomeScreen({super.key, required this.user});

  @override
  State<AdminOperationsHomeScreen> createState() =>
      _AdminOperationsHomeScreenState();
}

class _AdminOperationsHomeScreenState extends State<AdminOperationsHomeScreen> {
  static const _sections = [
    AdminOperationsSection(
      id: 'departures',
      label: 'Départs',
      icon: Icons.directions_bus_outlined,
    ),
    AdminOperationsSection(
      id: 'seat-layouts',
      label: 'Plans de sièges',
      icon: Icons.view_module_outlined,
    ),
    AdminOperationsSection(
      id: 'seats',
      label: 'Sièges',
      icon: Icons.event_seat_outlined,
    ),
    AdminOperationsSection(
      id: 'boarding',
      label: 'Embarquement',
      icon: Icons.qr_code_scanner,
    ),
  ];

  String _selectedSectionId = 'departures';
  AdminDeparture? _selectedDeparture;

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(widget.user.scopes);
    if (!permissions.canReadAdminOperations) {
      return const StaffAccessDeniedPage();
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StaffModuleHeader(
                icon: Icons.event_seat,
                title: 'Opérations admin',
                description:
                    'Départs opérationnels, sièges générés et contrôle embarquement.',
              ),
              const SizedBox(height: 14),
              StaffReadOnlyBanner(
                isReadOnly: !permissions.canManageAdminOperations,
              ),
              const SizedBox(height: 14),
              AdminOperationsNavigation(
                selectedSectionId: _selectedSectionId,
                sections: _sections,
                onSectionSelected: (id) => setState(() {
                  _selectedSectionId = id;
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: _contentHeight(constraints.maxHeight),
                child: _buildSection(permissions),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(StaffPermissions permissions) {
    switch (_selectedSectionId) {
      case 'seat-layouts':
        return AdminSeatLayoutsScreen(
          canManage: permissions.canManageAdminOperations,
        );
      case 'seats':
        return AdminDepartureSeatsScreen(
          departure: _selectedDeparture,
          canManage: permissions.canManageAdminOperations,
        );
      case 'boarding':
        return AdminBoardingScreen(
          departure: _selectedDeparture,
          canReadManifest: permissions.canReadBoardingManifest,
          canValidate: permissions.canValidateBoarding,
        );
      default:
        return AdminDeparturesScreen(
          canManage: permissions.canManageAdminOperations,
          selectedDeparture: _selectedDeparture,
          onDepartureSelected: (departure) => setState(() {
            _selectedDeparture = departure;
          }),
          onOpenSeats: (departure) => setState(() {
            _selectedDeparture = departure;
            _selectedSectionId = 'seats';
          }),
          onOpenBoarding: (departure) => setState(() {
            _selectedDeparture = departure;
            _selectedSectionId = 'boarding';
          }),
        );
    }
  }

  double _contentHeight(double maxHeight) {
    if (!maxHeight.isFinite || maxHeight < 520) return 620;
    return (maxHeight - 210).clamp(520, 900);
  }
}
