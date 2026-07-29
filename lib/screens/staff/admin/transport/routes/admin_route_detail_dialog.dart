import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminRouteDetailDialog({
  required BuildContext context,
  required AdminRoute route,
  required Future<AdminRoute> Function(String id) loadDetail,
}) async {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = _AdminRouteDetailDialog(
        initialRoute: route,
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

class _AdminRouteDetailDialog extends StatefulWidget {
  final AdminRoute initialRoute;
  final Future<AdminRoute> Function(String id) loadDetail;

  const _AdminRouteDetailDialog({
    required this.initialRoute,
    required this.loadDetail,
  });

  @override
  State<_AdminRouteDetailDialog> createState() =>
      _AdminRouteDetailDialogState();
}

class _AdminRouteDetailDialogState extends State<_AdminRouteDetailDialog> {
  AdminRoute? _detail;
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
      final detail = await widget.loadDetail(widget.initialRoute.id);
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
    final detail = _detail ?? widget.initialRoute;
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(route: detail, onClose: () => Navigator.pop(context)),
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

  Widget _buildBody(AdminRoute detail) {
    if (_isLoading) {
      return const StaffLoadingState(message: 'Chargement de la route...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }
    return SingleChildScrollView(
      child: _Section(
        title: 'Informations route',
        rows: [
          _Line('Compagnie', detail.company.name),
          _Line('Gare départ', detail.departureStation.name),
          _Line('Ville départ',
              detail.departureCity?.name ?? detail.departureStation.cityName),
          _Line('Destination', detail.displayDestination),
          _Line('Statut', detail.isActive ? 'Active' : 'Inactive'),
          _Line('Créée le', detail.createdAt),
          _Line('Mise à jour', detail.updatedAt),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Impossible de charger le détail route.';
  }
}

class _Header extends StatelessWidget {
  final AdminRoute route;
  final VoidCallback onClose;

  const _Header({required this.route, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.alt_route, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              route.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          AdminTransportStatusBadge(isActive: route.isActive),
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
              key: const Key('admin-route-detail-title'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
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
