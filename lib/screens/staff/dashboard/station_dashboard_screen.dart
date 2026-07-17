import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/station/dashboard/station_dashboard_overview.dart';
import 'package:catrans_app/screens/staff/dashboard/station_dashboard_alerts_dialog.dart';
import 'package:catrans_app/screens/staff/shell/staff_navigation_request.dart';
import 'package:catrans_app/services/api/station_dashboard_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';

class StationDashboardScreen extends StatefulWidget {
  final User user;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const StationDashboardScreen({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  @override
  State<StationDashboardScreen> createState() => _StationDashboardScreenState();
}

class _StationDashboardScreenState extends State<StationDashboardScreen> {
  static const Color _brandPurple = Color(0xFF0F056B);
  static const Color _accentYellow = Color(0xFFEFD807);

  final _apiService = StationDashboardApiService();

  StationDashboardOverview? _overview;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _overview == null) {
      return const _DashboardLoading();
    }

    return RefreshIndicator(
      onRefresh: _refreshOverview,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_overview != null) ...[
            _Header(
              user: widget.user,
              overview: _overview!,
              isRefreshing: _isRefreshing,
              onRefresh: _isRefreshing ? null : _refreshOverview,
            ),
            const SizedBox(height: 18),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _InlineError(
                  message: _errorMessage!,
                  onRetry: _isRefreshing ? null : _refreshOverview,
                ),
              ),
            _PrimaryMetrics(summary: _overview!.summary),
            const SizedBox(height: 18),
            _BoardingRateCard(summary: _overview!.summary),
            const SizedBox(height: 18),
            _MainColumns(
              overview: _overview!,
              onNavigate: widget.onNavigate,
            ),
            const SizedBox(height: 18),
            _SecondaryMetrics(overview: _overview!),
            const SizedBox(height: 18),
            _QuickAccess(
              capabilities: _overview!.capabilities,
              onNavigate: widget.onNavigate,
            ),
          ] else ...[
            _DashboardError(
              message:
                  _errorMessage ?? 'Impossible de charger le tableau de bord.',
              onRetry: _loadOverview,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final overview = await _apiService.getOverview();
      if (!mounted) return;
      setState(() => _overview = overview);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOverview() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final overview = await _apiService.getOverview(date: _overview?.date);
      if (!mounted) return;
      setState(() => _overview = overview);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          return 'La demande de tableau de bord est invalide.';
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’avez pas accès au tableau de bord de la gare.';
        case 404:
          return 'La gare rattachée est introuvable.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }

    return 'Impossible de charger le tableau de bord.';
  }
}

class _Header extends StatelessWidget {
  final User user;
  final StationDashboardOverview overview;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;

  const _Header({
    required this.user,
    required this.overview,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user.firstname.isEmpty ? user.fullName : user.firstname;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _StationDashboardScreenState._brandPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                overview.station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Activité du ${_formatDate(overview.date)} • Actualisé ${_formatDateTime(overview.generatedAt)}',
                maxLines: isNarrow ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, height: 1.35),
              ),
            ],
          );
          final action = FilledButton.icon(
            onPressed: onRefresh,
            style: FilledButton.styleFrom(
              backgroundColor: _StationDashboardScreenState._brandPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(isRefreshing ? 'Actualisation…' : 'Actualiser'),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 14),
                action,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryMetrics extends StatelessWidget {
  final StationDashboardSummary summary;

  const _PrimaryMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StaffMetricCard(
        title: 'Départs du jour',
        value: summary.departuresTotal.toString(),
        icon: Icons.directions_bus,
        color: Colors.indigo,
      ),
      StaffMetricCard(
        title: 'Voyageurs attendus',
        value: summary.travelersExpected.toString(),
        icon: Icons.groups,
        color: Colors.blue,
      ),
      StaffMetricCard(
        title: 'Billets contrôlés',
        value: summary.ticketsChecked.toString(),
        icon: Icons.fact_check,
        color: Colors.green,
      ),
      StaffMetricCard(
        title: 'À embarquer',
        value: summary.ticketsRemaining.toString(),
        icon: Icons.pending_actions,
        color: Colors.orange,
      ),
      StaffMetricCard(
        title: 'Alertes',
        value: summary.alertsTotal.toString(),
        icon: Icons.notifications_active,
        color: Colors.redAccent,
      ),
    ];

    return _ResponsiveGrid(
      minItemWidth: 210,
      spacing: 12,
      children: cards,
    );
  }
}

class _BoardingRateCard extends StatelessWidget {
  final StationDashboardSummary summary;

  const _BoardingRateCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final rate = summary.boardingRate.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Taux d’embarquement',
                  style: TextStyle(
                    color: _StationDashboardScreenState._brandPurple,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_formatPercent(summary.boardingRate)} %',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _StationDashboardScreenState._brandPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE8EAF2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _StationDashboardScreenState._accentYellow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.ticketsChecked} billet(s) contrôlé(s) sur ${summary.ticketsActive} billet(s) actif(s).',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _MainColumns extends StatelessWidget {
  final StationDashboardOverview overview;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _MainColumns({
    required this.overview,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 1020;
        final departures = _DeparturesSection(
          departures: overview.upcomingDepartures,
          capabilities: overview.capabilities,
          onNavigate: onNavigate,
        );
        final alerts = _AlertsSection(
          alerts: overview.alerts,
          alertsTotal: overview.summary.alertsTotal,
          capabilities: overview.capabilities,
          onNavigate: onNavigate,
        );

        if (stack) {
          return Column(
            children: [
              departures,
              const SizedBox(height: 18),
              alerts,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: departures),
            const SizedBox(width: 18),
            Expanded(flex: 2, child: alerts),
          ],
        );
      },
    );
  }
}

class _DeparturesSection extends StatelessWidget {
  final List<StationDashboardDeparture> departures;
  final StationDashboardCapabilities capabilities;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _DeparturesSection({
    required this.departures,
    required this.capabilities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      title: 'Prochains départs',
      child: departures.isEmpty
          ? const _EmptyState(
              icon: Icons.event_busy,
              message: 'Aucun départ programmé pour cette journée.',
            )
          : Column(
              children: departures
                  .map(
                    (departure) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DepartureCard(
                        departure: departure,
                        capabilities: capabilities,
                        onNavigate: onNavigate,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final StationDashboardDeparture departure;
  final StationDashboardCapabilities capabilities;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _DepartureCard({
    required this.departure,
    required this.capabilities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final action = _departureAction();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 620;
              final title = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimeBadge(time: departure.departureTimeDisplay),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departure.destinationName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _StationDashboardScreenState._brandPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _SoftChip(
                              label: departure.serviceClassName,
                              icon: Icons.event_seat,
                            ),
                            _StatusChip(status: departure.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (narrow || action == null) return title;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                label: 'Voyageurs',
                value: departure.travelersExpected.toString(),
                icon: Icons.groups,
              ),
              _MiniStat(
                label: 'Contrôlés',
                value: departure.ticketsChecked.toString(),
                icon: Icons.fact_check,
              ),
              _MiniStat(
                label: 'Restants',
                value: departure.ticketsRemaining.toString(),
                icon: Icons.pending_actions,
              ),
              _MiniStat(
                label: 'Embarquement',
                value: '${_formatPercent(departure.boardingRate)} %',
                icon: Icons.trending_up,
              ),
              _MiniStat(
                label: 'Capacité',
                value: _capacityLabel(departure),
                icon: Icons.airline_seat_recline_normal,
              ),
              if (departure.blockedSeats > 0)
                _MiniStat(
                  label: 'Bloqués',
                  value: departure.blockedSeats.toString(),
                  icon: Icons.block,
                ),
              if (departure.alertsCount > 0)
                _MiniStat(
                  label: 'Alertes',
                  value: departure.alertsCount.toString(),
                  icon: Icons.notifications_active,
                ),
            ],
          ),
          if (action != null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 620) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(width: double.infinity, child: action),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget? _departureAction() {
    if (capabilities.canOpenBoarding) {
      return _CompactActionButton(
        label: 'Ouvrir l’embarquement',
        icon: Icons.how_to_reg,
        onPressed: () => onNavigate(
          StaffNavigationRequest(
            menuId: 'boarding',
            departureId: departure.id,
          ),
        ),
      );
    }
    if (capabilities.canReadDepartures) {
      return _CompactActionButton(
        label: 'Voir les départs',
        icon: Icons.directions_bus,
        onPressed: () => onNavigate(
          StaffNavigationRequest(
            menuId: 'departures',
            departureId: departure.id,
          ),
        ),
      );
    }
    return null;
  }
}

class _AlertsSection extends StatelessWidget {
  final List<StationDashboardAlert> alerts;
  final int alertsTotal;
  final StationDashboardCapabilities capabilities;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _AlertsSection({
    required this.alerts,
    required this.alertsTotal,
    required this.capabilities,
    required this.onNavigate,
  });

  static const int _visibleAlertsCount = 5;

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = alerts.take(_visibleAlertsCount).toList();

    return _SectionPanel(
      title: 'Alertes opérationnelles — $alertsTotal',
      child: alerts.isEmpty
          ? const _EmptyState(
              icon: Icons.verified,
              message: 'Aucune alerte opérationnelle pour le moment.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...visibleAlerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AlertCard(
                      alert: alert,
                      actionId: _actionIdFor(alert),
                      onNavigate: onNavigate,
                    ),
                  ),
                ),
                if (alerts.length > _visibleAlertsCount)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showStationDashboardAlertsDialog(
                        context: context,
                        alerts: alerts,
                        alertsTotal: alertsTotal,
                        capabilities: capabilities,
                        onNavigate: onNavigate,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('Voir les ${alerts.length} alertes reçues'),
                    ),
                  ),
              ],
            ),
    );
  }

  String? _actionIdFor(StationDashboardAlert alert) {
    switch (alert.actionTarget) {
      case 'boarding':
        return capabilities.canOpenBoarding ? 'boarding' : null;
      case 'departures':
        return capabilities.canReadDepartures ? 'departures' : null;
      case 'reports':
        return capabilities.canManageReports ? 'reports' : null;
    }
    return null;
  }
}

class _AlertCard extends StatelessWidget {
  final StationDashboardAlert alert;
  final String? actionId;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _AlertCard({
    required this.alert,
    required this.actionId,
    required this.onNavigate,
  });

  String? _departureContextFor(String menuId) {
    if (menuId != 'boarding' && menuId != 'departures') return null;
    final value = alert.departureId.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_severityIcon(alert.severity), color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: const TextStyle(color: Colors.black87, height: 1.35),
          ),
          if (actionId != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onNavigate(
                  StaffNavigationRequest(
                    menuId: actionId!,
                    departureId: _departureContextFor(actionId!),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ouvrir'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecondaryMetrics extends StatelessWidget {
  final StationDashboardOverview overview;

  const _SecondaryMetrics({required this.overview});

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final pending = overview.pendingRequests;
    final items = [
      _SecondaryMetric('Billets actifs', summary.ticketsActive.toString()),
      _SecondaryMetric(
        'Réservations confirmées',
        summary.confirmedReservations.toString(),
      ),
      _SecondaryMetric(
        'Départs avec voyageurs',
        summary.departuresWithTravelers.toString(),
      ),
      _SecondaryMetric('Sièges bloqués', summary.blockedSeats.toString()),
      _SecondaryMetric('Reports en attente', pending.reports.toString()),
      _SecondaryMetric(
        'Annulations en attente',
        pending.cancellations.toString(),
      ),
      _SecondaryMetric('Départs ouverts', summary.departuresOpen.toString()),
      _SecondaryMetric('Départs partis', summary.departuresDeparted.toString()),
    ];

    return _SectionPanel(
      title: 'Métriques secondaires',
      child: _ResponsiveGrid(
        minItemWidth: 180,
        spacing: 10,
        children: items
            .map(
              (item) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: _StationDashboardScreenState._brandPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final StationDashboardCapabilities capabilities;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _QuickAccess({
    required this.capabilities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (capabilities.canReadReservations)
        const _QuickAction(
          id: 'station_reservations',
          title: 'Réservations gare',
          icon: Icons.confirmation_number,
        ),
      if (capabilities.canReadDepartures || capabilities.canManageDepartures)
        const _QuickAction(
          id: 'departures',
          title: 'Départs du jour',
          icon: Icons.directions_bus,
        ),
      if (capabilities.canOpenBoarding)
        const _QuickAction(
          id: 'boarding',
          title: 'Embarquement',
          icon: Icons.how_to_reg,
        ),
      if (capabilities.canManageReports)
        const _QuickAction(
          id: 'reports',
          title: 'Reports / annulations',
          icon: Icons.edit_calendar,
        ),
    ];

    return _SectionPanel(
      title: 'Accès rapides',
      child: actions.isEmpty
          ? const _EmptyState(
              icon: Icons.lock_outline,
              message: 'Aucun accès rapide disponible pour ce profil.',
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions
                  .map(
                    (action) => OutlinedButton.icon(
                      onPressed: () => onNavigate(
                        StaffNavigationRequest(menuId: action.id),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _StationDashboardScreenState._brandPurple,
                        side: const BorderSide(color: Color(0xFFD9DCEA)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(action.icon),
                      label: Text(action.title),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _StationDashboardScreenState._brandPurple,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final double minItemWidth;
  final double spacing;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.minItemWidth,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            (width / minItemWidth).floor().clamp(1, children.length).toInt();
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: _StationDashboardScreenState._brandPurple),
          const SizedBox(width: 6),
          Text(
            '$label : ',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String time;

  const _TimeBadge({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _StationDashboardScreenState._brandPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time.isEmpty ? '--:--' : time,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final StationDashboardStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return _SoftChip(
      label: status.label.isEmpty ? status.code : status.label,
      icon: Icons.circle,
      color: _statusColor(status.code),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _SoftChip({
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _StationDashboardScreenState._brandPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _StationDashboardScreenState._brandPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD4CF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Chargement de l’activité de la gare…',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          minItemWidth: 210,
          spacing: 12,
          children: List.generate(5, (_) => const _SkeletonCard()),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off, color: Colors.redAccent, size: 30),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger le tableau de bord.',
            style: TextStyle(
              color: _StationDashboardScreenState._brandPurple,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: _StationDashboardScreenState._brandPurple),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetric {
  final String label;
  final String value;

  const _SecondaryMetric(this.label, this.value);
}

class _QuickAction {
  final String id;
  final String title;
  final IconData icon;

  const _QuickAction({
    required this.id,
    required this.title,
    required this.icon,
  });
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.black12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

String _capacityLabel(StationDashboardDeparture departure) {
  final total = departure.totalCapacity;
  final available = departure.availableCapacity;
  if (total == null || available == null) return 'Capacité non disponible';
  return '$available / $total';
}

String _formatDate(DateTime? value) {
  if (value == null) return 'date non disponible';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'non disponible';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} à $hour:$minute';
}

String _formatPercent(double value) {
  final normalized = value.clamp(0, 100).toDouble();
  if (normalized == normalized.roundToDouble()) {
    return normalized.toInt().toString();
  }
  return normalized.toStringAsFixed(1);
}

Color _statusColor(String code) {
  switch (code) {
    case 'open':
      return Colors.green;
    case 'closed':
      return Colors.blueGrey;
    case 'departed':
      return Colors.indigo;
    case 'cancelled':
      return Colors.redAccent;
    case 'scheduled':
    default:
      return Colors.orange;
  }
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'critical':
      return Colors.redAccent;
    case 'warning':
      return Colors.orange;
    case 'info':
    default:
      return _StationDashboardScreenState._brandPurple;
  }
}

IconData _severityIcon(String severity) {
  switch (severity) {
    case 'critical':
      return Icons.error_outline;
    case 'warning':
      return Icons.warning_amber;
    case 'info':
    default:
      return Icons.info_outline;
  }
}
