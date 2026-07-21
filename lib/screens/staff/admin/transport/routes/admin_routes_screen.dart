import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_route_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_route_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_routes_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_routes_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_routes_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminRoutesScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;
  const AdminRoutesScreen(
      {super.key, required this.canManage, this.apiService});
  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  late final AdminRoutesController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AdminRoutesController(apiService: widget.apiService);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AdminRoutesToolbar(
                initialQuery: _controller.query,
                selectedCompanyId: _controller.companyId,
                selectedDepartureStationId: _controller.departureStationId,
                selectedDepartureCityId: _controller.departureCityId,
                selectedDestinationCityId: _controller.destinationCityId,
                selectedIsActive: _controller.isActive,
                ordering: _controller.ordering,
                companies: _controller.companies,
                stations: _controller.stations,
                cities: _controller.cities,
                canManage: widget.canManage,
                onSearch: _controller.search,
                onCompanyChanged: _controller.setCompanyFilter,
                onDepartureStationChanged:
                    _controller.setDepartureStationFilter,
                onDepartureCityChanged: _controller.setDepartureCityFilter,
                onDestinationCityChanged: _controller.setDestinationCityFilter,
                onActiveChanged: _controller.setActiveFilter,
                onOrderingChanged: _controller.setOrdering,
                onRefresh: _controller.refresh,
                onCreate: _openCreateForm),
            const SizedBox(height: 18),
            Expanded(child: SingleChildScrollView(child: _buildContent())),
          ]));

  Widget _buildContent() {
    if (_controller.isLoading && _controller.routesPage == null) {
      return const StaffLoadingState(message: 'Chargement des routes...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
          message: _controller.listError!, onRetry: _controller.refresh);
    }
    final page = _controller.routesPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
          icon: Icons.alt_route,
          title: 'Aucune route',
          message: 'Aucune route ne correspond aux filtres actuels.');
    }
    return Stack(children: [
      AdminRoutesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateRoute,
          onDeactivate: _deactivateRoute),
      if (_controller.isLoading || _controller.isSubmitting)
        const Positioned.fill(
            child: IgnorePointer(
                child: ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))))
    ]);
  }

  Future<void> _openDetail(AdminRoute route) async =>
      showAdminRouteDetailDialog(
          context: context, route: route, loadDetail: _controller.getDetail);

  Future<void> _openCreateForm() async {
    if (!widget.canManage) {
      return;
    }
    StructuredApiError? formError;
    AdminRouteCreateRequest? draft;
    while (mounted) {
      final result = await showAdminRouteFormDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          companies: _controller.companies,
          stations: _controller.stations,
          cities: _controller.cities,
          error: formError,
          initialCreateRequest: draft);
      if (result?.createRequest == null) {
        return;
      }
      draft = result!.createRequest!;
      final success = await _controller.createRoute(draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Route créée.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminRoute route) async {
    if (!widget.canManage) {
      return;
    }
    AdminRoute detail;
    try {
      detail = await _controller.getDetail(route.id);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Impossible de charger le détail route.');
      }
      return;
    }
    if (!mounted) {
      return;
    }
    StructuredApiError? formError;
    AdminRouteUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminRouteFormDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          companies: _controller.companies,
          stations: _controller.stations,
          cities: _controller.cities,
          error: formError,
          initialRoute: detail,
          initialUpdateRequest: draft);
      if (result?.updateRequest == null) {
        return;
      }
      draft = result!.updateRequest!;
      final success = await _controller.updateRoute(route.id, draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Route mise à jour.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateRoute(AdminRoute route) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Activer cette route ?',
        message:
            '${route.departureStation.name} -> ${route.displayDestination}',
        actionLabel: 'Activer');
    if (confirmed != true) {
      return;
    }
    final success = await _controller.activateRoute(route.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Route activée.'
        : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateRoute(AdminRoute route) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Désactiver cette route ?',
        message:
            '${route.departureStation.name} -> ${route.displayDestination}',
        actionLabel: 'Désactiver',
        destructive: true);
    if (confirmed != true) {
      return;
    }
    final success = await _controller.deactivateRoute(route.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Route désactivée.'
        : _controller.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction(
          {required String title,
          required String message,
          required String actionLabel,
          bool destructive = false}) =>
      showDialog<bool>(
          context: context,
          barrierDismissible: !_controller.isSubmitting,
          builder: (dialogContext) => AlertDialog(
                  key: Key(destructive
                      ? 'admin-route-deactivate-confirm-dialog'
                      : 'admin-route-activate-confirm-dialog'),
                  title: Text(title),
                  content: Text(message),
                  actions: [
                    TextButton(
                        onPressed: _controller.isSubmitting
                            ? null
                            : () => Navigator.pop(dialogContext, false),
                        child: const Text('Annuler')),
                    ElevatedButton(
                        key: Key(destructive
                            ? 'admin-route-deactivate-confirm'
                            : 'admin-route-activate-confirm'),
                        style: destructive
                            ? ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB42318),
                                foregroundColor: Colors.white)
                            : null,
                        onPressed: _controller.isSubmitting
                            ? null
                            : () => Navigator.pop(dialogContext, true),
                        child: Text(actionLabel))
                  ]));
  void _showSnackBar(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
