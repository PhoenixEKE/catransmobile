import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminCompanyDetailDialog({
  required BuildContext context,
  required AdminCompany company,
  required Future<AdminCompany> Function(String id) loadDetail,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminCompanyDetailDialog(
        key: Key('admin-company-details-${company.id}'),
        company: company,
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
          height: size.height > 620 ? 560 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminCompanyDetailDialog extends StatefulWidget {
  final AdminCompany company;
  final Future<AdminCompany> Function(String id) loadDetail;

  const AdminCompanyDetailDialog({
    super.key,
    required this.company,
    required this.loadDetail,
  });

  @override
  State<AdminCompanyDetailDialog> createState() =>
      _AdminCompanyDetailDialogState();
}

class _AdminCompanyDetailDialogState extends State<AdminCompanyDetailDialog> {
  AdminCompany? _detail;
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
      final detail = await widget.loadDetail(widget.company.id);
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
    final detail = _detail ?? widget.company;
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(company: detail),
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

  Widget _buildBody(AdminCompany detail) {
    if (_isLoading) {
      return const StaffLoadingState(message: 'Chargement de la compagnie...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }

    return SingleChildScrollView(
      child: _Section(
        title: 'Informations compagnie',
        rows: [
          _Row('Nom', _display(detail.name)),
          _Row('Code', _display(detail.code)),
          _Row('Téléphone service client',
              _display(detail.customerServicePhone)),
          _Row('Statut', detail.isActive ? 'Actif' : 'Inactif'),
          _Row('Créée le', _formatDate(detail.createdAt)),
          _Row('Mise à jour le', _formatDate(detail.updatedAt)),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Impossible de charger le détail compagnie.';
  }
}

class _Header extends StatelessWidget {
  final AdminCompany company;

  const _Header({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.business, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              company.name.isEmpty ? 'Compagnie' : company.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          AdminTransportStatusBadge(isActive: company.isActive),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;

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
          Text(
            title,
            key: const Key('admin-company-detail-title'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        row.label,
                        style: const TextStyle(color: Color(0xFF666A76)),
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;

  const _Row(this.label, this.value);
}

String _display(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '-';
  return trimmed;
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return _display(value);
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year à $hour:$minute';
}
