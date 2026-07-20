import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_toolbar.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_city_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_city_form_dialog.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminCitiesScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;

  const AdminCitiesScreen({
    super.key,
    required this.canManage,
    this.apiService,
  });

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  late final AdminCitiesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminCitiesController(apiService: widget.apiService);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminCitiesToolbar(
              initialQuery: _controller.query,
              selectedIsActive: _controller.isActive,
              ordering: _controller.ordering,
              canManage: widget.canManage,
              onSearch: _controller.search,
              onActiveChanged: _controller.setActiveFilter,
              onOrderingChanged: _controller.setOrdering,
              onRefresh: _controller.refresh,
              onCreate: _openCreateForm,
            ),
            const SizedBox(height: 18),
            _buildContent(),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.citiesPage == null) {
      return const StaffLoadingState(message: 'Chargement des villes...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(message: _controller.listError!, onRetry: _controller.refresh);
    }
    final page = _controller.citiesPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.location_city,
        title: 'Aucune ville',
        message: 'Aucune ville ne correspond aux filtres actuels.',
      );
    }
    return Stack(
      children: [
        AdminCitiesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage: _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateCity,
          onDeactivate: _deactivateCity,
        ),
        if (_controller.isLoading || _controller.isSubmitting)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openDetail(AdminCity city) async {
    await showAdminCityDetailDialog(
      context: context,
      city: city,
      loadDetail: _controller.getDetail,
    );
  }

  Future<void> _openCreateForm() async {
    if (!widget.canManage) return;
    StructuredApiError? formError;
    AdminCityCreateRequest? draft;
    while (mounted) {
      final result = await showAdminCityFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialCreateRequest: draft,
      );
      if (result?.createRequest == null) return;
      draft = result!.createRequest!;
      final success = await _controller.createCity(draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Ville créée.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminCity city) async {
    if (!widget.canManage) return;
    AdminCity detail;
    try {
      detail = await _controller.getDetail(city.id);
    } catch (_) {
      if (mounted) _showSnackBar('Impossible de charger le détail ville.');
      return;
    }
    if (!mounted) return;

    StructuredApiError? formError;
    AdminCityUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminCityFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialCity: detail,
        initialUpdateRequest: draft,
      );
      if (result?.updateRequest == null) return;
      draft = result!.updateRequest!;
      final success = await _controller.updateCity(city.id, draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Ville mise à jour.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateCity(AdminCity city) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Activer cette ville ?',
      message: 'La ville ${city.name} pourra être utilisée par les référentiels transport.',
      actionLabel: 'Activer',
    );
    if (confirmed != true) return;
    final success = await _controller.activateCity(city.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Ville activée.' : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateCity(AdminCity city) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Désactiver cette ville ?',
      message: 'La ville ${city.name} ne pourra plus être utilisée pour de nouveaux référentiels actifs.',
      actionLabel: 'Désactiver',
      destructive: true,
    );
    if (confirmed != true) return;
    final success = await _controller.deactivateCity(city.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Ville désactivée.' : _controller.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !_controller.isSubmitting,
      builder: (dialogContext) {
        return AlertDialog(
          key: Key(destructive
              ? 'admin-city-deactivate-confirm-dialog'
              : 'admin-city-activate-confirm-dialog'),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              key: Key(destructive
                  ? 'admin-city-deactivate-confirm'
                  : 'admin-city-activate-confirm'),
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
