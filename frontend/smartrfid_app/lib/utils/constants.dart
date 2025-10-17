import 'package:flutter/material.dart';

// =========================
// App Constants
// =========================
class AppConstants {
  static const String appName = 'SmartRFID';
  static const String appVersion = '1.0.0';
  static const String companyName = 'MASSLINE';
  static const String supportEmail = 'support@massline.com';
  static const String websiteUrl = 'https://www.massline.com';
  
  // Configuración de API
  static const String baseApiUrl = 'https://api.massline.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Configuración de caché
  static const Duration cacheExpiration = Duration(hours: 4);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Configuración de sesión
  static const Duration sessionTimeout = Duration(hours: 8);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
}

// =========================
// UI Constants
// =========================
class UIConstants {
  // Espaciado
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  
  // Radio de bordes
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  
  // Elevaciones
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Tamaños de iconos
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
  
  // Alturas de componentes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 72.0;
  static const double tabBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  
  // Anchos
  static const double maxContentWidth = 1200.0;
  static const double minButtonWidth = 120.0;
  static const double fabSize = 56.0;
  
  // Duraciones de animación
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Breakpoints responsivos
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
}

// =========================
// Color Palette
// =========================
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  
  // Colores secundarios
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryDark = Color(0xFF00695C);
  
  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Neutrales
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF424242);
  
  // Grises
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // RFID específicos
  static const Color rfidActive = Color(0xFF00BCD4);
  static const Color rfidInactive = Color(0xFF607D8B);
  static const Color rfidError = Color(0xFFE91E63);
  
  // Inventario específicos
  static const Color stockHigh = Color(0xFF4CAF50);
  static const Color stockMedium = Color(0xFFFF9800);
  static const Color stockLow = Color(0xFFE53935);
  static const Color stockOut = Color(0xFF9E9E9E);
}

// =========================
// Text Styles
// =========================
class AppTextStyles {
  // Headlines
  static const TextStyle headline1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle headline4 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  
  // Especiales
  static const TextStyle button = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.grey600,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.grey600,
  );
}

// =========================
// RFID Constants
// =========================
class RFIDConstants {
  // Configuración del lector
  static const int defaultPower = 75; // 0-100
  static const int defaultSession = 1; // 0-3
  static const int defaultPopulation = 100;
  static const Duration scanTimeout = Duration(seconds: 10);
  static const Duration continuousScanInterval = Duration(milliseconds: 500);
  
  // EPC
  static const int epcMinLength = 24; // 96 bits
  static const int epcMaxLength = 32; // 128 bits
  static const String epcPrefix = 'E200'; // Ejemplo de prefijo común
  
  // Potencias comunes
  static const Map<String, int> powerLevels = {
    'Bajo': 50,
    'Medio': 75,
    'Alto': 90,
    'Máximo': 100,
  };
  
  // Filtros comunes
  static const Map<String, String> commonFilters = {
    'Todos': '',
    'SKU': 'SKU',
    'LOC': 'LOC',
    'PROD': 'PROD',
  };
}

// =========================
// Barcode Constants
// =========================
class BarcodeConstants {
  // Patrones de códigos
  static const String skuPattern = r'^SKU[A-Z0-9]{8,15}$';
  static const String locationPattern = r'^LOC-[A-Z0-9]{2,6}-[A-Z0-9]{2,6}-[A-Z0-9]{2,6}$';
  static const String eanPattern = r'^\d{8,13}$';
  static const String qrPattern = r'^[A-Za-z0-9\-_.~:/\?#\[\]@!$&()*+,;=]*$';

  
  // Longitudes comunes
  static const int skuMinLength = 8;
  static const int skuMaxLength = 20;
  static const int eanLength = 13;
  static const int upcLength = 12;
  
  // Prefijos
  static const List<String> skuPrefixes = ['SKU', 'ART', 'PROD', 'ITM'];
  static const List<String> locationPrefixes = ['LOC-', 'UBI-', 'POS-'];
}

// =========================
// Inventory Constants
// =========================
class InventoryConstants {
  // Estados de stock
  static const int stockCriticalThreshold = 10;
  static const int stockLowThreshold = 50;
  static const int stockHighThreshold = 500;
  
  // Tipos de transacción
  static const Map<String, String> transactionTypes = {
    'reception': 'Recepción',
    'movement': 'Movimiento',
    'adjustment': 'Ajuste',
    'count': 'Conteo',
    'dispatch': 'Despacho',
  };
  
  // Unidades de medida comunes
  static const List<String> commonUOMs = [
    'PCS', 'KG', 'LT', 'MT', 'M2', 'M3', 'PAR', 'SET', 'BOX', 'PAL'
  ];
  
  // Tipos de ubicación
  static const Map<String, String> locationTypes = {
    'warehouse': 'Almacén',
    'shelf': 'Estante',
    'zone': 'Zona',
    'dock': 'Muelle',
    'staging': 'Preparación',
  };
  
  // Validación de lotes
  static const String lotPattern = r'^[A-Z0-9]{3,20}$';
  static const int maxLotLength = 20;
  
  // Fechas de vencimiento
  static const int expiryWarningDays = 30;
  static const int expiryCriticalDays = 7;
}

// =========================
// User Constants
// =========================
class UserConstants {
  // Roles
  static const Map<String, String> roleNames = {
    'admin': 'Administrador',
    'manager': 'Supervisor',
    'operator': 'Operador',
    'viewer': 'Consulta',
  };
  
  // Permisos comunes
  static const List<String> adminPermissions = [
    'read_all',
    'write_all',
    'delete_all',
    'manage_users',
    'manage_settings',
    'manage_reports',
  ];
  
  static const List<String> managerPermissions = [
    'read_all',
    'write_inventory',
    'manage_transactions',
    'view_reports',
  ];
  
  static const List<String> operatorPermissions = [
    'read_inventory',
    'write_inventory',
    'scan_rfid',
    'scan_barcode',
  ];
  
  static const List<String> viewerPermissions = [
    'read_inventory',
    'view_reports',
  ];
}

// =========================
// File & Storage Constants
// =========================
class StorageConstants {
  // Keys para SharedPreferences
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyLastLogin = 'last_login';
  static const String keySettings = 'app_settings';
  
  // Keys para caché
  static const String keyCachedSKUs = 'cached_skus';
  static const String keyCachedLocations = 'cached_locations';
  static const String keyCachedInventory = 'cached_inventory';
  
  // Configuración de archivos
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
}

// =========================
// Network Constants
// =========================
class NetworkConstants {
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'SmartRFID-Mobile/1.0.0',
  };
}

// =========================
// Validation Constants
// =========================
class ValidationConstants {
  // Longitudes de campos
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxNotesLength = 500;
  static const int maxDescriptionLength = 200;
  
  // Patrones de validación
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[\d\s\-\(\)]{7,15}$';
  static const String alphanumericPattern = r'^[a-zA-Z0-9]+$';
  static const String numericPattern = r'^\d+$';
  static const String decimalPattern = r'^\d+\.?\d*$';
  
  // Rangos numéricos
  static const int minQuantity = 0;
  static const int maxQuantity = 999999;
  static const double minWeight = 0.0;
  static const double maxWeight = 9999.99;
  static const int minPower = 0;
  static const int maxPower = 100;
}

// =========================
// Error Messages
// =========================
class ErrorMessages {
  // Errores de conexión
  static const String noInternet = 'No hay conexión a internet';
  static const String serverError = 'Error del servidor';
  static const String timeout = 'Tiempo de espera agotado';
  static const String unauthorizedAccess = 'Acceso no autorizado';
  
  // Errores de validación
  static const String fieldRequired = 'Este campo es obligatorio';
  static const String invalidEmail = 'Email inválido';
  static const String invalidPassword = 'Contraseña inválida';
  static const String passwordTooShort = 'Contraseña muy corta';
  static const String invalidQuantity = 'Cantidad inválida';
  static const String invalidSKU = 'Código SKU inválido';
  
  // Errores de hardware
  static const String rfidNotAvailable = 'Lector RFID no disponible';
  static const String barcodeNotAvailable = 'Escáner no disponible';
  static const String cameraNotAvailable = 'Cámara no disponible';
  static const String bluetoothNotEnabled = 'Bluetooth no habilitado';
  
  // Errores de datos
  static const String dataNotFound = 'Datos no encontrados';
  static const String duplicateEntry = 'Entrada duplicada';
  static const String insufficientStock = 'Stock insuficiente';
  static const String invalidOperation = 'Operación inválida';
}

// =========================
// Success Messages
// =========================
class SuccessMessages {
  static const String loginSuccess = 'Inicio de sesión exitoso';
  static const String logoutSuccess = 'Sesión cerrada correctamente';
  static const String dataUpdated = 'Datos actualizados correctamente';
  static const String transactionCreated = 'Transacción creada exitosamente';
  static const String tagCommissioned = 'Etiqueta comisionada correctamente';
  static const String scanCompleted = 'Escaneo completado';
  static const String syncCompleted = 'Sincronización completada';
  static const String settingsSaved = 'Configuración guardada';
}

// =========================
// Routes
// =========================
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home'; // ✅ Ahora sí puede existir
  static const String reception = '/reception';
  static const String movement = '/movement';
  static const String count = '/count';
  static const String query = '/query';
  static const String commission = '/commission';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String reports = '/reports';
}

// =========================
// Feature Flags
// =========================
class FeatureFlags {
  static const bool enableOfflineMode = true;
  static const bool enableBiometricAuth = false;
  static const bool enableDarkMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableBetaFeatures = false;
  static const bool enableRFIDSimulation = true;
  static const bool enableBarcodeSimulation = true;
}

// =========================
// Debug Constants
// =========================
class DebugConstants {
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
  static const bool enablePerformanceLogs = false;
  static const bool showDebugBanner = false;
  static const Duration debugAnimationDuration = Duration(milliseconds: 5000);
}