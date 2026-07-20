import 'package:catrans_app/core/network/api_exception.dart';

class StructuredApiError {
  final String? code;
  final String detail;
  final String? field;
  final int? statusCode;
  final dynamic rawPayload;

  const StructuredApiError({
    this.code,
    required this.detail,
    this.field,
    this.statusCode,
    this.rawPayload,
  });

  String get userMessage => detail;

  factory StructuredApiError.fromException(ApiException exception) {
    return StructuredApiError.fromPayload(
      exception.details,
      statusCode: exception.statusCode,
      fallbackMessage: exception.message,
    );
  }

  factory StructuredApiError.fromPayload(
    dynamic payload, {
    int? statusCode,
    String fallbackMessage = 'Une erreur est survenue. Veuillez réessayer.',
  }) {
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final code = map['code']?.toString();
      final explicitField = map['field']?.toString();
      final drfField = explicitField == null ? _readDrfField(map) : null;
      final detail = _readMessage(map['detail']) ??
          _readMessage(map['message']) ??
          drfField?.message ??
          fallbackMessage;
      return StructuredApiError(
        code: code,
        detail: detail,
        field: explicitField ?? drfField?.field,
        statusCode: statusCode,
        rawPayload: payload,
      );
    }

    if (payload is String && payload.isNotEmpty) {
      return StructuredApiError(
        detail: payload,
        statusCode: statusCode,
        rawPayload: payload,
      );
    }

    return StructuredApiError(
      detail: fallbackMessage,
      statusCode: statusCode,
      rawPayload: payload,
    );
  }

  static _DrfFieldError? _readDrfField(Map<String, dynamic> map) {
    const reservedKeys = {'code', 'detail', 'message', 'field'};
    for (final entry in map.entries) {
      if (reservedKeys.contains(entry.key)) continue;
      final message = _readMessage(entry.value);
      if (message != null) return _DrfFieldError(entry.key, message);
    }
    return null;
  }

  static String? _readDrfFieldMessage(Map<String, dynamic> map) {
    return _readDrfField(map)?.message;
  }

  static String? _readMessage(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is List && value.isNotEmpty) {
      final messages = value.map(_readMessage).whereType<String>().toList();
      return messages.isEmpty ? null : messages.join(', ');
    }
    if (value is Map && value.isNotEmpty) {
      return _readDrfFieldMessage(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

const recognizedStaffApiErrorCodes = <String>{
  'authentication_failed',
  'permission_denied',
  'active_pending_reservation_exists',
  'station_counter_required',
  'station_counter_inactive',
  'station_departure_scope_forbidden',
  'booking_customer_not_found',
  'booking_seat_not_available',
  'booking_economy_capacity_exceeded',
  'payment_station_scope_forbidden',
  'operations_invalid_status_transition',
  'operations_departure_has_active_holds',
  'operations_departure_has_active_bookings',
};

class _DrfFieldError {
  final String field;
  final String message;

  const _DrfFieldError(this.field, this.message);
}
