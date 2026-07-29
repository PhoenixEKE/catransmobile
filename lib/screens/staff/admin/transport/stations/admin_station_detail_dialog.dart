import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminStationDetailDialog({required BuildContext context, required AdminStation station, required Future<AdminStation> Function(String id) loadDetail}) {
  return showDialog<void>(context: context, useSafeArea: true, builder: (dialogContext) {
    final size = MediaQuery.sizeOf(dialogContext);
    final content = AdminStationDetailDialog(key: Key('admin-station-details-${station.id}'), station: station, loadDetail: loadDetail);
    if (size.width < 640) return Dialog.fullscreen(child: SafeArea(child: content));
    return Dialog(clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: SizedBox(width: size.width > 760 ? 700 : size.width - 32, height: size.height > 660 ? 600 : size.height * 0.9, child: content));
  });
}

class AdminStationDetailDialog extends StatefulWidget {
  final AdminStation station;
  final Future<AdminStation> Function(String id) loadDetail;

  const AdminStationDetailDialog({super.key, required this.station, required this.loadDetail});

  @override
  State<AdminStationDetailDialog> createState() => _AdminStationDetailDialogState();
}

class _AdminStationDetailDialogState extends State<AdminStationDetailDialog> {
  AdminStation? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final detail = await widget.loadDetail(widget.station.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.station;
    return Material(color: const Color(0xFFF5F6FA), child: Column(children: [_Header(station: detail), Expanded(child: Padding(padding: const EdgeInsets.all(18), child: _buildBody(detail)))]));
  }

  Widget _buildBody(AdminStation detail) {
    if (_isLoading) return const StaffLoadingState(message: 'Chargement de la gare...');
    if (_error != null) return StaffErrorState(message: _error!, onRetry: _load);
    return SingleChildScrollView(child: _Section(title: 'Informations gare', rows: [
      _Row('Nom', _display(detail.name)),
      _Row('Compagnie', _display(detail.company.name)),
      _Row('Ville', _display(detail.cityName)),
      _Row('Code', _display(detail.code)),
      _Row('Téléphone', _display(detail.phoneLine)),
      _Row('Représentant', _display(detail.representative)),
      _Row('Statut', detail.isActive ? 'Actif' : 'Inactif'),
      _Row('Créée le', _formatDate(detail.createdAt)),
      _Row('Mise à jour le', _formatDate(detail.updatedAt)),
    ]));
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return StructuredApiError.fromException(error).userMessage;
    return 'Impossible de charger le détail gare.';
  }
}

class _Header extends StatelessWidget {
  final AdminStation station;
  const _Header({required this.station});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(18), color: Colors.white, child: Row(children: [const Icon(Icons.store_mall_directory, color: Color(0xFF0F056B)), const SizedBox(width: 12), Expanded(child: Text(_display(station.name), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))), AdminTransportStatusBadge(isActive: station.isActive), IconButton(tooltip: 'Fermer', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _Section({required this.title, required this.rows});
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E7EF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, key: const Key('admin-station-detail-title'), style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 10), ...rows.map((row) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: Text(row.label, style: const TextStyle(color: Color(0xFF666A76)))), Expanded(child: Text(row.value))])))]));
  }
}

class _Row { final String label; final String value; const _Row(this.label, this.value); }

String _display(String? value) { final trimmed = value?.trim(); return trimmed == null || trimmed.isEmpty ? '-' : trimmed; }
String _formatDate(String value) { final parsed = DateTime.tryParse(value); if (parsed == null) return _display(value); final local = parsed.toLocal(); return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year.toString().padLeft(4, '0')} à ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}'; }
