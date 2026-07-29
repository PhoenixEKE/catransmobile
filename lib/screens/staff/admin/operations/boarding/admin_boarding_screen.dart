import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/station/station_boarding_manifest.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_departure_status_badge.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_confirmation_dialog.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_controller.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_result_card.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_helpers.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_screen.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminBoardingScreen extends StatefulWidget {
  final AdminDeparture? departure;
  final bool canReadManifest;
  final bool canValidate;
  final AdminOperationsApiService? adminApiService;
  final StationBoardingApiService? stationApiService;

  const AdminBoardingScreen({
    super.key,
    required this.departure,
    required this.canReadManifest,
    required this.canValidate,
    this.adminApiService,
    this.stationApiService,
  });

  @override
  State<AdminBoardingScreen> createState() => _AdminBoardingScreenState();
}

class _AdminBoardingScreenState extends State<AdminBoardingScreen> {
  late final AdminBoardingController _controller;
  late final StationBoardingApiService _scannerApiService;
  final _referenceController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerApiService =
        widget.stationApiService ?? StationBoardingApiService();
    _controller = AdminBoardingController(
      adminApiService: widget.adminApiService,
      stationApiService: _scannerApiService,
    );
    _loadCurrentDeparture();
  }

  @override
  void didUpdateWidget(covariant AdminBoardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.departure?.id != oldWidget.departure?.id ||
        widget.canReadManifest != oldWidget.canReadManifest) {
      _loadCurrentDeparture();
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _tokenController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departure = widget.departure;
    if (departure == null) {
      return const StaffEmptyState(
        icon: Icons.qr_code_scanner,
        title: 'Sélectionnez un départ',
        message: 'Le contrôle embarquement exige un départ sélectionné.',
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DepartureHeader(departure: departure),
          const SizedBox(height: 12),
          if (!widget.canValidate)
            const _ScopeBanner(
              message:
                  'Le scope boarding.validate est requis pour valider un billet.',
            ),
          if (!widget.canReadManifest)
            const _ScopeBanner(
              message:
                  'Le scope boarding.manifest.read est requis pour consulter le manifeste.',
            ),
          _ManualValidationPanel(
            canValidate: widget.canValidate && !_controller.isSubmitting,
            referenceController: _referenceController,
            tokenController: _tokenController,
            isScannerSupported: isBoardingQrScannerSupportedOnCurrentPlatform,
            onValidateReference: () => _validate(isToken: false),
            onValidateToken: () => _validate(isToken: true),
            onOpenScanner: _openScanner,
          ),
          if (_controller.formError != null) ...[
            const SizedBox(height: 10),
            Text(
              _controller.formError!,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ],
          if (_controller.lastValidation != null) ...[
            const SizedBox(height: 12),
            AdminBoardingResultCard(
              validation: _controller.lastValidation!,
              onClear: _controller.clearValidation,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: _buildManifest())),
        ],
      ),
    );
  }

  Widget _buildManifest() {
    if (!widget.canReadManifest) {
      return const SizedBox.shrink();
    }
    if (_controller.isLoading && _controller.manifest == null) {
      return const StaffLoadingState(message: 'Chargement du manifeste...');
    }
    if (_controller.listError != null) {
      return StaffErrorState(
        message: _controller.listError!,
        onRetry: _loadCurrentDeparture,
      );
    }
    final manifest = _controller.manifest;
    if (manifest == null) return const SizedBox.shrink();
    return _ManifestPanel(manifest: manifest);
  }

  void _loadCurrentDeparture() {
    final departure = widget.departure;
    if (departure == null) return;
    _controller.loadManifest(departure.id, canRead: widget.canReadManifest);
  }

  Future<void> _validate({required bool isToken}) async {
    final controller = isToken ? _tokenController : _referenceController;
    final value = controller.text.trim();
    if (value.isEmpty) return;
    final confirmed = await showAdminBoardingConfirmationDialog(
      context: context,
      identifier: value,
      isToken: isToken,
      isSubmitting: _controller.isSubmitting,
    );
    if (confirmed != true) return;
    final success = isToken
        ? await _controller.validateToken(value)
        : await _controller.validateReference(value);
    if (!mounted) return;
    if (success) {
      controller.clear();
    }
  }

  Future<void> _openScanner() async {
    final departure = widget.departure;
    if (departure == null || !widget.canValidate) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BoardingQrScannerScreen(
          departureId: departure.id,
          departureLabel: departure.displayRoute,
          departureTime: departure.displaySchedule,
          serviceClassName: departure.displayClass,
          apiService: _scannerApiService,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      _loadCurrentDeparture();
    }
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
                      fontSize: 16, fontWeight: FontWeight.w900),
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

class _ScopeBanner extends StatelessWidget {
  final String message;

  const _ScopeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFEC84B)),
        ),
        child: Text(message),
      ),
    );
  }
}

class _ManualValidationPanel extends StatelessWidget {
  final bool canValidate;
  final bool isScannerSupported;
  final TextEditingController referenceController;
  final TextEditingController tokenController;
  final VoidCallback onValidateReference;
  final VoidCallback onValidateToken;
  final VoidCallback onOpenScanner;

  const _ManualValidationPanel({
    required this.canValidate,
    required this.isScannerSupported,
    required this.referenceController,
    required this.tokenController,
    required this.onValidateReference,
    required this.onValidateToken,
    required this.onOpenScanner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final referenceField = TextField(
            key: const Key('admin-boarding-reference-field'),
            controller: referenceController,
            decoration: const InputDecoration(labelText: 'Référence ticket'),
            enabled: canValidate,
            onSubmitted: (_) => onValidateReference(),
          );
          final tokenField = TextField(
            key: const Key('admin-boarding-token-field'),
            controller: tokenController,
            decoration: const InputDecoration(labelText: 'Token QR'),
            enabled: canValidate,
            onSubmitted: (_) => onValidateToken(),
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                key: const Key('admin-boarding-validate-reference'),
                onPressed: canValidate ? onValidateReference : null,
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('Valider référence'),
              ),
              OutlinedButton.icon(
                key: const Key('admin-boarding-validate-token'),
                onPressed: canValidate ? onValidateToken : null,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Valider token'),
              ),
              OutlinedButton.icon(
                key: const Key('admin-boarding-open-scanner'),
                onPressed:
                    canValidate && isScannerSupported ? onOpenScanner : null,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                referenceField,
                const SizedBox(height: 10),
                tokenField,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: referenceField),
                  const SizedBox(width: 10),
                  Expanded(child: tokenField),
                ],
              ),
              const SizedBox(height: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ManifestPanel extends StatelessWidget {
  final StationBoardingManifestResponse manifest;

  const _ManifestPanel({required this.manifest});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Total : ${manifest.summary.total}')),
            Chip(label: Text('À embarquer : ${manifest.summary.toBoard}')),
            Chip(label: Text('Embarqués : ${manifest.summary.boarded}')),
            Chip(
                label: Text(
                    'Non embarquables : ${manifest.summary.notBoardable}')),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: manifest.passengers
                    .map((ticket) => _PassengerCard(ticket: ticket))
                    .toList(),
              );
            }
            return _PassengerTable(passengers: manifest.passengers);
          },
        ),
      ],
    );
  }
}

class _PassengerTable extends StatelessWidget {
  final List<StationBoardingTicket> passengers;

  const _PassengerTable({required this.passengers});

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
            DataColumn(label: Text('Ticket')),
            DataColumn(label: Text('Voyageur')),
            DataColumn(label: Text('Siège')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Message')),
          ],
          rows: passengers
              .map((ticket) => DataRow(cells: [
                    DataCell(Text(ticket.reference)),
                    DataCell(Text(ticket.displayTraveler)),
                    DataCell(Text(ticket.displaySeat)),
                    DataCell(Text(ticket.statusLabel)),
                    DataCell(Text(ticket.boardingMessage ?? '-')),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  final StationBoardingTicket ticket;

  const _PassengerCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ticket.reference,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(ticket.displayTraveler),
          Text(ticket.displaySeat),
          Text(ticket.statusLabel),
          if (ticket.boardingMessage != null) Text(ticket.boardingMessage!),
        ],
      ),
    );
  }
}
