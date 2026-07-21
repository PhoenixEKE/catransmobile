import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/admin/transport/admin_transport_navigation.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_companies_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counters_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_routes_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_stations_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminTransportHomeScreen extends StatefulWidget {
  final User user;
  final AdminTransportBaseApiService? apiService;

  const AdminTransportHomeScreen({
    super.key,
    required this.user,
    this.apiService,
  });

  @override
  State<AdminTransportHomeScreen> createState() =>
      _AdminTransportHomeScreenState();
}

class _AdminTransportHomeScreenState extends State<AdminTransportHomeScreen> {
  static const _companiesSectionId = 'companies';
  static const _citiesSectionId = 'cities';
  static const _serviceClassesSectionId = 'service_classes';
  static const _stationsSectionId = 'stations';
  static const _countersSectionId = 'counters';
  static const _routesSectionId = 'routes';
  static const _faresSectionId = 'fares';
  String _selectedSectionId = _companiesSectionId;

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(widget.user.scopes);
    if (!permissions.canReadAdminTransport) {
      return const StaffAccessDeniedPage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffModuleHeader(
            icon: Icons.route,
            title: 'Référentiels transport',
            description:
                'Administration des référentiels utilisés par le catalogue, les opérations et la vente.',
          ),
          const SizedBox(height: 14),
          StaffReadOnlyBanner(isReadOnly: !permissions.canManageAdminTransport),
          const SizedBox(height: 18),
          AdminTransportNavigation(
            selectedSectionId: _selectedSectionId,
            sections: _sections,
            onSectionSelected: (sectionId) {
              setState(() => _selectedSectionId = sectionId);
            },
          ),
          const SizedBox(height: 18),
          _buildSelectedSection(permissions),
        ],
      ),
    );
  }

  Widget _buildSelectedSection(StaffPermissions permissions) {
    if (_selectedSectionId == _companiesSectionId) {
      return AdminCompaniesScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _citiesSectionId) {
      return AdminCitiesScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _serviceClassesSectionId) {
      return AdminServiceClassesScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _stationsSectionId) {
      return AdminStationsScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _countersSectionId) {
      return AdminCountersScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _routesSectionId) {
      return AdminRoutesScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    if (_selectedSectionId == _faresSectionId) {
      return AdminFaresScreen(
        canManage: permissions.canManageAdminTransport,
        apiService: widget.apiService,
      );
    }

    return const SizedBox.shrink();
  }
}

const _sections = [
  AdminTransportSection(
    id: 'companies',
    label: 'Compagnies',
    icon: Icons.business,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'cities',
    label: 'Villes',
    icon: Icons.location_city,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'stations',
    label: 'Gares',
    icon: Icons.store_mall_directory,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'counters',
    label: 'Guichets',
    icon: Icons.point_of_sale,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'service_classes',
    label: 'Classes',
    icon: Icons.airline_seat_recline_extra,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'routes',
    label: 'Routes',
    icon: Icons.alt_route,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'fares',
    label: 'Tarifs',
    icon: Icons.payments,
    isAvailable: true,
  ),
  AdminTransportSection(
    id: 'schedules',
    label: 'Horaires',
    icon: Icons.schedule,
  ),
];
