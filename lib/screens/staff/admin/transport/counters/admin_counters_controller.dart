import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminCountersController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;

  AdminCountersController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  List<AdminStation> stations = const [];
  AdminStation? selectedStation;
  PagedResult<AdminStationCounter>? countersPage;
  bool isLoadingStations = false;
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

  bool get hasPreviousPage => countersPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => countersPage?.hasNext == true;

  Future<void> initialize() async {
    await loadStations();
    if (stations.isNotEmpty) {
      selectedStation = stations.first;
      await loadCounters(resetPage: true);
    }
  }

  Future<void> loadStations() async {
    isLoadingStations = true;
    notifyListeners();
    try {
      final page = await apiService.listStations(isActive: true, ordering: 'name', pageSize: 100);
      stations = page.results;
    } catch (error) {
      listError = _messageFromError(error);
      stations = const [];
    } finally {
      isLoadingStations = false;
      notifyListeners();
    }
  }

  Future<void> selectStation(String? stationId) async {
    selectedStation = _stationById(stationId);
    countersPage = null;
    await loadCounters(resetPage: true);
  }

  Future<void> loadCounters({bool resetPage = false}) async {
    if (resetPage) page = 1;
    if (selectedStation == null) {
      countersPage = null;
      notifyListeners();
      return;
    }
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      countersPage = await apiService.listCounters(stationId: selectedStation!.id, query: query, isActive: isActive, ordering: ordering, page: page, pageSize: pageSize);
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadStations();
    if (selectedStation != null && !stations.any((s) => s.id == selectedStation!.id)) selectedStation = stations.isEmpty ? null : stations.first;
    await loadCounters();
  }

  Future<void> search(String value) async { query = value.trim(); await loadCounters(resetPage: true); }
  Future<void> setActiveFilter(bool? value) async { isActive = value; await loadCounters(resetPage: true); }
  Future<void> setOrdering(String? value) async { ordering = _supportedOrdering(value); await loadCounters(resetPage: true); }
  Future<void> nextPage() async { if (!hasNextPage) return; page += 1; await loadCounters(); }
  Future<void> previousPage() async { if (page <= 1) return; page -= 1; await loadCounters(); }

  Future<AdminStationCounter> getDetail(String id) => apiService.getCounter(id);
  Future<bool> createCounter(AdminStationCounterCreateRequest request) { final station = selectedStation; if (station == null) return Future.value(false); return _submit(() => apiService.createCounter(stationId: station.id, request: request)); }
  Future<bool> updateCounter(String id, AdminStationCounterUpdateRequest request) => _submit(() => apiService.updateCounter(id, request));
  Future<bool> activateCounter(String id) => _submit(() => apiService.activateCounter(id));
  Future<bool> deactivateCounter(String id) => _submit(() => apiService.deactivateCounter(id));

  Future<bool> _submit(Future<AdminStationCounter> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try { await action(); await loadCounters(); return true; } catch (error) { structuredFormError = _structuredError(error); formError = structuredFormError?.userMessage ?? _messageFromError(error); return false; } finally { isSubmitting = false; notifyListeners(); }
  }


  AdminStation? _stationById(String? stationId) {
    if (stationId == null || stationId.trim().isEmpty) return null;
    for (final station in stations) {
      if (station.id == stationId) return station;
    }
    return null;
  }

  String? _supportedOrdering(String? value) { final trimmed = value?.trim(); if (trimmed == null || trimmed.isEmpty) return null; const supported = {'code', '-code', 'label', '-label', 'is_active', '-is_active', 'created_at', '-created_at', 'updated_at', '-updated_at'}; return supported.contains(trimmed) ? trimmed : null; }
  String _messageFromError(Object error) { if (error is ApiException) return StructuredApiError.fromException(error).userMessage; return 'Une erreur est survenue. Veuillez réessayer.'; }
  StructuredApiError? _structuredError(Object error) { if (error is ApiException) return StructuredApiError.fromException(error); return null; }
}
