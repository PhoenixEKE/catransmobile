enum UserType { customer, agent, staff }

class User {
  final String id;
  final String lastname;
  final String firstname;
  final String phoneNumber;
  final String? email;
  final String passwordHash;
  final UserType userType;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.phoneNumber,
    this.email,
    required this.passwordHash,
    this.userType = UserType.customer,
    this.isActive = true,
    this.isStaff = false,
    this.isSuperuser = false,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstname $lastname';
  String get displayName => '$firstname ${lastname[0]}.';

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastname': lastname,
    'firstname': firstname,
    'phone_number': phoneNumber,
    'email': email,
    'password_hash': passwordHash,
    'user_type': userType.name,
    'is_active': isActive,
    'is_staff': isStaff,
    'is_superuser': isSuperuser,
    'last_login_at': lastLoginAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    lastname: json['lastname'],
    firstname: json['firstname'],
    phoneNumber: json['phone_number'],
    email: json['email'],
    passwordHash: json['password_hash'],
    userType: UserType.values.firstWhere(
      (e) => e.name == json['user_type'],
      orElse: () => UserType.customer,
    ),
    isActive: json['is_active'] ?? true,
    isStaff: json['is_staff'] ?? false,
    isSuperuser: json['is_superuser'] ?? false,
    lastLoginAt: json['last_login_at'] != null
        ? DateTime.parse(json['last_login_at'])
        : null,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}