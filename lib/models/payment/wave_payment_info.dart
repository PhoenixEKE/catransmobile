class WavePaymentInfo {
  final String? checkoutSessionId;
  final String? checkoutStatus;
  final String? waveLaunchUrl;
  final DateTime? whenExpires;

  const WavePaymentInfo({
    this.checkoutSessionId,
    this.checkoutStatus,
    this.waveLaunchUrl,
    this.whenExpires,
  });

  bool get hasLaunchUrl =>
      waveLaunchUrl != null && waveLaunchUrl!.trim().isNotEmpty;
  bool get isOpen => checkoutStatus == 'open';
  bool get isComplete => checkoutStatus == 'complete';
  bool get isExpired => checkoutStatus == 'expired';
  bool get isFailed => checkoutStatus == 'failed';
  DateTime? get localWhenExpires => whenExpires?.toLocal();

  factory WavePaymentInfo.fromJson(Map<String, dynamic> json) {
    return WavePaymentInfo(
      checkoutSessionId: _readString(json['checkout_session_id']),
      checkoutStatus: _readString(json['checkout_status']),
      waveLaunchUrl: _readString(json['wave_launch_url']),
      whenExpires: _readDate(json['when_expires']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
