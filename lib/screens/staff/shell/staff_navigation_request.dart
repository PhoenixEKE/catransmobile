class StaffNavigationRequest {
  final String menuId;
  final String? departureId;

  const StaffNavigationRequest({
    required this.menuId,
    this.departureId,
  });

  bool get hasDepartureContext =>
      departureId != null && departureId!.trim().isNotEmpty;
}
