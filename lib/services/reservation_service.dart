import 'package:catrans_app/models/booking/reservation_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  List<Reservation> _reservations = [];

  Future<List<Reservation>> getReservations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('reservations_$userId');
    
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _reservations = jsonList.map((e) => Reservation.fromJson(e)).toList();
    }
    return _reservations;
  }

  Future<void> saveReservation(Reservation reservation) async {
    _reservations.add(reservation);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reservations_${reservation.customer?.id ?? 'guest'}',
      jsonEncode(_reservations.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> cancelReservation(String reservationId) async {
    _reservations.removeWhere((r) => r.id == reservationId);
  }
}