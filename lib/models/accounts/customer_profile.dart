import 'package:catrans_app/models/accounts/user.dart';

class CustomerProfile {
  final String? id;
  final String? customerProfileId;
  final User? user;
  final String? phoneNumber;
  final String? lastname;
  final String? firstname;
  final String? fullName;
  final String? userType;
  final bool? isActive;
  final int? legacyUtilisateurId;
  final String? legacyFirebaseUid;
  final String? legacyIdentifiant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerProfile({
    this.id,
    this.customerProfileId,
    this.user,
    String? phoneNumber,
    String? lastname,
    String? firstname,
    String? fullName,
    String? userType,
    bool? isActive,
    this.legacyUtilisateurId,
    this.legacyFirebaseUid,
    this.legacyIdentifiant,
    this.createdAt,
    this.updatedAt,
  })  : phoneNumber = phoneNumber ?? user?.phoneNumber,
        lastname = lastname ?? user?.lastname,
        firstname = firstname ?? user?.firstname,
        userType = userType ?? user?.userType.name,
        isActive = isActive ?? user?.isActive,
        fullName = fullName ?? _buildFullName(lastname, firstname, user);

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_profile_id': customerProfileId,
        'user': user?.toJson(),
        'phone_number': phoneNumber,
        'lastname': lastname,
        'firstname': firstname,
        'full_name': fullName,
        'user_type': userType,
        'is_active': isActive,
        'legacy_utilisateur_id': legacyUtilisateurId,
        'legacy_firebase_uid': legacyFirebaseUid,
        'legacy_identifiant': legacyIdentifiant,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user =
        userJson is Map<String, dynamic> ? User.fromJson(userJson) : null;

    final lastname = _readString(json['lastname'] ?? userJson?['lastname']);
    final firstname = _readString(json['firstname'] ?? userJson?['firstname']);

    return CustomerProfile(
      id: _readString(json['id']),
      customerProfileId: _readString(json['customer_profile_id']),
      user: user,
      phoneNumber:
          _readString(json['phone_number'] ?? userJson?['phone_number']),
      lastname: lastname,
      firstname: firstname,
      fullName: _readString(json['full_name']) ??
          _buildFullName(lastname, firstname, user),
      userType: _readString(json['user_type'] ?? userJson?['user_type']),
      isActive: json['is_active'] as bool? ?? userJson?['is_active'] as bool?,
      legacyUtilisateurId: json['legacy_utilisateur_id'] as int?,
      legacyFirebaseUid: _readString(json['legacy_firebase_uid']),
      legacyIdentifiant: _readString(json['legacy_identifiant']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static String? _buildFullName(
      String? lastname, String? firstname, User? user) {
    final resolvedFirstname = firstname ?? user?.firstname;
    final resolvedLastname = lastname ?? user?.lastname;
    final value = [resolvedFirstname, resolvedLastname]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    return value.isEmpty ? null : value;
  }

  static String? _readString(dynamic value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
