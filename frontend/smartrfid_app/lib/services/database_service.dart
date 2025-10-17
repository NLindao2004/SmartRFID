// lib/services/database_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static const String _databaseName = 'smartrfid_local.db';
  static const int _databaseVersion = 1;

  // Singleton
  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  DatabaseService._internal();

  // Para web, simulamos base de datos con datos hardcodeados
  Future<Database?> get database async {
    if (kIsWeb) {
      // En web no usamos SQLite real, solo simulamos
      debugPrint('🌐 Usando base de datos simulada para web');
      return null;
    } else {
      // En móvil usaríamos SQLite real
      throw UnsupportedError('SQLite móvil no implementado aún');
    }
  }

  // Métodos de usuario - hardcodeados para web
  Future<User?> getUserByCredentials(String username, String password) async {
    try {
      debugPrint('🔍 Buscando usuario: $username');

      final users = _getHardcodedUsers();
      final hashedPassword = _hashPassword(password);

      for (final userData in users) {
        if (userData['username'] == username &&
            userData['password_hash'] == hashedPassword) {

          debugPrint('✅ Usuario encontrado: ${userData['username']}');
          return User.fromDatabaseJson(userData);
        }
      }

      debugPrint('❌ Usuario no encontrado');
      return null;
    } catch (e) {
      debugPrint('❌ Error buscando usuario: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final users = _getHardcodedUsers();
      return users.map((json) => User.fromDatabaseJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  // Usuarios hardcodeados para desarrollo
  List<Map<String, dynamic>> _getHardcodedUsers() {
    final now = DateTime.now().toIso8601String();

    return [
      {
        'uuid': 'admin-uuid-123',
        'username': 'admin',
        'email': 'admin@massline.com',
        'first_name': 'Administrador',
        'last_name': 'Sistema',
        'password_hash': _hashPassword('admin123'),
        'role': 'ADMIN',
        'permissions': '["inventory_read","inventory_write","reports","user_management","rfid_commission"]',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'uuid': 'operator-uuid-456',
        'username': 'operator',
        'email': 'operator@massline.com',
        'first_name': 'Operador',
        'last_name': 'Bodega',
        'password_hash': _hashPassword('operator123'),
        'role': 'OPERATOR',
        'permissions': '["inventory_read","inventory_write"]',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
    ];
  }

  // Métodos de inventario (simulados)
  Future<int> insertSku(Map<String, dynamic> sku) async {
    debugPrint('📦 SKU simulado insertado: ${sku['sku_code']}');
    return DateTime.now().millisecondsSinceEpoch; // ID simulado
  }

  // Hash simple para desarrollo
  String _hashPassword(String password) {
    return password.hashCode.toString();
  }

  Future<void> close() async {
    debugPrint('🗄️ Base de datos cerrada');
  }
}

// Clase dummy para compatibilidad
class Database {
  // Implementación vacía para web
}