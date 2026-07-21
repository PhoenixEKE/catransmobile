import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_departure_status_badge.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seat_action_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seat_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seats_controller.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminDepartureSeatsScreen extends StatefulWidget {
  final AdminDeparture? departure;
  final bool canManage;
  final AdminOperationsApiService? apiService;

  const AdminDepartureSeatsScreen({
    super.key,
    required this.departure,
    required this.canManage,
    this.apiService,
  });

  @override
  State<AdminDepartureSeatsScreen> createState() =>
      _AdminDepartureSeatsScreenState();
}

class _AdminDepartureSeatsScreenState extends State<AdminDepartureSeatsScreen> {
  late final AdminDepartureSeatsController _controller;
  final _seatNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AdminDepartureSeatsController(apiService: widget.apiService);
    final departure = widget.departure;
    if (departure != null) {
      _controller.load(departure);
    }
  }

  @override
  void didUpdateWidget(covariant AdminDepartureSeatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.departure?.id != oldWidget.departure?.id) {
      final departure = widget.departure;
      if (departure != null) _controller.load(departure);
    }
  }

  @override
  void dispose() {
    _seatNumberController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departure = widget.departure;
    if (departure == null) {
      return const StaffEmptyState(
        icon: Icons.event_seat_outlined,
        title: 'Sélectionnez un départ',
        message:
            'Les sièges sont toujours consultés dans le contexte d’un départ.',
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DepartureHeader(departure: departure),
          const SizedBox(height: 12),
          _Toolbar(
            status: _controller.status,
            seatType: _controller.seatType,
            ordering: _controller.ordering,
            seatNumberController: _seatNumberController,
            onStatusChanged: _controller.setStatus,
            onSeatTypeChanged: _controller.setSeatType,
            onOrderingChanged: _controller.setOrdering,
            onSeatNumberSubmitted: _controller.setSeatNumber,
            onRefresh: _controller.loadSeats,
          ),
          const SizedBox(height: 12),
          _Counters(map: _controller.seatMap),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.seatsResponse == null) {
      return const StaffLoadingState(message: 'Chargement des sièges...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
        message: _controller.listError!,
        onRetry: _controller.loadSeats,
      );
    }
    final seats = _controller.seatsResponse?.results ?? const [];
    if (seats.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.event_seat_outlined,
        title: 'Aucun siège',
        message: 'Aucun siège généré ou aucun siège ne correspond aux filtres.',
      );
    }
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return _SeatCards(seats: seats, actions: _actions);
            }
            return _SeatTable(seats: seats, actions: _actions);
          },
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

  _SeatActions get _actions => _SeatActions(
        canManage: widget.canManage && !_controller.isSubmitting,
        onDetail: (seat) => showAdminDepartureSeatDetailDialog(
          context: context,
          seat: seat,
        ),
        onBlock: (seat) => _submitSeatAction(seat, 'block'),
        onUnblock: (seat) => _submitSeatAction(seat, 'unblock'),
      );

  Future<void> _submitSeatAction(AdminDepartureSeat seat, String action) async {
    StructuredApiError? formError;
    while (mounted) {
      final reason = await showAdminDepartureSeatActionDialog(
        context: context,
        seat: seat,
        action: action,
        isSubmitting: _controller.isSubmitting,
        error: formError,
      );
      if (reason == null) return;
      final success = action == 'block'
          ? await _controller.blockSeat(seat, reason)
          : await _controller.unblockSeat(seat, reason);
      if (!mounted) return;
      if (success) {
        _showSnackBar(action == 'block' ? 'Siège bloqué.' : 'Siège débloqué.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Action impossible.');
        return;
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DepartureHeader extends StatelessWidget {
  final AdminDeparture departure;

  const _DepartureHeader({required this.departure});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departure.displaySchedule,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('${departure.displayRoute} · ${departure.displayStation}'),
                Text(departure.displayClass),
              ],
            ),
          ),
          AdminDepartureStatusBadge(
            code: departure.status.code,
            label: departure.status.label,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String? status;
  final String? seatType;
  final String? ordering;
  final TextEditingController seatNumberController;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSeatTypeChanged;
  final ValueChanged<String?> onOrderingChanged;
  final ValueChanged<String?> onSeatNumberSubmitted;
  final VoidCallback onRefresh;

  const _Toolbar({
    required this.status,
    required this.seatType,
    required this.ordering,
    required this.seatNumberController,
    required this.onStatusChanged,
    required this.onSeatTypeChanged,
    required this.onOrderingChanged,
    required this.onSeatNumberSubmitted,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    const statusItems = [
      DropdownMenuItem(value: null, child: _DropdownItemText('Tous')),
      DropdownMenuItem(
          value: 'available', child: _DropdownItemText('Disponible')),
      DropdownMenuItem(value: 'held', child: _DropdownItemText('Hold')),
      DropdownMenuItem(value: 'reserved', child: _DropdownItemText('Réservé')),
      DropdownMenuItem(value: 'blocked', child: _DropdownItemText('Bloqué')),
      DropdownMenuItem(
          value: 'legacy_unknown', child: _DropdownItemText('Legacy')),
    ];
    const seatTypeItems = [
      DropdownMenuItem(value: null, child: _DropdownItemText('Tous')),
      DropdownMenuItem(value: 'standard', child: _DropdownItemText('Standard')),
      DropdownMenuItem(value: 'vip', child: _DropdownItemText('VIP')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileWidth = constraints.maxWidth < 640;

        final statusField = KeyedSubtree(
          key: ValueKey('admin-seats-status-$status'),
          child: DropdownButtonFormField<String?>(
            key: const Key('admin-seats-status-filter'),
            initialValue: status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Statut'),
            items: statusItems,
            onChanged: onStatusChanged,
          ),
        );

        final typeField = KeyedSubtree(
          key: ValueKey('admin-seats-type-$seatType'),
          child: DropdownButtonFormField<String?>(
            key: const Key('admin-seats-type-filter'),
            initialValue: seatType,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type'),
            items: seatTypeItems,
            onChanged: onSeatTypeChanged,
          ),
        );

        final numberField = TextField(
          key: const Key('admin-seats-number-filter'),
          controller: seatNumberController,
          decoration: const InputDecoration(labelText: 'Numéro'),
          keyboardType: TextInputType.number,
          onSubmitted: onSeatNumberSubmitted,
        );

        final orderingField = KeyedSubtree(
          key: ValueKey('admin-seats-ordering-$ordering'),
          child: DropdownButtonFormField<String?>(
            key: const Key('admin-seats-ordering'),
            initialValue: ordering,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tri'),
            items: const [
              DropdownMenuItem(value: null, child: _DropdownItemText('Défaut')),
              DropdownMenuItem(
                  value: 'seat_number', child: _DropdownItemText('Numéro ↑')),
              DropdownMenuItem(
                  value: '-seat_number', child: _DropdownItemText('Numéro ↓')),
              DropdownMenuItem(
                  value: 'status', child: _DropdownItemText('Statut ↑')),
              DropdownMenuItem(
                  value: '-status', child: _DropdownItemText('Statut ↓')),
            ],
            onChanged: onOrderingChanged,
          ),
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              key: const Key('admin-seats-apply-number'),
              onPressed: () => onSeatNumberSubmitted(seatNumberController.text),
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filtrer'),
            ),
            OutlinedButton.icon(
              key: const Key('admin-seats-refresh'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        );

        if (isMobileWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              statusField,
              const SizedBox(height: 10),
              typeField,
              const SizedBox(height: 10),
              numberField,
              const SizedBox(height: 10),
              orderingField,
              const SizedBox(height: 10),
              actionButtons,
            ],
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(width: 200, child: statusField),
            SizedBox(width: 180, child: typeField),
            SizedBox(width: 130, child: numberField),
            SizedBox(width: 170, child: orderingField),
            actionButtons,
          ],
        );
      },
    );
  }
}

class _DropdownItemText extends StatelessWidget {
  final String text;

  const _DropdownItemText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

class _Counters extends StatelessWidget {
  final AdminDepartureSeatMap? map;

  const _Counters({required this.map});

  @override
  Widget build(BuildContext context) {
    final counters = [
      ('Total', map?.total ?? 0),
      ('Disponibles', map?.available ?? 0),
      ('Hold', map?.held ?? 0),
      ('Réservés', map?.reserved ?? 0),
      ('Bloqués', map?.blocked ?? 0),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: counters
          .map((item) => Chip(
                label: Text('${item.$1} : ${item.$2}'),
                backgroundColor: const Color(0xFFF7F8FC),
                side: const BorderSide(color: Color(0xFFE4E7EF)),
              ))
          .toList(),
    );
  }
}

class _SeatActions {
  final bool canManage;
  final ValueChanged<AdminDepartureSeat> onDetail;
  final ValueChanged<AdminDepartureSeat> onBlock;
  final ValueChanged<AdminDepartureSeat> onUnblock;

  const _SeatActions({
    required this.canManage,
    required this.onDetail,
    required this.onBlock,
    required this.onUnblock,
  });
}

class _SeatTable extends StatelessWidget {
  final List<AdminDepartureSeat> seats;
  final _SeatActions actions;

  const _SeatTable({required this.seats, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
          columns: const [
            DataColumn(label: Text('Siège')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Position')),
            DataColumn(label: Text('Actions')),
          ],
          rows: seats
              .map((seat) => DataRow(cells: [
                    DataCell(Text(seat.displayLabel)),
                    DataCell(_SeatStatusBadge(status: seat.status)),
                    DataCell(Text(seat.seatType)),
                    DataCell(Text(
                        '${seat.visual.rowNumber}/${seat.visual.columnNumber}')),
                    DataCell(_SeatActionButtons(seat: seat, actions: actions)),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

class _SeatCards extends StatelessWidget {
  final List<AdminDepartureSeat> seats;
  final _SeatActions actions;

  const _SeatCards({required this.seats, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: seats
          .map((seat) => SizedBox(
                width: 150,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E7EF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seat.displayLabel,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      _SeatStatusBadge(status: seat.status),
                      const SizedBox(height: 6),
                      Text(seat.seatType),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SeatActionButtons(seat: seat, actions: actions),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SeatActionButtons extends StatelessWidget {
  final AdminDepartureSeat seat;
  final _SeatActions actions;

  const _SeatActionButtons({required this.seat, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      children: [
        IconButton(
          key: Key('admin-seat-detail-${seat.id}'),
          tooltip: 'Détail',
          onPressed: () => actions.onDetail(seat),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (actions.canManage && seat.canBlock)
          IconButton(
            key: Key('admin-seat-block-${seat.id}'),
            tooltip: 'Bloquer',
            onPressed: () => actions.onBlock(seat),
            icon: const Icon(Icons.block, color: Color(0xFFB42318)),
          ),
        if (actions.canManage && seat.canUnblock)
          IconButton(
            key: Key('admin-seat-unblock-${seat.id}'),
            tooltip: 'Débloquer',
            onPressed: () => actions.onUnblock(seat),
            icon: const Icon(Icons.check_circle_outline,
                color: Color(0xFF157347)),
          ),
      ],
    );
  }
}

class _SeatStatusBadge extends StatelessWidget {
  final String status;

  const _SeatStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'available' => const Color(0xFF157347),
      'held' => const Color(0xFFB54708),
      'reserved' => const Color(0xFF175CD3),
      'blocked' => const Color(0xFFB42318),
      _ => const Color(0xFF344054),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
