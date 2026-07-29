import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/station_reservation_list.dart';
import 'package:catrans_app/models/station/station_ticket_summary.dart';
import 'package:catrans_app/screens/staff/counter/counter_permissions.dart';
import 'package:catrans_app/screens/staff/counter/counter_sales_screen.dart';
import 'package:catrans_app/screens/staff/counter/station_reservation_detail_dialog.dart';
import 'package:catrans_app/services/api/station_counter_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

class CounterSearchScreen extends StatefulWidget {
  final bool supervisionMode;
  final String? stationId;
  final StationCounterApiService? apiService;

  const CounterSearchScreen({
    super.key,
    this.supervisionMode = false,
    this.stationId,
    this.apiService,
  });

  @override
  State<CounterSearchScreen> createState() => _CounterSearchScreenState();
}

class _CounterSearchScreenState extends State<CounterSearchScreen> {
  static const int _pageSize = 20;

  final _searchController = TextEditingController();
  late final StationCounterApiService _apiService;

  StationReservationListResponse? _listResponse;
  String? _listError;
  String? _reservationStatus;
  String? _paymentStatus;
  String? _ticketStatus;
  String? _serviceClass;
  DateTime? _departureDate;
  int _page = 1;
  bool _isLoadingList = false;
  bool _isLoadingPrint = false;
  bool _isOpeningPdf = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? StationCounterApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReservations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null || !_canAccessCounter(user)) {
      return _AccessDeniedContent(user: user);
    }

    final canSellCash = _canSellCash(user);
    if (!canSellCash) {
      return _buildSearchPane(user);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            color: Colors.white,
            child: TabBar(
              tabs: [
                Tab(text: 'Recherche'),
                Tab(text: 'Vente cash'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSearchPane(user),
                CounterSalesScreen(
                  user: user,
                  stationId: widget.stationId,
                  counterApiService: _apiService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPane(User user) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Header(supervisionMode: widget.supervisionMode, user: user),
        const SizedBox(height: 18),
        _FilterPanel(
          controller: _searchController,
          isLoading: _isLoadingList,
          errorMessage: _listError,
          reservationStatus: _reservationStatus,
          paymentStatus: _paymentStatus,
          ticketStatus: _ticketStatus,
          serviceClass: _serviceClass,
          departureDate: _departureDate,
          onReservationStatusChanged: (value) {
            setState(() => _reservationStatus = value);
          },
          onPaymentStatusChanged: (value) {
            setState(() => _paymentStatus = value);
          },
          onTicketStatusChanged: (value) {
            setState(() => _ticketStatus = value);
          },
          onServiceClassChanged: (value) {
            setState(() => _serviceClass = value);
          },
          onPickDate: _pickDepartureDate,
          onClearDate: () => setState(() => _departureDate = null),
          onSearch: () => _loadReservations(page: 1),
          onReset: _resetFilters,
        ),
        const SizedBox(height: 18),
        _buildReservations(user),
      ],
    );
  }

  bool _canAccessCounter(User user) {
    final scopes = user.scopes.toSet();
    return scopes.contains('station.reservations.search') ||
        user.isSuperuser ||
        scopes.contains('station.all.read') ||
        scopes.contains('station.reservations.read') ||
        scopes.contains('station.tickets.print') ||
        scopes.contains('station.tickets.read');
  }

  bool _canSellCash(User user) {
    return user.isSuperuser || hasCounterSalesCashScope(user.scopes);
  }

  bool _canPrint(User user) {
    return hasCounterTicketPrintScope(user.scopes);
  }

  bool _canEditReservationItems(User user) {
    return user.isSuperuser || user.scopes.contains('station.reports.manage');
  }

  Future<void> _loadReservations({int? page}) async {
    FocusScope.of(context).unfocus();
    final nextPage = page ?? _page;
    setState(() {
      _page = nextPage;
      _isLoadingList = true;
      _listError = null;
    });

    try {
      final response = await _apiService.listReservations(
        query: _searchController.text,
        status: _reservationStatus,
        paymentStatus: _paymentStatus,
        ticketStatus: _ticketStatus,
        dateFrom: _formatApiDate(_departureDate),
        dateTo: _formatApiDate(_departureDate),
        serviceClass: _serviceClass,
        stationId: widget.stationId,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() => _listResponse = response);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listResponse = null;
        _listError = _messageFromError(error);
      });
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _openReservationDetail(
    StationReservationListItem reservation,
    User user,
  ) async {
    await showStationReservationDetailDialog(
      context: context,
      reservation: reservation,
      loadDetail: (reservationId) =>
          _apiService.getReservationDetail(reservationId: reservationId),
      editItem: ({
        required reservationId,
        required itemId,
        travelerLastname,
        travelerFirstname,
        travelerPhone,
        newDepartureId,
        newDepartureSeatId,
        notes,
      }) =>
          _apiService.editReservationItem(
        reservationId: reservationId,
        itemId: itemId,
        travelerLastname: travelerLastname,
        travelerFirstname: travelerFirstname,
        travelerPhone: travelerPhone,
        newDepartureId: newDepartureId,
        newDepartureSeatId: newDepartureSeatId,
        stationId: widget.stationId,
        notes: notes,
      ),
      suspendTicket: ({
        required reservationId,
        required itemId,
        required suspendedUntil,
        notes,
      }) =>
          _apiService.suspendReservationItemTicket(
        reservationId: reservationId,
        itemId: itemId,
        suspendedUntil: suspendedUntil,
        stationId: widget.stationId,
        notes: notes,
      ),
      reactivateTicket: ({
        required reservationId,
        required itemId,
      }) =>
          _apiService.reactivateReservationItemTicket(
        reservationId: reservationId,
        itemId: itemId,
        stationId: widget.stationId,
      ),
      canEditItems: _canEditReservationItems(user),
      stationId: widget.stationId,
      canPrint: canPrintCounterTicket(
        hasPrintScope: _canPrint(user),
        backendAllowsPrint: reservation.actions.canPrintTicket,
      ),
      onPrint: _showPrintInfo,
      onPdf: _openPdf,
    );
    if (mounted) {
      await _loadReservations();
    }
  }

  Future<void> _showPrintInfo(String ticketId) async {
    setState(() => _isLoadingPrint = true);

    try {
      final printInfo = await _apiService.getTicketPrintInfo(
        ticketId: ticketId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _TicketPrintDialog(printInfo: printInfo),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoadingPrint = false);
    }
  }

  Future<void> _openPdf(String ticketId) async {
    setState(() => _isOpeningPdf = true);

    try {
      final bytes = await _apiService.downloadTicketPdfBytes(
        ticketId: ticketId,
      );
      await Printing.layoutPdf(
        name: 'ticket-$ticketId.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _isOpeningPdf = false);
    }
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _departureDate ?? now,
    );

    if (selected != null && mounted) {
      setState(() => _departureDate = selected);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _reservationStatus = null;
      _paymentStatus = null;
      _ticketStatus = null;
      _serviceClass = null;
      _departureDate = null;
    });
    _loadReservations(page: 1);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return error.message;
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  Widget _buildReservations(User user) {
    if (_isLoadingList && _listResponse == null) {
      return const _LoadingPanel(message: 'Chargement des réservations...');
    }

    if (_listError != null && _listResponse == null) {
      return _StatePanel(
        icon: Icons.error_outline,
        title: 'Réservations indisponibles',
        message: _listError!,
        actionLabel: 'Réessayer',
        onAction: () => _loadReservations(),
      );
    }

    final response = _listResponse;
    if (response == null) {
      return const _StatePanel(
        icon: Icons.table_rows,
        title: 'Réservations',
        message: 'Les réservations de la gare apparaîtront ici.',
      );
    }

    if (response.isEmpty) {
      return _StatePanel(
        icon: Icons.inbox_outlined,
        title: 'Aucune réservation',
        message: 'Aucune réservation ne correspond aux filtres sélectionnés.',
        actionLabel: 'Réinitialiser',
        onAction: _resetFilters,
      );
    }

    return _ReservationTablePanel(
      response: response,
      page: _page,
      isRefreshing: _isLoadingList,
      canPrint: _canPrint(user),
      isLoadingPrint: _isLoadingPrint,
      isOpeningPdf: _isOpeningPdf,
      onOpenDetail: (reservation) => _openReservationDetail(reservation, user),
      onPrint: _showPrintInfo,
      onPdf: _openPdf,
      onPrevious: response.hasPrevious
          ? () => _loadReservations(page: _page > 1 ? _page - 1 : 1)
          : null,
      onNext:
          response.hasNext ? () => _loadReservations(page: _page + 1) : null,
    );
  }
}

class _Header extends StatelessWidget {
  final bool supervisionMode;
  final User user;

  const _Header({required this.supervisionMode, required this.user});

  @override
  Widget build(BuildContext context) {
    final station = user.internalProfile?.station?.name;
    const title = 'Réservations';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          title,
          style: TextStyle(
            color: Color(0xFF0F056B),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          station == null
              ? 'Liste des réservations liées à votre gare.'
              : 'Gare $station - liste des réservations liées à votre gare.',
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String? errorMessage;
  final String? reservationStatus;
  final String? paymentStatus;
  final String? ticketStatus;
  final String? serviceClass;
  final DateTime? departureDate;
  final ValueChanged<String?> onReservationStatusChanged;
  final ValueChanged<String?> onPaymentStatusChanged;
  final ValueChanged<String?> onTicketStatusChanged;
  final ValueChanged<String?> onServiceClassChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  const _FilterPanel({
    required this.controller,
    required this.isLoading,
    required this.errorMessage,
    required this.reservationStatus,
    required this.paymentStatus,
    required this.ticketStatus,
    required this.serviceClass,
    required this.departureDate,
    required this.onReservationStatusChanged,
    required this.onPaymentStatusChanged,
    required this.onTicketStatusChanged,
    required this.onServiceClassChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onSearch,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Filtres',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            enabled: !isLoading,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => isLoading ? null : onSearch(),
            decoration: const InputDecoration(
              hintText: 'Référence, téléphone, nom ou ticket...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterDropdown(
                width: 190,
                label: 'Statut réservation',
                value: reservationStatus,
                items: const {
                  'pending_payment': 'En attente paiement',
                  'confirmed': 'Confirmée',
                  'cancelled': 'Annulée',
                  'expired': 'Expirée',
                },
                onChanged: isLoading ? null : onReservationStatusChanged,
              ),
              _FilterDropdown(
                width: 170,
                label: 'Paiement',
                value: paymentStatus,
                items: const {
                  'pending': 'En attente',
                  'processing': 'En traitement',
                  'success': 'Payé',
                  'failed': 'Échoué',
                  'cancelled': 'Annulé',
                  'expired': 'Expiré',
                },
                onChanged: isLoading ? null : onPaymentStatusChanged,
              ),
              _FilterDropdown(
                width: 150,
                label: 'Ticket',
                value: ticketStatus,
                items: const {
                  'issued': 'Émis',
                  'used': 'Utilisé',
                  'cancelled': 'Annulé',
                },
                onChanged: isLoading ? null : onTicketStatusChanged,
              ),
              _FilterDropdown(
                width: 150,
                label: 'Classe',
                value: serviceClass,
                items: const {'ECONOMIE': 'Économie', 'PRESTIGE': 'Prestige'},
                onChanged: isLoading ? null : onServiceClassChanged,
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onPickDate,
                icon: const Icon(Icons.event),
                label: Text(
                  departureDate == null
                      ? 'Date départ'
                      : _formatDate(departureDate),
                ),
              ),
              if (departureDate != null)
                IconButton(
                  onPressed: isLoading ? null : onClearDate,
                  tooltip: 'Effacer la date',
                  icon: const Icon(Icons.close),
                ),
              FilledButton.icon(
                onPressed: isLoading ? null : onSearch,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Rechercher'),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final double width;
  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?>? onChanged;

  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Tous')),
          ...items.entries.map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ReservationTablePanel extends StatelessWidget {
  final StationReservationListResponse response;
  final int page;
  final bool isRefreshing;
  final bool canPrint;
  final bool isLoadingPrint;
  final bool isOpeningPdf;
  final ValueChanged<StationReservationListItem> onOpenDetail;
  final void Function(String ticketId) onPrint;
  final void Function(String ticketId) onPdf;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _ReservationTablePanel({
    required this.response,
    required this.page,
    required this.isRefreshing,
    required this.canPrint,
    required this.isLoadingPrint,
    required this.isOpeningPdf,
    required this.onOpenDetail,
    required this.onPrint,
    required this.onPdf,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Résultats / réservations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${response.count} réservation(s) - page $page',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (isRefreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 920) {
                return Column(
                  children: response.results
                      .map(
                        (reservation) => _ReservationMobileCard(
                          reservation: reservation,
                          canPrint: canPrint,
                          isLoadingPrint: isLoadingPrint,
                          isOpeningPdf: isOpeningPdf,
                          onOpenDetail: onOpenDetail,
                          onPrint: onPrint,
                          onPdf: onPdf,
                        ),
                      )
                      .toList(),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1080),
                  child: DataTable(
                    columnSpacing: 18,
                    horizontalMargin: 14,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 82,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF7F8FC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Réservation')),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Voyage')),
                      DataColumn(label: Text('Service')),
                      DataColumn(label: Text('Paiement')),
                      DataColumn(label: Text('Ticket')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: response.results
                        .map((reservation) => _reservationRow(reservation))
                        .toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Précédent'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _reservationRow(StationReservationListItem reservation) {
    return DataRow(
      cells: [
        DataCell(_ReservationCell(reservation: reservation)),
        DataCell(_ClientCell(reservation: reservation)),
        DataCell(_TripCell(reservation: reservation)),
        DataCell(_ServiceCell(reservation: reservation)),
        DataCell(_PaymentCell(payment: reservation.payment)),
        DataCell(_TicketsCell(tickets: reservation.tickets)),
        DataCell(
          _ReservationActions(
            reservation: reservation,
            canPrint: canPrint,
            isLoadingPrint: isLoadingPrint,
            isOpeningPdf: isOpeningPdf,
            onOpenDetail: onOpenDetail,
            onPrint: onPrint,
            onPdf: onPdf,
          ),
        ),
      ],
    );
  }
}

class _ReservationMobileCard extends StatelessWidget {
  final StationReservationListItem reservation;
  final bool canPrint;
  final bool isLoadingPrint;
  final bool isOpeningPdf;
  final ValueChanged<StationReservationListItem> onOpenDetail;
  final void Function(String ticketId) onPrint;
  final void Function(String ticketId) onPdf;

  const _ReservationMobileCard({
    required this.reservation,
    required this.canPrint,
    required this.isLoadingPrint,
    required this.isOpeningPdf,
    required this.onOpenDetail,
    required this.onPrint,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ReservationCell(reservation: reservation)),
              _ReservationActions(
                reservation: reservation,
                canPrint: canPrint,
                isLoadingPrint: isLoadingPrint,
                isOpeningPdf: isOpeningPdf,
                onOpenDetail: onOpenDetail,
                onPrint: onPrint,
                onPdf: onPdf,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _ClientCell(reservation: reservation),
              ),
              SizedBox(width: 250, child: _TripCell(reservation: reservation)),
              SizedBox(
                width: 190,
                child: _ServiceCell(reservation: reservation),
              ),
              SizedBox(
                width: 160,
                child: _PaymentCell(payment: reservation.payment),
              ),
              SizedBox(
                width: 180,
                child: _TicketsCell(tickets: reservation.tickets),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReservationCell extends StatelessWidget {
  final StationReservationListItem reservation;

  const _ReservationCell({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _StackedCell(
      primary: reservation.reference,
      secondary: '${reservation.itemsCount} passager(s)',
      chip: _StatusChip(
        label: _shortReservationLabel(
          reservation.status,
          reservation.statusLabel,
        ),
        status: reservation.status,
      ),
      width: 150,
    );
  }
}

class _ClientCell extends StatelessWidget {
  final StationReservationListItem reservation;

  const _ClientCell({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _StackedCell(
      primary: reservation.primaryTraveler?.fullName.isNotEmpty == true
          ? reservation.primaryTraveler!.fullName
          : reservation.customer.displayName,
      secondary: reservation.customer.phone ?? '-',
      width: 150,
    );
  }
}

class _TripCell extends StatelessWidget {
  final StationReservationListItem reservation;

  const _TripCell({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _StackedCell(
      primary: reservation.trip.routeLabel,
      secondary: _formatDateTime(reservation.trip.departureDateTime),
      width: 220,
    );
  }
}

class _ServiceCell extends StatelessWidget {
  final StationReservationListItem reservation;

  const _ServiceCell({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return _StackedCell(
      primary: reservation.trip.serviceClass ?? '-',
      secondary: reservation.displaySeats,
      width: 140,
    );
  }
}

class _PaymentCell extends StatelessWidget {
  final StationReservationListPayment? payment;

  const _PaymentCell({required this.payment});

  @override
  Widget build(BuildContext context) {
    final payment = this.payment;
    if (payment == null) {
      return const _StackedCell(
        primary: 'Aucun',
        secondary: '-',
        chip: _StatusChip(label: 'Aucun', status: 'none'),
        width: 130,
      );
    }

    return _StackedCell(
      primary: payment.displayAmount.isEmpty ? '-' : payment.displayAmount,
      secondary: payment.provider ?? '-',
      chip: _StatusChip(
        label: _shortPaymentLabel(payment.status),
        status: payment.status,
      ),
      width: 130,
    );
  }
}

class _TicketsCell extends StatelessWidget {
  final List<StationReservationListTicket> tickets;

  const _TicketsCell({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const _StackedCell(
        primary: 'Aucun ticket',
        secondary: '-',
        chip: _StatusChip(label: 'Aucun', status: 'none'),
        width: 145,
      );
    }

    final first = tickets.first;
    return _StackedCell(
      primary: first.reference,
      secondary: tickets.length > 1 ? '${tickets.length} tickets' : '1 ticket',
      chip: _StatusChip(
        label: _shortTicketLabel(first.status),
        status: first.status,
      ),
      width: 145,
    );
  }
}

class _StackedCell extends StatelessWidget {
  final String primary;
  final String secondary;
  final Widget? chip;
  final double width;

  const _StackedCell({
    required this.primary,
    required this.secondary,
    this.chip,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            primary.isEmpty ? '-' : primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            secondary.isEmpty ? '-' : secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (chip != null) ...[const SizedBox(height: 5), chip!],
        ],
      ),
    );
  }
}

class _ReservationActions extends StatelessWidget {
  final StationReservationListItem reservation;
  final bool canPrint;
  final bool isLoadingPrint;
  final bool isOpeningPdf;
  final ValueChanged<StationReservationListItem> onOpenDetail;
  final void Function(String ticketId) onPrint;
  final void Function(String ticketId) onPdf;
  final bool compact;

  const _ReservationActions({
    required this.reservation,
    required this.canPrint,
    required this.isLoadingPrint,
    required this.isOpeningPdf,
    required this.onOpenDetail,
    required this.onPrint,
    required this.onPdf,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ticket = reservation.firstTicket;
    final canUseTicketActions = canPrintCounterTicket(
          hasPrintScope: canPrint,
          backendAllowsPrint: reservation.actions.canPrintTicket,
        ) &&
        ticket != null;

    return SizedBox(
      width: compact ? 132 : 150,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            compact ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          TextButton(
            onPressed: reservation.actions.canViewDetail
                ? () => onOpenDetail(reservation)
                : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(54, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Détail'),
          ),
          _ActionIconButton(
            tooltip: 'Voir données ticket',
            icon: Icons.receipt_long,
            onPressed: canUseTicketActions && !isLoadingPrint
                ? () => onPrint(ticket.id)
                : null,
          ),
          _ActionIconButton(
            tooltip: 'Ouvrir PDF',
            icon: Icons.picture_as_pdf,
            onPressed: canUseTicketActions && !isOpeningPdf
                ? () => onPdf(ticket.id)
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      constraints: const BoxConstraints.tightFor(width: 34, height: 36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TicketPrintDialog extends StatelessWidget {
  final StationTicketPrintResponse printInfo;

  const _TicketPrintDialog({required this.printInfo});

  @override
  Widget build(BuildContext context) {
    final ticket = printInfo.ticket;

    return AlertDialog(
      title: const Text('Données ticket'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoLine(label: 'Ticket', value: ticket.reference),
            _InfoLine(label: 'Réservation', value: ticket.reservationReference),
            _InfoLine(label: 'Voyageur', value: ticket.travelerFullName),
            _InfoLine(label: 'Téléphone', value: ticket.travelerPhone),
            _InfoLine(label: 'Trajet', value: ticket.tripLabel),
            _InfoLine(
              label: 'Départ',
              value: [ticket.departureDate, ticket.departureTime]
                  .where((part) => part != null && part.trim().isNotEmpty)
                  .join(' '),
            ),
            _InfoLine(
              label: 'Siège',
              value: ticket.seatNumber == null
                  ? 'Placement gare'
                  : ticket.seatNumber.toString(),
            ),
            _InfoLine(label: 'Classe', value: ticket.serviceClassName ?? '-'),
            _InfoLine(label: 'Montant', value: ticket.displayAmount),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String? status;

  const _StatusChip({required this.label, this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status ?? label);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112, minHeight: 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label.isEmpty ? '-' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _shortReservationLabel(String status, String fallback) {
  final normalized = status.toLowerCase();
  if (normalized.contains('confirm')) return 'Confirmée';
  if (normalized.contains('pending')) return 'En attente';
  if (normalized.contains('expire')) return 'Expirée';
  if (normalized.contains('cancel')) return 'Annulée';
  final label = fallback.trim();
  return label.isEmpty ? '-' : label;
}

String _shortPaymentLabel(String? status) {
  final normalized = status?.toLowerCase() ?? '';
  if (normalized.isEmpty) return 'Aucun';
  if (normalized.contains('success') || normalized.contains('paid')) {
    return 'Payé';
  }
  if (normalized.contains('pending') || normalized.contains('processing')) {
    return 'En attente';
  }
  if (normalized.contains('failed')) return 'Échoué';
  if (normalized.contains('cancel')) return 'Annulé';
  if (normalized.contains('expire')) return 'Expiré';
  return status ?? '-';
}

String _shortTicketLabel(String? status) {
  final normalized = status?.toLowerCase() ?? '';
  if (normalized.isEmpty) return 'Aucun';
  if (normalized.contains('issued')) return 'Émis';
  if (normalized.contains('used')) return 'Utilisé';
  if (normalized.contains('cancel')) return 'Annulé';
  return status ?? '-';
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F056B),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String message;

  const _LoadingPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return _Panel(title: message, child: const LinearProgressIndicator());
  }
}

class _AccessDeniedContent extends StatelessWidget {
  final User? user;

  const _AccessDeniedContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _StatePanel(
          icon: Icons.lock_outline,
          title: 'Accès non autorisé',
          message:
              'Votre profil ne dispose pas des droits nécessaires pour utiliser le module guichet.',
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

String? _formatApiDate(DateTime? value) {
  if (value == null) return null;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final date = '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
  final time = '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date à $time';
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('confirm') ||
      normalized.contains('success') ||
      normalized.contains('issued') ||
      normalized.contains('payé')) {
    return const Color(0xFF157347);
  }
  if (normalized.contains('pending') ||
      normalized.contains('processing') ||
      normalized.contains('attente')) {
    return const Color(0xFFB8860B);
  }
  if (normalized.contains('cancel') ||
      normalized.contains('expired') ||
      normalized.contains('failed') ||
      normalized.contains('annul') ||
      normalized.contains('échou')) {
    return const Color(0xFFB42318);
  }
  return const Color(0xFF0F056B);
}
