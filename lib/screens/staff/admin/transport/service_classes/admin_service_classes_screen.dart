import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_class_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_class_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminServiceClassesScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;

  const AdminServiceClassesScreen({
    super.key,
    required this.canManage,
    this.apiService,
  });

  @override
  State<AdminServiceClassesScreen> createState() =>
      _AdminServiceClassesScreenState();
}

class _AdminServiceClassesScreenState extends State<AdminServiceClassesScreen> {
  late final AdminServiceClassesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminServiceClassesController(apiService: widget.apiService);
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
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;
            final children = [
              AdminServiceClassesToolbar(
                initialQuery: _controller.query,
                selectedIsActive: _controller.isActive,
                selectedAllowsSeatSelection: _controller.allowsSeatSelection,
                ordering: _controller.ordering,
                canManage: widget.canManage,
                onSearch: _controller.search,
                onActiveChanged: _controller.setActiveFilter,
                onSeatSelectionChanged: _controller.setSeatSelectionFilter,
                onOrderingChanged: _controller.setOrdering,
                onRefresh: _controller.refresh,
                onCreate: _openCreateForm,
              ),
              const SizedBox(height: 18),
              if (compact)
                _buildContent()
              else
                Expanded(child: SingleChildScrollView(child: _buildContent())),
            ];
            final column = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
            return compact ? SingleChildScrollView(child: column) : column;
          }));

  Widget _buildContent() {
    if (_controller.isLoading && _controller.serviceClassesPage == null) {
      return const StaffLoadingState(message: 'Chargement des classes...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
          message: _controller.listError!, onRetry: _controller.refresh);
    }
    final page = _controller.serviceClassesPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.airline_seat_recline_extra,
        title: 'Aucune classe de service',
        message: 'Aucune classe ne correspond aux filtres actuels.',
      );
    }
    return Stack(
      children: [
        AdminServiceClassesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateServiceClass,
          onDeactivate: _deactivateServiceClass,
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

  Future<void> _openDetail(AdminServiceClass serviceClass) async {
    await showAdminServiceClassDetailDialog(
      context: context,
      serviceClass: serviceClass,
      loadDetail: _controller.getDetail,
    );
  }

  Future<void> _openCreateForm() async {
    if (!widget.canManage) return;
    StructuredApiError? formError;
    AdminServiceClassCreateRequest? draft;
    while (mounted) {
      final result = await showAdminServiceClassFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialCreateRequest: draft,
      );
      if (result?.createRequest == null) return;
      draft = result!.createRequest!;
      final success = await _controller.createServiceClass(draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Classe créée.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminServiceClass serviceClass) async {
    if (!widget.canManage) return;
    AdminServiceClass detail;
    try {
      detail = await _controller.getDetail(serviceClass.id);
    } catch (_) {
      if (mounted) _showSnackBar('Impossible de charger le détail classe.');
      return;
    }
    if (!mounted) return;

    StructuredApiError? formError;
    AdminServiceClassUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminServiceClassFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialServiceClass: detail,
        initialUpdateRequest: draft,
      );
      if (result?.updateRequest == null) return;
      draft = result!.updateRequest!;
      final success =
          await _controller.updateServiceClass(serviceClass.id, draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Classe mise à jour.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateServiceClass(AdminServiceClass serviceClass) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Activer cette classe ?',
      message:
          'La classe ${serviceClass.name} pourra être utilisée par les référentiels transport.',
      actionLabel: 'Activer',
    );
    if (confirmed != true) return;
    final success = await _controller.activateServiceClass(serviceClass.id);
    if (!mounted) return;
    _showSnackBar(success
        ? 'Classe activée.'
        : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateServiceClass(AdminServiceClass serviceClass) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Désactiver cette classe ?',
      message:
          'La classe ${serviceClass.name} ne pourra plus être utilisée pour de nouveaux référentiels actifs.',
      actionLabel: 'Désactiver',
      destructive: true,
    );
    if (confirmed != true) return;
    final success = await _controller.deactivateServiceClass(serviceClass.id);
    if (!mounted) return;
    _showSnackBar(success
        ? 'Classe désactivée.'
        : _controller.formError ?? 'Désactivation impossible.');
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
              ? 'admin-service-class-deactivate-confirm-dialog'
              : 'admin-service-class-activate-confirm-dialog'),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: _controller.isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              key: Key(destructive
                  ? 'admin-service-class-deactivate-confirm'
                  : 'admin-service-class-activate-confirm'),
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: _controller.isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
