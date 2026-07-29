import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

class AdminDepartureSeatsController extends ChangeNotifier {
  final AdminOperationsApiService apiService;

  AdminDepartureSeatsController({AdminOperationsApiService? apiService})
      : apiService = apiService ?? AdminOperationsApiService();

  AdminDepartureSeatsResponse? seatsResponse;
  AdminDepartureSeatMap? seatMap;
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String? status;
  String? seatType;
  int? seatNumber;
  bool? isSelectable;
  String? ordering;
  String? _departureId;

  Future<void> load(AdminDeparture departure) async {
    _departureId = departure.id;
    await loadSeats();
  }

  Future<void> loadSeats() async {
    final departureId = _departureId;
    if (departureId == null || departureId.isEmpty) return;
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        apiService.listDepartureSeats(
          departureId: departureId,
          status: status,
          seatType: seatType,
          seatNumber: seatNumber,
          isSelectable: isSelectable,
          ordering: _supportedOrdering(ordering),
        ),
        apiService.getAdminDepartureSeatMap(departureId),
      ]);
      seatsResponse = results[0] as AdminDepartureSeatsResponse;
      seatMap = results[1] as AdminDepartureSeatMap;
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStatus(String? value) async {
    status = _emptyToNull(value);
    await loadSeats();
  }

  Future<void> setSeatType(String? value) async {
    seatType = _emptyToNull(value);
    await loadSeats();
  }

  Future<void> setSeatNumber(String? value) async {
    final trimmed = _emptyToNull(value);
    seatNumber = trimmed == null ? null : int.tryParse(trimmed);
    await loadSeats();
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadSeats();
  }

  Future<bool> blockSeat(AdminDepartureSeat seat, String reason) async {
    return _submit(() => apiService.blockSeats(
          _departureId!,
          [seat.seatNumber],
          reason: reason,
        ));
  }

  Future<bool> unblockSeat(AdminDepartureSeat seat, String reason) async {
    return _submit(() => apiService.unblockSeats(
          _departureId!,
          [seat.seatNumber],
          reason: reason,
        ));
  }

  Future<bool> _submit(
      Future<AdminOperationActionResponse> Function() action) async {
    if (isSubmitting || _departureId == null) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadSeats();
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

  String? _supportedOrdering(String? value) {
    final trimmed = _emptyToNull(value);
    const supported = {
      'seat_number',
      '-seat_number',
      'status',
      '-status',
      'created_at',
      '-created_at',
      'updated_at',
      '-updated_at',
    };
    return trimmed != null && supported.contains(trimmed) ? trimmed : null;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
