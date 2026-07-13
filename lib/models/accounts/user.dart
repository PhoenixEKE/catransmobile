enum UserType { customer, agent, staff }

class User {
  final String id;
  final String lastname;
  final String firstname;
  final String phoneNumber;
  final String? email;
  final UserType userType;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.phoneNumber,
    this.email,
    this.userType = UserType.customer,
    this.isActive = true,
    this.isStaff = false,
    this.isSuperuser = false,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstname $lastname'.trim();
  String get displayName {
    if (lastname.isEmpty) return firstname;
    return '$firstname ${lastname[0]}.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastname': lastname,
        'firstname': firstname,
        'phone_number': phoneNumber,
        'email': email,
        'user_type': userType.name,
        'is_active': isActive,
        'is_staff': isStaff,
        'is_superuser': isSuperuser,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _readString(json['id']),
        lastname: _readString(json['lastname']),
        firstname: _readString(json['firstname']),
        phoneNumber: _readString(json['phone_number'] ?? json['phoneNumber']),
        email: json['email'] as String?,
        userType: UserType.values.firstWhere(
          (e) => e.name == json['user_type'] || e.name == json['userType'],
          orElse: () => UserType.customer,
        ),
        isActive:
            json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
        isStaff: json['is_staff'] as bool? ?? json['isStaff'] as bool? ?? false,
        isSuperuser: json['is_superuser'] as bool? ??
            json['isSuperuser'] as bool? ??
            false,
        lastLoginAt:
            _parseDateTime(json['last_login_at'] ?? json['lastLoginAt']),
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
        updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      );

  static String _readString(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
