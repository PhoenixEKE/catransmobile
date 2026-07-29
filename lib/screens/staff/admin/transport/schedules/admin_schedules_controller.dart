import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminSchedulesController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;
  AdminSchedulesController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminSchedule>? schedulesPage;
  List<AdminStation> stations = const [];
  List<AdminRoute> routes = const [];
  List<AdminServiceClass> serviceClasses = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;
  String query = '';
  String? stationId;
  String? routeId;
  String? serviceClassId;
  String departureTime = '';
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => schedulesPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => schedulesPage?.hasNext == true;

  Future<void> initialize() async {
    await loadReferenceData();
    await loadSchedules(resetPage: true);
  }

  Future<void> loadReferenceData() async {
    try {
      final results = await Future.wait([
        apiService.listStations(
            isActive: true, ordering: 'name', pageSize: 100),
        apiService.listRoutes(
            isActive: true,
            ordering: 'destination_name_snapshot',
            pageSize: 100),
        apiService.listServiceClasses(
            isActive: true, ordering: 'name', pageSize: 100),
      ]);
      stations = (results[0] as PagedResult<AdminStation>).results;
      routes = (results[1] as PagedResult<AdminRoute>).results;
      serviceClasses = (results[2] as PagedResult<AdminServiceClass>).results;
    } catch (_) {
      stations = const [];
      routes = const [];
      serviceClasses = const [];
    }
  }

  Future<void> loadSchedules({bool resetPage = false}) async {
    if (resetPage) {
      page = 1;
    }
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      schedulesPage = await apiService.listSchedules(
          query: query,
          stationId: stationId,
          routeId: routeId,
          serviceClassId: serviceClassId,
          departureTime: departureTime,
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
    await loadSchedules();
  }

  Future<void> search(String value) async {
    query = value.trim();
    await loadSchedules(resetPage: true);
  }

  Future<void> setStationFilter(String? value) async {
    stationId = _emptyToNull(value);
    await loadSchedules(resetPage: true);
  }

  Future<void> setRouteFilter(String? value) async {
    routeId = _emptyToNull(value);
    await loadSchedules(resetPage: true);
  }

  Future<void> setServiceClassFilter(String? value) async {
    serviceClassId = _emptyToNull(value);
    await loadSchedules(resetPage: true);
  }

  Future<void> setDepartureTimeFilter(String value) async {
    departureTime = normalizeScheduleTime(value);
    await loadSchedules(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadSchedules(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadSchedules(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) {
      return;
    }
    page += 1;
    await loadSchedules();
  }

  Future<void> previousPage() async {
    if (page <= 1) {
      return;
    }
    page -= 1;
    await loadSchedules();
  }

  Future<AdminSchedule> getDetail(String id) => apiService.getSchedule(id);
  Future<bool> createSchedule(AdminScheduleCreateRequest request) =>
      _submit(() => apiService.createSchedule(request));
  Future<bool> updateSchedule(String id, AdminScheduleUpdateRequest request) =>
      _submit(() => apiService.updateSchedule(id, request));
  Future<bool> activateSchedule(String id) =>
      _submit(() => apiService.activateSchedule(id));
  Future<bool> deactivateSchedule(String id) =>
      _submit(() => apiService.deactivateSchedule(id));

  Future<bool> _submit(Future<AdminSchedule> Function() action) async {
    if (isSubmitting) {
      return false;
    }
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      await action();
      await loadSchedules();
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
      'departure_time',
      '-departure_time',
      'departure_time_raw',
      '-departure_time_raw',
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
