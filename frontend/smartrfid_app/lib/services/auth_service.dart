import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  final ApiService _apiService = ApiService();

  User? _currentUser;
  String? _currentToken;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _currentToken;

  // Inicializar el servicio
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar sesión guardada
      final userData = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);

      if (userData != null && token != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        _currentToken = token;
        _isAuthenticated = true;

        debugPrint('✅ Sesión restaurada: ${_currentUser?.username}');
      } else {
        debugPrint('❌ No hay sesión guardada');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando auth: $e');
    }
  }

  // Login - Para web usaremos usuarios hardcodeados
  Future<User?> login(String username, String password) async {
    try {
      debugPrint('🔐 Intentando login: $username');

      // Usuarios hardcodeados para desarrollo web
      final users = _getHardcodedUsers();

      for (final userData in users) {
        if (userData['username'] == username &&
            _verifyPassword(password, userData['password_hash'])) {

          final user = User.fromDatabaseJson(userData);
          _currentUser = user;
          _isAuthenticated = true;

          // Generar token para desarrollo
          _currentToken = 'web_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

          // Guardar sesión
          await _saveSession(user, _currentToken!);

          debugPrint('✅ Login exitoso: ${user.username}');
          return user;
        }
      }

      debugPrint('❌ Credenciales incorrectas');
      return null;

    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return null;
    }
  }

  // Usuarios hardcodeados para web
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

  // Verificar contraseña
  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // Hash simple para desarrollo
  String _hashPassword(String password) {
    return password.hashCode.toString();
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limpiar datos locales
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);

      // Limpiar estado
      _currentUser = null;
      _currentToken = null;
      _isAuthenticated = false;

      debugPrint('✅ Logout exitoso');
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
    }
  }

  // ✅ Método getCurrentUser que necesitan las pantallas
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    // Intentar cargar desde SharedPreferences
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

  // Verificación de permisos
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _currentUser!.hasPermission(permission);
  }

  bool hasRole(UserRole role) {
    if (_currentUser == null) return false;
    return _currentUser!.hasRole(role);
  }

  // Guardar sesión
  Future<void> _saveSession(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);
      await prefs.setString('last_login', DateTime.now().toIso8601String());

      debugPrint('✅ Sesión guardada');
    } catch (e) {
      debugPrint('❌ Error guardando sesión: $e');
    }
  }
}