import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counter_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counter_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counter_station_selector.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counters_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counters_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counters_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminCountersScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;
  const AdminCountersScreen({super.key, required this.canManage, this.apiService});
  @override
  State<AdminCountersScreen> createState() => _AdminCountersScreenState();
}

class _AdminCountersScreenState extends State<AdminCountersScreen> {
  late final AdminCountersController _controller;
  @override
  void initState() { super.initState(); _controller = AdminCountersController(apiService: widget.apiService); _controller.initialize(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    AdminCounterStationSelector(stations: _controller.stations, selectedStation: _controller.selectedStation, isLoading: _controller.isLoadingStations, onChanged: _controller.selectStation),
    const SizedBox(height: 14),
    AdminCountersToolbar(initialQuery: _controller.query, selectedIsActive: _controller.isActive, ordering: _controller.ordering, canManage: widget.canManage, hasSelectedStation: _controller.selectedStation != null, onSearch: _controller.search, onActiveChanged: _controller.setActiveFilter, onOrderingChanged: _controller.setOrdering, onRefresh: _controller.refresh, onCreate: _openCreateForm),
    const SizedBox(height: 18),
    Expanded(child: SingleChildScrollView(child: _buildContent())),
  ]));

  Widget _buildContent() {
    if (_controller.isLoadingStations && _controller.selectedStation == null) return const StaffLoadingState(message: 'Chargement des gares...');
    if (_controller.selectedStation == null) return const StaffEmptyState(icon: Icons.store_mall_directory, title: 'Sélectionnez une gare', message: 'Choisissez une gare active pour consulter ses guichets.');
    if (_controller.isLoading && _controller.countersPage == null) return const StaffLoadingState(message: 'Chargement des guichets...');
    if (_controller.listError != null) return StaffErrorState(message: _controller.listError!, onRetry: _controller.refresh);
    final page = _controller.countersPage;
    if (page == null || page.results.isEmpty) return const StaffEmptyState(icon: Icons.point_of_sale, title: 'Aucun guichet', message: 'Aucun guichet ne correspond à cette gare ou aux filtres actuels.');
    return Stack(children: [
      AdminCountersList(page: page, canManage: widget.canManage && !_controller.isSubmitting, onPreviousPage: _controller.hasPreviousPage ? () => _controller.previousPage() : null, onNextPage: _controller.hasNextPage ? () => _controller.nextPage() : null, onOpenDetail: _openDetail, onEdit: _openEditForm, onActivate: _activateCounter, onDeactivate: _deactivateCounter),
      if (_controller.isLoading || _controller.isSubmitting) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))),
    ]);
  }

  Future<void> _openDetail(AdminStationCounter counter) async => showAdminCounterDetailDialog(context: context, counter: counter, loadDetail: _controller.getDetail);

  Future<void> _openCreateForm() async {
    if (!widget.canManage || _controller.selectedStation == null) return;
    StructuredApiError? formError;
    AdminStationCounterCreateRequest? draft;
    while (mounted) {
      final result = await showAdminCounterFormDialog(context: context, isSubmitting: _controller.isSubmitting, stationName: _controller.selectedStation!.name, error: formError, initialCreateRequest: draft);
      if (result?.createRequest == null) return;
      draft = result!.createRequest!;
      final success = await _controller.createCounter(draft);
      if (!mounted) return;
      if (success) { _showSnackBar('Guichet créé.'); return; }
      formError = _controller.structuredFormError;
      if (formError == null) { _showSnackBar(_controller.formError ?? 'Création impossible.'); return; }
    }
  }

  Future<void> _openEditForm(AdminStationCounter counter) async {
    if (!widget.canManage || _controller.selectedStation == null) return;
    AdminStationCounter detail;
    try { detail = await _controller.getDetail(counter.id); } catch (_) { if (mounted) _showSnackBar('Impossible de charger le détail guichet.'); return; }
    if (!mounted) return;
    StructuredApiError? formError;
    AdminStationCounterUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminCounterFormDialog(context: context, isSubmitting: _controller.isSubmitting, stationName: _controller.selectedStation!.name, error: formError, initialCounter: detail, initialUpdateRequest: draft);
      if (result?.updateRequest == null) return;
      draft = result!.updateRequest!;
      final success = await _controller.updateCounter(counter.id, draft);
      if (!mounted) return;
      if (success) { _showSnackBar('Guichet mis à jour.'); return; }
      formError = _controller.structuredFormError;
      if (formError == null) { _showSnackBar(_controller.formError ?? 'Modification impossible.'); return; }
    }
  }

  Future<void> _activateCounter(AdminStationCounter counter) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(title: 'Activer ce guichet ?', message: 'Le guichet ${counter.code} pourra être utilisé par la gare.', actionLabel: 'Activer');
    if (confirmed != true) return;
    final success = await _controller.activateCounter(counter.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Guichet activé.' : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateCounter(AdminStationCounter counter) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(title: 'Désactiver ce guichet ?', message: 'Le guichet ${counter.code} ne pourra plus être utilisé pour de nouvelles opérations.', actionLabel: 'Désactiver', destructive: true);
    if (confirmed != true) return;
    final success = await _controller.deactivateCounter(counter.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Guichet désactivé.' : _controller.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction({required String title, required String message, required String actionLabel, bool destructive = false}) => showDialog<bool>(context: context, barrierDismissible: !_controller.isSubmitting, builder: (dialogContext) => AlertDialog(key: Key(destructive ? 'admin-counter-deactivate-confirm-dialog' : 'admin-counter-activate-confirm-dialog'), title: Text(title), content: Text(message), actions: [TextButton(onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, false), child: const Text('Annuler')), ElevatedButton(key: Key(destructive ? 'admin-counter-deactivate-confirm' : 'admin-counter-activate-confirm'), style: destructive ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB42318), foregroundColor: Colors.white) : null, onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, true), child: Text(actionLabel))]));
  void _showSnackBar(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
