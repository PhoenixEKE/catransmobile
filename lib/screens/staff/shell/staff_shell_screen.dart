import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
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
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';
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
  AdminUsersApiService? _adminUsersApiService;
  String? _selectedId;
  String? _initializedUserId;
  StaffNavigationRequest? _navigationRequest;
  List<StaffStationRef> _adminStations = const [];
  String? _selectedAdminStationId;
  String? _adminStationError;
  bool _isLoadingAdminStations = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null || user.isCustomer) {
      return StaffAccessDeniedPage(user: user);
    }

    final menuItems = StaffMenuItem.forUser(user);
    if (menuItems.isEmpty) {
      return StaffAccessDeniedPage(user: user);
    }

    _ensureInitialSelection(user, menuItems);

    final selectedId = _selectedId ?? menuItems.first.id;
    final selectedItem = menuItems.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => menuItems.first,
    );
    final requiresAdminStation =
        _requiresAdminStationSelection(user, selectedItem);
    if (requiresAdminStation) {
      _ensureAdminStationsLoaded();
    }

    final content = requiresAdminStation
        ? _adminStationScopedContent(user, selectedItem, menuItems)
        : _contentFor(user, selectedItem, menuItems);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            PersonnelBreakpoints.isDesktop(constraints.maxWidth);
        final isLarge = PersonnelBreakpoints.isLarge(constraints.maxWidth);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: PersonnelColors.background,
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
                    Expanded(
                      child: isLarge
                          ? Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth:
                                      PersonnelBreakpoints.maxContentWidth,
                                ),
                                child: content,
                              ),
                            )
                          : content,
                    ),
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
    final stationId = _requiresAdminStationSelection(user, selectedItem)
        ? _selectedAdminStationId
        : null;

    if (selectedItem.id == 'home') {
      if (user.internalProfile?.role == InternalRole.station_manager) {
        return StationDashboardScreen(
          user: user,
          onNavigate: _navigate,
        );
      }

      return StaffHomePage(user: user, menuItems: menuItems);
    }

    if (selectedItem.id == 'station_dashboard') {
      return StationDashboardScreen(
        user: user,
        stationId: stationId,
        onNavigate: _navigate,
      );
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
      return CounterSearchScreen(
        stationId: stationId,
        supervisionMode: _requiresAdminStationSelection(user, selectedItem),
      );
    }

    if (selectedItem.id == 'station_reservations') {
      return CounterSearchScreen(
        stationId: stationId,
        supervisionMode: true,
      );
    }

    if (selectedItem.id == 'boarding') {
      final request = _navigationRequestFor('boarding');
      return BoardingScreen(
        stationId: stationId,
        initialDepartureId: request?.departureId,
        onInitialDepartureConsumed: _clearNavigationRequest,
      );
    }

    if (selectedItem.id == 'departures') {
      final request = _navigationRequestFor('departures');
      return StationDeparturesScreen(
        user: user,
        stationId: stationId,
        initialDepartureId: request?.departureId,
        onInitialDepartureConsumed: _clearNavigationRequest,
        onNavigate: _navigate,
      );
    }

    if (selectedItem.id == 'reports') {
      return StationReportsScreen(user: user, stationId: stationId);
    }

    return StaffPlaceholderPage(user: user, item: selectedItem);
  }

  bool _requiresAdminStationSelection(User user, StaffMenuItem item) {
    if (!_adminCanUseStationSelection(user)) return false;
    return const {
      'station_dashboard',
      'departures',
      'reservation_search',
      'station_reservations',
      'boarding',
      'reports',
    }.contains(item.id);
  }

  bool _adminCanUseStationSelection(User user) {
    final role = user.internalProfile?.role;
    return user.isSuperuser ||
        role == InternalRole.admin ||
        user.scopes.contains(StaffPermissions.stationAllRead);
  }

  Widget _adminStationScopedContent(
    User user,
    StaffMenuItem selectedItem,
    List<StaffMenuItem> menuItems,
  ) {
    final selectedStation = _selectedAdminStation;
    return Column(
      children: [
        _AdminStationSelector(
          stations: _adminStations,
          selectedStationId: _selectedAdminStationId,
          isLoading: _isLoadingAdminStations,
          errorMessage: _adminStationError,
          onChanged: _selectAdminStation,
          onRetry: _loadAdminStations,
        ),
        Expanded(
          child: selectedStation == null
              ? _AdminStationEmptyState(
                  isLoading: _isLoadingAdminStations,
                  hasError: _adminStationError != null,
                )
              : KeyedSubtree(
                  key: ValueKey(
                    '${selectedItem.id}-${selectedStation.id}',
                  ),
                  child: _contentFor(user, selectedItem, menuItems),
                ),
        ),
      ],
    );
  }

  StaffStationRef? get _selectedAdminStation {
    final selectedId = _selectedAdminStationId;
    if (selectedId == null) return null;
    for (final station in _adminStations) {
      if (station.id == selectedId) return station;
    }
    return null;
  }

  void _ensureAdminStationsLoaded() {
    if (_adminStations.isNotEmpty || _isLoadingAdminStations) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAdminStations();
    });
  }

  Future<void> _loadAdminStations() async {
    if (_isLoadingAdminStations) return;
    setState(() {
      _isLoadingAdminStations = true;
      _adminStationError = null;
    });

    try {
      final apiService = _adminUsersApiService ??= AdminUsersApiService();
      final stations = await apiService.listStations();
      if (!mounted) return;
      setState(() {
        _adminStations = stations;
        if (_selectedAdminStationId == null ||
            !stations.any((station) => station.id == _selectedAdminStationId)) {
          _selectedAdminStationId = stations.isEmpty ? null : stations.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _adminStations = const [];
        _selectedAdminStationId = null;
        _adminStationError = 'Impossible de charger les gares.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingAdminStations = false);
    }
  }

  void _selectAdminStation(String? stationId) {
    setState(() {
      _selectedAdminStationId = stationId;
      _navigationRequest = null;
    });
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
    context.go(RoutePaths.root);
  }
}

class _AdminStationSelector extends StatelessWidget {
  final List<StaffStationRef> stations;
  final String? selectedStationId;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  const _AdminStationSelector({
    required this.stations,
    required this.selectedStationId,
    required this.isLoading,
    required this.errorMessage,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              color: Color(0xFF0F056B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('admin-station-selector'),
                initialValue: selectedStationId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Gare',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: stations
                    .map(
                      (station) => DropdownMenuItem(
                        value: station.id,
                        child: Text(
                          station.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isLoading || stations.isEmpty ? null : onChanged,
              ),
            ),
            const SizedBox(width: 12),
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                key: const Key('admin-station-selector-refresh'),
                tooltip: 'Actualiser les gares',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            if (errorMessage != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  errorMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminStationEmptyState extends StatelessWidget {
  final bool isLoading;
  final bool hasError;

  const _AdminStationEmptyState({
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final title = isLoading
        ? 'Chargement des gares...'
        : hasError
            ? 'Gares indisponibles'
            : 'Sélectionnez une gare';
    final message = isLoading
        ? 'Le contexte gare est en cours de préparation.'
        : hasError
            ? 'Actualisez la liste des gares pour reprendre.'
            : 'Choisissez une gare pour afficher cet écran opérationnel.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.store_outlined,
                size: 42,
                color: hasError
                    ? const Color(0xFFB42318)
                    : const Color(0xFF0F056B),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F056B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5B6270)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
