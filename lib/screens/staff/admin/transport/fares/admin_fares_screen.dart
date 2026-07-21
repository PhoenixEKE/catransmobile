import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fare_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fare_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fare_replace_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminFaresScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;
  const AdminFaresScreen({super.key, required this.canManage, this.apiService});
  @override
  State<AdminFaresScreen> createState() => _AdminFaresScreenState();
}

class _AdminFaresScreenState extends State<AdminFaresScreen> {
  late final AdminFaresController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AdminFaresController(apiService: widget.apiService);
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
            AdminFaresToolbar(
                initialQuery: _controller.query,
                selectedRouteId: _controller.routeId,
                selectedServiceClassId: _controller.serviceClassId,
                selectedCurrency: _controller.currency,
                selectedIsActive: _controller.isActive,
                ordering: _controller.ordering,
                routes: _controller.routes,
                serviceClasses: _controller.serviceClasses,
                canManage: widget.canManage,
                onSearch: _controller.search,
                onRouteChanged: _controller.setRouteFilter,
                onServiceClassChanged: _controller.setServiceClassFilter,
                onCurrencyChanged: _controller.setCurrencyFilter,
                onActiveChanged: _controller.setActiveFilter,
                onOrderingChanged: _controller.setOrdering,
                onRefresh: _controller.refresh,
                onCreate: _openCreateForm),
            const SizedBox(height: 18),
            _buildContent(),
          ]));

  Widget _buildContent() {
    if (_controller.isLoading && _controller.faresPage == null) {
      return const StaffLoadingState(message: 'Chargement des tarifs...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
          message: _controller.listError!, onRetry: _controller.refresh);
    }
    final page = _controller.faresPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
          icon: Icons.payments,
          title: 'Aucun tarif',
          message: 'Aucun tarif ne correspond aux filtres actuels.');
    }
    return Stack(children: [
      AdminFaresList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onReplace: _openReplaceDialog,
          onActivate: _activateFare,
          onDeactivate: _deactivateFare),
      if (_controller.isLoading || _controller.isSubmitting)
        const Positioned.fill(
            child: IgnorePointer(
                child: ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))))
    ]);
  }

  Future<void> _openDetail(AdminFare fare) async => showAdminFareDetailDialog(
      context: context, fare: fare, loadDetail: _controller.getDetail);

  Future<void> _openCreateForm() async {
    if (!widget.canManage) {
      return;
    }
    StructuredApiError? formError;
    AdminFareCreateRequest? draft;
    while (mounted) {
      final result = await showAdminFareFormDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          routes: _controller.routes,
          serviceClasses: _controller.serviceClasses,
          error: formError,
          initialCreateRequest: draft);
      if (result?.createRequest == null) {
        return;
      }
      draft = result!.createRequest!;
      final success = await _controller.createFare(draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Tarif créé.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openReplaceDialog(AdminFare fare) async {
    if (!widget.canManage) {
      return;
    }
    StructuredApiError? formError;
    AdminFareReplaceRequest? draft;
    while (mounted) {
      final result = await showAdminFareReplaceDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          fare: fare,
          error: formError,
          initialRequest: draft);
      if (result == null) {
        return;
      }
      draft = result;
      final success = await _controller.replaceFare(fare.id, draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Tarif remplacé.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Remplacement impossible.');
        return;
      }
    }
  }

  Future<void> _activateFare(AdminFare fare) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Activer ce tarif ?',
        message:
            '${fare.route.displayLabel} · ${fare.serviceClass.name} · ${fare.displayAmount}',
        actionLabel: 'Activer');
    if (confirmed != true) {
      return;
    }
    final success = await _controller.activateFare(fare.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Tarif activé.'
        : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateFare(AdminFare fare) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Désactiver ce tarif ?',
        message:
            '${fare.route.displayLabel} · ${fare.serviceClass.name} · ${fare.displayAmount}',
        actionLabel: 'Désactiver',
        destructive: true);
    if (confirmed != true) {
      return;
    }
    final success = await _controller.deactivateFare(fare.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Tarif désactivé.'
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
                      ? 'admin-fare-deactivate-confirm-dialog'
                      : 'admin-fare-activate-confirm-dialog'),
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
                            ? 'admin-fare-deactivate-confirm'
                            : 'admin-fare-activate-confirm'),
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
