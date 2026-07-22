import 'package:catrans_app/models/staff/paged_result.dart';

class AdminDashboardOverviewResponse {
  final String date;
  final AdminDashboardReservations reservations;
  final AdminDashboardPayments payments;
  final AdminDashboardTickets tickets;
  final AdminDashboardDepartures departures;
  final AdminDashboardSeats seats;
  final AdminDashboardRequests requests;

  const AdminDashboardOverviewResponse({
    required this.date,
    required this.reservations,
    required this.payments,
    required this.tickets,
    required this.departures,
    required this.seats,
    required this.requests,
  });

  factory AdminDashboardOverviewResponse.fromJson(JsonMap json) {
    return AdminDashboardOverviewResponse(
      date: _readString(json['date']),
      reservations: AdminDashboardReservations.fromJson(
        _readMap(json['reservations']),
      ),
      payments: AdminDashboardPayments.fromJson(_readMap(json['payments'])),
      tickets: AdminDashboardTickets.fromJson(_readMap(json['tickets'])),
      departures:
          AdminDashboardDepartures.fromJson(_readMap(json['departures'])),
      seats: AdminDashboardSeats.fromJson(_readMap(json['seats'])),
      requests: AdminDashboardRequests.fromJson(_readMap(json['requests'])),
    );
  }
}

class AdminDashboardReservations {
  final int todayTotal;
  final int pendingPayment;
  final int confirmed;
  final int cancelled;

  const AdminDashboardReservations({
    required this.todayTotal,
    required this.pendingPayment,
    required this.confirmed,
    required this.cancelled,
  });

  factory AdminDashboardReservations.fromJson(JsonMap json) {
    return AdminDashboardReservations(
      todayTotal: _readInt(json['today_total']),
      pendingPayment: _readInt(json['pending_payment']),
      confirmed: _readInt(json['confirmed']),
      cancelled: _readInt(json['cancelled']),
    );
  }
}

class AdminDashboardPayments {
  final int todayTotal;
  final int success;
  final int failed;
  final int pending;
  final String revenue;
  final String currency;

  const AdminDashboardPayments({
    required this.todayTotal,
    required this.success,
    required this.failed,
    required this.pending,
    required this.revenue,
    required this.currency,
  });

  factory AdminDashboardPayments.fromJson(JsonMap json) {
    return AdminDashboardPayments(
      todayTotal: _readInt(json['today_total']),
      success: _readInt(json['success']),
      failed: _readInt(json['failed']),
      pending: _readInt(json['pending']),
      revenue: _readString(json['revenue']),
      currency: _readString(json['currency'], fallback: 'XOF'),
    );
  }
}

class AdminDashboardTickets {
  final int todayTotal;
  final int issued;
  final int used;
  final int cancelled;

  const AdminDashboardTickets({
    required this.todayTotal,
    required this.issued,
    required this.used,
    required this.cancelled,
  });

  factory AdminDashboardTickets.fromJson(JsonMap json) {
    return AdminDashboardTickets(
      todayTotal: _readInt(json['today_total']),
      issued: _readInt(json['issued']),
      used: _readInt(json['used']),
      cancelled: _readInt(json['cancelled']),
    );
  }
}

class AdminDashboardDepartures {
  final int todayTotal;
  final int scheduled;
  final int open;
  final int closed;
  final int departed;
  final int cancelled;

  const AdminDashboardDepartures({
    required this.todayTotal,
    required this.scheduled,
    required this.open,
    required this.closed,
    required this.departed,
    required this.cancelled,
  });

  factory AdminDashboardDepartures.fromJson(JsonMap json) {
    return AdminDashboardDepartures(
      todayTotal: _readInt(json['today_total']),
      scheduled: _readInt(json['scheduled']),
      open: _readInt(json['open']),
      closed: _readInt(json['closed']),
      departed: _readInt(json['departed']),
      cancelled: _readInt(json['cancelled']),
    );
  }
}

class AdminDashboardSeats {
  final int todayTotal;
  final int available;
  final int held;
  final int reserved;
  final int blocked;

  const AdminDashboardSeats({
    required this.todayTotal,
    required this.available,
    required this.held,
    required this.reserved,
    required this.blocked,
  });

  factory AdminDashboardSeats.fromJson(JsonMap json) {
    return AdminDashboardSeats(
      todayTotal: _readInt(json['today_total']),
      available: _readInt(json['available']),
      held: _readInt(json['held']),
      reserved: _readInt(json['reserved']),
      blocked: _readInt(json['blocked']),
    );
  }
}

class AdminDashboardRequests {
  final int pendingChanges;
  final int pendingCancellations;

  const AdminDashboardRequests({
    required this.pendingChanges,
    required this.pendingCancellations,
  });

  factory AdminDashboardRequests.fromJson(JsonMap json) {
    return AdminDashboardRequests(
      pendingChanges: _readInt(json['pending_changes']),
      pendingCancellations: _readInt(json['pending_cancellations']),
    );
  }
}

class AdminDashboardSalesByChannelResponse {
  final String date;
  final List<AdminDashboardChannelSales> results;

  const AdminDashboardSalesByChannelResponse({
    required this.date,
    required this.results,
  });

  factory AdminDashboardSalesByChannelResponse.fromJson(JsonMap json) {
    return AdminDashboardSalesByChannelResponse(
      date: _readString(json['date']),
      results: _readList(json['results'])
          .map((item) => AdminDashboardChannelSales.fromJson(_readMap(item)))
          .toList(),
    );
  }
}

class AdminDashboardChannelSales {
  final String channel;
  final int total;

  const AdminDashboardChannelSales({
    required this.channel,
    required this.total,
  });

  factory AdminDashboardChannelSales.fromJson(JsonMap json) {
    return AdminDashboardChannelSales(
      channel: _readString(json['channel']),
      total: _readInt(json['total']),
    );
  }
}

class AdminDashboardRevenueByPaymentMethodResponse {
  final String date;
  final String currency;
  final List<AdminDashboardPaymentMethodRevenue> results;

  const AdminDashboardRevenueByPaymentMethodResponse({
    required this.date,
    required this.currency,
    required this.results,
  });

  factory AdminDashboardRevenueByPaymentMethodResponse.fromJson(JsonMap json) {
    return AdminDashboardRevenueByPaymentMethodResponse(
      date: _readString(json['date']),
      currency: _readString(json['currency'], fallback: 'XOF'),
      results: _readList(json['results'])
          .map((item) =>
              AdminDashboardPaymentMethodRevenue.fromJson(_readMap(item)))
          .toList(),
    );
  }
}

class AdminDashboardPaymentMethodRevenue {
  final String method;
  final String provider;
  final String totalAmount;
  final int totalPayments;

  const AdminDashboardPaymentMethodRevenue({
    required this.method,
    required this.provider,
    required this.totalAmount,
    required this.totalPayments,
  });

  factory AdminDashboardPaymentMethodRevenue.fromJson(JsonMap json) {
    return AdminDashboardPaymentMethodRevenue(
      method: _readString(json['method']),
      provider: _readString(json['provider']),
      totalAmount: _readString(json['total_amount']),
      totalPayments: _readInt(json['total_payments']),
    );
  }
}

class AdminDashboardTopRoutesResponse {
  final String date;
  final String currency;
  final List<AdminDashboardTopRoute> results;

  const AdminDashboardTopRoutesResponse({
    required this.date,
    required this.currency,
    required this.results,
  });

  factory AdminDashboardTopRoutesResponse.fromJson(JsonMap json) {
    return AdminDashboardTopRoutesResponse(
      date: _readString(json['date']),
      currency: _readString(json['currency'], fallback: 'XOF'),
      results: _readList(json['results'])
          .map((item) => AdminDashboardTopRoute.fromJson(_readMap(item)))
          .toList(),
    );
  }
}

class AdminDashboardTopRoute {
  final String routeId;
  final String destination;
  final int totalTickets;
  final String revenue;

  const AdminDashboardTopRoute({
    required this.routeId,
    required this.destination,
    required this.totalTickets,
    required this.revenue,
  });

  factory AdminDashboardTopRoute.fromJson(JsonMap json) {
    return AdminDashboardTopRoute(
      routeId: _readString(json['route_id']),
      destination: _readString(json['destination']),
      totalTickets: _readInt(json['total_tickets']),
      revenue: _readString(json['revenue']),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

JsonMap _readMap(dynamic value) {
  if (value is JsonMap) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _readList(dynamic value) {
  if (value is List) return value;
  return const [];
}
