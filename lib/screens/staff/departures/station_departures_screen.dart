import 'dart:async';

import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';
import 'package:catrans_app/screens/staff/departures/station_departure_detail_dialog.dart';
import 'package:catrans_app/screens/staff/departures/station_departure_transition_dialog.dart';
import 'package:catrans_app/screens/staff/shell/staff_navigation_request.dart';
import 'package:catrans_app/services/api/station_operational_departures_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';

const _brandPurple = Color(0xFF0F056B);
const _softPanel = Color(0xFFF7F8FC);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

class StationDeparturesScreen extends StatefulWidget {
  final User user;
  final String? initialDepartureId;
  final VoidCallback? onInitialDepartureConsumed;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const StationDeparturesScreen({
    super.key,
    required this.user,
    required this.onNavigate,
    this.initialDepartureId,
    this.onInitialDepartureConsumed,
  });

  @override
  State<StationDeparturesScreen> createState() =>
      _StationDeparturesScreenState();
}

class _StationDeparturesScreenState extends State<StationDeparturesScreen> {
  final _apiService = StationOperationalDeparturesApiService();
  final _searchController = TextEditingController();

  StationOperationalDeparturesResponse? _response;
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'all';
  String? _selectedServiceClassId;
  String? _errorMessage;
  String? _pendingInitialDepartureId;
  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _didAttemptInitialDeparture = false;
  String? _mutatingDepartureId;
  StationDepartureTransitionAction? _mutatingAction;
  int _page = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _pendingInitialDepartureId =
        _normalizeDepartureId(widget.initialDepartureId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDepartures();
    });
  }

  @override
  void didUpdateWidget(covariant StationDeparturesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDepartureId != widget.initialDepartureId) {
      _pendingInitialDepartureId =
          _normalizeDepartureId(widget.initialDepartureId);
      _didAttemptInitialDeparture = false;
      if (_response != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryOpenInitialDeparture();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canReadDepartures(widget.user)) {
      return const _AccessDeniedDepartures();
    }

    return RefreshIndicator(
      onRefresh: _refreshDepartures,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 900
              ? 24.0
              : constraints.maxWidth >= 560
                  ? 18.0
                  : 12.0;
          final sectionGap = constraints.maxWidth < 560 ? 14.0 : 18.0;

          return ListView(
            padding: EdgeInsets.all(padding),
            children: [
              _Header(
                response: _response,
                selectedDate: _selectedDate,
                isRefreshing: _isRefreshing,
                onRefresh:
                    _isRefreshing || _isLoading ? null : _refreshDepartures,
                onPickDate: _pickDate,
                onToday: _selectToday,
              ),
              SizedBox(height: sectionGap),
              _buildSummary(),
              SizedBox(height: sectionGap),
              _FiltersPanel(
                controller: _searchController,
                selectedStatus: _selectedStatus,
                selectedServiceClassId: _selectedServiceClassId,
                serviceClassOptions: _serviceClassOptions,
                onSearchChanged: _onSearchChanged,
                onStatusChanged: _onStatusChanged,
                onServiceClassChanged: _onServiceClassChanged,
                onReset: _resetFilters,
              ),
              SizedBox(height: sectionGap),
              _buildContent(),
            ],
          );
        },
      ),
    );
  }

  bool _canReadDepartures(User user) {
    return user.scopes.contains('station.departures.read');
  }

  Future<void> _loadDepartures({bool keepData = false}) async {
    if (!mounted) return;
    setState(() {
      if (keepData) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getOperationalDepartures(
        date: _selectedDate,
        page: _page,
        pageSize: _pageSize,
        statuses: _selectedStatus == 'all' ? null : [_selectedStatus],
        serviceClassId: _selectedServiceClassId,
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() => _response = response);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryOpenInitialDeparture();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!keepData) _response = null;
        _errorMessage = _messageFromError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshDepartures() async {
    if (_isRefreshing || _isLoading) return;
    await _loadDepartures(keepData: true);
  }

  List<_ServiceClassOption> get _serviceClassOptions {
    final byId = <String, _ServiceClassOption>{};
    for (final departure in _response?.results ?? const []) {
      final id = departure.serviceClassId;
      if (id == null || id.isEmpty) continue;
      byId.putIfAbsent(
        id,
        () => _ServiceClassOption(
          id: id,
          label: departure.displayServiceClass,
        ),
      );
    }
    final options = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  Widget _buildSummary() {
    final summary = _response?.summary;
    if (_isLoading && summary == null) {
      return const _LoadingPanel(
          message: 'Chargement des départs opérationnels...');
    }

    if (summary == null) {
      return _StatePanel(
        icon: Icons.insights_outlined,
        title: 'Synthèse indisponible',
        message: 'La synthèse s’affiche après le chargement des départs.',
        actionLabel: 'Actualiser',
        onAction: _loadDepartures,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricSlot(
              width: width,
              child: StaffMetricCard(
                title: 'Départs',
                value: summary.departuresTotal.toString(),
                icon: Icons.departure_board_outlined,
                color: _brandPurple,
              ),
            ),
            _MetricSlot(
              width: width,
              child: StaffMetricCard(
                title: 'Ouverts',
                value: summary.departuresOpen.toString(),
                icon: Icons.lock_open_outlined,
                color: _success,
              ),
            ),
            _MetricSlot(
              width: width,
              child: StaffMetricCard(
                title: 'Voyageurs attendus',
                value: summary.travelersExpected.toString(),
                icon: Icons.groups_2_outlined,
                color: Colors.indigo,
              ),
            ),
            _MetricSlot(
              width: width,
              child: StaffMetricCard(
                title: 'Alertes',
                value: summary.alertsTotal.toString(),
                icon: Icons.warning_amber_outlined,
                color: summary.alertsTotal > 0 ? _warning : Colors.blueGrey,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading && _response == null) {
      return const _LoadingPanel(
          message: 'Chargement des départs opérationnels...');
    }

    if (_errorMessage != null && _response == null) {
      return _StatePanel(
        icon: Icons.error_outline,
        title: 'Départs indisponibles',
        message: _errorMessage!,
        actionLabel: 'Réessayer',
        onAction: _loadDepartures,
      );
    }

    final response = _response;
    if (response == null) {
      return _StatePanel(
        icon: Icons.event_note_outlined,
        title: 'Aucun contenu à afficher',
        message: 'Actualisez la page pour charger les départs opérationnels.',
        actionLabel: 'Actualiser',
        onAction: _loadDepartures,
      );
    }

    if (response.results.isEmpty) {
      return _StatePanel(
        icon: Icons.filter_alt_off,
        title: 'Aucun départ dans cette vue',
        message: 'Aucun départ ne correspond aux filtres actuels.',
        actionLabel: 'Réinitialiser',
        onAction: _resetFilters,
      );
    }

    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _InlineError(
              message: _errorMessage!,
              onRetry: _isRefreshing ? null : _refreshDepartures,
            ),
          ),
        _DeparturesPanel(
          response: response,
          isRefreshing: _isRefreshing,
          mutatingDepartureId: _mutatingDepartureId,
          mutatingAction: _mutatingAction,
          onRefresh: _isRefreshing ? null : _refreshDepartures,
          onOpenDeparture: _openDepartureDetail,
          onOpenBoarding: _openBoarding,
          onTransitionRequested: _requestTransition,
        ),
        const SizedBox(height: 14),
        _PaginationBar(
          count: response.count,
          currentPage: _page,
          pageSize: _pageSize,
          hasPrevious: response.previous != null,
          hasNext: response.next != null,
          onPrevious: response.previous == null ? null : _previousPage,
          onNext: response.next == null ? null : _nextPage,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _page = 1;
    });
    await _loadDepartures();
  }

  Future<void> _selectToday() async {
    final today = DateTime.now();
    if (_sameDate(_selectedDate, today)) return;
    setState(() {
      _selectedDate = today;
      _page = 1;
    });
    await _loadDepartures();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _page = 1);
      _loadDepartures();
    });
  }

  void _onStatusChanged(String? value) {
    if (value == null || value == _selectedStatus) return;
    setState(() {
      _selectedStatus = value;
      _page = 1;
    });
    _loadDepartures();
  }

  void _onServiceClassChanged(String? value) {
    final nextValue = value == 'all' ? null : value;
    if (nextValue == _selectedServiceClassId) return;
    setState(() {
      _selectedServiceClassId = nextValue;
      _page = 1;
    });
    _loadDepartures();
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _selectedStatus = 'all';
      _selectedServiceClassId = null;
      _page = 1;
    });
    _loadDepartures();
  }

  void _previousPage() {
    if (_page <= 1) return;
    setState(() => _page -= 1);
    _loadDepartures();
  }

  void _nextPage() {
    setState(() => _page += 1);
    _loadDepartures();
  }

  void _tryOpenInitialDeparture() {
    final targetId = _pendingInitialDepartureId;
    final response = _response;
    if (targetId == null || targetId.isEmpty || response == null) return;
    if (_didAttemptInitialDeparture) return;

    _didAttemptInitialDeparture = true;
    widget.onInitialDepartureConsumed?.call();

    final departure =
        response.results.cast<StationOperationalDeparture?>().firstWhere(
              (departure) => departure?.id == targetId,
              orElse: () => null,
            );

    if (departure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Le départ demandé n’est pas disponible dans la liste actuelle.'),
        ),
      );
      return;
    }

    _openDepartureDetail(departure);
  }

  void _openDepartureDetail(StationOperationalDeparture departure) {
    showStationDepartureDetailDialog(
      context: context,
      departure: departure,
      isMutating: _mutatingDepartureId == departure.id,
      onOpenBoarding: departure.availableActions.canOpenBoarding
          ? () => _openBoarding(departure)
          : null,
      onTransitionRequested: (request) => _requestTransition(
        request.departure,
        request.action,
      ),
    );
  }

  void _openBoarding(StationOperationalDeparture departure) {
    widget.onNavigate(
      StaffNavigationRequest(
        menuId: 'boarding',
        departureId: departure.id,
      ),
    );
  }

  Future<void> _requestTransition(
    StationOperationalDeparture departure,
    StationDepartureTransitionAction action,
  ) async {
    if (_mutatingDepartureId != null) return;

    final confirmed = await showStationDepartureTransitionDialog(
      context: context,
      departure: departure,
      action: action,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _mutatingDepartureId = departure.id;
      _mutatingAction = action;
      _errorMessage = null;
    });

    try {
      switch (action) {
        case StationDepartureTransitionAction.open:
          await _apiService.openDeparture(departure.id);
          break;
        case StationDepartureTransitionAction.close:
          await _apiService.closeDeparture(departure.id);
          break;
        case StationDepartureTransitionAction.depart:
          await _apiService.markDepartureAsDeparted(departure.id);
          break;
      }

      await _reloadAfterMutation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action.successMessage)),
      );
    } catch (error) {
      final message = _messageFromTransitionError(error);
      if (_shouldReloadAfterTransitionError(error)) {
        await _loadDepartures(keepData: true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingDepartureId = null;
          _mutatingAction = null;
        });
      }
    }
  }

  Future<void> _reloadAfterMutation() async {
    await _loadDepartures(keepData: true);
    if (!mounted) return;

    final response = _response;
    if (_page > 1 && response != null && response.results.isEmpty) {
      setState(() => _page -= 1);
      await _loadDepartures(keepData: true);
    }
  }

  bool _shouldReloadAfterTransitionError(Object error) {
    if (error is! ApiException) return false;
    final code = _transitionErrorCode(error.details);
    return code == 'DEPARTURE_INVALID_TRANSITION' ||
        code == 'DEPARTURE_NOT_OPERATIONAL_TODAY' ||
        error.statusCode == 403 ||
        error.statusCode == 404;
  }

  String _messageFromTransitionError(Object error) {
    if (error is ApiException) {
      final code = _transitionErrorCode(error.details);
      if (code == 'DEPARTURE_INVALID_TRANSITION') {
        return 'Le statut de ce départ a changé. Les informations vont être actualisées.';
      }
      if (code == 'DEPARTURE_NOT_OPERATIONAL_TODAY') {
        return 'Cette action est uniquement disponible pour un départ prévu aujourd’hui.';
      }

      switch (error.statusCode) {
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’êtes pas autorisé à modifier ce départ.';
        case 404:
          return 'Ce départ n’est plus accessible.';
      }

      if (error.message.trim().isNotEmpty) return error.message;
    }

    return 'La modification n’a pas pu être enregistrée. Vérifiez votre connexion puis réessayez.';
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'La demande de départs opérationnels est invalide.';
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’avez pas accès aux départs de cette gare.';
        case 404:
          return 'La gare rattachée est introuvable.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }
    return 'Impossible de charger les départs opérationnels.';
  }
}

class _Header extends StatelessWidget {
  final StationOperationalDeparturesResponse? response;
  final DateTime selectedDate;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;
  final VoidCallback onPickDate;
  final VoidCallback onToday;

  const _Header({
    required this.response,
    required this.selectedDate,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onPickDate,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final stationName = response?.station.name ?? 'Gare rattachée';
          final generatedAt = response?.generatedAt;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Départs du jour',
                style: TextStyle(
                  color: _brandPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stationName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Activité du ${_formatDate(selectedDate)}${generatedAt == null ? '' : ' • Actualisé ${_formatDateTime(generatedAt)}'}',
                maxLines: isNarrow ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_outlined, size: 18),
                label: const Text('Aujourd’hui'),
              ),
              OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Date'),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                style: FilledButton.styleFrom(
                  backgroundColor: _brandPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Actualiser'),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              actions
            ],
          );
        },
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final TextEditingController controller;
  final String selectedStatus;
  final String? selectedServiceClassId;
  final List<_ServiceClassOption> serviceClassOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onServiceClassChanged;
  final VoidCallback onReset;

  const _FiltersPanel({
    required this.controller,
    required this.selectedStatus,
    required this.selectedServiceClassId,
    required this.serviceClassOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onServiceClassChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final statusValue = selectedStatus;
    final serviceClassValue = selectedServiceClassId != null &&
            serviceClassOptions.any(
              (option) => option.id == selectedServiceClassId,
            )
        ? selectedServiceClassId!
        : 'all';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1020
              ? 4
              : constraints.maxWidth >= 700
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: width,
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Destination, route...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('departure-status-$statusValue'),
                  initialValue: statusValue,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous')),
                    DropdownMenuItem(value: 'scheduled', child: Text('Prévu')),
                    DropdownMenuItem(value: 'open', child: Text('Ouvert')),
                    DropdownMenuItem(value: 'closed', child: Text('Clôturé')),
                    DropdownMenuItem(value: 'departed', child: Text('Parti')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: width,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('departure-service-class-$serviceClassValue'),
                  initialValue: serviceClassValue,
                  decoration: InputDecoration(
                    labelText: 'Classe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    ...serviceClassOptions.map(
                      (option) => DropdownMenuItem(
                        value: option.id,
                        child: Text(option.label),
                      ),
                    ),
                  ],
                  onChanged: onServiceClassChanged,
                ),
              ),
              SizedBox(
                width: width,
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Réinitialiser'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeparturesPanel extends StatelessWidget {
  final StationOperationalDeparturesResponse response;
  final bool isRefreshing;
  final String? mutatingDepartureId;
  final StationDepartureTransitionAction? mutatingAction;
  final Future<void> Function()? onRefresh;
  final ValueChanged<StationOperationalDeparture> onOpenDeparture;
  final ValueChanged<StationOperationalDeparture> onOpenBoarding;
  final void Function(
    StationOperationalDeparture departure,
    StationDepartureTransitionAction action,
  ) onTransitionRequested;

  const _DeparturesPanel({
    required this.response,
    required this.isRefreshing,
    required this.mutatingDepartureId,
    required this.mutatingAction,
    required this.onRefresh,
    required this.onOpenDeparture,
    required this.onOpenBoarding,
    required this.onTransitionRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Liste opérationnelle',
                  style: TextStyle(
                    color: _brandPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Actualiser',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1220
                  ? 3
                  : constraints.maxWidth >= 780
                      ? 2
                      : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: response.results
                    .map(
                      (departure) => SizedBox(
                        width: cardWidth,
                        child: _DepartureCard(
                          departure: departure,
                          isMutating: mutatingDepartureId == departure.id,
                          mutatingAction: mutatingDepartureId == departure.id
                              ? mutatingAction
                              : null,
                          onOpen: () => onOpenDeparture(departure),
                          onOpenBoarding: () => onOpenBoarding(departure),
                          onTransitionRequested: onTransitionRequested,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final StationOperationalDeparture departure;
  final bool isMutating;
  final StationDepartureTransitionAction? mutatingAction;
  final VoidCallback onOpen;
  final VoidCallback onOpenBoarding;
  final void Function(
    StationOperationalDeparture departure,
    StationDepartureTransitionAction action,
  ) onTransitionRequested;

  const _DepartureCard({
    required this.departure,
    required this.isMutating,
    required this.mutatingAction,
    required this.onOpen,
    required this.onOpenBoarding,
    required this.onTransitionRequested,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(departure.status);
    final transitionAction = _resolveTransitionAction(departure);
    final canOpenBoarding = departure.availableActions.canOpenBoarding;

    return InkWell(
      onTap: isMutating ? null : onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E8EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brandPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    departure.displayTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _brandPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departure.destinationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _brandPurple,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        departure.displayRoute,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: departure.statusLabel, color: statusColor),
                _Badge(
                  label: departure.displayServiceClass,
                  color: Colors.indigo,
                ),
                if (departure.alertsCount > 0)
                  _Badge(
                    label: '${departure.alertsCount} alerte(s)',
                    color: _warning,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressLine(departure: departure),
            const SizedBox(height: 12),
            _MiniStats(departure: departure),
            if (departure.priorityAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...departure.priorityAlerts
                  .map((alert) => _CompactAlert(alert: alert)),
            ],
            const SizedBox(height: 12),
            Text(
              departure.capacityLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onOpen,
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text('Détail'),
                ),
                if (canOpenBoarding)
                  OutlinedButton.icon(
                    onPressed: isMutating ? null : onOpenBoarding,
                    icon: const Icon(Icons.fact_check_outlined, size: 17),
                    label: const Text('Embarquement'),
                  ),
                if (transitionAction != null)
                  FilledButton.icon(
                    onPressed: isMutating
                        ? null
                        : () => onTransitionRequested(
                              departure,
                              transitionAction,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: transitionAction.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: isMutating && mutatingAction == transitionAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(transitionAction.icon, size: 17),
                    label: Text(transitionAction.shortLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _ProgressLine({required this.departure});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${departure.ticketsChecked}/${departure.ticketsActive} billets contrôlés',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${departure.boardingRate.toStringAsFixed(0)} %',
              style: const TextStyle(
                color: _brandPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: departure.progressValue,
            backgroundColor: const Color(0xFFE6E8EF),
            valueColor: AlwaysStoppedAnimation<Color>(
              departure.progressValue >= 1 ? _success : _brandPurple,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStats extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _MiniStats({required this.departure});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Attendus',
            value: departure.travelersExpected.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Restants',
            value: departure.ticketsRemaining.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Rejets',
            value: departure.validationRejections.toString(),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _brandPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CompactAlert extends StatelessWidget {
  final StationOperationalDepartureAlert alert;

  const _CompactAlert({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int count;
  final int currentPage;
  final int pageSize;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.count,
    required this.currentPage,
    required this.pageSize,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = count <= 0 ? 1 : (count / pageSize).ceil();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count départ(s) • Page $currentPage/$totalPages',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: hasPrevious ? onPrevious : null,
            tooltip: 'Page précédente',
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: hasNext ? onNext : null,
            tooltip: 'Page suivante',
            icon: const Icon(Icons.chevron_right),
          ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _brandPurple, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _brandPurple,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: _brandPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _AccessDeniedDepartures extends StatelessWidget {
  const _AccessDeniedDepartures();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: _cardDecoration(),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: _brandPurple, size: 42),
            SizedBox(height: 12),
            Text(
              'Accès non autorisé',
              style: TextStyle(
                color: _brandPurple,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Votre profil ne permet pas de consulter les départs opérationnels de la gare.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSlot extends StatelessWidget {
  final double width;
  final Widget child;

  const _MetricSlot({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ServiceClassOption {
  final String id;
  final String label;

  const _ServiceClassOption({required this.id, required this.label});
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE6E8EF)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

StationDepartureTransitionAction? _resolveTransitionAction(
  StationOperationalDeparture departure,
) {
  final nextAction = departure.nextAction;
  if (nextAction == StationDepartureTransitionAction.open.code &&
      departure.availableActions.canOpen) {
    return StationDepartureTransitionAction.open;
  }
  if (nextAction == StationDepartureTransitionAction.close.code &&
      departure.availableActions.canClose) {
    return StationDepartureTransitionAction.close;
  }
  if (nextAction == StationDepartureTransitionAction.depart.code &&
      departure.availableActions.canMarkDeparted) {
    return StationDepartureTransitionAction.depart;
  }

  if (nextAction == null || nextAction.isEmpty) {
    if (departure.availableActions.canOpen) {
      return StationDepartureTransitionAction.open;
    }
    if (departure.availableActions.canClose) {
      return StationDepartureTransitionAction.close;
    }
    if (departure.availableActions.canMarkDeparted) {
      return StationDepartureTransitionAction.depart;
    }
  }

  return null;
}

String? _transitionErrorCode(dynamic details) {
  if (details is Map) {
    final directCode = _firstString(details['code']);
    if (directCode != null) return directCode;

    final detail = details['detail'];
    if (detail is Map) return _transitionErrorCode(detail);

    final nestedCode = _firstString(details['error_code']);
    if (nestedCode != null) return nestedCode;
  }
  return null;
}

String? _firstString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is List && value.isNotEmpty) return _firstString(value.first);
  return null;
}

String? _normalizeDepartureId(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _statusColor(String code) {
  switch (code) {
    case 'open':
      return _success;
    case 'closed':
      return Colors.indigo;
    case 'departed':
      return Colors.blueGrey;
    case 'cancelled':
      return _danger;
    case 'scheduled':
      return _warning;
  }
  return Colors.black54;
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'error':
    case 'critical':
      return _danger;
    case 'warning':
      return _warning;
    case 'success':
      return _success;
  }
  return Colors.blueGrey;
}
