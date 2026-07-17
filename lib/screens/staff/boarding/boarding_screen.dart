import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/station_boarding_manifest.dart';
import 'package:catrans_app/models/station/station_boarding_summary.dart';
import 'package:catrans_app/models/station/station_departure.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_ticket_detail_dialog.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_ticket_search.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBg = Color(0xFFF5F6FA);
const _cardBg = Colors.white;
const _softPanel = Color(0xFFF7F8FC);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

class BoardingScreen extends StatefulWidget {
  final String? initialDepartureId;
  final VoidCallback? onInitialDepartureConsumed;

  const BoardingScreen({
    super.key,
    this.initialDepartureId,
    this.onInitialDepartureConsumed,
  });

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  final _apiService = StationBoardingApiService();
  final _searchController = TextEditingController();

  List<StationDeparture> _departures = const [];
  String _searchText = '';
  String _selectedClass = 'all';
  String _selectedStatus = 'all';
  bool _withTicketsOnly = false;
  String? _departuresError;
  String? _pendingInitialDepartureId;
  bool _didAttemptInitialDeparture = false;
  bool _isLoadingDepartures = false;

  @override
  void initState() {
    super.initState();
    _pendingInitialDepartureId =
        _normalizeDepartureId(widget.initialDepartureId);
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDepartures();
    });
  }

  @override
  void didUpdateWidget(covariant BoardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDepartureId != widget.initialDepartureId) {
      _pendingInitialDepartureId =
          _normalizeDepartureId(widget.initialDepartureId);
      _didAttemptInitialDeparture = false;
      if (_departures.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryOpenInitialDeparture();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null || !_canAccessBoarding(user)) {
      return const _AccessDeniedBoarding();
    }

    final filteredDepartures = _filteredDepartures;
    final overview = _BoardingOverview.fromDepartures(_departures);

    return LayoutBuilder(
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
            _Header(user: user),
            SizedBox(height: sectionGap),
            _OverviewBand(overview: overview),
            SizedBox(height: sectionGap),
            _FiltersPanel(
              controller: _searchController,
              selectedClass: _selectedClass,
              selectedStatus: _selectedStatus,
              withTicketsOnly: _withTicketsOnly,
              onClassChanged: (value) => setState(() => _selectedClass = value),
              onStatusChanged: (value) =>
                  setState(() => _selectedStatus = value),
              onWithTicketsChanged: (value) {
                setState(() => _withTicketsOnly = value);
              },
            ),
            SizedBox(height: sectionGap),
            _buildDepartures(filteredDepartures),
          ],
        );
      },
    );
  }

  bool _canAccessBoarding(User user) {
    final scopes = user.scopes.toSet();
    return scopes.contains('station.departures.read') ||
        scopes.contains('boarding.manifest.read') ||
        scopes.contains('boarding.validate') ||
        scopes.contains('boarding.summary.read');
  }

  Future<void> _loadDepartures() async {
    setState(() {
      _isLoadingDepartures = true;
      _departuresError = null;
    });

    try {
      final departures = await _apiService.getTodayDepartures();
      if (!mounted) return;
      setState(() => _departures = departures);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryOpenInitialDeparture();
      });
    } catch (error) {
      debugPrint('Erreur chargement départs embarquement: $error');
      if (!mounted) return;
      setState(() {
        _departures = const [];
        _departuresError =
            'Impossible de charger les départs. Vérifiez la connexion puis réessayez.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingDepartures = false);
    }
  }

  List<StationDeparture> get _filteredDepartures {
    final query = _normalize(_searchText);
    return _departures.where((departure) {
      final destination = _normalize(departure.destinationName ?? '');
      final route = _normalize(departure.routeLabel);
      final className = _classFilterValue(departure);
      final status = _statusFilterValue(departure.statusCode);

      if (query.isNotEmpty &&
          !destination.contains(query) &&
          !route.contains(query)) {
        return false;
      }
      if (_selectedClass != 'all' && className != _selectedClass) return false;
      if (_selectedStatus != 'all' && status != _selectedStatus) return false;
      if (_withTicketsOnly && departure.tickets.total <= 0) return false;
      return true;
    }).toList();
  }

  Widget _buildDepartures(List<StationDeparture> visibleDepartures) {
    if (_isLoadingDepartures && _departures.isEmpty) {
      return const _LoadingPanel(message: 'Chargement des départs du jour...');
    }

    if (_departuresError != null) {
      return _StatePanel(
        icon: Icons.error_outline,
        title: 'Départs indisponibles',
        message: _departuresError!,
        actionLabel: 'Réessayer',
        onAction: _loadDepartures,
      );
    }

    if (_departures.isEmpty) {
      return _StatePanel(
        icon: Icons.event_busy,
        title: 'Aucun départ aujourd’hui',
        message: 'Aucun départ prévu aujourd’hui pour votre gare.',
        actionLabel: 'Actualiser',
        onAction: _loadDepartures,
      );
    }

    if (visibleDepartures.isEmpty) {
      return _StatePanel(
        icon: Icons.filter_alt_off,
        title: 'Aucun départ dans cette vue',
        message: 'Aucun départ ne correspond aux filtres sélectionnés.',
        actionLabel: 'Réinitialiser',
        onAction: _clearFilters,
      );
    }

    return _Panel(
      title: 'Départs du jour',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoadingDepartures)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          IconButton(
            onPressed: _isLoadingDepartures ? null : _loadDepartures,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1180
              ? 3
              : width >= 760
                  ? 2
                  : 1;
          final cardWidth = (width - (columns - 1) * 14) / columns;

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: visibleDepartures
                .map(
                  (departure) => SizedBox(
                    width: cardWidth,
                    child: _DepartureCard(
                      departure: departure,
                      onOpen: () => _openDeparturePanel(departure),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _tryOpenInitialDeparture() async {
    final departureId = _pendingInitialDepartureId;
    if (_didAttemptInitialDeparture || departureId == null) return;
    if (_isLoadingDepartures || _departures.isEmpty) return;

    _didAttemptInitialDeparture = true;
    _pendingInitialDepartureId = null;
    widget.onInitialDepartureConsumed?.call();

    final matchingDepartures = _departures.where(
      (departure) => departure.id == departureId,
    );

    if (matchingDepartures.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Le départ demandé n’est pas disponible dans cette journée.'),
        ),
      );
      return;
    }

    await _openDeparturePanel(matchingDepartures.first);
  }

  String? _normalizeDepartureId(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> _openDeparturePanel(StationDeparture departure) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final workspace = _DepartureWorkspace(
          departure: departure,
          user: user,
          apiService: _apiService,
          onValidated: _loadDepartures,
        );
        if (MediaQuery.sizeOf(dialogContext).width < 600) {
          return Dialog.fullscreen(
            backgroundColor: _staffBg,
            child: SafeArea(child: workspace),
          );
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 22,
          ),
          backgroundColor: Colors.transparent,
          child: workspace,
        );
      },
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedClass = 'all';
      _selectedStatus = 'all';
      _withTicketsOnly = false;
    });
  }
}

class _DepartureWorkspace extends StatefulWidget {
  final StationDeparture departure;
  final User user;
  final StationBoardingApiService apiService;
  final Future<void> Function() onValidated;

  const _DepartureWorkspace({
    required this.departure,
    required this.user,
    required this.apiService,
    required this.onValidated,
  });

  @override
  State<_DepartureWorkspace> createState() => _DepartureWorkspaceState();
}

class _DepartureWorkspaceState extends State<_DepartureWorkspace> {
  final _manualReferenceController = TextEditingController();
  final _ticketSearchController = TextEditingController();

  late StationDeparture _departure;
  StationBoardingManifestResponse? _manifest;
  StationBoardingSummaryResponse? _summary;
  StationTicketValidation? _lastValidation;
  String? _loadError;
  String? _validationError;
  bool _isLoading = true;
  bool _isValidatingManual = false;
  final Set<String> _validatingTicketIds = <String>{};
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _departure = widget.departure;
    _loadBoardingData();
  }

  @override
  void dispose() {
    _manualReferenceController.dispose();
    _ticketSearchController.dispose();
    super.dispose();
  }

  bool get _canValidate => widget.user.scopes.contains('boarding.validate');
  bool get _canReadManifest =>
      widget.user.scopes.contains('boarding.manifest.read') ||
      widget.user.scopes.contains('station.departures.read');
  bool get _canReadSummary =>
      widget.user.scopes.contains('boarding.summary.read');

  Future<bool> _loadBoardingData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        if (_canReadManifest)
          widget.apiService.getBoardingManifest(departureId: _departure.id)
        else
          Future<StationBoardingManifestResponse?>.value(null),
        if (_canReadSummary)
          widget.apiService.getBoardingSummary(departureId: _departure.id)
        else
          Future<StationBoardingSummaryResponse?>.value(null),
      ]);
      if (!mounted) return false;

      final manifest = results[0] as StationBoardingManifestResponse?;
      setState(() {
        _manifest = manifest;
        _summary = results[1] as StationBoardingSummaryResponse?;
        _departure = manifest?.departure ?? _departure;
        _loadError = null;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      final message = _messageFromError(error);
      setState(() {
        if (showLoading) {
          _manifest = null;
          _summary = null;
          _loadError = message;
        } else {
          _validationError =
              'Billet traité, mais les données n’ont pas pu être actualisées.';
        }
      });
      return false;
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _validatePassenger(StationBoardingTicket passenger) async {
    if (!_canValidate ||
        _validatingTicketIds.contains(passenger.id) ||
        !_isTicketEligible(passenger)) {
      return;
    }

    final confirmed = await _confirmPassengerValidation(passenger);
    if (!confirmed || !mounted) return;

    await _runReferenceValidation(passenger.reference, ticketId: passenger.id);
  }

  Future<void> _validateManualReference() async {
    final reference = _manualReferenceController.text.trim();
    if (reference.isEmpty) {
      setState(() {
        _validationError = 'Saisissez la référence complète du billet.';
        _lastValidation = null;
      });
      return;
    }

    final confirmed = await _confirmManualValidation(reference);
    if (!confirmed || !mounted) return;

    await _runReferenceValidation(reference, isManual: true);
  }

  Future<void> _runReferenceValidation(
    String reference, {
    String? ticketId,
    bool isManual = false,
  }) async {
    FocusScope.of(context).unfocus();
    setState(() {
      if (ticketId != null) _validatingTicketIds.add(ticketId);
      if (isManual) _isValidatingManual = true;
      _validationError = null;
      _lastValidation = null;
    });

    try {
      final validation = await widget.apiService.validateTicketByReference(
        ticketReference: reference,
        departureId: _departure.id,
      );
      if (!mounted) return;

      setState(() {
        _lastValidation = validation;
        if (isManual && validation.isAccepted) {
          _manualReferenceController.clear();
        }
      });

      final message = validation.resultMessage ??
          (validation.isAccepted
              ? 'Billet validé avec succès.'
              : 'Le billet n’a pas été accepté pour ce départ.');
      _showValidationMessage(
        validation.isAccepted ? 'Billet validé avec succès.' : message,
        isSuccess: validation.isAccepted,
      );

      if (validation.isAccepted) {
        await Future.wait<void>([
          _refreshWorkspaceAfterValidation(),
          widget.onValidated(),
        ]);
      }
    } catch (error) {
      if (!mounted) return;
      final message = _messageFromError(error);
      setState(() {
        _validationError = message;
        _lastValidation = null;
      });
      _showValidationMessage(message, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          if (ticketId != null) _validatingTicketIds.remove(ticketId);
          if (isManual) _isValidatingManual = false;
        });
      }
    }
  }

  Future<void> _refreshWorkspaceAfterValidation() async {
    await _loadBoardingData(showLoading: false);
  }

  Future<void> _openTicketDetail(StationBoardingTicket passenger) {
    return showBoardingTicketDetailDialog(
      context: context,
      departure: _departure,
      ticket: passenger,
      canValidate: _canValidate,
      isValidating: _validatingTicketIds.contains(passenger.id),
      onValidate: () => _validatePassenger(passenger),
    );
  }

  Future<void> _openValidationDetail() async {
    final validation = _lastValidation;
    if (validation == null) return;

    await showBoardingTicketDetailDialog(
      context: context,
      departure: _departure,
      validation: validation,
    );
  }

  Future<bool> _confirmPassengerValidation(
    StationBoardingTicket passenger,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Valider ce billet ?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConfirmationDetail(
                  label: 'Voyageur',
                  value: passenger.displayTraveler.isEmpty
                      ? 'Voyageur non renseigné'
                      : passenger.displayTraveler,
                ),
                _ConfirmationDetail(
                  label: 'Ticket',
                  value: passenger.reference,
                ),
                _ConfirmationDetail(
                  label: 'Départ',
                  value: _departure.routeLabel,
                ),
                _ConfirmationDetail(
                  label: 'Heure',
                  value: _departure.displayTime,
                ),
                _ConfirmationDetail(
                  label: 'Classe',
                  value: passenger.serviceClass ??
                      _departure.serviceClassName ??
                      'Non renseignée',
                ),
                _ConfirmationDetail(
                  label: 'Siège',
                  value: passenger.displaySeat,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.verified),
              label: const Text('Valider le billet'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _confirmManualValidation(String reference) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Valider le billet $reference pour ce départ ?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConfirmationDetail(
                  label: 'Départ',
                  value: _departure.routeLabel,
                ),
                _ConfirmationDetail(
                  label: 'Heure',
                  value: _departure.displayTime,
                ),
                _ConfirmationDetail(
                  label: 'Classe',
                  value: _departure.serviceClassName ?? 'Non renseignée',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.verified),
              label: const Text('Valider le billet'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showValidationMessage(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? _success : _danger,
        ),
      );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’avez pas la permission de valider ce billet.';
        case 404:
          return 'Ce départ est inaccessible ou introuvable.';
        case 400:
          return error.message;
        default:
          if (error.statusCode == null) {
            return 'Impossible de contacter le service. Vérifiez votre connexion.';
          }
          return error.message;
      }
    }
    return 'Impossible de valider le billet pour le moment.';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth > 1180 ? 1180.0 : constraints.maxWidth;
        final height =
            constraints.maxHeight > 820 ? 820.0 : constraints.maxHeight;
        final isFullscreen = constraints.maxWidth < 600;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: Material(
            color: _staffBg,
            borderRadius: BorderRadius.circular(isFullscreen ? 0 : 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _WorkspaceHeader(departure: _departure),
                _WorkspaceQuickSummary(
                  departure: _departure,
                  summary: _summary,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: _SegmentedTabs(
                    selectedIndex: _selectedTab,
                    onChanged: (index) => setState(() => _selectedTab = index),
                    tabs: const [
                      _TabItem(icon: Icons.list_alt, label: 'Manifeste'),
                      _TabItem(
                        icon: Icons.verified,
                        label: 'Validation billet',
                      ),
                      _TabItem(icon: Icons.query_stats, label: 'Résumé'),
                    ],
                  ),
                ),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const _WorkspaceBody(
        child: _SoftLoading(
          message: 'Chargement des informations du départ...',
        ),
      );
    }

    if (_loadError != null && (_selectedTab == 0 || _selectedTab == 2)) {
      return _WorkspaceBody(
        child: _StatePanel(
          icon: Icons.error_outline,
          title: 'Informations indisponibles',
          message: _loadError!,
          actionLabel: 'Réessayer',
          onAction: _loadBoardingData,
        ),
      );
    }

    if (_selectedTab == 0) {
      return _WorkspaceBody(
        child: _ManifestSection(
          manifest: _manifest,
          searchController: _ticketSearchController,
          searchQuery: _ticketSearchController.text,
          canValidate: _canValidate,
          validatingTicketIds: _validatingTicketIds,
          onSearchChanged: (_) => setState(() {}),
          onOpenDetail: _openTicketDetail,
          onValidate: _validatePassenger,
        ),
      );
    }

    if (_selectedTab == 1) {
      return _WorkspaceBody(
        child: _ValidationSection(
          manifest: _manifest,
          searchController: _ticketSearchController,
          searchQuery: _ticketSearchController.text,
          manualReferenceController: _manualReferenceController,
          isValidatingManual: _isValidatingManual,
          canValidate: _canValidate,
          validatingTicketIds: _validatingTicketIds,
          validation: _lastValidation,
          errorMessage: _validationError,
          onSearchChanged: (_) => setState(() {}),
          onOpenTicketDetail: _openTicketDetail,
          onOpenValidationDetail: _openValidationDetail,
          onValidateTicket: _validatePassenger,
          onValidateManualReference: _validateManualReference,
        ),
      );
    }

    return _WorkspaceBody(
      child: _SummarySection(
        departure: _departure,
        summary: _summary,
        manifest: _manifest,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final station = user.internalProfile?.station?.name;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.all(compact ? 16 : 22),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7F0)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 44 : 52,
                height: compact ? 44 : 52,
                decoration: BoxDecoration(
                  color: _brandPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.how_to_reg,
                  color: Colors.white,
                  size: compact ? 24 : 28,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Embarquement',
                      style: TextStyle(
                        color: _brandPurple,
                        fontSize: compact ? 24 : 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station == null
                          ? 'Départs du jour de votre gare.'
                          : 'Départs du jour de $station.',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardingOverview {
  final int departuresCount;
  final int ticketsIssued;
  final int ticketsValidated;
  final int passengersRemaining;
  final int departuresWithTickets;

  const _BoardingOverview({
    required this.departuresCount,
    required this.ticketsIssued,
    required this.ticketsValidated,
    required this.passengersRemaining,
    required this.departuresWithTickets,
  });

  factory _BoardingOverview.fromDepartures(List<StationDeparture> departures) {
    final ticketsIssued = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.tickets.issued,
    );
    final ticketsValidated = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.validationsAccepted,
    );
    final passengersRemaining = departures.fold<int>(
      0,
      (sum, departure) => sum + departure.tickets.remaining,
    );
    final departuresWithTickets =
        departures.where((departure) => departure.tickets.total > 0).length;

    return _BoardingOverview(
      departuresCount: departures.length,
      ticketsIssued: ticketsIssued,
      ticketsValidated: ticketsValidated,
      passengersRemaining: passengersRemaining,
      departuresWithTickets: departuresWithTickets,
    );
  }
}

class _OverviewBand extends StatelessWidget {
  final _BoardingOverview overview;

  const _OverviewBand({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = [
      _OverviewItem(
        title: 'Départs du jour',
        value: overview.departuresCount.toString(),
        icon: Icons.directions_bus,
      ),
      _OverviewItem(
        title: 'Tickets émis',
        value: overview.ticketsIssued.toString(),
        icon: Icons.airplane_ticket,
      ),
      _OverviewItem(
        title: 'Tickets validés',
        value: overview.ticketsValidated.toString(),
        icon: Icons.verified,
      ),
      _OverviewItem(
        title: 'Passagers restants',
        value: overview.passengersRemaining.toString(),
        icon: Icons.pending_actions,
      ),
      _OverviewItem(
        title: 'Départs avec tickets',
        value: overview.departuresWithTickets.toString(),
        icon: Icons.fact_check,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 760
                ? 3
                : constraints.maxWidth >= 420
                    ? 2
                    : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              items.map((item) => SizedBox(width: width, child: item)).toList(),
        );
      },
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _brandPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _brandPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final TextEditingController controller;
  final String selectedClass;
  final String selectedStatus;
  final bool withTicketsOnly;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onWithTicketsChanged;

  const _FiltersPanel({
    required this.controller,
    required this.selectedClass,
    required this.selectedStatus,
    required this.withTicketsOnly,
    required this.onClassChanged,
    required this.onStatusChanged,
    required this.onWithTicketsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Vue opérationnelle',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          final search = TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Rechercher une destination',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          );
          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ChoicePillGroup(
                value: selectedClass,
                options: const [
                  _FilterOption('all', 'Tous'),
                  _FilterOption('economie', 'Économie'),
                  _FilterOption('prestige', 'Prestige'),
                ],
                onChanged: onClassChanged,
              ),
              _ChoicePillGroup(
                value: selectedStatus,
                options: const [
                  _FilterOption('all', 'Tous statuts'),
                  _FilterOption('open', 'Ouvert'),
                  _FilterOption('closed', 'Fermé'),
                  _FilterOption('departed', 'Parti'),
                ],
                onChanged: onStatusChanged,
              ),
              FilterChip(
                label: const Text('Avec tickets'),
                selected: withTicketsOnly,
                onSelected: onWithTicketsChanged,
                selectedColor: _brandPurple.withValues(alpha: 0.12),
                checkmarkColor: _brandPurple,
                side: const BorderSide(color: Color(0xFFDCE0EE)),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [search, const SizedBox(height: 12), filters],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: search),
              const SizedBox(width: 14),
              Expanded(child: filters),
            ],
          );
        },
      ),
    );
  }
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption(this.value, this.label);
}

class _ChoicePillGroup extends StatelessWidget {
  final String value;
  final List<_FilterOption> options;
  final ValueChanged<String> onChanged;

  const _ChoicePillGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: options.map((option) {
        final selected = option.value == value;
        return ChoiceChip(
          label: Text(option.label),
          selected: selected,
          onSelected: (_) => onChanged(option.value),
          selectedColor: _brandPurple.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: selected ? _brandPurple : Colors.black87,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          side: BorderSide(
            color: selected ? _brandPurple : const Color(0xFFDCE0EE),
          ),
        );
      }).toList(),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final StationDeparture departure;
  final VoidCallback onOpen;

  const _DepartureCard({required this.departure, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final progress = departure.tickets.total == 0
        ? 0.0
        : (departure.validationsAccepted / departure.tickets.total).clamp(
            0.0,
            1.0,
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  departure.displayTime,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: _brandPurple,
                  ),
                ),
              ),
              _StatusChip(
                label: _shortDepartureStatus(
                  departure.statusCode,
                  departure.statusLabel,
                ),
                status: departure.statusCode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            departure.routeLabel.isEmpty
                ? 'Trajet non renseigné'
                : departure.routeLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2330),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_seat, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  departure.serviceClassName ?? 'Classe non renseignée',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetric(
                label: 'Places',
                value: '${departure.seats.available}/${departure.seats.total}',
              ),
              _MiniMetric(
                label: 'Tickets',
                value: '${departure.tickets.issued}/${departure.tickets.total}',
              ),
              _MiniMetric(
                label: 'Validés',
                value:
                    '${departure.validationsAccepted}/${departure.validationsTotal}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE9ECF5),
              valueColor: const AlwaysStoppedAnimation<Color>(_brandPurple),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final StationDeparture departure;

  const _WorkspaceHeader({required this.departure});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 22,
            compact ? 14 : 20,
            8,
            compact ? 14 : 18,
          ),
          color: _brandPurple,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departure.routeLabel.isEmpty
                          ? 'Départ sélectionné'
                          : departure.routeLabel,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${departure.displayTime} · ${departure.serviceClassName ?? 'Classe non renseignée'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Fermer',
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkspaceQuickSummary extends StatelessWidget {
  final StationDeparture departure;
  final StationBoardingSummaryResponse? summary;

  const _WorkspaceQuickSummary({
    required this.departure,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final counts = summary?.summary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _CompactMetric('Tickets', departure.tickets.total.toString()),
            _CompactMetric('Émis', departure.tickets.issued.toString()),
            _CompactMetric(
              'Validés',
              (counts?.boarded ?? departure.validationsAccepted).toString(),
            ),
            _CompactMetric(
              'Restants',
              (counts?.remainingToBoard ?? departure.tickets.remaining)
                  .toString(),
            ),
          ];

          if (constraints.maxWidth < 640) {
            final columns = constraints.maxWidth < 360 ? 1 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          }
          return Row(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index < cards.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  final Widget child;

  const _WorkspaceBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 600 ? 12.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 20),
          child: child,
        );
      },
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.selectedIndex,
    required this.tabs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7F0)),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final selected = index == selectedIndex;
              final color = selected ? Colors.white : _brandPurple;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    constraints: BoxConstraints(minHeight: compact ? 58 : 42),
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 7 : 10,
                      horizontal: compact ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _brandPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: compact
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tab.icon, size: 18, color: color),
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(tab.icon, size: 18, color: color),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ManifestSection extends StatelessWidget {
  final StationBoardingManifestResponse? manifest;
  final TextEditingController searchController;
  final String searchQuery;
  final bool canValidate;
  final Set<String> validatingTicketIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<StationBoardingTicket> onOpenDetail;
  final ValueChanged<StationBoardingTicket> onValidate;

  const _ManifestSection({
    required this.manifest,
    required this.searchController,
    required this.searchQuery,
    required this.canValidate,
    required this.validatingTicketIds,
    required this.onSearchChanged,
    required this.onOpenDetail,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    if (manifest == null) {
      return const _StatePanel(
        icon: Icons.list_alt,
        title: 'Manifeste non disponible',
        message:
            'Le manifeste de ce départ n’est pas disponible pour le moment.',
      );
    }

    final passengers = manifest!.passengers;
    if (passengers.isEmpty) {
      return const _StatePanel(
        icon: Icons.people_outline,
        title: 'Aucun voyageur enregistré',
        message: 'Aucun voyageur enregistré pour ce départ.',
      );
    }

    final visiblePassengers = filterBoardingTickets(passengers, searchQuery);

    return _Panel(
      title: 'Manifeste passagers',
      trailing: Text(
        '${visiblePassengers.length}/${passengers.length}',
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoardingTicketSearchField(
            controller: searchController,
            hintText: 'Rechercher un voyageur, un téléphone ou un billet',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (visiblePassengers.isEmpty)
            const _SearchPrompt(
              icon: Icons.search_off,
              message:
                  'Aucun voyageur ou billet ne correspond à votre recherche.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1040) {
                  return Column(
                    children: visiblePassengers
                        .map(
                          (passenger) => _PassengerCard(
                            passenger: passenger,
                            canValidate: canValidate,
                            isValidating: validatingTicketIds.contains(
                              passenger.id,
                            ),
                            onOpenDetail: () => onOpenDetail(passenger),
                            onValidate: () => onValidate(passenger),
                          ),
                        )
                        .toList(),
                  );
                }

                return _ManifestDesktopList(
                  passengers: visiblePassengers,
                  canValidate: canValidate,
                  validatingTicketIds: validatingTicketIds,
                  onOpenDetail: onOpenDetail,
                  onValidate: onValidate,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ValidationSection extends StatelessWidget {
  final StationBoardingManifestResponse? manifest;
  final TextEditingController searchController;
  final String searchQuery;
  final TextEditingController manualReferenceController;
  final bool isValidatingManual;
  final bool canValidate;
  final Set<String> validatingTicketIds;
  final StationTicketValidation? validation;
  final String? errorMessage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<StationBoardingTicket> onOpenTicketDetail;
  final VoidCallback onOpenValidationDetail;
  final ValueChanged<StationBoardingTicket> onValidateTicket;
  final VoidCallback onValidateManualReference;

  const _ValidationSection({
    required this.manifest,
    required this.searchController,
    required this.searchQuery,
    required this.manualReferenceController,
    required this.isValidatingManual,
    required this.canValidate,
    required this.validatingTicketIds,
    required this.validation,
    required this.errorMessage,
    required this.onSearchChanged,
    required this.onOpenTicketDetail,
    required this.onOpenValidationDetail,
    required this.onValidateTicket,
    required this.onValidateManualReference,
  });

  @override
  Widget build(BuildContext context) {
    if (!canValidate) {
      return const _StatePanel(
        icon: Icons.lock_outline,
        title: 'Validation non autorisée',
        message:
            'Votre profil permet la consultation mais pas la validation des billets.',
      );
    }

    final passengers = manifest?.passengers ?? const <StationBoardingTicket>[];
    final hasQuery = searchQuery.trim().isNotEmpty;
    final visiblePassengers =
        hasQuery ? filterBoardingTickets(passengers, searchQuery) : const [];

    return _Panel(
      title: 'Validation billet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoardingTicketSearchField(
            controller: searchController,
            hintText: 'Rechercher par nom, téléphone, billet ou siège',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 14),
          if (!hasQuery)
            const _SearchPrompt(
              icon: Icons.manage_search,
              message:
                  'Recherchez un voyageur ou saisissez une référence de billet.',
            )
          else if (visiblePassengers.isEmpty)
            const _SearchPrompt(
              icon: Icons.search_off,
              message:
                  'Aucun voyageur ou billet ne correspond à votre recherche.',
            )
          else
            Column(
              children: visiblePassengers
                  .map(
                    (passenger) => _ValidationTicketRow(
                      passenger: passenger,
                      isValidating: validatingTicketIds.contains(passenger.id),
                      onOpenDetail: () => onOpenTicketDetail(passenger),
                      onValidate: () => onValidateTicket(passenger),
                    ),
                  )
                  .toList(),
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            _ValidationResultBox(
              isSuccess: false,
              title: 'Validation refusée',
              message: errorMessage!,
            ),
          ],
          if (validation != null) ...[
            const SizedBox(height: 14),
            _ValidationResultBox(
              isSuccess: validation!.isAccepted,
              title: validation!.isAccepted
                  ? 'Billet validé avec succès.'
                  : validation!.statusLabel,
              message: validation!.resultMessage ??
                  (validation!.isAccepted
                      ? 'Le voyageur peut embarquer sur ce départ.'
                      : 'Le billet n’a pas été accepté pour ce départ.'),
              onOpenDetail: validation!.ticketReference != null ||
                      validation!.travelerFullName.isNotEmpty
                  ? onOpenValidationDetail
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 4),
            leading: const Icon(Icons.keyboard_alt_outlined),
            title: const Text(
              'Saisir la référence complète du billet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Mode secondaire'),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final field = TextField(
                    controller: manualReferenceController,
                    enabled: !isValidatingManual,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isValidatingManual) onValidateManualReference();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Numéro du ticket',
                      hintText: 'TCK-XXXXXXXXXXXX',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      border: OutlineInputBorder(),
                    ),
                  );

                  final button = FilledButton.icon(
                    onPressed:
                        isValidatingManual ? null : onValidateManualReference,
                    icon: isValidatingManual
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified),
                    label: Text(
                      isValidatingManual
                          ? 'Validation...'
                          : 'Valider cette référence',
                    ),
                  );

                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [field, const SizedBox(height: 12), button],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: field),
                      const SizedBox(width: 12),
                      SizedBox(height: 56, child: button),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationTicketRow extends StatelessWidget {
  final StationBoardingTicket passenger;
  final bool isValidating;
  final VoidCallback onOpenDetail;
  final VoidCallback onValidate;

  const _ValidationTicketRow({
    required this.passenger,
    required this.isValidating,
    required this.onOpenDetail,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passenger.displayTraveler.isEmpty
                    ? 'Voyageur'
                    : passenger.displayTraveler,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    label: 'Téléphone',
                    value: passenger.travelerPhone ?? '—',
                  ),
                  _InfoPill(label: 'Ticket', value: passenger.reference),
                  _InfoPill(label: 'Siège', value: passenger.displaySeat),
                  _InfoPill(
                    label: 'Classe',
                    value: passenger.serviceClass ?? '—',
                  ),
                ],
              ),
            ],
          );
          final action = _TicketActions(
            passenger: passenger,
            canValidate: true,
            isValidating: isValidating,
            onOpenDetail: onOpenDetail,
            onValidate: onValidate,
          );

          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _TicketActions extends StatelessWidget {
  final StationBoardingTicket passenger;
  final bool canValidate;
  final bool isValidating;
  final VoidCallback onOpenDetail;
  final VoidCallback onValidate;
  final bool compact;

  const _TicketActions({
    required this.passenger,
    required this.canValidate,
    required this.isValidating,
    required this.onOpenDetail,
    required this.onValidate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenDetail,
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Détail'),
          style: compact
              ? OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                )
              : null,
        ),
        _TicketAction(
          passenger: passenger,
          canValidate: canValidate,
          isValidating: isValidating,
          onValidate: onValidate,
          compact: compact,
        ),
      ],
    );
  }
}

class _TicketAction extends StatelessWidget {
  final StationBoardingTicket passenger;
  final bool canValidate;
  final bool isValidating;
  final VoidCallback onValidate;
  final bool compact;

  const _TicketAction({
    required this.passenger,
    required this.canValidate,
    required this.isValidating,
    required this.onValidate,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (passenger.isBoarded) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: _success),
          SizedBox(width: 6),
          Text('Validé', style: TextStyle(color: _success)),
        ],
      );
    }

    if (!canValidate) {
      return const Text(
        'Consultation',
        style: TextStyle(color: Colors.black54),
      );
    }

    if (!_isTicketEligible(passenger)) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Text(
          passenger.boardingMessage ?? passenger.statusLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: isValidating ? null : onValidate,
      icon: isValidating
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.verified, size: 18),
      label: Text(isValidating ? 'Validation...' : 'Valider'),
      style: compact
          ? FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            )
          : null,
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SearchPrompt({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black45),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationDetail extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Non renseigné' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final StationDeparture departure;
  final StationBoardingSummaryResponse? summary;
  final StationBoardingManifestResponse? manifest;

  const _SummarySection({
    required this.departure,
    required this.summary,
    required this.manifest,
  });

  @override
  Widget build(BuildContext context) {
    final counts = summary?.summary;
    final totalTickets = counts?.totalTickets ?? departure.tickets.total;
    final issued = counts?.issued ?? departure.tickets.issued;
    final boarded = counts?.boarded ?? departure.validationsAccepted;
    final cancelled = counts?.cancelled ?? departure.tickets.cancelled;
    final remaining = counts?.remainingToBoard ?? departure.tickets.remaining;
    final rejected = departure.validationsRejected;
    final rate =
        totalTickets == 0 ? null : (boarded / totalTickets * 100).round();

    return _Panel(
      title: 'Résumé du départ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _SummaryTile(
                  'Tickets total',
                  totalTickets.toString(),
                  Icons.airplane_ticket,
                ),
                _SummaryTile(
                  'Tickets émis',
                  issued.toString(),
                  Icons.fact_check,
                ),
                _SummaryTile(
                  'Tickets validés',
                  boarded.toString(),
                  Icons.how_to_reg,
                ),
                _SummaryTile(
                  'Tickets restants',
                  remaining.toString(),
                  Icons.pending_actions,
                ),
                _SummaryTile(
                  'Tickets annulés',
                  cancelled.toString(),
                  Icons.block,
                ),
                _SummaryTile(
                  'Validations rejetées',
                  rejected.toString(),
                  Icons.report_gmailerrorred,
                ),
                _SummaryTile(
                  'Taux embarquement',
                  rate == null ? '—' : '$rate%',
                  Icons.query_stats,
                ),
              ];
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map((item) => SizedBox(width: width, child: item))
                    .toList(),
              );
            },
          ),
          if (manifest == null) ...[
            const SizedBox(height: 14),
            const Text(
              'Le détail passagers sera affiché dès que le manifeste sera disponible.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _brandPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestDesktopList extends StatelessWidget {
  final List<StationBoardingTicket> passengers;
  final bool canValidate;
  final Set<String> validatingTicketIds;
  final ValueChanged<StationBoardingTicket> onOpenDetail;
  final ValueChanged<StationBoardingTicket> onValidate;

  const _ManifestDesktopList({
    required this.passengers,
    required this.canValidate,
    required this.validatingTicketIds,
    required this.onOpenDetail,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Column(
        children: [
          const _ManifestDesktopHeader(),
          for (var index = 0; index < passengers.length; index++)
            _ManifestDesktopRow(
              passenger: passengers[index],
              canValidate: canValidate,
              isValidating: validatingTicketIds.contains(passengers[index].id),
              showDivider: index < passengers.length - 1,
              onOpenDetail: () => onOpenDetail(passengers[index]),
              onValidate: () => onValidate(passengers[index]),
            ),
        ],
      ),
    );
  }
}

class _ManifestDesktopHeader extends StatelessWidget {
  const _ManifestDesktopHeader();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _softPanel,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            _ManifestColumnLabel('Voyageur', flex: 3),
            _ManifestColumnLabel('Ticket', flex: 2),
            _ManifestColumnLabel('Siège', flex: 1),
            _ManifestColumnLabel('Classe', flex: 2),
            _ManifestColumnLabel('Statut', flex: 2),
            SizedBox(width: 230, child: Text('Actions')),
          ],
        ),
      ),
    );
  }
}

class _ManifestColumnLabel extends StatelessWidget {
  final String label;
  final int flex;

  const _ManifestColumnLabel(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ManifestDesktopRow extends StatelessWidget {
  final StationBoardingTicket passenger;
  final bool canValidate;
  final bool isValidating;
  final bool showDivider;
  final VoidCallback onOpenDetail;
  final VoidCallback onValidate;

  const _ManifestDesktopRow({
    required this.passenger,
    required this.canValidate,
    required this.isValidating,
    required this.showDivider,
    required this.onOpenDetail,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFE5E7F0)))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _ManifestTextGroup(
              primary: passenger.displayTraveler.isEmpty
                  ? 'Voyageur non renseigné'
                  : passenger.displayTraveler,
              secondary: passenger.travelerPhone ?? 'Téléphone non renseigné',
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              passenger.reference,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              passenger.displaySeat,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              passenger.serviceClass ?? 'Non renseignée',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _StatusChip(
                  label: passenger.statusLabel,
                  status: passenger.statusCode,
                ),
                _StatusChip(
                  label: _boardingLabel(passenger),
                  status: _boardingStatus(passenger),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 230,
            child: _TicketActions(
              passenger: passenger,
              canValidate: canValidate,
              isValidating: isValidating,
              onOpenDetail: onOpenDetail,
              onValidate: onValidate,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManifestTextGroup extends StatelessWidget {
  final String primary;
  final String secondary;

  const _ManifestTextGroup({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _PassengerCard extends StatelessWidget {
  final StationBoardingTicket passenger;
  final bool canValidate;
  final bool isValidating;
  final VoidCallback onOpenDetail;
  final VoidCallback onValidate;

  const _PassengerCard({
    required this.passenger,
    required this.canValidate,
    required this.isValidating,
    required this.onOpenDetail,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  passenger.displayTraveler.isEmpty
                      ? 'Voyageur'
                      : passenger.displayTraveler,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(
                label: passenger.statusLabel,
                status: passenger.statusCode,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoPill(
                label: 'Téléphone',
                value: passenger.travelerPhone ?? '—',
              ),
              _InfoPill(label: 'Ticket', value: passenger.reference),
              _InfoPill(label: 'Siège', value: passenger.displaySeat),
              _InfoPill(label: 'Classe', value: passenger.serviceClass ?? '—'),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final status = _StatusChip(
                label: _boardingLabel(passenger),
                status: _boardingStatus(passenger),
              );
              final actions = _TicketActions(
                passenger: passenger,
                canValidate: canValidate,
                isValidating: isValidating,
                onOpenDetail: onOpenDetail,
                onValidate: onValidate,
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    status,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }

              return Row(children: [status, const Spacer(), actions]);
            },
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ValidationResultBox extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback? onOpenDetail;

  const _ValidationResultBox({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? _success : _danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(message),
                if (onOpenDetail != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onOpenDetail,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Voir le détail'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Panel({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: _brandPurple,
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              SizedBox(height: compact ? 12 : 14),
              child,
            ],
          ),
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _brandPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _brandPurple),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 12),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          );
        },
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

class _SoftLoading extends StatelessWidget {
  final String message;

  const _SoftLoading({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _AccessDeniedBoarding extends StatelessWidget {
  const _AccessDeniedBoarding();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _StatePanel(
          icon: Icons.lock_outline,
          title: 'Accès non autorisé',
          message:
              'Votre profil ne dispose pas des droits nécessaires pour utiliser le module embarquement.',
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7F0)),
      ),
      child: Text('$label : ${value.isEmpty ? '—' : value}'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label.isEmpty ? '—' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('ç', 'c');
}

String _classFilterValue(StationDeparture departure) {
  final value = _normalize(
    '${departure.serviceClassCode ?? ''} ${departure.serviceClassName ?? ''}',
  );
  if (value.contains('prestige')) return 'prestige';
  if (value.contains('economie') || value.contains('economy')) {
    return 'economie';
  }
  return 'other';
}

String _statusFilterValue(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('open')) return 'open';
  if (normalized.contains('closed')) return 'closed';
  if (normalized.contains('departed')) return 'departed';
  return normalized.isEmpty ? 'unknown' : normalized;
}

String _shortDepartureStatus(String status, String fallback) {
  final normalized = status.toLowerCase();
  if (normalized.contains('open')) return 'Ouvert';
  if (normalized.contains('scheduled')) return 'Prévu';
  if (normalized.contains('closed')) return 'Fermé';
  if (normalized.contains('departed')) return 'Parti';
  if (normalized.contains('cancel')) return 'Annulé';
  return fallback.isEmpty ? '—' : fallback;
}

String _boardingLabel(StationBoardingTicket passenger) {
  if (passenger.isBoarded) return 'Embarqué';
  if (passenger.canBoard) return 'À valider';
  return 'Non valide';
}

bool _isTicketEligible(StationBoardingTicket passenger) {
  return passenger.canBoard &&
      !passenger.isBoarded &&
      passenger.statusCode.toLowerCase() == 'issued';
}

String _boardingStatus(StationBoardingTicket passenger) {
  if (passenger.isBoarded) return 'accepted';
  if (passenger.canBoard) return 'pending';
  return 'rejected';
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('accepted') ||
      normalized.contains('used') ||
      normalized.contains('open') ||
      normalized.contains('confirm') ||
      normalized.contains('émis')) {
    return _success;
  }
  if (normalized.contains('pending') ||
      normalized.contains('scheduled') ||
      normalized.contains('issued') ||
      normalized.contains('prévu')) {
    return _warning;
  }
  if (normalized.contains('duplicate') ||
      normalized.contains('wrong') ||
      normalized.contains('invalid') ||
      normalized.contains('rejected') ||
      normalized.contains('cancel') ||
      normalized.contains('expired') ||
      normalized.contains('fermé') ||
      normalized.contains('annul')) {
    return _danger;
  }
  return _brandPurple;
}
