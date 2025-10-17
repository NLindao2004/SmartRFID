// lib/services/hive_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

class HiveService {
  static bool _initialized = false;

  // Boxes (tablas)
  static late Box<User> usersBox;

  /// Inicializar Hive
  static Future<void> init() async {
    if (_initialized) {
      debugPrint('⚠️ Hive ya estaba inicializado');
      return;
    }

    try {
      debugPrint('🗄️ Inicializando Hive...');

      // 1. Inicializar Hive Flutter
      await Hive.initFlutter();

      // 2. Registrar adaptadores
      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(UserRoleAdapter());

      // 3. Abrir boxes
      usersBox = await Hive.openBox<User>('users');

      _initialized = true;

      debugPrint('✅ Hive inicializado correctamente');
      debugPrint('📦 Box de usuarios abierto: ${usersBox.length} registros');

      // 4. Insertar usuarios por defecto si está vacío
      await _seedInitialUsers();

    } catch (e, stackTrace) {
      debugPrint('❌ Error inicializando Hive: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Insertar usuarios iniciales
  static Future<void> _seedInitialUsers() async {
    if (usersBox.isEmpty) {
      debugPrint('📝 Insertando usuarios por defecto...');

      // Usuario Admin
      final admin = User(
        uuid: 'admin-uuid-123',
        username: 'admin',
        email: 'admin@massline.com',
        firstName: 'Administrador',
        lastName: 'Sistema',
        passwordHash: _hashPassword('admin123'),
        role: UserRole.ADMIN,
        permissions: [
          'inventory_read',
          'inventory_write',
          'reports',
          'user_management',
          'rfid_commission',
        ],
        isActive: true,
      );

      // Usuario Operator
      final operator = User(
        uuid: 'operator-uuid-456',
        username: 'operator',
        email: 'operator@massline.com',
        firstName: 'Operador',
        lastName: 'Bodega',
        passwordHash: _hashPassword('operator123'),
        role: UserRole.OPERATOR,
        permissions: [
          'inventory_read',
          'inventory_write',
        ],
        isActive: true,
      );

      await usersBox.add(admin);
      await usersBox.add(operator);

      debugPrint('✅ Usuarios por defecto creados:');
      debugPrint('   • admin (ADMIN)');
      debugPrint('   • operator (OPERATOR)');
    } else {
      debugPrint('ℹ️ Usuarios ya existentes: ${usersBox.length}');
    }
  }

  /// Hash simple de contraseña (para desarrollo)
  static String _hashPassword(String password) {
    return password.hashCode.toString();
  }

  /// Limpiar todos los datos
  static Future<void> clearAllData() async {
    await usersBox.clear();
    debugPrint('🗑️ Todos los usuarios eliminados');
  }

  /// Cerrar Hive
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
    debugPrint('🔒 Hive cerrado');
  }

  /// Verificar si está inicializado
  static bool get isInitialized => _initialized;
}