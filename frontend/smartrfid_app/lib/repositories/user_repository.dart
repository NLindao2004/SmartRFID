// lib/repositories/user_repository.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/hive_service.dart';

class UserRepository {
  /// Obtener todos los usuarios
  Future<List<User>> getAll() async {
    try {
      return HiveService.usersBox.values.toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo usuarios: $e');
      return [];
    }
  }

  /// Buscar usuario por username
  Future<User?> getByUsername(String username) async {
    try {
      return HiveService.usersBox.values.firstWhere(
        (user) => user.username.toLowerCase() == username.toLowerCase(),
        orElse: () => throw Exception('Usuario no encontrado'),
      );
    } catch (e) {
      debugPrint('❌ Usuario no encontrado: $username');
      return null;
    }
  }

  /// Buscar usuario por UUID
  Future<User?> getByUuid(String uuid) async {
    try {
      return HiveService.usersBox.values.firstWhere(
        (user) => user.uuid == uuid,
        orElse: () => throw Exception('Usuario no encontrado'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Login: verificar credenciales
  Future<User?> login(String username, String password) async {
    try {
      debugPrint('🔐 Verificando credenciales: $username');

      final user = await getByUsername(username);

      if (user == null) {
        debugPrint('❌ Usuario no existe');
        return null;
      }

      if (!user.isActive) {
        debugPrint('❌ Usuario inactivo');
        return null;
      }

      final passwordHash = _hashPassword(password);
      if (user.passwordHash == passwordHash) {
        debugPrint('✅ Login exitoso: ${user.username}');
        return user;
      } else {
        debugPrint('❌ Contraseña incorrecta');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return null;
    }
  }

  /// Crear nuevo usuario
  Future<User?> create(User user) async {
    try {
      // Verificar que el username no exista
      final existing = await getByUsername(user.username);
      if (existing != null) {
        debugPrint('❌ Username ya existe: ${user.username}');
        return null;
      }

      await HiveService.usersBox.add(user);
      debugPrint('✅ Usuario creado: ${user.username}');
      return user;
    } catch (e) {
      debugPrint('❌ Error creando usuario: $e');
      return null;
    }
  }

  /// Actualizar usuario
  Future<bool> update(User user) async {
    try {
      await user.save(); // HiveObject tiene método save()
      debugPrint('✅ Usuario actualizado: ${user.username}');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando usuario: $e');
      return false;
    }
  }

  /// Eliminar usuario
  Future<bool> delete(User user) async {
    try {
      await user.delete(); // HiveObject tiene método delete()
      debugPrint('✅ Usuario eliminado: ${user.username}');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando usuario: $e');
      return false;
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword(User user, String newPassword) async {
    try {
      user.passwordHash = _hashPassword(newPassword);
      user.updatedAt = DateTime.now();
      await user.save();
      debugPrint('✅ Contraseña cambiada para: ${user.username}');
      return true;
    } catch (e) {
      debugPrint('❌ Error cambiando contraseña: $e');
      return false;
    }
  }

  /// Hash de contraseña
  String _hashPassword(String password) {
    return password.hashCode.toString();
  }
}