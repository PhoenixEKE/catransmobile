import 'package:catrans_app/models/accounts/user.dart';

class CustomerProfile {
  final String id;
  final User user;
  final int? legacyUtilisateurId;
  final String? legacyFirebaseUid;
  final String? legacyIdentifiant;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerProfile({
    required this.id,
    required this.user,
    this.legacyUtilisateurId,
    this.legacyFirebaseUid,
    this.legacyIdentifiant,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user.toJson(),
    'legacy_utilisateur_id': legacyUtilisateurId,
    'legacy_firebase_uid': legacyFirebaseUid,
    'legacy_identifiant': legacyIdentifiant,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
    id: json['id'],
    user: User.fromJson(json['user']),
    legacyUtilisateurId: json['legacy_utilisateur_id'],
    legacyFirebaseUid: json['legacy_firebase_uid'],
    legacyIdentifiant: json['legacy_identifiant'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}