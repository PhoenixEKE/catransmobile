import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_dashboard_models.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/admin_dashboard_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';

typedef AdminDashboardDatePicker = Future<DateTime?> Function(
  BuildContext context,
  DateTime initialDate,
);

class AdminDashboardHomeScreen extends StatefulWidget {
  final User user;
  final AdminDashboardApiService? apiService;
  final AdminDashboardDatePicker? datePicker;
  final DateTime Function()? nowProvider;

  const AdminDashboardHomeScreen({
    super.key,
    required this.user,
    this.apiService,
    this.datePicker,
    this.nowProvider,
  });

  @override
  State<AdminDashboardHomeScreen> createState() =>
      _AdminDashboardHomeScreenState();
}

class _AdminDashboardHomeScreenState extends State<AdminDashboardHomeScreen> {
  late final AdminDashboardApiService _apiService;

  DateTime _selectedDate = DateTime.now();
  DateTime? _lastUpdatedAt;

  bool _isLoading = false;
  String? _overviewError;

  AdminDashboardOverviewResponse? _overview;

  AdminDashboardSalesByChannelResponse? _salesByChannel;
  String? _salesError;

  AdminDashboardRevenueByPaymentMethodResponse? _revenueByMethod;
  String? _revenueError;

  AdminDashboardTopRoutesResponse? _topRoutes;
  String? _topRoutesError;

  bool get _canReadDashboard {
    final permissions = StaffPermissions.fromScopes(widget.user.scopes);
    return permissions.canReadAdminDashboard;
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? AdminDashboardApiService();
    _selectedDate = _stripTime((widget.nowProvider ?? DateTime.now)());

    if (_canReadDashboard) {
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canReadDashboard) {
      return StaffAccessDeniedPage(user: widget.user);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < PersonnelBreakpoints.mobile
            ? PersonnelSpacing.md
            : PersonnelSpacing.lg;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffModuleHeader(
                icon: Icons.query_stats,
                title: 'Tableau de bord',
                description:
                    'Pilotage opérationnel de la journée: revenus, réservations, tickets et départs.',
                trailing: _HeaderActions(
                  selectedDate: _selectedDate,
                  lastUpdatedAt: _lastUpdatedAt,
                  isLoading: _isLoading,
                  onPickDate: _pickDate,
                  onRefresh: _loadDashboard,
                ),
              ),
              const SizedBox(height: PersonnelSpacing.lg),
              if (_overview == null && _isLoading)
                const SizedBox(
                  height: 240,
                  child: StaffLoadingState(
                    message: 'Chargement du tableau de bord administrateur...',
                  ),
                )
              else if (_overview == null && _overviewError != null)
                KeyedSubtree(
                  key: const Key('admin-dashboard-overview-error'),
                  child: StaffErrorState(
                    message: _overviewError!,
                    onRetry: _loadDashboard,
                  ),
                )
              else if (_overview != null)
                _DashboardContent(
                  overview: _overview!,
                  salesByChannel: _salesByChannel,
                  salesError: _salesError,
                  revenueByMethod: _revenueByMethod,
                  revenueError: _revenueError,
                  topRoutes: _topRoutes,
                  topRoutesError: _topRoutesError,
                  selectedDate: _selectedDate,
                  isRefreshing: _isLoading,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    if (_isLoading) return;

    final pickedDate = await (widget.datePicker ?? _defaultDatePicker)(
      context,
      _selectedDate,
    );

    if (!mounted || pickedDate == null) return;

    final normalized = _stripTime(pickedDate);
    if (_sameDate(normalized, _selectedDate)) return;

    setState(() => _selectedDate = normalized);
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!_canReadDashboard || _isLoading) return;

    setState(() {
      _isLoading = true;
      _overviewError = null;
    });

    final date = _selectedDate;

    final snapshots = await Future.wait([
      _capture(() => _apiService.getOverview(date: date)),
      _capture(() => _apiService.getSalesByChannel(date: date)),
      _capture(() => _apiService.getRevenueByPaymentMethod(date: date)),
      _capture(() => _apiService.getTopRoutes(date: date)),
    ]);

    if (!mounted) return;

    final overviewSnapshot =
        snapshots[0] as _SectionSnapshot<AdminDashboardOverviewResponse>;
    final salesSnapshot =
        snapshots[1] as _SectionSnapshot<AdminDashboardSalesByChannelResponse>;
    final revenueSnapshot = snapshots[2]
        as _SectionSnapshot<AdminDashboardRevenueByPaymentMethodResponse>;
    final routesSnapshot =
        snapshots[3] as _SectionSnapshot<AdminDashboardTopRoutesResponse>;

    setState(() {
      _isLoading = false;

      if (overviewSnapshot.data == null) {
        _overview = null;
        _overviewError = overviewSnapshot.errorMessage ??
            'Impossible de charger les indicateurs du tableau de bord.';
        return;
      }

      _overview = overviewSnapshot.data;
      _overviewError = null;
      _lastUpdatedAt = (widget.nowProvider ?? DateTime.now)();

      _salesByChannel = salesSnapshot.data;
      _salesError = salesSnapshot.errorMessage;

      _revenueByMethod = revenueSnapshot.data;
      _revenueError = revenueSnapshot.errorMessage;

      _topRoutes = routesSnapshot.data;
      _topRoutesError = routesSnapshot.errorMessage;
    });
  }

  Future<_SectionSnapshot<T>> _capture<T>(
    Future<T> Function() loader,
  ) async {
    try {
      return _SectionSnapshot(data: await loader());
    } catch (error) {
      return _SectionSnapshot(errorMessage: _readableError(error));
    }
  }

  String _readableError(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return 'Une erreur est survenue lors du chargement des données.';
  }

  Future<DateTime?> _defaultDatePicker(
    BuildContext context,
    DateTime initialDate,
  ) {
    final now = _stripTime((widget.nowProvider ?? DateTime.now)());
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final AdminDashboardOverviewResponse overview;
  final AdminDashboardSalesByChannelResponse? salesByChannel;
  final String? salesError;
  final AdminDashboardRevenueByPaymentMethodResponse? revenueByMethod;
  final String? revenueError;
  final AdminDashboardTopRoutesResponse? topRoutes;
  final String? topRoutesError;
  final DateTime selectedDate;
  final bool isRefreshing;

  const _DashboardContent({
    required this.overview,
    required this.salesByChannel,
    required this.salesError,
    required this.revenueByMethod,
    required this.revenueError,
    required this.topRoutes,
    required this.topRoutesError,
    required this.selectedDate,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _primaryMetrics(overview);
        final kpiColumns = _columnCountForWidth(constraints.maxWidth);
        final sideBySide = constraints.maxWidth >= 1080;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: PersonnelSpacing.sm),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Text(
              'Date analysée: ${_DashboardFormatters.displayDate(selectedDate)}',
              style: const TextStyle(
                color: PersonnelColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: PersonnelSpacing.md),
            _MetricGrid(metrics: metrics, columns: kpiColumns),
            const SizedBox(height: PersonnelSpacing.lg),
            _SectionCard(
              title: 'Activité détaillée',
              child: _DetailedActivity(overview: overview),
            ),
            const SizedBox(height: PersonnelSpacing.lg),
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SectionCard(
                      key: const Key('admin-dashboard-sales-section'),
                      title: 'Ventes par canal',
                      child: _SalesByChannelSection(
                        salesByChannel: salesByChannel,
                        errorMessage: salesError,
                      ),
                    ),
                  ),
                  const SizedBox(width: PersonnelSpacing.md),
                  Expanded(
                    child: _SectionCard(
                      key: const Key('admin-dashboard-revenue-section'),
                      title: 'Revenus par moyen de paiement',
                      child: _RevenueByMethodSection(
                        revenueByMethod: revenueByMethod,
                        errorMessage: revenueError,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              _SectionCard(
                key: const Key('admin-dashboard-sales-section'),
                title: 'Ventes par canal',
                child: _SalesByChannelSection(
                  salesByChannel: salesByChannel,
                  errorMessage: salesError,
                ),
              ),
              const SizedBox(height: PersonnelSpacing.md),
              _SectionCard(
                key: const Key('admin-dashboard-revenue-section'),
                title: 'Revenus par moyen de paiement',
                child: _RevenueByMethodSection(
                  revenueByMethod: revenueByMethod,
                  errorMessage: revenueError,
                ),
              ),
            ],
            const SizedBox(height: PersonnelSpacing.lg),
            _SectionCard(
              key: const Key('admin-dashboard-top-routes-section'),
              title: 'Top trajets',
              child: _TopRoutesSection(
                topRoutes: topRoutes,
                errorMessage: topRoutesError,
              ),
            ),
            const SizedBox(height: PersonnelSpacing.lg),
            _SectionCard(
              title: 'Points d’attention opérationnels',
              child: _AttentionPoints(overview: overview),
            ),
          ],
        );
      },
    );
  }

  List<_MetricTileData> _primaryMetrics(AdminDashboardOverviewResponse value) {
    return [
      _MetricTileData(
        title: 'Revenu encaissé',
        value: _DashboardFormatters.money(value.payments.revenue),
        icon: Icons.payments_outlined,
        color: PersonnelColors.success,
      ),
      _MetricTileData(
        title: 'Réservations',
        value: _DashboardFormatters.number(value.reservations.todayTotal),
        icon: Icons.confirmation_num_outlined,
        color: PersonnelColors.brandPrimary,
      ),
      _MetricTileData(
        title: 'Tickets',
        value: _DashboardFormatters.number(value.tickets.todayTotal),
        icon: Icons.qr_code_2_outlined,
        color: const Color(0xFF0B6BCB),
      ),
      _MetricTileData(
        title: 'Départs',
        value: _DashboardFormatters.number(value.departures.todayTotal),
        icon: Icons.alt_route,
        color: const Color(0xFF7A3E00),
      ),
    ];
  }

  int _columnCountForWidth(double width) {
    if (width < PersonnelBreakpoints.mobile) return 1;
    if (width < PersonnelBreakpoints.desktop) return 2;
    if (width < PersonnelBreakpoints.large) return 3;
    return 4;
  }
}

class _HeaderActions extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? lastUpdatedAt;
  final bool isLoading;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onRefresh;

  const _HeaderActions({
    required this.selectedDate,
    required this.lastUpdatedAt,
    required this.isLoading,
    required this.onPickDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: PersonnelSpacing.sm,
      runSpacing: PersonnelSpacing.sm,
      children: [
        OutlinedButton.icon(
          key: const Key('admin-dashboard-date-button'),
          onPressed: isLoading ? null : onPickDate,
          icon: const Icon(Icons.event_outlined),
          label: Text(_DashboardFormatters.displayDate(selectedDate)),
        ),
        ElevatedButton.icon(
          key: const Key('admin-dashboard-refresh-button'),
          onPressed: isLoading ? null : onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
        ),
        if (lastUpdatedAt != null)
          Text(
            'Dernière actualisation: ${_DashboardFormatters.dateTime(lastUpdatedAt!)}',
            key: const Key('admin-dashboard-last-updated'),
            style: const TextStyle(
              fontSize: 12,
              color: PersonnelColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PersonnelSpacing.md),
      decoration: BoxDecoration(
        color: PersonnelColors.surface,
        borderRadius: BorderRadius.circular(PersonnelRadius.md),
        border: Border.all(color: PersonnelColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PersonnelColors.textPrimary,
            ),
          ),
          const SizedBox(height: PersonnelSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricTileData> metrics;
  final int columns;

  const _MetricGrid({required this.metrics, required this.columns});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: PersonnelSpacing.sm,
        mainAxisSpacing: PersonnelSpacing.sm,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return StaffMetricCard(
          title: metric.title,
          value: metric.value,
          icon: metric.icon,
          color: metric.color,
        );
      },
    );
  }
}

class _DetailedActivity extends StatelessWidget {
  final AdminDashboardOverviewResponse overview;

  const _DetailedActivity({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PersonnelSpacing.md,
      runSpacing: PersonnelSpacing.md,
      children: [
        _DataGroup(
          title: 'Réservations',
          rows: [
            _DataRowData('Total', overview.reservations.todayTotal),
            _DataRowData('Confirmées', overview.reservations.confirmed),
            _DataRowData(
                'En attente paiement', overview.reservations.pendingPayment),
            _DataRowData('Annulées', overview.reservations.cancelled),
          ],
        ),
        _DataGroup(
          title: 'Paiements',
          rows: [
            _DataRowData('Total', overview.payments.todayTotal),
            _DataRowData('Réussis', overview.payments.success),
            _DataRowData('En attente', overview.payments.pending),
            _DataRowData('Échoués', overview.payments.failed),
          ],
          footer:
              'Revenu: ${_DashboardFormatters.money(overview.payments.revenue)}',
        ),
        _DataGroup(
          title: 'Tickets',
          rows: [
            _DataRowData('Total', overview.tickets.todayTotal),
            _DataRowData('Émis', overview.tickets.issued),
            _DataRowData('Utilisés', overview.tickets.used),
            _DataRowData('Annulés', overview.tickets.cancelled),
          ],
        ),
        _DataGroup(
          title: 'Départs',
          rows: [
            _DataRowData('Total', overview.departures.todayTotal),
            _DataRowData('Programmés', overview.departures.scheduled),
            _DataRowData('Ouverts', overview.departures.open),
            _DataRowData('Fermés', overview.departures.closed),
            _DataRowData('Partis', overview.departures.departed),
            _DataRowData('Annulés', overview.departures.cancelled),
          ],
        ),
        _DataGroup(
          title: 'Sièges',
          rows: [
            _DataRowData('Total', overview.seats.todayTotal),
            _DataRowData('Disponibles', overview.seats.available),
            _DataRowData('Réservés', overview.seats.reserved),
            _DataRowData('En attente', overview.seats.held),
            _DataRowData('Bloqués', overview.seats.blocked),
          ],
        ),
        _DataGroup(
          title: 'Demandes',
          rows: [
            _DataRowData(
                'Reports en attente', overview.requests.pendingChanges),
            _DataRowData(
              'Annulations en attente',
              overview.requests.pendingCancellations,
            ),
          ],
        ),
      ],
    );
  }
}

class _SalesByChannelSection extends StatelessWidget {
  final AdminDashboardSalesByChannelResponse? salesByChannel;
  final String? errorMessage;

  const _SalesByChannelSection({
    required this.salesByChannel,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return StaffErrorState(message: errorMessage!);
    }

    final response = salesByChannel;
    if (response == null || response.results.isEmpty) {
      return const KeyedSubtree(
        key: Key('admin-dashboard-sales-empty'),
        child: StaffEmptyState(
          title: 'Aucune vente',
          message: 'Aucune vente enregistrée pour cette date.',
          icon: Icons.sell_outlined,
        ),
      );
    }

    final total =
        response.results.fold<int>(0, (sum, item) => sum + item.total);

    return Column(
      children: response.results.map((item) {
        final ratio = total > 0 ? item.total / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: PersonnelSpacing.sm),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  _DashboardFormatters.channelLabel(item.channel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PersonnelRadius.sm),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: ratio,
                    backgroundColor: const Color(0xFFE8EAF2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      PersonnelColors.brandPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PersonnelSpacing.sm),
              Expanded(
                flex: 3,
                child: Text(
                  '${_DashboardFormatters.number(item.total)} · ${_DashboardFormatters.percent(ratio)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RevenueByMethodSection extends StatelessWidget {
  final AdminDashboardRevenueByPaymentMethodResponse? revenueByMethod;
  final String? errorMessage;

  const _RevenueByMethodSection({
    required this.revenueByMethod,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return StaffErrorState(
        message: errorMessage!,
      );
    }

    final response = revenueByMethod;

    if (response == null || response.results.isEmpty) {
      return const KeyedSubtree(
        key: Key('admin-dashboard-revenue-empty'),
        child: StaffEmptyState(
          title: 'Aucun revenu encaissé',
          message: 'Aucun paiement réussi pour cette date.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }

    final total = response.results.fold<double>(
      0,
      (sum, item) {
        return sum +
            _DashboardFormatters.toAmount(
              item.totalAmount,
            );
      },
    );

    return Column(
      children: response.results.map((item) {
        final amount = _DashboardFormatters.toAmount(
          item.totalAmount,
        );

        final ratio = total > 0 ? amount / total : 0.0;

        return Padding(
          padding: const EdgeInsets.only(
            bottom: PersonnelSpacing.sm,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              PersonnelSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: PersonnelColors.background,
              borderRadius: BorderRadius.circular(
                PersonnelRadius.sm,
              ),
              border: Border.all(
                color: PersonnelColors.border,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;

                final paymentIdentity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _DashboardFormatters.paymentMethodLabel(
                        item.method,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: PersonnelColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _DashboardFormatters.paymentProviderLabel(
                        item.provider,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: PersonnelColors.textSecondary,
                      ),
                    ),
                  ],
                );

                final paymentSummary = Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      _DashboardFormatters.money(
                        item.totalAmount,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: PersonnelColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_DashboardFormatters.number(item.totalPayments)} '
                      'paiement(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PersonnelColors.textSecondary,
                      ),
                    ),
                    Text(
                      _DashboardFormatters.percent(ratio),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PersonnelColors.textSecondary,
                      ),
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      paymentIdentity,
                      const SizedBox(
                        height: PersonnelSpacing.sm,
                      ),
                      const Divider(height: 1),
                      const SizedBox(
                        height: PersonnelSpacing.sm,
                      ),
                      paymentSummary,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: paymentIdentity,
                    ),
                    const SizedBox(
                      width: PersonnelSpacing.md,
                    ),
                    Flexible(
                      child: paymentSummary,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TopRoutesSection extends StatelessWidget {
  final AdminDashboardTopRoutesResponse? topRoutes;
  final String? errorMessage;

  const _TopRoutesSection(
      {required this.topRoutes, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return StaffErrorState(message: errorMessage!);
    }

    final response = topRoutes;
    if (response == null || response.results.isEmpty) {
      return const KeyedSubtree(
        key: Key('admin-dashboard-top-routes-empty'),
        child: StaffEmptyState(
          title: 'Aucun trajet vendu',
          message: 'Aucun ticket enregistré pour cette date.',
          icon: Icons.alt_route,
        ),
      );
    }

    return Column(
      children: response.results.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final route = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: PersonnelSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(PersonnelSpacing.sm),
            decoration: BoxDecoration(
              color: PersonnelColors.background,
              borderRadius: BorderRadius.circular(PersonnelRadius.sm),
              border: Border.all(color: PersonnelColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: PersonnelColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(PersonnelRadius.sm),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: PersonnelColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: PersonnelSpacing.sm),
                Expanded(
                  child: Text(
                    route.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: PersonnelSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_DashboardFormatters.number(route.totalTickets)} ticket(s)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _DashboardFormatters.money(route.revenue),
                      style: const TextStyle(
                        fontSize: 12,
                        color: PersonnelColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AttentionPoints extends StatelessWidget {
  final AdminDashboardOverviewResponse overview;

  const _AttentionPoints({required this.overview});

  @override
  Widget build(BuildContext context) {
    final points = <_AttentionPointData>[];

    if (overview.requests.pendingChanges > 0) {
      points.add(_AttentionPointData(
        icon: Icons.swap_horiz,
        tone: PersonnelColors.warning,
        text:
            '${_DashboardFormatters.number(overview.requests.pendingChanges)} demande(s) de report en attente.',
      ));
    }

    if (overview.requests.pendingCancellations > 0) {
      points.add(_AttentionPointData(
        icon: Icons.cancel_outlined,
        tone: PersonnelColors.warning,
        text:
            '${_DashboardFormatters.number(overview.requests.pendingCancellations)} demande(s) d’annulation en attente.',
      ));
    }

    if (overview.payments.failed > 0 || overview.payments.pending > 0) {
      points.add(_AttentionPointData(
        icon: Icons.payments_outlined,
        tone: PersonnelColors.danger,
        text:
            '${_DashboardFormatters.number(overview.payments.failed)} paiement(s) échoué(s), ${_DashboardFormatters.number(overview.payments.pending)} en attente.',
      ));
    }

    if (overview.departures.open > 0 || overview.departures.scheduled > 0) {
      points.add(_AttentionPointData(
        icon: Icons.departure_board,
        tone: PersonnelColors.brandPrimary,
        text:
            '${_DashboardFormatters.number(overview.departures.open)} départ(s) ouvert(s), ${_DashboardFormatters.number(overview.departures.scheduled)} programmé(s).',
      ));
    }

    if (points.isEmpty) {
      return const StaffEmptyState(
        title: 'Aucun point critique',
        message: 'Aucune alerte opérationnelle détectée pour la date analysée.',
        icon: Icons.task_alt,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: PersonnelSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(point.icon, color: point.tone, size: 18),
                  const SizedBox(width: PersonnelSpacing.sm),
                  Expanded(child: Text(point.text)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DataGroup extends StatelessWidget {
  final String title;
  final List<_DataRowData> rows;
  final String? footer;

  const _DataGroup({
    required this.title,
    required this.rows,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 320),
      padding: const EdgeInsets.all(PersonnelSpacing.sm),
      decoration: BoxDecoration(
        color: PersonnelColors.background,
        borderRadius: BorderRadius.circular(PersonnelRadius.sm),
        border: Border.all(color: PersonnelColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PersonnelColors.brandPrimary,
            ),
          ),
          const SizedBox(height: PersonnelSpacing.sm),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(row.label)),
                  Text(
                    _DashboardFormatters.number(row.value),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 18),
            Text(
              footer!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ]
        ],
      ),
    );
  }
}

class _MetricTileData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTileData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _DataRowData {
  final String label;
  final int value;

  const _DataRowData(this.label, this.value);
}

class _AttentionPointData {
  final IconData icon;
  final Color tone;
  final String text;

  const _AttentionPointData({
    required this.icon,
    required this.tone,
    required this.text,
  });
}

class _SectionSnapshot<T> {
  final T? data;
  final String? errorMessage;

  const _SectionSnapshot({this.data, this.errorMessage});
}

class _DashboardFormatters {
  static final NumberFormat _intFormat = NumberFormat.decimalPattern('fr_FR');
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'XOF ',
    decimalDigits: 0,
  );

  static String number(int value) => _intFormat.format(value);

  static String money(String value) {
    final amount = toAmount(value);
    return _moneyFormat.format(amount);
  }

  static String displayDate(DateTime date) {
    final localDate = date.toLocal();
    return '${_twoDigits(localDate.day)}/'
        '${_twoDigits(localDate.month)}/'
        '${localDate.year}';
  }

  static String dateTime(DateTime date) {
    final localDate = date.toLocal();
    return '${displayDate(localDate)} '
        '${_twoDigits(localDate.hour)}:'
        '${_twoDigits(localDate.minute)}';
  }

  static String percent(double ratio) {
    final percentValue = (ratio * 100).round();
    return '$percentValue %';
  }

  static double toAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static String channelLabel(String channel) {
    return switch (channel.trim().toLowerCase()) {
      'station_counter' => 'Guichet gare',
      'customer_app' => 'Application voyageur',
      'admin_portal' => 'Portail administrateur',
      'mobile' => 'Mobile',
      'web' => 'Web',
      'api' => 'API',
      '' => 'Canal non renseigné',
      _ => channel,
    };
  }

  static String paymentMethodLabel(String method) {
    return switch (method.trim().toLowerCase()) {
      'cash' => 'Espèces',
      'wave' => 'Wave',
      'mobile_money' => 'Mobile Money',
      'card' => 'Carte',
      '' => 'Méthode non renseignée',
      _ => method,
    };
  }

  static String paymentProviderLabel(String provider) {
    return switch (provider.trim().toLowerCase()) {
      'manual_validation' => 'Validation manuelle',
      'wave_ci' => 'Wave Côte d’Ivoire',
      '' => 'Fournisseur non renseigné',
      _ => provider,
    };
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
