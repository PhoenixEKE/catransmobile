import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_badges.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminUserDetailDialog({
  required BuildContext context,
  required AdminInternalUserSummary user,
  required Future<AdminInternalUserDetail> Function(String id) loadDetail,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminUserDetailDialog(user: user, loadDetail: loadDetail);
      if (size.width < 640) {
        return Dialog.fullscreen(child: SafeArea(child: content));
      }
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: size.width > 760 ? 720 : size.width - 32,
          height: size.height > 760 ? 680 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminUserDetailDialog extends StatefulWidget {
  final AdminInternalUserSummary user;
  final Future<AdminInternalUserDetail> Function(String id) loadDetail;

  const AdminUserDetailDialog({
    super.key,
    required this.user,
    required this.loadDetail,
  });

  @override
  State<AdminUserDetailDialog> createState() => _AdminUserDetailDialogState();
}

class _AdminUserDetailDialogState extends State<AdminUserDetailDialog> {
  AdminInternalUserDetail? _detail;
  String? _error;
  bool _isLoading = true;

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
      final detail = await widget.loadDetail(widget.user.id);
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
    final detail = _detail;
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(user: detail ?? widget.user),
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

  Widget _buildBody(AdminInternalUserDetail? detail) {
    if (_isLoading) {
      return const StaffLoadingState(message: 'Chargement du détail...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }
    if (detail == null) {
      return StaffErrorState(
        message: 'Détail utilisateur indisponible.',
        onRetry: _load,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Identité',
            rows: [
              _Row('Nom complet',
                  detail.fullName.isEmpty ? '-' : detail.fullName),
              _Row('Email', detail.email.isEmpty ? '-' : detail.email),
              _Row('Téléphone',
                  detail.phoneNumber.isEmpty ? '-' : detail.phoneNumber),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Profil interne',
            rows: [
              _Row('Rôle',
                  detail.roleLabel.isEmpty ? detail.role : detail.roleLabel),
              _Row('Gare', detail.station?.name ?? '-'),
              _Row('Guichet', detail.counter?.label ?? '-'),
              _Row('Statut', detail.isActive ? 'Actif' : 'Inactif'),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Scopes',
            rows: [
              _Row('Autorisations',
                  detail.scopes.isEmpty ? '-' : detail.scopes.join(', ')),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Historique',
            rows: [
              _Row('Créé le', _formatDate(detail.createdAt)),
              _Row('Mis à jour le', _formatDate(detail.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Impossible de charger le détail utilisateur.';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }
}

class _Header extends StatelessWidget {
  final AdminInternalUserSummary user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.manage_accounts, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Utilisateur interne' : user.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(color: Color(0xFF666A76))),
              ],
            ),
          ),
          AdminUserStatusBadge(isActive: user.isActive),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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
