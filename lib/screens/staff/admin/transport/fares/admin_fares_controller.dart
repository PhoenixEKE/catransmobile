import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminFaresController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;
  AdminFaresController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminFare>? faresPage;
  List<AdminRoute> routes = const [];
  List<AdminServiceClass> serviceClasses = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String query = '';
  String? routeId;
  String? serviceClassId;
  String? currency;
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => faresPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => faresPage?.hasNext == true;

  Future<void> initialize() async {
    await loadReferenceData();
    await loadFares(resetPage: true);
  }

  Future<void> loadReferenceData() async {
    try {
      final results = await Future.wait([
        apiService.listRoutes(
            isActive: true,
            ordering: 'destination_name_snapshot',
            pageSize: 100),
        apiService.listServiceClasses(
            isActive: true, ordering: 'name', pageSize: 100),
      ]);
      routes = (results[0] as PagedResult<AdminRoute>).results;
      serviceClasses = (results[1] as PagedResult<AdminServiceClass>).results;
    } catch (_) {
      routes = const [];
      serviceClasses = const [];
    }
  }

  Future<void> loadFares({bool resetPage = false}) async {
    if (resetPage) {
      page = 1;
    }
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      faresPage = await apiService.listFares(
          query: query,
          routeId: routeId,
          serviceClassId: serviceClassId,
          currency: currency,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadReferenceData();
    await loadFares();
  }

  Future<void> search(String value) async {
    query = value.trim();
    await loadFares(resetPage: true);
  }

  Future<void> setRouteFilter(String? value) async {
    routeId = _emptyToNull(value);
    await loadFares(resetPage: true);
  }

  Future<void> setServiceClassFilter(String? value) async {
    serviceClassId = _emptyToNull(value);
    await loadFares(resetPage: true);
  }

  Future<void> setCurrencyFilter(String? value) async {
    currency = _emptyToNull(value)?.toUpperCase();
    await loadFares(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadFares(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadFares(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) {
      return;
    }
    page += 1;
    await loadFares();
  }

  Future<void> previousPage() async {
    if (page <= 1) {
      return;
    }
    page -= 1;
    await loadFares();
  }

  Future<AdminFare> getDetail(String id) => apiService.getFare(id);
  Future<bool> createFare(AdminFareCreateRequest request) =>
      _submit(() => apiService.createFare(request));
  Future<bool> replaceFare(String id, AdminFareReplaceRequest request) =>
      _submit(() => apiService.replaceFare(id, request));
  Future<bool> activateFare(String id) =>
      _submit(() => apiService.activateFare(id));
  Future<bool> deactivateFare(String id) =>
      _submit(() => apiService.deactivateFare(id));

  Future<bool> _submit(Future<AdminFare> Function() action) async {
    if (isSubmitting) {
      return false;
    }
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadFares();
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
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    const supported = {
      'amount',
      '-amount',
      'currency',
      '-currency',
      'is_active',
      '-is_active',
      'created_at',
      '-created_at',
      'updated_at',
      '-updated_at'
    };
    return supported.contains(trimmed) ? trimmed : null;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  StructuredApiError? _structuredError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error);
    }
    return null;
  }
}
