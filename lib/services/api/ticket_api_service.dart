import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/ticket/ticket_digital.dart';

class TicketApiService {
  final ApiClient _apiClient;

  TicketApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<TicketDigital> getTicketDigital({required String ticketId}) async {
    final normalizedTicketId = _normalizeTicketId(ticketId);
    final response = await _apiClient.get(
      'tickets/$normalizedTicketId/digital/',
    );

    return TicketDigital.fromJson(_readObject(response.data));
  }

  String ticketPdfPath(String ticketId) {
    final normalizedTicketId = _normalizeTicketId(ticketId);
    return 'tickets/$normalizedTicketId/download/';
  }

  String _normalizeTicketId(String ticketId) {
    final normalizedTicketId = ticketId.trim();
    if (normalizedTicketId.isEmpty) {
      throw ApiException(message: 'Ticket introuvable.');
    }
    return normalizedTicketId;
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Reponse ticket invalide.',
      details: data,
    );
  }
}
