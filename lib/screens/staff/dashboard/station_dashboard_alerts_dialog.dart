import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/dashboard/station_dashboard_overview.dart';
import 'package:catrans_app/screens/staff/shell/staff_navigation_request.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBackground = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);

Future<void> showStationDashboardAlertsDialog({
  required BuildContext context,
  required List<StationDashboardAlert> alerts,
  required int alertsTotal,
  required StationDashboardCapabilities capabilities,
  required ValueChanged<StaffNavigationRequest> onNavigate,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = StationDashboardAlertsDialog(
        alerts: alerts,
        alertsTotal: alertsTotal,
        capabilities: capabilities,
        onNavigate: onNavigate,
      );

      if (size.width < 600) {
        return Dialog.fullscreen(
          backgroundColor: _staffBackground,
          child: SafeArea(child: content),
        );
      }

      final width = size.width > 900 ? 820.0 : size.width - 40;
      final height = size.height > 820 ? 760.0 : size.height * 0.9;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(width: width, height: height, child: content),
      );
    },
  );
}

class StationDashboardAlertsDialog extends StatelessWidget {
  final List<StationDashboardAlert> alerts;
  final int alertsTotal;
  final StationDashboardCapabilities capabilities;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const StationDashboardAlertsDialog({
    super.key,
    required this.alerts,
    required this.alertsTotal,
    required this.capabilities,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _staffBackground,
      child: Column(
        children: [
          _DialogHeader(alerts: alerts, alertsTotal: alertsTotal),
          Expanded(
            child: alerts.isEmpty
                ? const _DialogEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
                    ),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _DialogAlertCard(
                        alert: alert,
                        actionId: _actionIdFor(alert),
                        onNavigate: (request) {
                          Navigator.of(context).pop();
                          onNavigate(request);
                        },
                      );
                    },
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

class _DialogHeader extends StatelessWidget {
  final List<StationDashboardAlert> alerts;
  final int alertsTotal;

  const _DialogHeader({
    required this.alerts,
    required this.alertsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = alertsTotal > alerts.length
        ? '${alerts.length} alertes affichées sur $alertsTotal au total.'
        : '${alerts.length} alertes';

    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
        18,
        10,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _brandPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: _brandPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertes opérationnelles',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _brandPurple,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _DialogAlertCard extends StatelessWidget {
  final StationDashboardAlert alert;
  final String? actionId;
  final ValueChanged<StaffNavigationRequest> onNavigate;

  const _DialogAlertCard({
    required this.alert,
    required this.actionId,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final actionLabel = _actionLabel(actionId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SeverityBadge(
                label: _severityLabel(alert.severity),
                icon: _severityIcon(alert.severity),
                color: color,
              ),
              if (alert.departureId.trim().isNotEmpty)
                const _NeutralBadge(
                  label: 'Départ associé',
                  icon: Icons.directions_bus_outlined,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.title.isEmpty ? 'Alerte opérationnelle' : alert.title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            alert.message,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => onNavigate(
                  StaffNavigationRequest(
                    menuId: actionId!,
                    departureId: _departureContextFor(actionId!),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _departureContextFor(String menuId) {
    if (menuId != 'boarding' && menuId != 'departures') return null;
    final value = alert.departureId.trim();
    return value.isEmpty ? null : value;
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SeverityBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _NeutralBadge({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black54, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogEmptyState extends StatelessWidget {
  const _DialogEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aucune alerte opérationnelle pour le moment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}

String? _actionLabel(String? actionId) {
  switch (actionId) {
    case 'boarding':
      return 'Ouvrir l’embarquement';
    case 'departures':
      return 'Voir les départs';
    case 'reports':
      return 'Voir les reports';
  }
  return null;
}

String _severityLabel(String severity) {
  switch (severity) {
    case 'critical':
      return 'Critique';
    case 'warning':
      return 'Attention';
    case 'info':
    default:
      return 'Info';
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
      return _brandPurple;
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
