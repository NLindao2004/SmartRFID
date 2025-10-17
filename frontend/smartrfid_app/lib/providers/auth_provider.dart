import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '/services/api_service.dart';


class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  
  final ApiService _apiService = ApiService();
  User? _currentUser;
  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // Inicializar el servicio
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar token
      _token = prefs.getString(_tokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);
      
      // Cargar fecha de expiración
      final expiryString = prefs.getString(_tokenExpiryKey);
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
      
      // Cargar datos del usuario
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }
      
      // Configurar token en API service si existe y es válido
      if (_token != null && !_isTokenExpired()) {
        _apiService.setAuthTokens(_token!, _refreshToken!);
      } else if (_token != null && _isTokenExpired()) {
        // Intentar refrescar el token si está expirado
        await refreshToken();
      }
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      await _clearStoredData();
    }
  }

  // Verificar si el usuario está logueado
  Future<bool> isLoggedIn() async {
    if (_token == null || _currentUser == null) {
      return false;
    }
    
    // Verificar si el token está expirado
    if (_isTokenExpired()) {
      // Intentar refrescar el token
      final refreshed = await refreshToken();
      return refreshed;
    }
    
    return true;
  }

  // Obtener el usuario actual
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Intentar cargar desde storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
    
    return null;
  }

  // Verificar si el token necesita renovarse
  Future<bool> needsTokenRefresh() async {
    if (_tokenExpiry == null) return false;
    
    // Renovar si falta menos de 5 minutos para expirar
    final now = DateTime.now();
    final difference = _tokenExpiry!.difference(now);
    
    return difference.inMinutes < 5;
  }

  // Login
  Future<User?> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/api/auth/login',
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extraer tokens
        _token = data['access_token'] ?? data['token'];
        _refreshToken = data['refresh_token'];
        
        // Calcular fecha de expiración (típicamente 1 hora)
        final expiresIn = data['expires_in'] ?? 3600; // segundos
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        // Extraer usuario
        _currentUser = User.fromJson(data['user']);
        
        // Guardar en storage
        await _saveToStorage();
        
        // Configurar token en API service
        _apiService.setAuthTokens(_token!, _refreshToken!);
        
        return _currentUser;
      }
      
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Intentar hacer logout en el servidor
      if (_token != null) {
        await _apiService.post('/api/auth/logout');
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Limpiar datos locales
      await _clearStoredData();
      _token = null;
      _refreshToken = null;
      _currentUser = null;
      _tokenExpiry = null;
      _apiService.clearAuthTokens();
    }
  }

  // Refrescar token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      return false;
    }
    
    try {
      final response = await _apiService.post(
        '/api/auth/refresh',
        body: {
          'refresh_token': _refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        _token = data['access_token'] ?? data['token'];
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }
        
        final expiresIn = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        await _saveToStorage();
        _apiService.setAuthTokens(_token!, _refreshToken!);
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.post(
        '/api/auth/change-password',
        body: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  // Actualizar perfil
  Future<User?> updateProfile(String userId, Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.put(
        '/api/users/$userId',
        body: userData,
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        await _saveToStorage();
        return _currentUser;
      }
      
      return null;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return null;
    }
  }

  // Validar token
  Future<bool> validateToken() async {
    if (_token == null) return false;
    
    try {
      final response = await _apiService.get('/api/auth/validate');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Verificar si el token está expirado
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  // Guardar datos en storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
      }
      
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }
      
      if (_tokenExpiry != null) {
        await prefs.setString(_tokenExpiryKey, _tokenExpiry!.toIso8601String());
      }
      
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      debugPrint('Error saving to storage: $e');
    }
  }

  // Limpiar datos almacenados
  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_tokenExpiryKey);
    } catch (e) {
      debugPrint('Error clearing stored data: $e');
    }
  }
}

// Clase para resultados de autenticación
class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
  });

  factory AuthResult.success({User? user, String? token}) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}

// Interceptor para manejar renovación automática de tokens
class AuthInterceptor {
  final AuthService _authService;

  AuthInterceptor(this._authService);

  Future<void> handleRequest() async {
    // Verificar si el token necesita renovarse antes de cada request
    final needsRefresh = await _authService.needsTokenRefresh();
    if (needsRefresh) {
      await _authService.refreshToken();
    }
  }

  Future<void> handleError(dynamic error) async {
    // Si hay un error 401 (no autorizado), intentar refrescar el token
    if (error.toString().contains('401')) {
      final refreshed = await _authService.refreshToken();
      if (!refreshed) {
        // Si no se puede refrescar, hacer logout
        await _authService.logout();
      }
    }
  }
}