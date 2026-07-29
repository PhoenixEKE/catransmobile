import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedule_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedule_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedules_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedules_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedules_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminSchedulesScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;

  const AdminSchedulesScreen({
    super.key,
    required this.canManage,
    this.apiService,
  });

  @override
  State<AdminSchedulesScreen> createState() => _AdminSchedulesScreenState();
}

class _AdminSchedulesScreenState extends State<AdminSchedulesScreen> {
  late final AdminSchedulesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminSchedulesController(apiService: widget.apiService);
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
              AdminSchedulesToolbar(
                  initialQuery: _controller.query,
                  selectedStationId: _controller.stationId,
                  selectedRouteId: _controller.routeId,
                  selectedServiceClassId: _controller.serviceClassId,
                  departureTime: _controller.departureTime,
                  selectedIsActive: _controller.isActive,
                  ordering: _controller.ordering,
                  stations: _controller.stations,
                  routes: _controller.routes,
                  serviceClasses: _controller.serviceClasses,
                  canManage: widget.canManage,
                  onSearch: _controller.search,
                  onStationChanged: _controller.setStationFilter,
                  onRouteChanged: _controller.setRouteFilter,
                  onServiceClassChanged: _controller.setServiceClassFilter,
                  onDepartureTimeChanged: _controller.setDepartureTimeFilter,
                  onActiveChanged: _controller.setActiveFilter,
                  onOrderingChanged: _controller.setOrdering,
                  onRefresh: _controller.refresh,
                  onCreate: _openCreateForm),
              const SizedBox(height: 18),
              if (compact)
                _buildContent()
              else
                Expanded(
                    child: SingleChildScrollView(child: _buildContent())),
            ];
            final column = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children);
            return compact ? SingleChildScrollView(child: column) : column;
          }));

  Widget _buildContent() {
    if (_controller.isLoading && _controller.schedulesPage == null) {
      return const StaffLoadingState(message: 'Chargement des horaires...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
          message: _controller.listError!, onRetry: _controller.refresh);
    }
    final page = _controller.schedulesPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
          icon: Icons.schedule,
          title: 'Aucun horaire',
          message: 'Aucun horaire ne correspond aux filtres actuels.');
    }
    return Stack(children: [
      AdminSchedulesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateSchedule,
          onDeactivate: _deactivateSchedule),
      if (_controller.isLoading || _controller.isSubmitting)
        const Positioned.fill(
            child: IgnorePointer(
                child: ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)))))
    ]);
  }

  Future<void> _openDetail(AdminSchedule schedule) async =>
      showAdminScheduleDetailDialog(
          context: context,
          schedule: schedule,
          loadDetail: _controller.getDetail);

  Future<void> _openCreateForm() async {
    if (!widget.canManage) {
      return;
    }
    StructuredApiError? formError;
    AdminScheduleCreateRequest? draft;
    while (mounted) {
      final result = await showAdminScheduleFormDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          stations: _controller.stations,
          routes: _controller.routes,
          serviceClasses: _controller.serviceClasses,
          error: formError,
          initialCreateRequest: draft);
      if (result?.createRequest == null) {
        return;
      }
      draft = result!.createRequest!;
      final success = await _controller.createSchedule(draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Horaire créé.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminSchedule schedule) async {
    if (!widget.canManage) {
      return;
    }
    AdminSchedule detail;
    try {
      detail = await _controller.getDetail(schedule.id);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Impossible de charger le détail horaire.');
      }
      return;
    }
    if (!mounted) {
      return;
    }
    StructuredApiError? formError;
    AdminScheduleUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminScheduleFormDialog(
          context: context,
          isSubmitting: _controller.isSubmitting,
          stations: _controller.stations,
          routes: _controller.routes,
          serviceClasses: _controller.serviceClasses,
          error: formError,
          initialSchedule: detail,
          initialUpdateRequest: draft);
      if (result?.updateRequest == null) {
        return;
      }
      draft = result!.updateRequest!;
      final success = await _controller.updateSchedule(schedule.id, draft);
      if (!mounted) {
        return;
      }
      if (success) {
        _showSnackBar('Horaire mis à jour.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateSchedule(AdminSchedule schedule) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Activer cet horaire ?',
        message: schedule.displaySummary,
        actionLabel: 'Activer');
    if (confirmed != true) {
      return;
    }
    final success = await _controller.activateSchedule(schedule.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Horaire activé.'
        : _controller.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateSchedule(AdminSchedule schedule) async {
    if (!widget.canManage) {
      return;
    }
    final confirmed = await _confirmAction(
        title: 'Désactiver cet horaire ?',
        message: schedule.displaySummary,
        actionLabel: 'Désactiver',
        destructive: true);
    if (confirmed != true) {
      return;
    }
    final success = await _controller.deactivateSchedule(schedule.id);
    if (!mounted) {
      return;
    }
    _showSnackBar(success
        ? 'Horaire désactivé.'
        : _controller.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) =>
      showDialog<bool>(
          context: context,
          barrierDismissible: !_controller.isSubmitting,
          builder: (dialogContext) => AlertDialog(
                  key: Key(destructive
                      ? 'admin-schedule-deactivate-confirm-dialog'
                      : 'admin-schedule-activate-confirm-dialog'),
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
                            ? 'admin-schedule-deactivate-confirm'
                            : 'admin-schedule-activate-confirm'),
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
