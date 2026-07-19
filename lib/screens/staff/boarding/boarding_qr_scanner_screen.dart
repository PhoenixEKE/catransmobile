import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_helpers.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';

const _scannerPurple = Color(0xFF0F056B);
const _scannerSuccess = Color(0xFF157347);
const _scannerDanger = Color(0xFFB42318);

class BoardingQrScannerScreen extends StatefulWidget {
  final String departureId;
  final String departureLabel;
  final String departureTime;
  final String? serviceClassName;
  final StationBoardingApiService apiService;

  const BoardingQrScannerScreen({
    super.key,
    required this.departureId,
    required this.departureLabel,
    required this.departureTime,
    required this.apiService,
    this.serviceClassName,
  });

  @override
  State<BoardingQrScannerScreen> createState() =>
      _BoardingQrScannerScreenState();
}

class _BoardingQrScannerScreenState extends State<BoardingQrScannerScreen>
    with WidgetsBindingObserver {
  final BoardingQrScanGate _scanGate = BoardingQrScanGate();
  late final MobileScannerController _controller;

  StationTicketValidation? _validation;
  BoardingQrValidationPresentation? _presentation;
  String? _errorMessage;
  bool _isProcessing = false;
  bool _hasProcessedScan = false;
  bool _isResettingScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.stop());
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _validation == null &&
        _errorMessage == null &&
        !_isProcessing) {
      unawaited(_controller.start());
    }
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_isProcessing || _validation != null || _errorMessage != null) return;

    String? token;
    for (final barcode in capture.barcodes) {
      token = normalizeScannedQrValue(barcode.rawValue);
      if (token != null) break;
    }
    if (token == null) return;

    if (!_scanGate.tryStartProcessing(token, DateTime.now())) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _controller.pause();
      final validation = await widget.apiService.validateTicket(
        validationToken: token,
        departureId: widget.departureId,
        deviceIdentifier: 'staff_mobile_scanner',
      );
      if (!mounted) return;

      setState(() {
        _validation = validation;
        _presentation = presentationForValidation(validation);
        _hasProcessedScan = shouldRefreshBoardingAfterValidation(validation);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageFromError(error);
      });
    } finally {
      _scanGate.finishProcessing();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return httpScannerErrorMessage(error.statusCode, error.message);
    }
    return 'Impossible de contacter le serveur. Vérifiez la connexion puis réessayez.';
  }

  Future<void> _scanNext() async {
    setState(() {
      _isResettingScanner = true;
      _validation = null;
      _presentation = null;
      _errorMessage = null;
    });
    _scanGate.resetForNextScan();

    try {
      await _controller.start();
    } finally {
      if (mounted) setState(() => _isResettingScanner = false);
    }
  }

  void _closeScanner() {
    Navigator.of(context).pop(_hasProcessedScan);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeScanner();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scanner un billet'),
          backgroundColor: _scannerPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: _closeScanner,
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
          ),
          actions: [
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                final canUseTorch = state.torchState != TorchState.unavailable;
                return IconButton(
                  onPressed: canUseTorch ? _controller.toggleTorch : null,
                  tooltip: 'Lampe',
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                );
              },
            ),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                final canSwitch = (state.availableCameras ?? 0) > 1;
                return IconButton(
                  onPressed: canSwitch ? _controller.switchCamera : null,
                  tooltip: 'Changer de caméra',
                  icon: const Icon(Icons.cameraswitch),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _ScannerDepartureHeader(
                routeLabel: widget.departureLabel,
                departureTime: widget.departureTime,
                serviceClassName: widget.serviceClassName,
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      fit: BoxFit.cover,
                      onDetect: _handleBarcodeCapture,
                      placeholderBuilder: (context) => const _ScannerLoading(),
                      errorBuilder: (context, error) {
                        return _ScannerCameraError(
                            message: _cameraError(error));
                      },
                    ),
                    const _ScannerFrameOverlay(),
                    if (_isProcessing)
                      const _ScannerBlockingPanel(
                        message: 'Validation du billet...',
                      ),
                  ],
                ),
              ),
              _ScannerBottomPanel(
                validation: _validation,
                presentation: _presentation,
                errorMessage: _errorMessage,
                isProcessing: _isProcessing,
                isResettingScanner: _isResettingScanner,
                onScanNext: _scanNext,
                onManualFallback: _closeScanner,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cameraError(MobileScannerException error) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      return 'Autorisez l’accès caméra pour scanner les billets.';
    }
    return 'La caméra n’est pas disponible. Utilisez la saisie manuelle.';
  }
}

class _ScannerDepartureHeader extends StatelessWidget {
  final String routeLabel;
  final String departureTime;
  final String? serviceClassName;

  const _ScannerDepartureHeader({
    required this.routeLabel,
    required this.departureTime,
    required this.serviceClassName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routeLabel.isEmpty ? 'Départ sélectionné' : routeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _scannerPurple,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$departureTime · ${serviceClassName ?? 'Classe non renseignée'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrameOverlay extends StatelessWidget {
  const _ScannerFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cadrez le QR du billet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerLoading extends StatelessWidget {
  const _ScannerLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 14),
            Text(
              'Chargement du scanner...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerCameraError extends StatelessWidget {
  final String message;

  const _ScannerCameraError({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, color: Colors.white, size: 44),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerBlockingPanel extends StatelessWidget {
  final String message;

  const _ScannerBlockingPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerBottomPanel extends StatelessWidget {
  final StationTicketValidation? validation;
  final BoardingQrValidationPresentation? presentation;
  final String? errorMessage;
  final bool isProcessing;
  final bool isResettingScanner;
  final VoidCallback onScanNext;
  final VoidCallback onManualFallback;

  const _ScannerBottomPanel({
    required this.validation,
    required this.presentation,
    required this.errorMessage,
    required this.isProcessing,
    required this.isResettingScanner,
    required this.onScanNext,
    required this.onManualFallback,
  });

  @override
  Widget build(BuildContext context) {
    final validation = this.validation;
    final presentation = this.presentation;
    final errorMessage = this.errorMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (presentation != null && validation != null)
              _ScannerValidationResult(
                validation: validation,
                presentation: presentation,
              )
            else if (errorMessage != null)
              _ScannerErrorResult(message: errorMessage)
            else
              const Text(
                'Le scanner valide uniquement les QR officiels générés par le backend CA TRANS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 12),
            if (presentation != null || errorMessage != null)
              FilledButton.icon(
                onPressed:
                    isResettingScanner || isProcessing ? null : onScanNext,
                icon: isResettingScanner
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner le suivant'),
              )
            else
              OutlinedButton.icon(
                onPressed: isProcessing ? null : onManualFallback,
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Saisir une référence manuellement'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerValidationResult extends StatelessWidget {
  final StationTicketValidation validation;
  final BoardingQrValidationPresentation presentation;

  const _ScannerValidationResult({
    required this.validation,
    required this.presentation,
  });

  @override
  Widget build(BuildContext context) {
    final color = presentation.isSuccess ? _scannerSuccess : _scannerDanger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(presentation.icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  presentation.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(presentation.message),
          if (validation.travelerFullName.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ScannerResultLine('Voyageur', validation.travelerFullName),
          ],
          if (validation.ticketReference?.trim().isNotEmpty == true)
            _ScannerResultLine('Ticket', validation.ticketReference!),
          if (validation.destinationName?.trim().isNotEmpty == true)
            _ScannerResultLine('Destination', validation.destinationName!),
          if (validation.serviceClassName?.trim().isNotEmpty == true)
            _ScannerResultLine('Classe', validation.serviceClassName!),
          _ScannerResultLine('Siège', validation.displaySeat),
          if (validation.departureTime?.trim().isNotEmpty == true)
            _ScannerResultLine('Heure', validation.departureTime!),
        ],
      ),
    );
  }
}

class _ScannerErrorResult extends StatelessWidget {
  final String message;

  const _ScannerErrorResult({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _scannerDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _scannerDanger.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: _scannerDanger),
          const SizedBox(width: 8),
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

class _ScannerResultLine extends StatelessWidget {
  final String label;
  final String value;

  const _ScannerResultLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
