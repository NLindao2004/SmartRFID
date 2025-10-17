// lib/services/web_storage_service.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';

// Servicio dummy para web - los usuarios están hardcodeados en AuthService
class DatabaseService {
  Future<Database> get database async {
    throw UnsupportedError('SQLite no está disponible en web');
  }

  Future<User?> getUserByCredentials(String username, String password) async {
    throw UnsupportedError('Use AuthService._loginWeb() en su lugar');
  }

  Future<List<User>> getAllUsers() async {
    throw UnsupportedError('Use AuthService._getHardcodedUsers() en su lugar');
  }

  Future<int> insertSku(Map<String, dynamic> sku) async {
    throw UnsupportedError('No implementado para web');
  }

  Future<void> close() async {
    // No hacer nada en web
  }
}

// Clase dummy para compatibilidad
class Database {
  // Implementación vacía para web
}