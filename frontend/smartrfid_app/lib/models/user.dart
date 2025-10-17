enum UserRole {
  operator,
  supervisor,
  manager,
  admin
}

class User {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final List<String> permissions;
  final List<String>? allowedAreas; // Áreas permitidas
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.permissions = const [],
    this.allowedAreas,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.operator,
      ),
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions']) 
          : [],
      allowedAreas: json['allowed_areas'] != null 
          ? List<String>.from(json['allowed_areas']) 
          : null,
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role.name,
      'permissions': permissions,
      'allowed_areas': allowedAreas,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
  
  String get roleDisplayName {
    switch (role) {
      case UserRole.operator:
        return 'Operador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == UserRole.admin;
  }

  bool canAccessArea(String area) {
    return allowedAreas == null || allowedAreas!.contains(area) || role == UserRole.admin;
  }

  @override
  String toString() {
    return '$fullName ($username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}