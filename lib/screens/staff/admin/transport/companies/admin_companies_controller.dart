import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

class AdminCompaniesController extends ChangeNotifier {
  final AdminTransportBaseApiService apiService;

  AdminCompaniesController({AdminTransportBaseApiService? apiService})
      : apiService = apiService ?? AdminTransportBaseApiService();

  PagedResult<AdminCompany>? companiesPage;
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

  bool get hasPreviousPage => companiesPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => companiesPage?.hasNext == true;

  Future<void> initialize() => loadCompanies(resetPage: true);

  Future<void> loadCompanies({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();

    try {
      companiesPage = await apiService.listCompanies(
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

  Future<void> refresh() => loadCompanies();

  Future<void> search(String value) async {
    query = value.trim();
    await loadCompanies(resetPage: true);
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await loadCompanies(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadCompanies(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadCompanies();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadCompanies();
  }

  Future<AdminCompany> getDetail(String id) {
    return apiService.getCompany(id);
  }

  Future<bool> createCompany(AdminCompanyCreateRequest request) async {
    return _submit(() => apiService.createCompany(request));
  }

  Future<bool> updateCompany(
    String id,
    AdminCompanyUpdateRequest request,
  ) async {
    return _submit(() => apiService.updateCompany(id, request));
  }

  Future<bool> activateCompany(String id) async {
    return _submit(() => apiService.activateCompany(id));
  }

  Future<bool> deactivateCompany(String id) async {
    return _submit(() => apiService.deactivateCompany(id));
  }

  Future<bool> _submit(Future<AdminCompany> Function() action) async {
    if (isSubmitting) return false;
    isSubmitting = true;
    formError = null;
    structuredFormError = null;
    notifyListeners();

    try {
      await action();
      await loadCompanies();
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
      'code',
      '-code',
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
