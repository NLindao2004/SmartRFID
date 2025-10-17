import 'dart:convert';

enum UserRole { ADMIN, MANAGER, OPERATOR, VIEWER }

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final List<String> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  // Getters calculados
  String get fullName => '$firstName $lastName';

  String get roleDisplayName {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrador';
      case UserRole.MANAGER:
        return 'Gerente';
      case UserRole.OPERATOR:
        return 'Operador';
      case UserRole.VIEWER:
        return 'Consultor';
    }
  }

  // From API JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['uuid'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? json['firstName'] ?? 'Usuario',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.VIEWER,
      ),
      permissions: List<String>.from(
        json['permissions'] is String
          ? jsonDecode(json['permissions'])
          : json['permissions'] ?? []
      ),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null
        ? DateTime.parse(json['last_login'])
        : null,
    );
  }

  // From SQLite
  factory User.fromDatabaseJson(Map<String, dynamic> json) {
    return User(
      id: json['uuid'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? 'Usuario',
      lastName: json['last_name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.VIEWER,
      ),
      permissions: List<String>.from(jsonDecode(json['permissions'])),
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasRole(UserRole requiredRole) {
    return role == requiredRole;
  }
}