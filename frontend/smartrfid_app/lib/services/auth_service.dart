import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final UserRepository _userRepository = UserRepository();

  User? _currentUser;
  String? _currentToken;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _currentToken;

  /// Inicializar servicio
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restaurar sesión guardada
      final userData = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);

      if (userData != null && token != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        _currentToken = token;
        _isAuthenticated = true;

        debugPrint('✅ Sesión restaurada: ${_currentUser?.username}');
      } else {
        debugPrint('ℹ️ No hay sesión guardada');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando AuthService: $e');
    }
  }

  /// Login usando Hive
  Future<User?> login(String username, String password) async {
    try {
      debugPrint('🔐 Intentando login: $username');

      // Usar repositorio para verificar credenciales
      final user = await _userRepository.login(username, password);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;

        // Generar token
        _currentToken = 'hive_token_${user.uuid}_${DateTime.now().millisecondsSinceEpoch}';

        // Guardar sesión
        await _saveSession(user, _currentToken!);

        debugPrint('✅ Login exitoso: ${user.username} (${user.role})');
        return user;
      }

      debugPrint('❌ Credenciales incorrectas');
      return null;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return null;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);

      _currentUser = null;
      _currentToken = null;
      _isAuthenticated = false;

      debugPrint('✅ Logout exitoso');
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
    }
  }

  /// Obtener usuario actual
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        return _currentUser;
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo usuario: $e');
    }

    return null;
  }

  /// Verificar permiso
  bool hasPermission(String permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Verificar rol
  bool hasRole(UserRole role) {
    return _currentUser?.hasRole(role) ?? false;
  }

  /// Guardar sesión
  Future<void> _saveSession(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);

      debugPrint('✅ Sesión guardada');
    } catch (e) {
      debugPrint('❌ Error guardando sesión: $e');
    }
  }
}