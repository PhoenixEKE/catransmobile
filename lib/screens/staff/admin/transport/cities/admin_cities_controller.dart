import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminCitiesController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;

  AdminCitiesController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminCity>? citiesPage;
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;

  String query = '';
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => citiesPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => citiesPage?.hasNext == true;

  Future<void> initialize() => loadCities(resetPage: true);

  Future<void> loadCities({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();

    try {
      citiesPage = await apiService.listCities(
        query: query,
        isActive: isActive,
        ordering: ordering,
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

  Future<void> refresh() => loadCities();

  Future<void> search(String value) async {
    query = value.trim();
    await loadCities(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadCities(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadCities(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadCities();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadCities();
  }

  Future<AdminCity> getDetail(String id) => apiService.getCity(id);

  Future<bool> createCity(AdminCityCreateRequest request) async {
    return _submit(() => apiService.createCity(request));
  }

  Future<bool> updateCity(String id, AdminCityUpdateRequest request) async {
    return _submit(() => apiService.updateCity(id, request));
  }

  Future<bool> activateCity(String id) async {
    return _submit(() => apiService.activateCity(id));
  }

  Future<bool> deactivateCity(String id) async {
    return _submit(() => apiService.deactivateCity(id));
  }

  Future<bool> _submit(Future<AdminCity> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();

    try {
      await action();
      await loadCities();
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

  String? _supportedOrdering(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    const supported = {
      'name',
      '-name',
      'country',
      '-country',
      'is_active',
      '-is_active',
      'created_at',
      '-created_at',
      'updated_at',
      '-updated_at',
    };
    return supported.contains(trimmed) ? trimmed : null;
  }
}
