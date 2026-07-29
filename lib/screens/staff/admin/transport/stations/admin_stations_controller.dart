import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminStationsController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;

  AdminStationsController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminStation>? stationsPage;
  List<AdminCompany> companies = const [];
  List<AdminCity> cities = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;

  String query = '';
  String? companyId;
  String? cityId;
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => stationsPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => stationsPage?.hasNext == true;

  Future<void> initialize() async {
    await loadReferenceData();
    await loadStations(resetPage: true);
  }

  Future<void> loadReferenceData() async {
    try {
      final results = await Future.wait([
        apiService.listCompanies(isActive: true, ordering: 'name', pageSize: 100),
        apiService.listCities(isActive: true, ordering: 'name', pageSize: 100),
      ]);
      companies = (results[0] as PagedResult<AdminCompany>).results;
      cities = (results[1] as PagedResult<AdminCity>).results;
    } catch (_) {
      companies = const [];
      cities = const [];
    }
  }

  Future<void> loadStations({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      stationsPage = await apiService.listStations(
        query: query,
        companyId: companyId,
        cityId: cityId,
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

  Future<void> refresh() async {
    await loadReferenceData();
    await loadStations();
  }

  Future<void> search(String value) async {
    query = value.trim();
    await loadStations(resetPage: true);
  }

  Future<void> setCompanyFilter(String? value) async {
    companyId = _emptyToNull(value);
    await loadStations(resetPage: true);
  }

  Future<void> setCityFilter(String? value) async {
    cityId = _emptyToNull(value);
    await loadStations(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadStations(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadStations(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadStations();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadStations();
  }

  Future<AdminStation> getDetail(String id) => apiService.getStation(id);

  Future<bool> createStation(AdminStationCreateRequest request) {
    return _submit(() => apiService.createStation(request));
  }

  Future<bool> updateStation(String id, AdminStationUpdateRequest request) {
    return _submit(() => apiService.updateStation(id, request));
  }

  Future<bool> activateStation(String id) {
    return _submit(() => apiService.activateStation(id));
  }

  Future<bool> deactivateStation(String id) {
    return _submit(() => apiService.deactivateStation(id));
  }

  Future<String?> deactivateStationCascade(String id) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      final (_, message) = await apiService.deactivateStationCascade(id);
      await loadStations();
      return message ?? 'Gare désactivée.';
    } catch (error) {
      structuredFormError = _structuredError(error);
      formError = structuredFormError?.userMessage ?? _messageFromError(error);
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _submit(Future<AdminStation> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadStations();
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
    if (trimmed == null || trimmed.isEmpty) return null;
    const supported = {'name', '-name', 'code', '-code', 'is_active', '-is_active', 'created_at', '-created_at', 'updated_at', '-updated_at'};
    return supported.contains(trimmed) ? trimmed : null;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return StructuredApiError.fromException(error).userMessage;
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  StructuredApiError? _structuredError(Object error) {
    if (error is ApiException) return StructuredApiError.fromException(error);
    return null;
  }
}
