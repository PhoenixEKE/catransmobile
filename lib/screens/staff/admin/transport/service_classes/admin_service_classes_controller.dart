import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminServiceClassesController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;

  AdminServiceClassesController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminServiceClass>? serviceClassesPage;
  bool isLoading = false;
  bool isSubmitting = false;
  String? listError;
  String? formError;
  StructuredApiError? structuredFormError;

  String query = '';
  bool? isActive;
  bool? allowsSeatSelection;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => serviceClassesPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => serviceClassesPage?.hasNext == true;

  Future<void> initialize() => loadServiceClasses(resetPage: true);

  Future<void> loadServiceClasses({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();

    try {
      serviceClassesPage = await apiService.listServiceClasses(
        query: query,
        isActive: isActive,
        allowsSeatSelection: allowsSeatSelection,
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

  Future<void> refresh() => loadServiceClasses();

  Future<void> search(String value) async {
    query = value.trim();
    await loadServiceClasses(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadServiceClasses(resetPage: true);
  }

  Future<void> setSeatSelectionFilter(bool? value) async {
    allowsSeatSelection = value;
    await loadServiceClasses(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadServiceClasses(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadServiceClasses();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadServiceClasses();
  }

  Future<AdminServiceClass> getDetail(String id) => apiService.getServiceClass(id);

  Future<bool> createServiceClass(AdminServiceClassCreateRequest request) async {
    return _submit(() => apiService.createServiceClass(request));
  }

  Future<bool> updateServiceClass(
    String id,
    AdminServiceClassUpdateRequest request,
  ) async {
    return _submit(() => apiService.updateServiceClass(id, request));
  }

  Future<bool> activateServiceClass(String id) async {
    return _submit(() => apiService.activateServiceClass(id));
  }

  Future<bool> deactivateServiceClass(String id) async {
    return _submit(() => apiService.deactivateServiceClass(id));
  }

  Future<String?> deactivateServiceClassCascade(String id) async {
    if (isSubmitting) return null;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();
    try {
      final (_, message) = await apiService.deactivateServiceClassCascade(id);
      await loadServiceClasses();
      return message ?? 'Classe de service désactivée.';
    } catch (error) {
      structuredFormError = _structuredError(error);
      formError = structuredFormError?.userMessage ?? _messageFromError(error);
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _submit(Future<AdminServiceClass> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();

    try {
      await action();
      await loadServiceClasses();
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
      'code',
      '-code',
      'name',
      '-name',
      'default_loyalty_points',
      '-default_loyalty_points',
      'reward_threshold_points',
      '-reward_threshold_points',
      'allows_seat_selection',
      '-allows_seat_selection',
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
