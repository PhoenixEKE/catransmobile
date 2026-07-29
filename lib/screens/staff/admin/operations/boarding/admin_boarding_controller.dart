import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/station_boarding_manifest.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';

class AdminBoardingController extends ChangeNotifier {
  final AdminOperationsApiService adminApiService;
  final StationBoardingApiService stationApiService;

  AdminBoardingController({
    AdminOperationsApiService? adminApiService,
    StationBoardingApiService? stationApiService,
  })  : adminApiService = adminApiService ?? AdminOperationsApiService(),
        stationApiService = stationApiService ?? StationBoardingApiService();

  StationBoardingManifestResponse? manifest;
  StationTicketValidation? lastValidation;
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String? _departureId;

  Future<void> loadManifest(String departureId, {required bool canRead}) async {
    _departureId = departureId;
    if (!canRead) {
      manifest = null;
      notifyListeners();
      return;
    }
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      manifest = await stationApiService.getBoardingManifest(
        departureId: departureId,
      );
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateToken(String value) {
    return _validate(
      () => adminApiService.validateTicket(
        validationToken: value,
        departureId: _departureId!,
      ),
    );
  }

  Future<bool> validateReference(String value) {
    return _validate(
      () => adminApiService.validateTicketByReference(
        ticketReference: value,
        departureId: _departureId!,
      ),
    );
  }

  Future<bool> _validate(
    Future<StationTicketValidation> Function() action,
  ) async {
    if (isSubmitting || _departureId == null) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      lastValidation = await action();
      try {
        manifest = await stationApiService.getBoardingManifest(
          departureId: _departureId!,
        );
      } catch (_) {}
      return true;
    } catch (error) {
      structuredFormError = _structuredError(error);
      formError = structuredFormError?.userMessage ?? _messageFromError(error);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearValidation() {
    lastValidation = null;
    formError = null;
    structuredFormError = null;
    notifyListeners();
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  StructuredApiError? _structuredError(Object error) {
    if (error is ApiException) return StructuredApiError.fromException(error);
    return null;
  }
}
