import 'package:hive/hive.dart';
import 'dart:convert';

part 'user.g.dart'; // ✅ Archivo que se generará automáticamente

@HiveType(typeId: 0) // ✅ ID único para este modelo
class User extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String uuid;

  @HiveField(2)
  String username;

  @HiveField(3)
  String email;

  @HiveField(4)
  String firstName;

  @HiveField(5)
  String lastName;

  @HiveField(6)
  String passwordHash;

  @HiveField(7)
  UserRole role;

  @HiveField(8)
  List<String> permissions;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  User({
    this.id,
    required this.uuid,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.passwordHash,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Nombre completo
  String get fullName => '$firstName $lastName';

  // Display del rol
  String get roleDisplayName {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrador';
      case UserRole.OPERATOR:
        return 'Operador';
      case UserRole.VIEWER:
        return 'Visualizador';
    }
  }

  // Verificar permiso
  bool hasPermission(String permission) {
    if (role == UserRole.ADMIN) return true;
    return permissions.contains(permission);
  }

  // Verificar rol
  bool hasRole(UserRole checkRole) {
    return role == checkRole;
  }

  // Serialización JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'password_hash': passwordHash,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      uuid: json['uuid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      role: _parseRole(json['role']),
      permissions: _parsePermissions(json['permissions']),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
    );
  }

  factory User.fromDatabaseJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.VIEWER;

    final roleStr = role.toString().toUpperCase();
    return UserRole.values.firstWhere(
      (r) => r.toString().split('.').last == roleStr,
      orElse: () => UserRole.VIEWER,
    );
  }

  static List<String> _parsePermissions(dynamic permissions) {
    if (permissions == null) return [];

    if (permissions is String) {
      try {
        final List<dynamic> parsed = jsonDecode(permissions);
        return parsed.map((p) => p.toString()).toList();
      } catch (e) {
        return [];
      }
    }

    if (permissions is List) {
      return permissions.map((p) => p.toString()).toList();
    }

    return [];
  }
}

@HiveType(typeId: 1) // ✅ TypeAdapter para el enum
enum UserRole {
  @HiveField(0)
  ADMIN,

  @HiveField(1)
  OPERATOR,

  @HiveField(2)
  VIEWER,
}