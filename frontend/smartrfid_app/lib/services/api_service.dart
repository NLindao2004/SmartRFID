import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'https://api.massline.com'; // TODO: Configurar URL real
  static const Duration _timeoutDuration = Duration(seconds: 30);
  
  String? _authToken;
  String? _refreshToken;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers comunes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Configurar tokens de autenticación
  void setAuthTokens(String authToken, String refreshToken) {
    _authToken = authToken;
    _refreshToken = refreshToken;
  }

  // Limpiar tokens
  void clearAuthTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      debugPrint('GET: $uri');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeoutDuration);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('GET Error: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      debugPrint('POST: $uri');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('POST Error: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      debugPrint('PUT: $uri');

      final response = await http
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeoutDuration);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      debugPrint('DELETE: $uri');

      final response = await http
          .delete(uri, headers: _headers)
          .timeout(_timeoutDuration);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return ApiResponse.error(_handleError(e));
    }
  }

  // Construir URI con parámetros de consulta
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // Manejar respuesta HTTP
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (fromJson != null && jsonData.containsKey('data')) {
          final data = fromJson(jsonData['data']);
          return ApiResponse.success(data, jsonData['message']);
        }
        
        return ApiResponse.success(jsonData as T, jsonData['message']);
      } catch (e) {
        return ApiResponse.error('Error parsing response: $e');
      }
    } else if (response.statusCode == 401) {
      // Token expirado, intentar refrescar
      return ApiResponse.error('Unauthorized', needsRefresh: true);
    } else {
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.error(
          errorData['message'] ?? 'HTTP ${response.statusCode}',
          code: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.error('HTTP ${response.statusCode}');
      }
    }
  }

  // Manejar errores de conexión
  String _handleError(dynamic error) {
    if (error is SocketException) {
      return 'No hay conexión a internet';
    } else if (error is HttpException) {
      return 'Error de servidor: ${error.message}';
    } else if (error is FormatException) {
      return 'Respuesta inválida del servidor';
    } else {
      return 'Error desconocido: $error';
    }
  }

  // Refrescar token de autenticación
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {'refresh_token': _refreshToken},
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setAuthTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }

    return false;
  }

  // Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Clase para encapsular respuestas de API
class ApiResponse<T> {
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final bool needsRefresh;

  ApiResponse._({
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.needsRefresh = false,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse._(data: data, message: message);
  }

  factory ApiResponse.error(
    String error, {
    int? code,
    bool needsRefresh = false,
  }) {
    return ApiResponse._(
      error: error,
      statusCode: code,
      needsRefresh: needsRefresh,
    );
  }

  bool get isSuccess => error == null && data != null;
  bool get isError => error != null;
}

// Excepciones personalizadas
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}