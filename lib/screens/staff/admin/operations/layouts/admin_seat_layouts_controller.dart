import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/operations/seat_layout_seat.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

class AdminSeatLayoutsController extends ChangeNotifier {
  final AdminOperationsApiService apiService;

  AdminSeatLayoutsController({AdminOperationsApiService? apiService})
      : apiService = apiService ?? AdminOperationsApiService();

  PagedResult<AdminOperationRecord>? seatLayoutsPage;
  PagedResult<SeatLayoutSeat>? seatsPage;
  AdminOperationRecord? selectedLayout;
  bool isLoading = false;
  bool isLoadingDetail = false;
  String? listError;
  String? detailError;
  String? query;
  bool? isActive;
  String? ordering;
  int page = 1;
  int pageSize = 20;

  bool get hasPreviousPage => seatLayoutsPage?.hasPrevious == true || page > 1;
  bool get hasNextPage => seatLayoutsPage?.hasNext == true;

  Future<void> initialize() async {
    await loadLayouts(resetPage: true);
  }

  Future<void> loadLayouts({bool resetPage = false}) async {
    if (resetPage) page = 1;
    isLoading = true;
    listError = null;
    notifyListeners();
    try {
      seatLayoutsPage = await apiService.listSeatLayouts(
        query: query,
        isActive: isActive,
        ordering: _supportedOrdering(ordering),
        page: page,
        pageSize: pageSize,
      );
      if (seatLayoutsPage != null && seatLayoutsPage!.results.isNotEmpty) {
        final selectedId = selectedLayout?.id;
        final availableSelection = seatLayoutsPage!.results.firstWhere(
          (layout) => layout.id == selectedId,
          orElse: () => seatLayoutsPage!.results.first,
        );
        if (selectedLayout == null ||
            selectedLayout?.id != availableSelection.id) {
          await selectLayout(availableSelection);
        }
      } else {
        selectedLayout = null;
        seatsPage = null;
      }
    } catch (error) {
      listError = _messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadLayouts();
  }

  Future<void> setQuery(String? value) async {
    query = _emptyToNull(value);
    await loadLayouts(resetPage: true);
  }

  Future<void> setActive(String? value) async {
    switch (_emptyToNull(value)) {
      case 'true':
        isActive = true;
        break;
      case 'false':
        isActive = false;
        break;
      default:
        isActive = null;
    }
    await loadLayouts(resetPage: true);
  }

  Future<void> setOrdering(String? value) async {
    ordering = _supportedOrdering(value);
    await loadLayouts(resetPage: true);
  }

  Future<void> nextPage() async {
    if (!hasNextPage) return;
    page += 1;
    await loadLayouts();
  }

  Future<void> previousPage() async {
    if (page <= 1) return;
    page -= 1;
    await loadLayouts();
  }

  Future<void> selectLayout(AdminOperationRecord layout) async {
    selectedLayout = layout;
    isLoadingDetail = true;
    detailError = null;
    notifyListeners();
    try {
      final detail = await apiService.getSeatLayout(layout.id);
      selectedLayout = detail;
      seatsPage = await apiService.listSeatLayoutSeats(
        layout.id,
        ordering: 'seat_number',
        pageSize: 200,
      );
    } catch (error) {
      detailError = _messageFromError(error);
    } finally {
      isLoadingDetail = false;
      notifyListeners();
    }
  }

  String? _supportedOrdering(String? value) {
    final trimmed = _emptyToNull(value);
    const supported = {
      'name',
      '-name',
      'total_seats',
      '-total_seats',
      'is_active',
      '-is_active',
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
      return error.toString();
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
