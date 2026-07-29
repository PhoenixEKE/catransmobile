class StationReservationListResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<StationReservationListItem> results;

  const StationReservationListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get isEmpty => results.isEmpty;
  bool get hasNext => next != null && next!.isNotEmpty;
  bool get hasPrevious => previous != null && previous!.isNotEmpty;

  factory StationReservationListResponse.fromJson(Map<String, dynamic> json) {
    return StationReservationListResponse(
      count: _readInt(json['count']),
      next: _readNullableString(json['next']),
      previous: _readNullableString(json['previous']),
      results: _readList(json['results'])
          .map((item) => StationReservationListItem.fromJson(
                _readObject(item),
              ))
          .toList(),
    );
  }
}

class StationReservationListItem {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final String totalAmount;
  final String currency;
  final StationReservationListCustomer customer;
  final StationReservationListTrip trip;
  final int itemsCount;
  final List<String> seatNumbers;
  final StationReservationListTraveler? primaryTraveler;
  final List<StationReservationListTraveler> travelers;
  final StationReservationListPayment? payment;
  final List<StationReservationListTicket> tickets;
  final StationReservationListActions actions;

  const StationReservationListItem({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    this.createdAt,
    this.confirmedAt,
    required this.totalAmount,
    required this.currency,
    required this.customer,
    required this.trip,
    required this.itemsCount,
    required this.seatNumbers,
    this.primaryTraveler,
    this.travelers = const [],
    this.payment,
    required this.tickets,
    required this.actions,
  });

  String get displayAmount => '$totalAmount $currency'.trim();
  String get displaySeats =>
      seatNumbers.isEmpty ? 'Placement gare' : seatNumbers.join(', ');
  bool get hasTickets => tickets.isNotEmpty;
  StationReservationListTicket? get firstTicket =>
      tickets.isEmpty ? null : tickets.first;

  factory StationReservationListItem.fromJson(Map<String, dynamic> json) {
    final paymentJson = json['payment'];
    return StationReservationListItem(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      statusLabel: _readString(json['status_label']),
      createdAt: _parseDateTime(json['created_at']),
      confirmedAt: _parseDateTime(json['confirmed_at']),
      totalAmount: _readString(json['total_amount']),
      currency: _readString(json['currency']),
      customer: StationReservationListCustomer.fromJson(
        _readObject(json['customer']),
      ),
      trip: StationReservationListTrip.fromJson(_readObject(json['trip'])),
      itemsCount: _readInt(json['items_count']),
      seatNumbers: _readList(json['seat_numbers'])
          .map((seat) => seat.toString())
          .where((seat) => seat.isNotEmpty)
          .toList(),
      primaryTraveler: json['primary_traveler'] == null
          ? null
          : StationReservationListTraveler.fromJson(
              _readObject(json['primary_traveler']),
            ),
      travelers: _readList(json['travelers'])
          .map((traveler) => StationReservationListTraveler.fromJson(
                _readObject(traveler),
              ))
          .toList(),
      payment: paymentJson == null
          ? null
          : StationReservationListPayment.fromJson(_readObject(paymentJson)),
      tickets: _readList(json['tickets'])
          .map((ticket) => StationReservationListTicket.fromJson(
                _readObject(ticket),
              ))
          .toList(),
      actions: StationReservationListActions.fromJson(
        _readObject(json['actions']),
      ),
    );
  }
}

class StationReservationListTraveler {
  final String itemId;
  final String? ticketId;
  final String? ticketReference;
  final String? ticketStatus;
  final String? lastname;
  final String? firstname;
  final String? phone;
  final int? seatNumber;
  final bool canEdit;

  const StationReservationListTraveler({
    required this.itemId,
    this.ticketId,
    this.ticketReference,
    this.ticketStatus,
    this.lastname,
    this.firstname,
    this.phone,
    this.seatNumber,
    this.canEdit = false,
  });

  String get fullName {
    return [firstname, lastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  factory StationReservationListTraveler.fromJson(Map<String, dynamic> json) {
    return StationReservationListTraveler(
      itemId: _readString(json['item_id']),
      ticketId: _readNullableString(json['ticket_id']),
      ticketReference: _readNullableString(json['ticket_reference']),
      ticketStatus: _readNullableString(json['ticket_status']),
      lastname: _readNullableString(json['lastname']),
      firstname: _readNullableString(json['firstname']),
      phone: _readNullableString(json['phone']),
      seatNumber: _readNullableInt(json['seat_number']),
      canEdit: json['can_edit'] == true,
    );
  }
}

class StationReservationListCustomer {
  final String? name;
  final String? phone;

  const StationReservationListCustomer({this.name, this.phone});

  String get displayName =>
      name == null || name!.trim().isEmpty ? 'Client' : name!.trim();

  factory StationReservationListCustomer.fromJson(Map<String, dynamic> json) {
    return StationReservationListCustomer(
      name: _readNullableString(json['name']),
      phone: _readNullableString(json['phone']),
    );
  }
}

class StationReservationListTrip {
  final String? departureStation;
  final String? arrivalStation;
  final DateTime? departureDateTime;
  final String? serviceClass;

  const StationReservationListTrip({
    this.departureStation,
    this.arrivalStation,
    this.departureDateTime,
    this.serviceClass,
  });

  String get routeLabel {
    final label = [departureStation, arrivalStation]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' → ');
    return label.isEmpty ? '-' : label;
  }

  factory StationReservationListTrip.fromJson(Map<String, dynamic> json) {
    return StationReservationListTrip(
      departureStation: _readNullableString(json['departure_station']),
      arrivalStation: _readNullableString(json['arrival_station']),
      departureDateTime: _parseDateTime(json['departure_datetime']),
      serviceClass: _readNullableString(json['service_class']),
    );
  }
}

class StationReservationListPayment {
  final String? status;
  final String? provider;
  final String? amount;
  final String? currency;

  const StationReservationListPayment({
    this.status,
    this.provider,
    this.amount,
    this.currency,
  });

  String get displayAmount => [amount, currency]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' ');

  factory StationReservationListPayment.fromJson(Map<String, dynamic> json) {
    return StationReservationListPayment(
      status: _readNullableString(json['status']),
      provider: _readNullableString(json['provider']),
      amount: _readNullableString(json['amount']),
      currency: _readNullableString(json['currency']),
    );
  }
}

class StationReservationListTicket {
  final String id;
  final String reference;
  final String status;

  const StationReservationListTicket({
    required this.id,
    required this.reference,
    required this.status,
  });

  factory StationReservationListTicket.fromJson(Map<String, dynamic> json) {
    return StationReservationListTicket(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
    );
  }
}

class StationReservationListActions {
  final bool canViewDetail;
  final bool canPrintTicket;

  const StationReservationListActions({
    required this.canViewDetail,
    required this.canPrintTicket,
  });

  factory StationReservationListActions.fromJson(Map<String, dynamic> json) {
    return StationReservationListActions(
      canViewDetail: json['can_view_detail'] == true,
      canPrintTicket: json['can_print_ticket'] == true,
    );
  }
}

List<dynamic> _readList(dynamic value) => value is List ? value : const [];

Map<String, dynamic> _readObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
