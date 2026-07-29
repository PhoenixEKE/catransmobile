import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminFareDetailDialog({
  required BuildContext context,
  required AdminFare fare,
  required Future<AdminFare> Function(String id) loadDetail,
}) async {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = _AdminFareDetailDialog(
        initialFare: fare,
        loadDetail: loadDetail,
      );
      if (size.width < 640) {
        return Dialog.fullscreen(child: SafeArea(child: content));
      }
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: size.width > 720 ? 680 : size.width - 32,
          height: size.height > 640 ? 590 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class _AdminFareDetailDialog extends StatefulWidget {
  final AdminFare initialFare;
  final Future<AdminFare> Function(String id) loadDetail;

  const _AdminFareDetailDialog({
    required this.initialFare,
    required this.loadDetail,
  });

  @override
  State<_AdminFareDetailDialog> createState() => _AdminFareDetailDialogState();
}

class _AdminFareDetailDialogState extends State<_AdminFareDetailDialog> {
  AdminFare? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await widget.loadDetail(widget.initialFare.id);
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
    final detail = _detail ?? widget.initialFare;
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(fare: detail, onClose: () => Navigator.pop(context)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _buildBody(detail),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdminFare detail) {
    if (_isLoading) {
      return const StaffLoadingState(message: 'Chargement du tarif...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }
    return SingleChildScrollView(
      child: _Section(
        title: 'Informations tarif',
        rows: [
          _Line('Route', detail.route.displayLabel),
          _Line('Classe', detail.serviceClass.name),
          _Line('Montant', detail.displayAmount),
          _Line('Statut', detail.isActive ? 'Actif' : 'Inactif'),
          _Line('Créé le', detail.createdAt),
          _Line('Mis à jour', detail.updatedAt),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Impossible de charger le détail tarif.';
  }
}

class _Header extends StatelessWidget {
  final AdminFare fare;
  final VoidCallback onClose;

  const _Header({required this.fare, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.payments, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fare.route.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          AdminTransportStatusBadge(isActive: fare.isActive),
          IconButton(
            tooltip: 'Fermer',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Line> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              key: const Key('admin-fare-detail-title'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(row.label,
                          style: const TextStyle(color: Color(0xFF666A76))),
                    ),
                    Expanded(child: Text(_display(row.value))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Line {
  final String label;
  final String value;

  const _Line(this.label, this.value);
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
