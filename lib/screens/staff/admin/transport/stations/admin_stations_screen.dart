import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_station_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_station_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_stations_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_stations_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_stations_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminStationsScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;
  const AdminStationsScreen({super.key, required this.canManage, this.apiService});
  @override
  State<AdminStationsScreen> createState() => _AdminStationsScreenState();
}

class _AdminStationsScreenState extends State<AdminStationsScreen> {
  late final AdminStationsController _controller;
  @override
  void initState() { super.initState(); _controller = AdminStationsController(apiService: widget.apiService); _controller.initialize(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    AdminStationsToolbar(initialQuery: _controller.query, selectedCompanyId: _controller.companyId, selectedCityId: _controller.cityId, selectedIsActive: _controller.isActive, ordering: _controller.ordering, companies: _controller.companies, cities: _controller.cities, canManage: widget.canManage, onSearch: _controller.search, onCompanyChanged: _controller.setCompanyFilter, onCityChanged: _controller.setCityFilter, onActiveChanged: _controller.setActiveFilter, onOrderingChanged: _controller.setOrdering, onRefresh: _controller.refresh, onCreate: _openCreateForm),
    const SizedBox(height: 18),
    _buildContent(),
  ]));

  Widget _buildContent() {
    if (_controller.isLoading && _controller.stationsPage == null) return const StaffLoadingState(message: 'Chargement des gares...');
    if (_controller.listError != null) return StaffErrorState(message: _controller.listError!, onRetry: _controller.refresh);
    final page = _controller.stationsPage;
    if (page == null || page.results.isEmpty) return const StaffEmptyState(icon: Icons.store_mall_directory, title: 'Aucune gare', message: 'Aucune gare ne correspond aux filtres actuels.');
    return Stack(children: [
      AdminStationsList(page: page, canManage: widget.canManage && !_controller.isSubmitting, onPreviousPage: _controller.hasPreviousPage ? () => _controller.previousPage() : null, onNextPage: _controller.hasNextPage ? () => _controller.nextPage() : null, onOpenDetail: _openDetail, onEdit: _openEditForm, onActivate: _activateStation, onDeactivate: _deactivateStation),
      if (_controller.isLoading || _controller.isSubmitting) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator(strokeWidth: 2))))),
    ]);
  }

  Future<void> _openDetail(AdminStation station) async => showAdminStationDetailDialog(context: context, station: station, loadDetail: _controller.getDetail);

  Future<void> _openCreateForm() async {
    if (!widget.canManage) return;
    StructuredApiError? formError;
    AdminStationCreateRequest? draft;
    while (mounted) {
      final result = await showAdminStationFormDialog(context: context, isSubmitting: _controller.isSubmitting, companies: _controller.companies, cities: _controller.cities, error: formError, initialCreateRequest: draft);
      if (result?.createRequest == null) return;
      draft = result!.createRequest!;
      final success = await _controller.createStation(draft);
      if (!mounted) return;
      if (success) { _showSnackBar('Gare créée.'); return; }
      formError = _controller.structuredFormError;
      if (formError == null) { _showSnackBar(_controller.formError ?? 'Création impossible.'); return; }
    }
  }

  Future<void> _openEditForm(AdminStation station) async {
    if (!widget.canManage) return;
    AdminStation detail;
    try { detail = await _controller.getDetail(station.id); } catch (_) { if (mounted) _showSnackBar('Impossible de charger le détail gare.'); return; }
    if (!mounted) return;
    StructuredApiError? formError;
    AdminStationUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminStationFormDialog(context: context, isSubmitting: _controller.isSubmitting, companies: _controller.companies, cities: _controller.cities, error: formError, initialStation: detail, initialUpdateRequest: draft);
      if (result?.updateRequest == null) return;
      draft = result!.updateRequest!;
      final success = await _controller.updateStation(station.id, draft);
      if (!mounted) return;
      if (success) { _showSnackBar('Gare mise à jour.'); return; }
      formError = _controller.structuredFormError;
      if (formError == null) { _showSnackBar(_controller.formError ?? 'Modification impossible.'); return; }
    }
  }

  Future<void> _activateStation(AdminStation station) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(title: 'Activer cette gare ?', message: 'La gare ${station.name} pourra être utilisée par les référentiels transport.', actionLabel: 'Activer');
    if (confirmed != true) return;
    final success = await _controller.activateStation(station.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Gare activée.' : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateStation(AdminStation station) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(title: 'Désactiver cette gare ?', message: 'La gare ${station.name} ne pourra plus être utilisée pour de nouveaux référentiels actifs.', actionLabel: 'Désactiver', destructive: true);
    if (confirmed != true) return;
    final success = await _controller.deactivateStation(station.id);
    if (!mounted) return;
    _showSnackBar(success ? 'Gare désactivée.' : _controller.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction({required String title, required String message, required String actionLabel, bool destructive = false}) => showDialog<bool>(context: context, barrierDismissible: !_controller.isSubmitting, builder: (dialogContext) => AlertDialog(key: Key(destructive ? 'admin-station-deactivate-confirm-dialog' : 'admin-station-activate-confirm-dialog'), title: Text(title), content: Text(message), actions: [TextButton(onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, false), child: const Text('Annuler')), ElevatedButton(key: Key(destructive ? 'admin-station-deactivate-confirm' : 'admin-station-activate-confirm'), style: destructive ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB42318), foregroundColor: Colors.white) : null, onPressed: _controller.isSubmitting ? null : () => Navigator.pop(dialogContext, true), child: Text(actionLabel))]));
  void _showSnackBar(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
