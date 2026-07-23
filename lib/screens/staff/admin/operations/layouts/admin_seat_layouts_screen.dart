import 'package:flutter/material.dart';

import 'package:catrans_app/models/operations/seat_layout_seat.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/layouts/admin_seat_layouts_controller.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminSeatLayoutsScreen extends StatefulWidget {
  final bool canManage;

  const AdminSeatLayoutsScreen({super.key, required this.canManage});

  @override
  State<AdminSeatLayoutsScreen> createState() => _AdminSeatLayoutsScreenState();
}

class _AdminSeatLayoutsScreenState extends State<AdminSeatLayoutsScreen> {
  late final AdminSeatLayoutsController _controller;
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AdminSeatLayoutsController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _queryController.dispose();
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
          _Toolbar(
            queryController: _queryController,
            isActive: _controller.isActive,
            ordering: _controller.ordering,
            onQuerySubmitted: _controller.setQuery,
            onActiveChanged: _controller.setActive,
            onOrderingChanged: _controller.setOrdering,
            onRefresh: _controller.refresh,
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.seatLayoutsPage == null) {
      return const StaffLoadingState(
          message: 'Chargement des plans de sièges...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
        message: _controller.listError!,
        onRetry: _controller.refresh,
      );
    }
    final page = _controller.seatLayoutsPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.view_module_outlined,
        title: 'Aucun plan de sièges',
        message: 'Aucune configuration de sièges ne correspond aux filtres.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1000;
        final listPane = _LayoutList(
          page: page,
          selectedLayoutId: _controller.selectedLayout?.id,
          canManage: widget.canManage,
          // Non-compact: listPane sits in a height-bounded SizedBox (see the
          // Row below), so the card list can safely use Expanded+ListView
          // and keep the pagination bar fixed outside the scroll area.
          // Compact: listPane is placed inside the outer SingleChildScrollView
          // a few lines down, whose height is unbounded — Expanded would
          // throw there, so it keeps rendering as a plain, non-scrolling
          // Column and lets that outer scroll view handle overflow instead.
          boundedHeight: !compact,
          onPreviousPage:
              _controller.hasPreviousPage ? _controller.previousPage : null,
          onNextPage: _controller.hasNextPage ? _controller.nextPage : null,
          onSelect: _controller.selectLayout,
        );
        final detailPane = _LayoutDetail(
          layout: _controller.selectedLayout,
          seatsPage: _controller.seatsPage,
          isLoading: _controller.isLoadingDetail,
          error: _controller.detailError,
          // Same reasoning as listPane's boundedHeight above: non-compact
          // puts this in a height-bounded Expanded, so the seat grid (whose
          // height grows with seat count) can safely scroll in its own
          // Expanded region instead of overflowing past the panel.
          boundedHeight: !compact,
        );

        if (compact) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                listPane,
                const SizedBox(height: 14),
                detailPane,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 380, child: listPane),
            const SizedBox(width: 14),
            Expanded(child: detailPane),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController queryController;
  final bool? isActive;
  final String? ordering;
  final ValueChanged<String?> onQuerySubmitted;
  final ValueChanged<String?> onActiveChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;

  const _Toolbar({
    required this.queryController,
    required this.isActive,
    required this.ordering,
    required this.onQuerySubmitted,
    required this.onActiveChanged,
    required this.onOrderingChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (queryController.text.isEmpty) {
      queryController.text = '';
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: queryController,
            decoration: const InputDecoration(labelText: 'Recherche'),
            onSubmitted: onQuerySubmitted,
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: switch (isActive) {
              true => 'true',
              false => 'false',
              null => null,
            },
            decoration: const InputDecoration(labelText: 'Statut'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: 'true', child: Text('Actifs')),
              DropdownMenuItem(value: 'false', child: Text('Inactifs')),
            ],
            onChanged: onActiveChanged,
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: ordering,
            decoration: const InputDecoration(labelText: 'Tri'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Défaut')),
              DropdownMenuItem(value: 'name', child: Text('Nom ↑')),
              DropdownMenuItem(value: '-name', child: Text('Nom ↓')),
              DropdownMenuItem(value: 'total_seats', child: Text('Capacité ↑')),
              DropdownMenuItem(
                  value: '-total_seats', child: Text('Capacité ↓')),
              DropdownMenuItem(value: 'updated_at', child: Text('MàJ ↑')),
              DropdownMenuItem(value: '-updated_at', child: Text('MàJ ↓')),
            ],
            onChanged: onOrderingChanged,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Rafraîchir'),
        ),
      ],
    );
  }
}

class _LayoutList extends StatelessWidget {
  final PagedResult<AdminOperationRecord> page;
  final String? selectedLayoutId;
  final bool canManage;
  final bool boundedHeight;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminOperationRecord> onSelect;

  const _LayoutList({
    required this.page,
    required this.selectedLayoutId,
    required this.canManage,
    required this.boundedHeight,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaginationBar(
          page: page,
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
        ),
        if (!canManage) ...[
          const SizedBox(height: 8),
          const Text(
            'Lecture seule: la gestion des plans reste limitée aux permissions admin complètes.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ],
      ],
    );

    final title = Text(
      'Plans disponibles',
      style: Theme.of(context).textTheme.titleMedium,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: boundedHeight
          // Height here comes from a bounded ancestor (the SizedBox in
          // _buildContent's non-compact Row): the card list can safely be
          // Expanded+ListView so it scrolls on its own, with the pagination
          // bar kept fixed below instead of being pushed off-screen.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: page.results.length,
                    itemBuilder: (context, index) {
                      final layout = page.results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LayoutCard(
                          layout: layout,
                          selected: layout.id == selectedLayoutId,
                          onTap: () => onSelect(layout),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                footer,
              ],
            )
          // Height here is unbounded (caller places this inside the
          // compact branch's outer SingleChildScrollView): Expanded would
          // throw, so this keeps the original plain, non-scrolling Column
          // and lets that outer scroll view handle any overflow.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 12),
                ...page.results.map((layout) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LayoutCard(
                        layout: layout,
                        selected: layout.id == selectedLayoutId,
                        onTap: () => onSelect(layout),
                      ),
                    )),
                const SizedBox(height: 8),
                footer,
              ],
            ),
    );
  }
}

class _LayoutCard extends StatelessWidget {
  final AdminOperationRecord layout;
  final bool selected;
  final VoidCallback onTap;

  const _LayoutCard({
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeSeatCount = _readInt(layout.raw['active_seat_count']) ?? 0;
    final totalSeats = _readInt(layout.raw['total_seats']) ?? 0;
    final locked = _readBool(layout.raw['structure_locked']) ?? false;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4F1FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF0F056B) : const Color(0xFFE4E7EF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    layout.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusBadge(
                  label: layout.isActive ? 'Actif' : 'Inactif',
                  color: layout.isActive
                      ? const Color(0xFF027A48)
                      : const Color(0xFF667085),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                '${layout.code ?? 'Plan'} · ${layout.statusLabel ?? 'Plan de sièges'}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'Sièges actifs', value: '$activeSeatCount'),
                _MetricChip(label: 'Capacité', value: '$totalSeats'),
                _MetricChip(label: 'Verrouillé', value: locked ? 'Oui' : 'Non'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutDetail extends StatelessWidget {
  final AdminOperationRecord? layout;
  final PagedResult<SeatLayoutSeat>? seatsPage;
  final bool isLoading;
  final String? error;
  final bool boundedHeight;

  const _LayoutDetail({
    required this.layout,
    required this.seatsPage,
    required this.isLoading,
    required this.error,
    required this.boundedHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: layout == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Sélectionnez un plan pour voir le détail.'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layout!.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(layout!.raw['description']?.toString() ??
                              'Aucune description.'),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: layout!.isActive ? 'Actif' : 'Inactif',
                      color: layout!.isActive
                          ? const Color(0xFF027A48)
                          : const Color(0xFF667085),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading) const LinearProgressIndicator(minHeight: 2),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
                      style: const TextStyle(color: Color(0xFFB42318))),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      label: 'Total',
                      value: '${_readInt(layout!.raw['total_seats']) ?? 0}',
                    ),
                    _MetricChip(
                      label: 'Sièges actifs',
                      value:
                          '${_readInt(layout!.raw['active_seat_count']) ?? 0}',
                    ),
                    _MetricChip(
                      label: 'Structure verrouillée',
                      value: _readBool(layout!.raw['structure_locked']) == true
                          ? 'Oui'
                          : 'Non',
                    ),
                    _MetricChip(
                      label: 'Créé le',
                      value: layout!.raw['created_at']?.toString() ?? '-',
                    ),
                    _MetricChip(
                      label: 'Mis à jour',
                      value: layout!.raw['updated_at']?.toString() ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Plan de sièges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                // Only render the grid (and its own "aucun siège" fallback)
                // once loading has finished without error - otherwise a
                // failed fetch renders as an empty-looking plan instead of
                // surfacing as the error message shown above.
                if (!isLoading && error == null)
                  if (boundedHeight)
                    // Non-compact: this Column sits in a height-bounded
                    // Expanded (see admin_seat_layouts_screen's LayoutBuilder),
                    // so a layout with many seats can overflow past the panel
                    // instead of just growing it. Give the grid its own
                    // Expanded + scroll region instead, keeping the header/
                    // metadata above always visible.
                    Expanded(
                      child: SingleChildScrollView(
                        child: _SeatPlanGrid(
                          seats: seatsPage?.results ?? const [],
                        ),
                      ),
                    )
                  else
                    // Compact: sits inside the outer SingleChildScrollView,
                    // whose height is unbounded - Expanded would throw, so
                    // let that outer scroll view handle the grid's height.
                    _SeatPlanGrid(seats: seatsPage?.results ?? const []),
              ],
            ),
    );
  }
}

class _SeatPlanGrid extends StatelessWidget {
  final List<SeatLayoutSeat> seats;

  const _SeatPlanGrid({required this.seats});

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Aucun siège n’est rattaché à ce plan.'),
      );
    }
    final maxRow = seats.fold<int>(
        1,
        (maxValue, seat) =>
            seat.rowNumber > maxValue ? seat.rowNumber : maxValue);
    final maxColumn = seats.fold<int>(
        1,
        (maxValue, seat) =>
            seat.columnNumber > maxValue ? seat.columnNumber : maxValue);
    final index = <String, SeatLayoutSeat>{
      for (final seat in seats) '${seat.rowNumber}:${seat.columnNumber}': seat,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(88),
        border: TableBorder.all(color: const Color(0xFFE4E7EF)),
        children: List.generate(maxRow, (rowIndex) {
          final rowNumber = rowIndex + 1;
          return TableRow(
            children: List.generate(maxColumn, (columnIndex) {
              final columnNumber = columnIndex + 1;
              final seat = index['$rowNumber:$columnNumber'];
              return Container(
                height: 72,
                padding: const EdgeInsets.all(8),
                color: _seatColor(seat),
                child: seat == null
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (seat.displayLabel ?? '').isNotEmpty
                                ? seat.displayLabel!
                                : seat.seatNumber.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            seat.seatType.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
              );
            }),
          );
        }),
      ),
    );
  }

  Color _seatColor(SeatLayoutSeat? seat) {
    if (seat == null) return const Color(0xFFF9FAFB);
    if (!seat.isActive) return const Color(0xFFF2F4F7);
    switch (seat.seatType) {
      case SeatType.vip:
        return const Color(0xFFFFF4CC);
      case SeatType.driver:
      case SeatType.door:
      case SeatType.empty:
        return const Color(0xFFF2F4F7);
      default:
        return seat.isSelectable
            ? const Color(0xFFE6F4EA)
            : const Color(0xFFFDEADB);
    }
  }
}

class _PaginationBar extends StatelessWidget {
  final PagedResult<AdminOperationRecord> page;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const _PaginationBar({
    required this.page,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    // Tight, no-minimum-tap-target style: the default Material TextButton
    // padding/minWidth was reserving more horizontal space than the visible
    // "Précédent"/"Suivant" labels need, squeezing the count text into an
    // ellipsis even when the row had visible room left.
    const navButtonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      minimumSize: WidgetStatePropertyAll(Size(0, 0)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '${page.results.length} plan(s) affiché(s) · ${page.count} au total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            TextButton(
              style: navButtonStyle,
              onPressed: onPreviousPage,
              child: const Text('Précédent'),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: navButtonStyle,
              onPressed: onNextPage,
              child: const Text('Suivant'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return null;
}
