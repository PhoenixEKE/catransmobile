import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';

class AdminUsersController extends ChangeNotifier {
  final AdminUsersApiService apiService;

  AdminUsersController({AdminUsersApiService? apiService})
      : apiService = apiService ?? AdminUsersApiService();

  PagedResult<AdminInternalUserSummary>? usersPage;
  List<AdminInternalRoleOption> roles = const [];
  List<StaffStationRef> stations = const [];
  List<StaffCounterRef> counters = const [];

  bool isLoadingUsers = false;
  bool isLoadingOptions = false;
  bool isLoadingCounters = false;
  bool isSubmitting = false;
  String? listError;
  String? optionsError;
  String? formError;
  StructuredApiError? structuredFormError;

  String query = '';
  String? role;
  String? stationId;
  String? counterId;
  bool? isActive;
  int page = 1;
  int pageSize = 20;
  Timer? _searchDebounce;

  bool get hasUsers => usersPage?.results.isNotEmpty == true;
  bool get hasPreviousPage => usersPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => usersPage?.hasNext == true;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    await Future.wait([loadOptions(), loadUsers(resetPage: true)]);
  }

  Future<void> loadOptions() async {
    isLoadingOptions = true;
    optionsError = null;
    notifyListeners();

    try {
      roles = await apiService.listRoles();
      stations = await apiService.listStations();
    } catch (error) {
      optionsError = _messageFromError(error);
    } finally {
      isLoadingOptions = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoadingUsers = true;
    listError = null;
    notifyListeners();

    try {
      usersPage = await apiService.listUsers(
        query: query,
        role: role,
        stationId: stationId,
        counterId: counterId,
        isActive: isActive,
        page: page,
        pageSize: pageSize,
      );
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadUsers();

  Future<void> search(String value) async {
    query = value.trim();
    await loadUsers(resetPage: true);
  }

  void searchDebounced(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      search(value);
    });
  }

  Future<void> setRole(String? value) async {
    role = _emptyToNull(value);
    await loadUsers(resetPage: true);
  }

  Future<void> setStation(String? value) async {
    stationId = _emptyToNull(value);
    counterId = null;
    counters = const [];
    notifyListeners();
    await loadCountersForStation(stationId);
    await loadUsers(resetPage: true);
  }

  Future<void> setCounter(String? value) async {
    counterId = _emptyToNull(value);
    await loadUsers(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadUsers(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadUsers();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadUsers();
  }

  Future<void> resetFilters() async {
    _searchDebounce?.cancel();
    query = '';
    role = null;
    stationId = null;
    counterId = null;
    isActive = null;
    counters = const [];
    notifyListeners();
    await loadUsers(resetPage: true);
  }

  Future<void> loadCountersForStation(String? selectedStationId) async {
    if (selectedStationId == null || selectedStationId.isEmpty) {
      counters = const [];
      notifyListeners();
      return;
    }

    isLoadingCounters = true;
    notifyListeners();
    try {
      counters = await apiService.listCounters(stationId: selectedStationId);
    } catch (error) {
      counters = const [];
      optionsError = _messageFromError(error);
    } finally {
      isLoadingCounters = false;
      notifyListeners();
    }
  }

  Future<List<StaffCounterRef>> countersForStation(
      String? selectedStationId) async {
    if (selectedStationId == null || selectedStationId.isEmpty) return const [];
    return apiService.listCounters(stationId: selectedStationId);
  }

  Future<AdminInternalUserDetail> getDetail(String id) {
    return apiService.getUser(id);
  }

  Future<bool> createUser(AdminInternalUserCreateRequest request) async {
    return _submit(() => apiService.createUser(request));
  }

  Future<bool> updateUser(
    String id,
    AdminInternalUserUpdateRequest request,
  ) async {
    return _submit(() => apiService.updateUser(id, request));
  }

  Future<bool> activateUser(String id) async {
    return _submit(() => apiService.activateUser(id));
  }

  Future<bool> deactivateUser(String id) async {
    return _submit(() => apiService.deactivateUser(id));
  }

  Future<bool> _submit(Future<dynamic> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();

    try {
      await action();
      await loadUsers();
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

  AdminInternalRoleOption? roleOption(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final option in roles) {
      if (option.value == value) return option;
    }
    return null;
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

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
