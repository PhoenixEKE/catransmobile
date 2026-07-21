import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_transition_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_controller.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_list.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_toolbar.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminDeparturesScreen extends StatefulWidget {
  final bool canManage;
  final AdminDeparture? selectedDeparture;
  final ValueChanged<AdminDeparture> onDepartureSelected;
  final ValueChanged<AdminDeparture> onOpenSeats;
  final ValueChanged<AdminDeparture> onOpenBoarding;
  final AdminOperationsApiService? apiService;

  const AdminDeparturesScreen({
    super.key,
    required this.canManage,
    required this.selectedDeparture,
    required this.onDepartureSelected,
    required this.onOpenSeats,
    required this.onOpenBoarding,
    this.apiService,
  });

  @override
  State<AdminDeparturesScreen> createState() => _AdminDeparturesScreenState();
}

class _AdminDeparturesScreenState extends State<AdminDeparturesScreen> {
  late final AdminDeparturesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminDeparturesController(apiService: widget.apiService);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminDeparturesToolbar(
            selectedStatus: _controller.selectedStatus,
            ordering: _controller.ordering,
            dateFrom: _controller.dateFrom,
            dateTo: _controller.dateTo,
            canManage: widget.canManage,
            onStatusChanged: _controller.setStatus,
            onOrderingChanged: _controller.setOrdering,
            onDateRangeChanged: (from, to) =>
                _controller.setDateRange(from: from, to: to),
            onRefresh: _controller.refresh,
            onCreate: _openCreateForm,
          ),
          const SizedBox(height: 12),
          _SelectedDepartureBanner(departure: widget.selectedDeparture),
          const SizedBox(height: 14),
          Expanded(child: SingleChildScrollView(child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.departuresPage == null) {
      return const StaffLoadingState(message: 'Chargement des départs...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
        message: _controller.listError!,
        onRetry: _controller.refresh,
      );
    }
    final page = _controller.departuresPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'Aucun départ',
        message: 'Aucun départ ne correspond aux filtres actuels.',
      );
    }
    return Stack(
      children: [
        AdminDeparturesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onOpenSeats: _openSeats,
          onOpenBoarding: _openBoarding,
          onEditDate: _openEditDateForm,
          onTransition: _confirmTransition,
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

  Future<void> _openDetail(AdminDeparture departure) async {
    widget.onDepartureSelected(departure);
    await showAdminDepartureDetailDialog(
      context: context,
      departure: departure,
      loadDetail: _controller.getDetail,
    );
  }

  void _openSeats(AdminDeparture departure) {
    widget.onDepartureSelected(departure);
    widget.onOpenSeats(departure);
  }

  void _openBoarding(AdminDeparture departure) {
    widget.onDepartureSelected(departure);
    widget.onOpenBoarding(departure);
  }

  Future<void> _openCreateForm() async {
    if (!widget.canManage) return;
    await _handleFormLoop(initialDeparture: null);
  }

  Future<void> _openEditDateForm(AdminDeparture departure) async {
    if (!widget.canManage) return;
    await _handleFormLoop(initialDeparture: departure);
  }

  Future<void> _handleFormLoop({AdminDeparture? initialDeparture}) async {
    StructuredApiError? formError;
    while (mounted) {
      final result = await showAdminDepartureFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        templates: _controller.templates,
        error: formError,
        initialDeparture: initialDeparture,
      );
      if (result == null) return;
      final success = result.createRequest != null
          ? await _controller.createDeparture(result.createRequest!)
          : await _controller.updateDepartureDate(
              initialDeparture!.id,
              result.updateRequest!,
            );
      if (!mounted) return;
      if (success) {
        _showSnackBar(
            result.createRequest != null ? 'Départ créé.' : 'Départ déplacé.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Action impossible.');
        return;
      }
    }
  }

  Future<void> _confirmTransition(
    AdminDeparture departure,
    String action,
  ) async {
    if (!widget.canManage) return;
    final confirmed = await showAdminDepartureTransitionDialog(
      context: context,
      departure: departure,
      action: action,
      isSubmitting: _controller.isSubmitting,
    );
    if (confirmed != true) return;
    final success = switch (action) {
      'generate-seats' => await _controller.generateSeats(departure.id),
      'open' => await _controller.openDeparture(departure.id),
      'close' => await _controller.closeDeparture(departure.id),
      'depart' => await _controller.markDeparted(departure.id),
      'cancel' => await _controller.cancelDeparture(departure.id),
      _ => false,
    };
    if (!mounted) return;
    _showSnackBar(success
        ? 'Action effectuée.'
        : _controller.formError ?? 'Action impossible.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedDepartureBanner extends StatelessWidget {
  final AdminDeparture? departure;

  const _SelectedDepartureBanner({required this.departure});

  @override
  Widget build(BuildContext context) {
    if (departure == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Text(
        'Départ sélectionné : ${departure!.displaySchedule} · '
        '${departure!.displayRoute} · ${departure!.displayClass}',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
