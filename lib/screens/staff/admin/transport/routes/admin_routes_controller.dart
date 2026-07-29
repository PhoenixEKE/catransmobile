import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminRoutesController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;
  AdminRoutesController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminRoute>? routesPage;
  List<AdminCompany> companies = const [];
  List<AdminStation> stations = const [];
  List<AdminCity> cities = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String query = '';
  String? companyId;
  String? departureStationId;
  String? departureCityId;
  String? destinationCityId;
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => routesPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => routesPage?.hasNext == true;

  Future<void> initialize() async {
    await loadReferenceData();
    await loadRoutes(resetPage: true);
  }

  Future<void> loadReferenceData() async {
    try {
      final results = await Future.wait([
        apiService.listCompanies(
            isActive: true, ordering: 'name', pageSize: 100),
        apiService.listStations(
            isActive: true, ordering: 'name', pageSize: 100),
        apiService.listCities(isActive: true, ordering: 'name', pageSize: 100),
      ]);
      companies = (results[0] as PagedResult<AdminCompany>).results;
      stations = (results[1] as PagedResult<AdminStation>).results;
      cities = (results[2] as PagedResult<AdminCity>).results;
    } catch (_) {
      companies = const [];
      stations = const [];
      cities = const [];
    }
  }

  Future<void> loadRoutes({bool resetPage = false}) async {
    if (resetPage) {
      page = 1;
    }
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      routesPage = await apiService.listRoutes(
          query: query,
          companyId: companyId,
          departureStationId: departureStationId,
          departureCityId: departureCityId,
          destinationCityId: destinationCityId,
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
    await loadRoutes();
  }

  Future<void> search(String value) async {
    query = value.trim();
    await loadRoutes(resetPage: true);
  }

  Future<void> setCompanyFilter(String? value) async {
    companyId = _emptyToNull(value);
    await loadRoutes(resetPage: true);
  }

  Future<void> setDepartureStationFilter(String? value) async {
    departureStationId = _emptyToNull(value);
    await loadRoutes(resetPage: true);
  }

  Future<void> setDepartureCityFilter(String? value) async {
    departureCityId = _emptyToNull(value);
    await loadRoutes(resetPage: true);
  }

  Future<void> setDestinationCityFilter(String? value) async {
    destinationCityId = _emptyToNull(value);
    await loadRoutes(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadRoutes(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadRoutes(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) {
      return;
    }
    page += 1;
    await loadRoutes();
  }

  Future<void> previousPage() async {
    if (page <= 1) {
      return;
    }
    page -= 1;
    await loadRoutes();
  }

  Future<AdminRoute> getDetail(String id) => apiService.getRoute(id);
  Future<bool> createRoute(AdminRouteCreateRequest request) =>
      _submit(() => apiService.createRoute(request));
  Future<bool> updateRoute(String id, AdminRouteUpdateRequest request) =>
      _submit(() => apiService.updateRoute(id, request));
  Future<bool> activateRoute(String id) =>
      _submit(() => apiService.activateRoute(id));
  Future<bool> deactivateRoute(String id) =>
      _submit(() => apiService.deactivateRoute(id));

  Future<String?> deactivateRouteCascade(String id) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      final (_, message) = await apiService.deactivateRouteCascade(id);
      await loadRoutes();
      return message ?? 'Route désactivée.';
    } catch (error) {
      structuredFormError = _structuredError(error);
      formError = structuredFormError?.userMessage ?? _messageFromError(error);
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _submit(Future<AdminRoute> Function() action) async {
    if (isSubmitting) {
      return false;
    }
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadRoutes();
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
      'destination_name_snapshot',
      '-destination_name_snapshot',
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
