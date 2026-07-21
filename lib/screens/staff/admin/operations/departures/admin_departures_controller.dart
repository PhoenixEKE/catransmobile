import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

class AdminDeparturesController extends ChangeNotifier {
  final AdminOperationsApiService apiService;

  AdminDeparturesController({AdminOperationsApiService? apiService})
      : apiService = apiService ?? AdminOperationsApiService();

  PagedResult<AdminDeparture>? departuresPage;
  List<AdminOperationRecord> templates = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String? selectedStatus;
  String? dateFrom;
  String? dateTo;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => departuresPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => departuresPage?.hasNext == true;

  Future<void> initialize() async {
    await loadTemplates();
    await loadDepartures(resetPage: true);
  }

  Future<void> loadTemplates() async {
    try {
      final result = await apiService.listDepartureTemplates(
        isActive: true,
        ordering: 'departure_time_raw',
        pageSize: 100,
      );
      templates = result.results;
    } catch (_) {
      templates = const [];
    }
  }

  Future<void> loadDepartures({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      departuresPage = await apiService.listAdminDepartures(
        status: selectedStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
        ordering: _supportedOrdering(ordering),
        page: page,
        pageSize: pageSize,
      );
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadTemplates();
    await loadDepartures();
  }

  Future<void> setStatus(String? value) async {
    selectedStatus = _emptyToNull(value);
    await loadDepartures(resetPage: true);
  }

  Future<void> setDateRange({String? from, String? to}) async {
    dateFrom = _emptyToNull(from);
    dateTo = _emptyToNull(to);
    await loadDepartures(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadDepartures(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadDepartures();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadDepartures();
  }

  Future<AdminDeparture> getDetail(String id) =>
      apiService.getAdminDeparture(id);

  Future<bool> createDeparture(AdminDepartureCreateRequest request) async {
    return _submit(() async => apiService.createAdminDeparture(request));
  }

  Future<bool> updateDepartureDate(
    String id,
    AdminDepartureDateUpdateRequest request,
  ) async {
    return _submit(
        () async => apiService.updateAdminDepartureDate(id, request));
  }

  Future<bool> generateSeats(String id) async {
    return _submit(() async => apiService.generateSeats(id));
  }

  Future<bool> openDeparture(String id) async {
    return _submit(() async => apiService.openDeparture(id));
  }

  Future<bool> closeDeparture(String id) async {
    return _submit(() async => apiService.closeDeparture(id));
  }

  Future<bool> markDeparted(String id) async {
    return _submit(() async => apiService.markDeparted(id));
  }

  Future<bool> cancelDeparture(String id) async {
    return _submit(() async => apiService.cancelDeparture(id));
  }

  Future<bool> _submit(Future<Object> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadDepartures();
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
      'departure_date',
      '-departure_date',
      'departure_time',
      '-departure_time',
      'departure_time_raw',
      '-departure_time_raw',
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
