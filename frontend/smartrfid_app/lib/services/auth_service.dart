import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _lastLoginKey = 'last_login';

  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isAuthenticated = false;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserRole => _currentUser?.role.toString().split('.').last;

  // Inicializar servicio (verificar tokens guardados)
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final userData = prefs.getString(_userKey);

      if (token != null && refreshToken != null && userData != null) {
        _apiService.setAuthTokens(token, refreshToken);
        
        try {
          final userMap = jsonDecode(userData) as Map<String, dynamic>;
          _currentUser = User.fromJson(userMap);
          _isAuthenticated = true;

          // Verificar si el token sigue siendo válido
          final isValid = await _validateToken();
          if (!isValid) {
            await logout();
            return false;
          }

          return true;
        } catch (e) {
          debugPrint('Error parsing saved user data: $e');
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }

    return false;
  }

  // Login
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/login',
        body: {
          'username': username,
          'password': password,
          'device_info': await _getDeviceInfo(),
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        final token = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Guardar tokens y datos del usuario
        await _saveAuthData(token, refreshToken, userData);

        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        _apiService.setAuthTokens(token, refreshToken);

        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure(response.error ?? 'Error de autenticación');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return AuthResult.failure('Error de conexión');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Notificar al servidor (opcional)
      await _apiService.post('/auth/logout');
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      // Limpiar datos locales
      await _clearAuthData();
      _currentUser = null;
      _isAuthenticated = false;
      _apiService.clearAuthTokens();
    }
  }

  // Cambiar contraseña
  Future<AuthResult> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!_isAuthenticated) {
      return AuthResult.failure('Usuario no autenticado');
    }

    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.isSuccess) {
        return AuthResult.success(_currentUser!);
      } else {
        return AuthResult.failure(
          response.error ?? 'Error cambiando contraseña',
        );
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      return AuthResult.failure('Error de conexión');
    }
  }

  // Validar token actual
  Future<bool> _validateToken() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/auth/validate');
      return response.isSuccess;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Refrescar token automáticamente
  Future<bool> refreshToken() async {
    try {
      final success = await _apiService.refreshAuthToken();
      if (success) {
        // Actualizar tokens guardados
        final prefs = await SharedPreferences.getInstance();
        // Los tokens ya están actualizados en ApiService
        // Solo necesitamos guardarlos
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
    
    return false;
  }

  // Verificar permisos de usuario
  bool hasPermission(String permission) {
    if (!_isAuthenticated || _currentUser == null) return false;
    
    return _currentUser!.permissions.contains(permission);
  }

  // Verificar rol de usuario
  bool hasRole(UserRole role) {
    if (!_isAuthenticated || _currentUser == null) return false;
    
    return _currentUser!.role == role;
  }

  // Verificar múltiples roles
  bool hasAnyRole(List<UserRole> roles) {
    if (!_isAuthenticated || _currentUser == null) return false;
    
    return roles.contains(_currentUser!.role);
  }

  // Obtener usuario actual actualizado del servidor
  Future<User?> getCurrentUser() async {
    if (!_isAuthenticated) return null;

    try {
      final response = await _apiService.get<Map<String, dynamic>>('/auth/user');
      
      if (response.isSuccess && response.data != null) {
        _currentUser = User.fromJson(response.data!);
        
        // Actualizar datos guardados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Get current user error: $e');
    }

    return _currentUser;
  }

  // Guardar datos de autenticación
  Future<void> _saveAuthData(
    String token,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString(_refreshTokenKey, refreshToken),
      prefs.setString(_userKey, jsonEncode(userData)),
      prefs.setString(_lastLoginKey, DateTime.now().toIso8601String()),
    ]);
  }

  // Limpiar datos de autenticación
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userKey),
      prefs.remove(_lastLoginKey),
    ]);
  }

  // Obtener información del dispositivo
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // TODO: Implementar obtención real de info del dispositivo
    return {
      'platform': defaultTargetPlatform.name,
      'app_version': '1.0.0',
      'device_id': 'device_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Obtener último login
  Future<DateTime?> getLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString(_lastLoginKey);
      if (lastLoginStr != null) {
        return DateTime.parse(lastLoginStr);
      }
    } catch (e) {
      debugPrint('Error getting last login: $e');
    }
    return null;
  }

  // Verificar si la sesión ha expirado por tiempo
  Future<bool> isSessionExpired() async {
    final lastLogin = await getLastLogin();
    if (lastLogin == null) return true;

    const sessionTimeout = Duration(hours: 8); // 8 horas de sesión
    return DateTime.now().difference(lastLogin) > sessionTimeout;
  }

  // Login offline (para casos de emergencia)
  Future<AuthResult> offlineLogin(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUserData = prefs.getString(_userKey);
      
      if (lastUserData != null) {
        final userData = jsonDecode(lastUserData) as Map<String, dynamic>;
        final lastUser = User.fromJson(userData);
        
        // Verificación simple (en producción usar hash)
        if (lastUser.username == username) {
          _currentUser = lastUser;
          _isAuthenticated = true;
          
          return AuthResult.success(_currentUser!);
        }
      }
      
      return AuthResult.failure('Credenciales offline no disponibles');
    } catch (e) {
      debugPrint('Offline login error: $e');
      return AuthResult.failure('Error en login offline');
    }
  }
}

// Clase para resultados de autenticación
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}

// Interceptor para manejar renovación automática de tokens
class AuthInterceptor {
  final AuthService _authService = AuthService();

  Future<bool> handleUnauthorized() async {
    // Intentar refrescar token
    final refreshed = await _authService.refreshToken();
    
    if (!refreshed) {
      // Si no se puede refrescar, cerrar sesión
      await _authService.logout();
      return false;
    }
    
    return true;
  }
}