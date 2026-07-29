import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBg = Color(0xFFF5F6FA);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

class StationDepartureTransitionRequest {
  final StationOperationalDeparture departure;
  final StationDepartureTransitionAction action;

  const StationDepartureTransitionRequest({
    required this.departure,
    required this.action,
  });
}

enum StationDepartureTransitionAction { open, close, depart }

extension StationDepartureTransitionActionLabels
    on StationDepartureTransitionAction {
  String get code {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'open';
      case StationDepartureTransitionAction.close:
        return 'close';
      case StationDepartureTransitionAction.depart:
        return 'depart';
    }
  }

  String get title {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'Ouvrir ce départ ?';
      case StationDepartureTransitionAction.close:
        return 'Fermer ce départ ?';
      case StationDepartureTransitionAction.depart:
        return 'Enregistrer le départ effectif ?';
    }
  }

  String get description {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'L’ouverture autorisera les opérations d’embarquement et de validation des billets pour ce départ.';
      case StationDepartureTransitionAction.close:
        return 'Après fermeture, aucun nouveau billet ne pourra être validé pour ce départ.';
      case StationDepartureTransitionAction.depart:
        return 'Cette action enregistrera l’heure réelle du départ et terminera le workflow opérationnel.';
    }
  }

  String get buttonLabel {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'Ouvrir le départ';
      case StationDepartureTransitionAction.close:
        return 'Confirmer la fermeture';
      case StationDepartureTransitionAction.depart:
        return 'Marquer comme parti';
    }
  }

  String get shortLabel {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'Ouvrir';
      case StationDepartureTransitionAction.close:
        return 'Fermer';
      case StationDepartureTransitionAction.depart:
        return 'Marquer parti';
    }
  }

  String get successMessage {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return 'Le départ est maintenant ouvert.';
      case StationDepartureTransitionAction.close:
        return 'Le départ a été fermé.';
      case StationDepartureTransitionAction.depart:
        return 'Le départ effectif a été enregistré.';
    }
  }

  IconData get icon {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return Icons.play_arrow_rounded;
      case StationDepartureTransitionAction.close:
        return Icons.lock_outline;
      case StationDepartureTransitionAction.depart:
        return Icons.directions_bus_filled_outlined;
    }
  }

  Color get color {
    switch (this) {
      case StationDepartureTransitionAction.open:
        return _brandPurple;
      case StationDepartureTransitionAction.close:
        return _warning;
      case StationDepartureTransitionAction.depart:
        return _danger;
    }
  }

  bool get warnsRemainingTravelers =>
      this == StationDepartureTransitionAction.close ||
      this == StationDepartureTransitionAction.depart;
}

Future<bool> showStationDepartureTransitionDialog({
  required BuildContext context,
  required StationOperationalDeparture departure,
  required StationDepartureTransitionAction action,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  final fullscreen = width < 640;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final content = _StationDepartureTransitionContent(
        departure: departure,
        action: action,
      );

      if (fullscreen) {
        return Dialog.fullscreen(
          backgroundColor: _staffBg,
          child: SafeArea(child: content),
        );
      }

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: content,
        ),
      );
    },
  );

  return result == true;
}

class _StationDepartureTransitionContent extends StatelessWidget {
  final StationOperationalDeparture departure;
  final StationDepartureTransitionAction action;

  const _StationDepartureTransitionContent({
    required this.departure,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = departure.ticketsRemaining;
    final showRemainingWarning =
        action.warnsRemainingTravelers && remaining > 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(bottom: BorderSide(color: Color(0xFFE6E8EF))),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                action.description,
                style:
                    const TextStyle(height: 1.4, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _DetailsGrid(departure: departure, action: action),
              if (showRemainingWarning) ...[
                const SizedBox(height: 16),
                _WarningPanel(
                  message: _remainingWarningMessage(remaining, action),
                ),
              ],
              if (action == StationDepartureTransitionAction.depart) ...[
                const SizedBox(height: 16),
                _InfoPanel(
                  message:
                      'Heure locale actuelle : ${_formatDateTime(DateTime.now())}. Elle est affichée à titre d’information seulement.',
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE6E8EF))),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              final cancel = OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              );
              final confirm = FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: action.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(action.icon, size: 18),
                label: Text(action.buttonLabel),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [confirm, const SizedBox(height: 10), cancel],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [cancel, const SizedBox(width: 10), confirm],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final StationOperationalDeparture departure;
  final StationDepartureTransitionAction action;

  const _DetailsGrid({required this.departure, required this.action});

  @override
  Widget build(BuildContext context) {
    final details = [
      _DetailData('Heure', departure.displayTime),
      _DetailData('Destination', departure.destinationName),
      _DetailData('Classe', departure.displayServiceClass),
      _DetailData('Statut actuel', departure.statusLabel),
      _DetailData('Voyageurs attendus', departure.travelersExpected.toString()),
      _DetailData('Billets contrôlés', departure.ticketsChecked.toString()),
      if (action != StationDepartureTransitionAction.open)
        _DetailData('Billets restants', departure.ticketsRemaining.toString()),
      if (action != StationDepartureTransitionAction.open)
        _DetailData(
          'Taux d’embarquement',
          '${departure.boardingRate.toStringAsFixed(0)} %',
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: details
              .map(
                (detail) => SizedBox(
                  width: width,
                  child: _DetailTile(label: detail.label, value: detail.value),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _brandPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningPanel extends StatelessWidget {
  final String message;

  const _WarningPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String message;

  const _InfoPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _brandPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _brandPurple),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _DetailData {
  final String label;
  final String value;

  const _DetailData(this.label, this.value);
}

String _remainingWarningMessage(
  int remaining,
  StationDepartureTransitionAction action,
) {
  final prefix = '$remaining voyageur(s)';
  if (action == StationDepartureTransitionAction.close) {
    return '$prefix n’ont pas encore été contrôlé(s). Ils pourront être considérés comme absents.';
  }
  return '$prefix ne sont pas contrôlé(s). Le départ peut néanmoins être enregistré.';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
