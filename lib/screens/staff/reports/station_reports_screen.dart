import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/reports/station_cancellation.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/models/station/reports/station_reports_page.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change.dart';
import 'package:catrans_app/screens/staff/reports/station_cancellation_detail_dialog.dart';
import 'package:catrans_app/screens/staff/reports/station_report_action_dialog.dart';
import 'package:catrans_app/screens/staff/reports/station_report_actions.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_ui_helpers.dart';
import 'package:catrans_app/screens/staff/reports/station_reservation_change_detail_dialog.dart';
import 'package:catrans_app/services/api/station_reports_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

const _brandPurple = Color(0xFF0F056B);
const _softPanel = Color(0xFFF7F8FC);
const _borderColor = Color(0xFFE5E7F0);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);
const _pageSize = 25;

enum _ReportsTab { changes, cancellations }

class StationReportsScreen extends StatefulWidget {
  final User user;

  const StationReportsScreen({super.key, required this.user});

  @override
  State<StationReportsScreen> createState() => _StationReportsScreenState();
}

class _StationReportsScreenState extends State<StationReportsScreen> {
  final _apiService = StationReportsApiService();
  final _changesSearchController = TextEditingController();
  final _cancellationsSearchController = TextEditingController();

  _ReportsTab _selectedTab = _ReportsTab.changes;
  StationReservationChangesPage? _changesPage;
  StationCancellationsPage? _cancellationsPage;
  String? _changesError;
  String? _cancellationsError;
  String? _changesStatus;
  String? _cancellationsStatus;
  DateTime? _changesDateFrom;
  DateTime? _changesDateTo;
  DateTime? _cancellationsDateFrom;
  DateTime? _cancellationsDateTo;
  int _changesPageNumber = 1;
  int _cancellationsPageNumber = 1;
  bool _changesLoading = false;
  bool _cancellationsLoading = false;
  String? _mutatingRequestId;
  _ReportsTab? _mutatingTab;
  StationReportActionKind? _mutatingAction;
  bool _cancellationsLoadedOnce = false;
  Timer? _changesSearchDebounce;
  Timer? _cancellationsSearchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadChanges();
    });
  }

  @override
  void dispose() {
    _changesSearchDebounce?.cancel();
    _cancellationsSearchDebounce?.cancel();
    _changesSearchController.dispose();
    _cancellationsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser ?? widget.user;
    if (!_canReadReports(currentUser)) {
      return const _AccessDeniedReports();
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth >= 900
              ? 24.0
              : constraints.maxWidth >= 560
                  ? 18.0
                  : 12.0;
          final gap = constraints.maxWidth < 560 ? 14.0 : 18.0;

          return ListView(
            padding: EdgeInsets.all(padding),
            children: [
              _Header(
                user: currentUser,
                isRefreshing: _currentLoading,
                onRefresh: _currentLoading ? null : _refreshCurrentTab,
              ),
              SizedBox(height: gap),
              _Tabs(
                selectedTab: _selectedTab,
                changesCount: _changesPage?.count,
                cancellationsCount: _cancellationsPage?.count,
                onSelected: _selectTab,
              ),
              SizedBox(height: gap),
              _FiltersPanel(
                controller: _activeSearchController,
                selectedStatus: _activeStatus,
                dateFrom: _activeDateFrom,
                dateTo: _activeDateTo,
                isLoading: _currentLoading,
                errorMessage: _activeError,
                onSearchChanged: _onSearchChanged,
                onSearchSubmitted: _searchCurrentTab,
                onStatusChanged: _onStatusChanged,
                onPickDateFrom: () => _pickDate(isFrom: true),
                onPickDateTo: () => _pickDate(isFrom: false),
                onClearDateFrom: () => _clearDate(isFrom: true),
                onClearDateTo: () => _clearDate(isFrom: false),
                onReset: _resetCurrentFilters,
              ),
              SizedBox(height: gap),
              _buildContent(),
            ],
          );
        },
      ),
    );
  }

  bool get _currentLoading => switch (_selectedTab) {
        _ReportsTab.changes => _changesLoading,
        _ReportsTab.cancellations => _cancellationsLoading,
      };

  String? get _activeError => switch (_selectedTab) {
        _ReportsTab.changes => _changesError,
        _ReportsTab.cancellations => _cancellationsError,
      };

  String? get _activeStatus => switch (_selectedTab) {
        _ReportsTab.changes => _changesStatus,
        _ReportsTab.cancellations => _cancellationsStatus,
      };

  DateTime? get _activeDateFrom => switch (_selectedTab) {
        _ReportsTab.changes => _changesDateFrom,
        _ReportsTab.cancellations => _cancellationsDateFrom,
      };

  DateTime? get _activeDateTo => switch (_selectedTab) {
        _ReportsTab.changes => _changesDateTo,
        _ReportsTab.cancellations => _cancellationsDateTo,
      };

  TextEditingController get _activeSearchController => switch (_selectedTab) {
        _ReportsTab.changes => _changesSearchController,
        _ReportsTab.cancellations => _cancellationsSearchController,
      };

  bool _canReadReports(User user) {
    return user.isSuperuser || user.scopes.contains('station.reports.manage');
  }

  Future<void> _refreshCurrentTab() async {
    if (_selectedTab == _ReportsTab.changes) {
      await _loadChanges(keepData: true);
    } else {
      await _loadCancellations(keepData: true);
    }
  }

  void _selectTab(_ReportsTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    if (tab == _ReportsTab.cancellations && !_cancellationsLoadedOnce) {
      _loadCancellations();
    }
  }

  Future<void> _loadChanges({bool keepData = false, int? page}) async {
    if (_changesLoading) return;
    if (!_validateDateRange(
      _changesDateFrom,
      _changesDateTo,
      _ReportsTab.changes,
    )) {
      return;
    }

    setState(() {
      _changesLoading = true;
      _changesError = null;
      if (page != null) _changesPageNumber = page;
    });

    try {
      final response = await _apiService.getReservationChanges(
        page: _changesPageNumber,
        pageSize: _pageSize,
        status: _changesStatus,
        search: _changesSearchController.text,
        dateFrom: _changesDateFrom,
        dateTo: _changesDateTo,
      );
      if (!mounted) return;
      setState(() {
        _changesPage = response;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!keepData) _changesPage = null;
        _changesError = _messageFromError(error, 'reports');
      });
    } finally {
      if (mounted) setState(() => _changesLoading = false);
    }
  }

  Future<void> _loadCancellations({bool keepData = false, int? page}) async {
    if (_cancellationsLoading) return;
    if (!_validateDateRange(
      _cancellationsDateFrom,
      _cancellationsDateTo,
      _ReportsTab.cancellations,
    )) {
      return;
    }

    setState(() {
      _cancellationsLoading = true;
      _cancellationsError = null;
      if (page != null) _cancellationsPageNumber = page;
    });

    try {
      final response = await _apiService.getCancellations(
        page: _cancellationsPageNumber,
        pageSize: _pageSize,
        status: _cancellationsStatus,
        search: _cancellationsSearchController.text,
        dateFrom: _cancellationsDateFrom,
        dateTo: _cancellationsDateTo,
      );
      if (!mounted) return;
      setState(() {
        _cancellationsPage = response;
        _cancellationsLoadedOnce = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!keepData) _cancellationsPage = null;
        _cancellationsError = _messageFromError(error, 'annulations');
        _cancellationsLoadedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _cancellationsLoading = false);
    }
  }

  bool _validateDateRange(DateTime? from, DateTime? to, _ReportsTab tab) {
    if (from == null || to == null || !from.isAfter(to)) return true;
    setState(() {
      const message = 'La date de début ne peut pas être après la date de fin.';
      if (tab == _ReportsTab.changes) {
        _changesError = message;
      } else {
        _cancellationsError = message;
      }
    });
    return false;
  }

  void _onSearchChanged(String value) {
    final debounce = _selectedTab == _ReportsTab.changes
        ? _changesSearchDebounce
        : _cancellationsSearchDebounce;
    debounce?.cancel();

    final nextDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _searchCurrentTab();
    });

    if (_selectedTab == _ReportsTab.changes) {
      _changesSearchDebounce = nextDebounce;
    } else {
      _cancellationsSearchDebounce = nextDebounce;
    }
  }

  void _searchCurrentTab() {
    if (_selectedTab == _ReportsTab.changes) {
      setState(() => _changesPageNumber = 1);
      _loadChanges();
    } else {
      setState(() => _cancellationsPageNumber = 1);
      _loadCancellations();
    }
  }

  void _onStatusChanged(String? value) {
    final normalized = value == 'all' ? null : value;
    if (_selectedTab == _ReportsTab.changes) {
      if (_changesStatus == normalized) return;
      setState(() {
        _changesStatus = normalized;
        _changesPageNumber = 1;
      });
      _loadChanges();
    } else {
      if (_cancellationsStatus == normalized) return;
      setState(() {
        _cancellationsStatus = normalized;
        _cancellationsPageNumber = 1;
      });
      _loadCancellations();
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _activeDateFrom : _activeDateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (_selectedTab == _ReportsTab.changes) {
        if (isFrom) {
          _changesDateFrom = picked;
        } else {
          _changesDateTo = picked;
        }
        _changesPageNumber = 1;
      } else {
        if (isFrom) {
          _cancellationsDateFrom = picked;
        } else {
          _cancellationsDateTo = picked;
        }
        _cancellationsPageNumber = 1;
      }
    });
    _searchCurrentTab();
  }

  void _clearDate({required bool isFrom}) {
    setState(() {
      if (_selectedTab == _ReportsTab.changes) {
        if (isFrom) {
          _changesDateFrom = null;
        } else {
          _changesDateTo = null;
        }
        _changesPageNumber = 1;
      } else {
        if (isFrom) {
          _cancellationsDateFrom = null;
        } else {
          _cancellationsDateTo = null;
        }
        _cancellationsPageNumber = 1;
      }
    });
    _searchCurrentTab();
  }

  void _resetCurrentFilters() {
    if (_selectedTab == _ReportsTab.changes) {
      _changesSearchDebounce?.cancel();
      _changesSearchController.clear();
      setState(() {
        _changesStatus = null;
        _changesDateFrom = null;
        _changesDateTo = null;
        _changesPageNumber = 1;
      });
      _loadChanges();
    } else {
      _cancellationsSearchDebounce?.cancel();
      _cancellationsSearchController.clear();
      setState(() {
        _cancellationsStatus = null;
        _cancellationsDateFrom = null;
        _cancellationsDateTo = null;
        _cancellationsPageNumber = 1;
      });
      _loadCancellations();
    }
  }

  void _previousPage() {
    if (_selectedTab == _ReportsTab.changes) {
      if (_changesPageNumber <= 1) return;
      _loadChanges(page: _changesPageNumber - 1, keepData: true);
    } else {
      if (_cancellationsPageNumber <= 1) return;
      _loadCancellations(page: _cancellationsPageNumber - 1, keepData: true);
    }
  }

  void _nextPage() {
    if (_selectedTab == _ReportsTab.changes) {
      _loadChanges(page: _changesPageNumber + 1, keepData: true);
    } else {
      _loadCancellations(page: _cancellationsPageNumber + 1, keepData: true);
    }
  }

  Future<void> _openChangeDetail(StationReservationChange change) async {
    final requestedAction = await showStationReservationChangeDetailDialog(
      context: context,
      change: change,
      loadDetail: _apiService.getReservationChangeDetail,
      mutatingRequestId: _mutatingRequestId,
      mutatingAction: _mutatingAction,
    );
    if (!mounted || requestedAction == null) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _requestChangeAction(
      requestedAction.change,
      requestedAction.action,
    );
  }

  Future<void> _openCancellationDetail(StationCancellation cancellation) async {
    final requestedAction = await showStationCancellationDetailDialog(
      context: context,
      cancellation: cancellation,
      loadDetail: _apiService.getCancellationDetail,
      mutatingRequestId: _mutatingRequestId,
      mutatingAction: _mutatingAction,
    );
    if (!mounted || requestedAction == null) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _requestCancellationAction(
      requestedAction.cancellation,
      requestedAction.action,
    );
  }

  Future<void> _requestChangeAction(
    StationReservationChange change,
    StationReportActionKind action,
  ) async {
    if (_mutatingRequestId != null) return;
    if (!canShowStationReportAction(
      availableActions: change.availableActions,
      eligibility: change.eligibility,
      action: action,
    )) {
      _showMessage(stationReportEligibilityMessage(change.eligibility));
      return;
    }

    final result = await showStationReportActionDialog(
      context: context,
      data: StationReportActionDialogData.fromChange(change, action),
    );
    if (!mounted || result == null) return;

    setState(() {
      _mutatingRequestId = change.id;
      _mutatingTab = _ReportsTab.changes;
      _mutatingAction = action;
    });

    try {
      switch (action) {
        case StationReportActionKind.approve:
          await _apiService.approveReservationChange(change.id);
          break;
        case StationReportActionKind.reject:
          await _apiService.rejectReservationChange(change.id, result.reason!);
          break;
        case StationReportActionKind.apply:
          await _apiService.applyReservationChange(change.id);
          break;
      }
      if (!mounted) return;
      await _reloadChangesAfterMutation();
      if (!mounted) return;
      _showMessage(
        stationReportSuccessMessage(StationReportRequestKind.report, action),
      );
    } catch (error) {
      final message = stationReportMutationErrorMessage(error);
      if (shouldRefreshAfterStationReportMutationError(error)) {
        await _loadChanges(keepData: true);
      }
      if (mounted) _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _mutatingRequestId = null;
          _mutatingTab = null;
          _mutatingAction = null;
        });
      }
    }
  }

  Future<void> _requestCancellationAction(
    StationCancellation cancellation,
    StationReportActionKind action,
  ) async {
    if (_mutatingRequestId != null) return;
    if (!canShowStationReportAction(
      availableActions: cancellation.availableActions,
      eligibility: cancellation.eligibility,
      action: action,
    )) {
      _showMessage(stationReportEligibilityMessage(cancellation.eligibility));
      return;
    }

    final result = await showStationReportActionDialog(
      context: context,
      data:
          StationReportActionDialogData.fromCancellation(cancellation, action),
    );
    if (!mounted || result == null) return;

    setState(() {
      _mutatingRequestId = cancellation.id;
      _mutatingTab = _ReportsTab.cancellations;
      _mutatingAction = action;
    });

    try {
      switch (action) {
        case StationReportActionKind.approve:
          await _apiService.approveCancellation(cancellation.id);
          break;
        case StationReportActionKind.reject:
          await _apiService.rejectCancellation(cancellation.id, result.reason!);
          break;
        case StationReportActionKind.apply:
          await _apiService.applyCancellation(cancellation.id);
          break;
      }
      if (!mounted) return;
      await _reloadCancellationsAfterMutation();
      if (!mounted) return;
      _showMessage(
        stationReportSuccessMessage(
          StationReportRequestKind.cancellation,
          action,
        ),
      );
    } catch (error) {
      final message = stationReportMutationErrorMessage(error);
      if (shouldRefreshAfterStationReportMutationError(error)) {
        await _loadCancellations(keepData: true);
      }
      if (mounted) _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _mutatingRequestId = null;
          _mutatingTab = null;
          _mutatingAction = null;
        });
      }
    }
  }

  Future<void> _reloadChangesAfterMutation() async {
    final nextPage = pageAfterStationReportMutation(
      currentPage: _changesPageNumber,
      currentResultCount: _changesPage?.results.length ?? 0,
    );
    if (nextPage != _changesPageNumber) {
      setState(() => _changesPageNumber = nextPage);
    }
    await _loadChanges(keepData: true);
  }

  Future<void> _reloadCancellationsAfterMutation() async {
    final nextPage = pageAfterStationReportMutation(
      currentPage: _cancellationsPageNumber,
      currentResultCount: _cancellationsPage?.results.length ?? 0,
    );
    if (nextPage != _cancellationsPageNumber) {
      setState(() => _cancellationsPageNumber = nextPage);
    }
    await _loadCancellations(keepData: true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFromError(Object error, String moduleLabel) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'Les filtres de recherche sont invalides.';
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’avez pas accès aux $moduleLabel de cette gare.';
        case 404:
          return 'La ressource demandée n’est plus accessible.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }
    return 'Impossible de charger les $moduleLabel.';
  }

  Widget _buildContent() {
    if (_selectedTab == _ReportsTab.changes) {
      if (_changesLoading && _changesPage == null) {
        return const _LoadingPanel(message: 'Chargement des reports...');
      }
      if (_changesError != null && _changesPage == null) {
        return _StatePanel(
          icon: Icons.error_outline,
          title: 'Reports indisponibles',
          message: _changesError!,
          actionLabel: 'Réessayer',
          onAction: _loadChanges,
        );
      }
      final page = _changesPage;
      if (page == null) {
        return _StatePanel(
          icon: Icons.edit_calendar,
          title: 'Reports / annulations',
          message: 'Les demandes de report de la gare apparaîtront ici.',
          actionLabel: 'Actualiser',
          onAction: _loadChanges,
        );
      }
      if (page.results.isEmpty) {
        return _StatePanel(
          icon: Icons.inbox_outlined,
          title: 'Aucun report',
          message:
              'Aucune demande de report ne correspond aux critères sélectionnés.',
          actionLabel: 'Réinitialiser',
          onAction: _resetCurrentFilters,
        );
      }
      return Column(
        children: [
          if (_changesError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _InlineError(
                  message: _changesError!, onRetry: _refreshCurrentTab),
            ),
          _ChangesPanel(
            page: page,
            pageNumber: _changesPageNumber,
            isRefreshing: _changesLoading,
            onOpenDetail: _openChangeDetail,
            onAction: _requestChangeAction,
            mutatingRequestId: _mutatingRequestId,
            mutatingTab: _mutatingTab,
            mutatingAction: _mutatingAction,
          ),
          const SizedBox(height: 14),
          _PaginationBar(
            count: page.count,
            currentPage: _changesPageNumber,
            pageSize: _pageSize,
            hasPrevious: page.hasPrevious,
            hasNext: page.hasNext,
            isLoading: _changesLoading,
            onPrevious: _previousPage,
            onNext: _nextPage,
          ),
        ],
      );
    }

    if (_cancellationsLoading && _cancellationsPage == null) {
      return const _LoadingPanel(message: 'Chargement des annulations...');
    }
    if (_cancellationsError != null && _cancellationsPage == null) {
      return _StatePanel(
        icon: Icons.error_outline,
        title: 'Annulations indisponibles',
        message: _cancellationsError!,
        actionLabel: 'Réessayer',
        onAction: _loadCancellations,
      );
    }
    final page = _cancellationsPage;
    if (page == null) {
      return _StatePanel(
        icon: Icons.assignment_return,
        title: 'Annulations',
        message: 'Les demandes d’annulation de la gare apparaîtront ici.',
        actionLabel: 'Actualiser',
        onAction: _loadCancellations,
      );
    }
    if (page.results.isEmpty) {
      return _StatePanel(
        icon: Icons.inbox_outlined,
        title: 'Aucune annulation',
        message:
            'Aucune demande d’annulation ne correspond aux critères sélectionnés.',
        actionLabel: 'Réinitialiser',
        onAction: _resetCurrentFilters,
      );
    }
    return Column(
      children: [
        if (_cancellationsError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _InlineError(
                message: _cancellationsError!, onRetry: _refreshCurrentTab),
          ),
        _CancellationsPanel(
          page: page,
          pageNumber: _cancellationsPageNumber,
          isRefreshing: _cancellationsLoading,
          onOpenDetail: _openCancellationDetail,
          onAction: _requestCancellationAction,
          mutatingRequestId: _mutatingRequestId,
          mutatingTab: _mutatingTab,
          mutatingAction: _mutatingAction,
        ),
        const SizedBox(height: 14),
        _PaginationBar(
          count: page.count,
          currentPage: _cancellationsPageNumber,
          pageSize: _pageSize,
          hasPrevious: page.hasPrevious,
          hasNext: page.hasNext,
          isLoading: _cancellationsLoading,
          onPrevious: _previousPage,
          onNext: _nextPage,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final User user;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;

  const _Header({
    required this.user,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final station = user.internalProfile?.station?.name ?? 'Gare rattachée';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports / annulations',
                style: TextStyle(
                    color: _brandPurple,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '$station - consultation des demandes voyageur liées à la gare.',
                maxLines: isNarrow ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: onRefresh,
            style: FilledButton.styleFrom(
              backgroundColor: _brandPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Actualiser'),
          );

          if (isNarrow) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 16), action]);
          }

          return Row(children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            action
          ]);
        },
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final _ReportsTab selectedTab;
  final int? changesCount;
  final int? cancellationsCount;
  final ValueChanged<_ReportsTab> onSelected;

  const _Tabs({
    required this.selectedTab,
    required this.changesCount,
    required this.cancellationsCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final children = [
            _TabButton(
              label: 'Reports',
              count: changesCount,
              icon: Icons.edit_calendar,
              selected: selectedTab == _ReportsTab.changes,
              onTap: () => onSelected(_ReportsTab.changes),
            ),
            _TabButton(
              label: 'Annulations',
              count: cancellationsCount,
              icon: Icons.assignment_return,
              selected: selectedTab == _ReportsTab.cancellations,
              onTap: () => onSelected(_ReportsTab.cancellations),
            ),
          ];

          if (isNarrow) {
            return Column(children: [
              children[0],
              const SizedBox(height: 8),
              children[1]
            ]);
          }

          return Row(children: [
            Expanded(child: children[0]),
            const SizedBox(width: 8),
            Expanded(child: children[1])
          ]);
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int? count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _brandPurple : _softPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _brandPurple : _borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : _brandPurple, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == null ? label : '$label ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final TextEditingController controller;
  final String? selectedStatus;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickDateFrom;
  final VoidCallback onPickDateTo;
  final VoidCallback onClearDateFrom;
  final VoidCallback onClearDateTo;
  final VoidCallback onReset;

  const _FiltersPanel({
    required this.controller,
    required this.selectedStatus,
    required this.dateFrom,
    required this.dateTo,
    required this.isLoading,
    required this.errorMessage,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onStatusChanged,
    required this.onPickDateFrom,
    required this.onPickDateTo,
    required this.onClearDateFrom,
    required this.onClearDateTo,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            enabled: !isLoading,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            onSubmitted: (_) => onSearchSubmitted(),
            decoration: const InputDecoration(
              hintText:
                  'Référence demande, réservation, téléphone ou client...',
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
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      isDense: true),
                  items: const [
                    DropdownMenuItem<String>(value: null, child: Text('Tous')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('En attente')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Approuvé')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
                    DropdownMenuItem(value: 'applied', child: Text('Appliqué')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                  ],
                  onChanged: isLoading ? null : onStatusChanged,
                ),
              ),
              _DateFilterButton(
                  label: 'Début',
                  date: dateFrom,
                  onPick: onPickDateFrom,
                  onClear: onClearDateFrom,
                  enabled: !isLoading),
              _DateFilterButton(
                  label: 'Fin',
                  date: dateTo,
                  onPick: onPickDateTo,
                  onClear: onClearDateTo,
                  enabled: !isLoading),
              FilledButton.icon(
                onPressed: isLoading ? null : onSearchSubmitted,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: const Text('Rechercher'),
              ),
              TextButton.icon(
                onPressed: isLoading ? null : onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(errorMessage!, style: const TextStyle(color: _danger)),
          ],
        ],
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(date == null ? label : formatStationReportDate(date)),
        ),
        if (date != null)
          IconButton(
            tooltip: 'Effacer $label',
            onPressed: enabled ? onClear : null,
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    );
  }
}

class _ChangesPanel extends StatelessWidget {
  final StationReservationChangesPage page;
  final int pageNumber;
  final bool isRefreshing;
  final ValueChanged<StationReservationChange> onOpenDetail;
  final void Function(StationReservationChange, StationReportActionKind)
      onAction;
  final String? mutatingRequestId;
  final _ReportsTab? mutatingTab;
  final StationReportActionKind? mutatingAction;

  const _ChangesPanel({
    required this.page,
    required this.pageNumber,
    required this.isRefreshing,
    required this.onOpenDetail,
    required this.onAction,
    required this.mutatingRequestId,
    required this.mutatingTab,
    required this.mutatingAction,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Demandes de report',
      trailing: isRefreshing ? const _SmallProgress() : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1080) {
            return Column(
              children: page.results
                  .map((change) => _ChangeMobileCard(
                      change: change,
                      onOpenDetail: onOpenDetail,
                      onAction: onAction,
                      isMutating: mutatingTab == _ReportsTab.changes &&
                          mutatingRequestId == change.id,
                      mutatingAction: mutatingAction))
                  .toList(),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1120),
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 14,
                dataRowMinHeight: 76,
                dataRowMaxHeight: 90,
                headingRowColor: WidgetStateProperty.all(_softPanel),
                columns: const [
                  DataColumn(label: Text('Demande')),
                  DataColumn(label: Text('Réservation')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Report')),
                  DataColumn(label: Text('Trajets')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: page.results.map((change) => _changeRow(change)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _changeRow(StationReservationChange change) {
    return DataRow(
      cells: [
        DataCell(_ReferenceCell(
            reference: change.reference,
            subtitle: formatStationReportDateTime(change.requestedAt))),
        DataCell(_TextCell(
            primary: change.reservationReference,
            secondary: '${change.itemsCount} voyageur(s)')),
        DataCell(_TextCell(
            primary: change.customerName ?? 'Client',
            secondary: change.customerPhone)),
        DataCell(_TextCell(
            primary: change.changeTypeLabel, secondary: _dash(change.reason))),
        DataCell(_TextCell(
            primary: change.currentDepartureSummary?.routeLabel ?? '-',
            secondary: change.requestedDepartureSummary?.routeLabel ?? '-')),
        DataCell(_StatusEligibilityCell(
            status: change.status,
            statusLabel: change.statusLabel,
            eligibility: change.eligibility)),
        DataCell(_RequestActions(
          kind: StationReportRequestKind.report,
          availableActions: change.availableActions,
          eligibility: change.eligibility,
          isMutating: mutatingTab == _ReportsTab.changes &&
              mutatingRequestId == change.id,
          mutatingAction: mutatingAction,
          onOpenDetail: () => onOpenDetail(change),
          onAction: (action) => onAction(change, action),
        )),
      ],
    );
  }
}

class _CancellationsPanel extends StatelessWidget {
  final StationCancellationsPage page;
  final int pageNumber;
  final bool isRefreshing;
  final ValueChanged<StationCancellation> onOpenDetail;
  final void Function(StationCancellation, StationReportActionKind) onAction;
  final String? mutatingRequestId;
  final _ReportsTab? mutatingTab;
  final StationReportActionKind? mutatingAction;

  const _CancellationsPanel({
    required this.page,
    required this.pageNumber,
    required this.isRefreshing,
    required this.onOpenDetail,
    required this.onAction,
    required this.mutatingRequestId,
    required this.mutatingTab,
    required this.mutatingAction,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Demandes d’annulation',
      trailing: isRefreshing ? const _SmallProgress() : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1040) {
            return Column(
              children: page.results
                  .map((cancellation) => _CancellationMobileCard(
                      cancellation: cancellation,
                      onOpenDetail: onOpenDetail,
                      onAction: onAction,
                      isMutating: mutatingTab == _ReportsTab.cancellations &&
                          mutatingRequestId == cancellation.id,
                      mutatingAction: mutatingAction))
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
                dataRowMinHeight: 76,
                dataRowMaxHeight: 90,
                headingRowColor: WidgetStateProperty.all(_softPanel),
                columns: const [
                  DataColumn(label: Text('Demande')),
                  DataColumn(label: Text('Réservation')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Volume')),
                  DataColumn(label: Text('Montant')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: page.results
                    .map((cancellation) => _cancellationRow(cancellation))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _cancellationRow(StationCancellation cancellation) {
    return DataRow(
      cells: [
        DataCell(_ReferenceCell(
            reference: cancellation.reference,
            subtitle: formatStationReportDateTime(cancellation.requestedAt))),
        DataCell(_TextCell(
            primary: cancellation.reservationReference,
            secondary: 'Annulation complète')),
        DataCell(_TextCell(
            primary: cancellation.customerName ?? 'Client',
            secondary: cancellation.customerPhone)),
        DataCell(_TextCell(
            primary: '${cancellation.travelersCount} voyageur(s)',
            secondary: '${cancellation.ticketsCount} ticket(s)')),
        DataCell(_TextCell(
            primary: cancellation.displayAmount,
            secondary: cancellation.currency)),
        DataCell(_StatusEligibilityCell(
            status: cancellation.status,
            statusLabel: cancellation.statusLabel,
            eligibility: cancellation.eligibility)),
        DataCell(_RequestActions(
          kind: StationReportRequestKind.cancellation,
          availableActions: cancellation.availableActions,
          eligibility: cancellation.eligibility,
          isMutating: mutatingTab == _ReportsTab.cancellations &&
              mutatingRequestId == cancellation.id,
          mutatingAction: mutatingAction,
          onOpenDetail: () => onOpenDetail(cancellation),
          onAction: (action) => onAction(cancellation, action),
        )),
      ],
    );
  }
}

class _ChangeMobileCard extends StatelessWidget {
  final StationReservationChange change;
  final ValueChanged<StationReservationChange> onOpenDetail;
  final void Function(StationReservationChange, StationReportActionKind)
      onAction;
  final bool isMutating;
  final StationReportActionKind? mutatingAction;

  const _ChangeMobileCard({
    required this.change,
    required this.onOpenDetail,
    required this.onAction,
    required this.isMutating,
    required this.mutatingAction,
  });

  @override
  Widget build(BuildContext context) {
    return _RequestCard(
      reference: change.reference,
      reservationReference: change.reservationReference,
      customerName: change.customerName,
      customerPhone: change.customerPhone,
      requestedAt: change.requestedAt,
      status: change.status,
      statusLabel: change.statusLabel,
      eligibility: change.eligibility,
      rows: [
        _InfoLine('Type', change.changeTypeLabel),
        _InfoLine('Actuel', change.currentDepartureSummary?.routeLabel ?? '-'),
        _InfoLine(
            'Demandé', change.requestedDepartureSummary?.routeLabel ?? '-'),
        _InfoLine('Voyageurs', change.itemsCount.toString()),
      ],
      onOpenDetail: () => onOpenDetail(change),
      mutationActions: _MutationActions(
        kind: StationReportRequestKind.report,
        availableActions: change.availableActions,
        eligibility: change.eligibility,
        isMutating: isMutating,
        mutatingAction: mutatingAction,
        onAction: (action) => onAction(change, action),
      ),
    );
  }
}

class _CancellationMobileCard extends StatelessWidget {
  final StationCancellation cancellation;
  final ValueChanged<StationCancellation> onOpenDetail;
  final void Function(StationCancellation, StationReportActionKind) onAction;
  final bool isMutating;
  final StationReportActionKind? mutatingAction;

  const _CancellationMobileCard({
    required this.cancellation,
    required this.onOpenDetail,
    required this.onAction,
    required this.isMutating,
    required this.mutatingAction,
  });

  @override
  Widget build(BuildContext context) {
    return _RequestCard(
      reference: cancellation.reference,
      reservationReference: cancellation.reservationReference,
      customerName: cancellation.customerName,
      customerPhone: cancellation.customerPhone,
      requestedAt: cancellation.requestedAt,
      status: cancellation.status,
      statusLabel: cancellation.statusLabel,
      eligibility: cancellation.eligibility,
      rows: [
        const _InfoLine('Portée', 'Annulation complète'),
        _InfoLine('Voyageurs', cancellation.travelersCount.toString()),
        _InfoLine('Tickets', cancellation.ticketsCount.toString()),
        _InfoLine('Montant', cancellation.displayAmount),
      ],
      onOpenDetail: () => onOpenDetail(cancellation),
      mutationActions: _MutationActions(
        kind: StationReportRequestKind.cancellation,
        availableActions: cancellation.availableActions,
        eligibility: cancellation.eligibility,
        isMutating: isMutating,
        mutatingAction: mutatingAction,
        onAction: (action) => onAction(cancellation, action),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String reference;
  final String reservationReference;
  final String? customerName;
  final String customerPhone;
  final DateTime? requestedAt;
  final String status;
  final String statusLabel;
  final dynamic eligibility;
  final List<_InfoLine> rows;
  final VoidCallback onOpenDetail;
  final Widget mutationActions;

  const _RequestCard({
    required this.reference,
    required this.reservationReference,
    required this.customerName,
    required this.customerPhone,
    required this.requestedAt,
    required this.status,
    required this.statusLabel,
    required this.eligibility,
    required this.rows,
    required this.onOpenDetail,
    required this.mutationActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _ReferenceCell(
                      reference: reference,
                      subtitle: formatStationReportDateTime(requestedAt))),
              const SizedBox(width: 8),
              _DetailButton(onPressed: onOpenDetail, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 18, runSpacing: 10, children: [
            _MiniCell(label: 'Réservation', value: reservationReference),
            _MiniCell(label: 'Client', value: customerName ?? 'Client'),
            _MiniCell(label: 'Téléphone', value: customerPhone),
          ]),
          const SizedBox(height: 10),
          Wrap(
              spacing: 18,
              runSpacing: 10,
              children: rows
                  .map((row) => _MiniCell(label: row.label, value: row.value))
                  .toList()),
          const SizedBox(height: 10),
          _StatusEligibilityCell(
              status: status,
              statusLabel: statusLabel,
              eligibility: eligibility),
          const SizedBox(height: 10),
          mutationActions,
        ],
      ),
    );
  }
}

class _InfoLine {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);
}

class _ReferenceCell extends StatelessWidget {
  final String reference;
  final String subtitle;

  const _ReferenceCell({required this.reference, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: reference,
            child: Text(reference,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: _brandPurple)),
          ),
          const SizedBox(height: 3),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String primary;
  final String? secondary;

  const _TextCell({required this.primary, this.secondary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: primary,
            child: Text(primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (secondary != null && secondary!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Tooltip(
              message: secondary!,
              child: Text(secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniCell extends StatelessWidget {
  final String label;
  final String value;

  const _MiniCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusEligibilityCell extends StatelessWidget {
  final String status;
  final String statusLabel;
  final dynamic eligibility;

  const _StatusEligibilityCell({
    required this.status,
    required this.statusLabel,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    final eligible = eligibility.isEligible == true;
    return SizedBox(
      width: 160,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _Badge(
              label: stationReportStatusLabel(status, statusLabel),
              color: _toneColor(stationReportStatusTone(status))),
          _Badge(
              label: eligible ? 'Éligible' : 'Non éligible',
              color: eligible ? _success : _warning),
        ],
      ),
    );
  }
}

class _RequestActions extends StatelessWidget {
  final StationReportRequestKind kind;
  final StationReportAvailableActions availableActions;
  final StationReportEligibility eligibility;
  final bool isMutating;
  final StationReportActionKind? mutatingAction;
  final VoidCallback onOpenDetail;
  final ValueChanged<StationReportActionKind> onAction;

  const _RequestActions({
    required this.kind,
    required this.availableActions,
    required this.eligibility,
    required this.isMutating,
    required this.mutatingAction,
    required this.onOpenDetail,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DetailButton(onPressed: isMutating ? null : onOpenDetail),
        _MutationActions(
          kind: kind,
          availableActions: availableActions,
          eligibility: eligibility,
          isMutating: isMutating,
          mutatingAction: mutatingAction,
          onAction: onAction,
        ),
      ],
    );
  }
}

class _MutationActions extends StatelessWidget {
  final StationReportRequestKind kind;
  final StationReportAvailableActions availableActions;
  final StationReportEligibility eligibility;
  final bool isMutating;
  final StationReportActionKind? mutatingAction;
  final ValueChanged<StationReportActionKind> onAction;

  const _MutationActions({
    required this.kind,
    required this.availableActions,
    required this.eligibility,
    required this.isMutating,
    required this.mutatingAction,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = visibleStationReportActions(
      availableActions: availableActions,
      eligibility: eligibility,
      isMutating: false,
    );
    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          _MutationActionButton(
            kind: kind,
            action: action,
            isLoading: isMutating && mutatingAction == action,
            isDisabled: isMutating,
            onPressed: () => onAction(action),
          ),
      ],
    );
  }
}

class _MutationActionButton extends StatelessWidget {
  final StationReportRequestKind kind;
  final StationReportActionKind action;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _MutationActionButton({
    required this.kind,
    required this.action,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = action.labelFor(kind);
    final child = isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(action.icon, size: 18);

    if (action == StationReportActionKind.approve) {
      return FilledButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: child,
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: action.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: child,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: action.color,
        side: BorderSide(color: action.color.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool compact;

  const _DetailButton({required this.onPressed, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton.filledTonal(
        tooltip: 'Ouvrir le détail',
        onPressed: onPressed,
        icon: const Icon(Icons.visibility_outlined),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('Détail'),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _brandPurple))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
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
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PaginationBar({
    required this.count,
    required this.currentPage,
    required this.pageSize,
    required this.hasPrevious,
    required this.hasNext,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = count <= 0 ? 1 : (count / pageSize).ceil();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text('$count résultat(s) • Page $currentPage/$totalPages',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton.outlined(
            tooltip: 'Page précédente',
            onPressed: isLoading || !hasPrevious || currentPage <= 1
                ? null
                : onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Page suivante',
            onPressed: isLoading || !hasNext ? null : onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _danger.withValues(alpha: 0.18)),
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

class _LoadingPanel extends StatelessWidget {
  final String message;

  const _LoadingPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.hourglass_top,
      title: message,
      message: 'Les demandes de la gare sont en cours de chargement.',
      showProgress: true,
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 42, color: _brandPurple),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
          if (showProgress) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _AccessDeniedReports extends StatelessWidget {
  const _AccessDeniedReports();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _StatePanel(
          icon: Icons.lock_outline,
          title: 'Accès refusé',
          message:
              'Votre profil ne permet pas de consulter les reports et annulations de la gare.',
        ),
      ],
    );
  }
}

class _SmallProgress extends StatelessWidget {
  const _SmallProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

Color _toneColor(String tone) {
  return switch (tone) {
    'success' => _success,
    'warning' => _warning,
    'danger' => _danger,
    'info' => _brandPurple,
    _ => Colors.blueGrey,
  };
}

String _dash(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? '-' : text;
}
