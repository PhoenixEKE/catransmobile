import 'package:shared_preferences/shared_preferences.dart';

/// Persists which reservation a Wave checkout was opened for, so the
/// success/error return screens can find it again after Wave redirects the
/// browser back — a full page reload on Flutter Web wipes all in-memory
/// state, so nothing carried via `extra`/navigation state survives that
/// round trip.
const _prefsKey = 'wave_pending_reservation_id';

Future<void> savePendingWaveReservationId(String reservationId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, reservationId);
}

Future<String?> readPendingWaveReservationId() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_prefsKey);
  return (value == null || value.trim().isEmpty) ? null : value;
}

Future<void> clearPendingWaveReservationId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefsKey);
}
