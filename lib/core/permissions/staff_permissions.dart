class StaffPermissions {
  static const adminUsersRead = 'admin.users.read';
  static const adminUsersManage = 'admin.users.manage';
  static const adminTransportRead = 'admin.transport.read';
  static const adminTransportManage = 'admin.transport.manage';
  static const adminOperationsRead = 'admin.operations.read';
  static const adminOperationsManage = 'admin.operations.manage';
  static const adminDashboardRead = 'admin.dashboard.read';
  static const stationAllRead = 'station.all.read';
  static const stationDashboardRead = 'station.dashboard.read';
  static const stationDeparturesRead = 'station.departures.read';
  static const stationDeparturesManage = 'station.departures.manage';
  static const stationReservationsSearch = 'station.reservations.search';
  static const stationReservationsRead = 'station.reservations.read';
  static const stationTicketsRead = 'station.tickets.read';
  static const stationTicketsPrint = 'station.tickets.print';
  static const stationReportsManage = 'station.reports.manage';
  static const stationSalesCash = 'station.sales.cash';
  static const boardingManifestRead = 'boarding.manifest.read';
  static const boardingSummaryRead = 'boarding.summary.read';
  static const boardingValidate = 'boarding.validate';

  final Set<String> scopes;

  StaffPermissions(Iterable<String> scopes) : scopes = scopes.toSet();

  factory StaffPermissions.fromScopes(Iterable<String> scopes) {
    return StaffPermissions(scopes);
  }

  bool hasScope(String scope) => scopes.contains(scope);

  bool hasAnyScope(Iterable<String> expectedScopes) {
    return expectedScopes.any(scopes.contains);
  }

  bool get canReadAdminUsers => hasAnyScope(const [
        adminUsersRead,
        adminUsersManage,
      ]);

  bool get canManageAdminUsers => hasScope(adminUsersManage);

  bool get canReadAdminTransport => hasAnyScope(const [
        adminTransportRead,
        adminTransportManage,
      ]);

  bool get canManageAdminTransport => hasScope(adminTransportManage);

  bool get canReadAdminOperations => hasAnyScope(const [
        adminOperationsRead,
        adminOperationsManage,
      ]);

  bool get canManageAdminOperations => hasScope(adminOperationsManage);

  bool get canReadAdminDashboard => hasScope(adminDashboardRead);

  bool get canReadAllStations => hasScope(stationAllRead);

  bool get canSellCashAtStation => hasScope(stationSalesCash);

  bool get canReadBoardingManifest => hasScope(boardingManifestRead);

  bool get canReadBoardingSummary => hasScope(boardingSummaryRead);

  bool get canValidateBoarding => hasScope(boardingValidate);
}
