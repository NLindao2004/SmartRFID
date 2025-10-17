import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import 'services/api_service.dart';
import 'services/auth_service.dart' as auth_service;
import 'services/inventory_service.dart';
import 'services/database_service.dart';

// Providers
import 'providers/inventory_provider.dart';
import 'providers/auth_provider.dart';

import 'models/user.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reception_screen.dart';
import 'screens/movement_screen.dart';
import 'screens/count_screen.dart';
import 'screens/query_screen.dart';
import 'screens/rfid_commission_screen.dart';
import 'screens/settings_screen.dart';

// Utils
import 'utils/constants.dart';

void main() async {
  // Asegurar que los bindings estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ AÑADIR: Inicializar base de datos ANTES que todo
  debugPrint('🗄️ Inicializando base de datos...');
  try {
    final dbService = DatabaseService();
    await dbService.database; // Esto creará las tablas
    debugPrint('✅ Base de datos inicializada correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando base de datos: $e');
  }

  // Configurar orientación de pantalla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar UI del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Crear instancias de servicios
  final apiService = ApiService();
  final auth_service.AuthService authService = auth_service.AuthService();
  final inventoryService = InventoryService();

  // ✅ CAMBIAR: Inicializar servicio de autenticación DESPUÉS de DB
  debugPrint('🔐 Inicializando servicio de autenticación...');
  await authService.initialize();

  runApp(SmartRFIDApp(
    apiService: apiService,
    authService: authService,
    inventoryService: inventoryService,
    prefs: prefs,
  ));
}

class SmartRFIDApp extends StatelessWidget {
  final ApiService apiService;
  final auth_service.AuthService authService;
  final InventoryService inventoryService;
  final SharedPreferences prefs;

  const SmartRFIDApp({
    super.key,
    required this.apiService,
    required this.authService,
    required this.inventoryService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<auth_service.AuthService>.value(value: authService),
        Provider<InventoryService>.value(value: inventoryService),
        Provider<SharedPreferences>.value(value: prefs),

        // ✅ AÑADIR AuthProvider
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(authService),
        ),

        ChangeNotifierProvider<InventoryProvider>(
          create: (context) => InventoryProvider(inventoryService),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: DebugConstants.showDebugBanner,

        theme: _buildLightTheme(),
        darkTheme: FeatureFlags.enableDarkMode ? _buildDarkTheme() : null,
        themeMode: ThemeMode.system,

        // ✅ OPCIÓN 2: Usar initialRoute en lugar de home
        initialRoute: authService.isAuthenticated ? AppRoutes.home : AppRoutes.login,

        routes: _buildRoutes(),
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: _onUnknownRoute,

        builder: (context, child) {
          return _AppWrapper(child: child);
        },
      ),
    );
  }

  // Definir rutas de la aplicación
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.home: (context) => const AuthGuard(child: HomeScreen()), // ✅ Ahora sí puede estar
      AppRoutes.reception: (context) => const AuthGuard(child: ReceptionScreen()),
      AppRoutes.movement: (context) => const AuthGuard(child: MovementScreen()),
      AppRoutes.count: (context) => const AuthGuard(child: CountScreen()),
      AppRoutes.query: (context) => const AuthGuard(child: QueryScreen()),
      AppRoutes.commission: (context) => const AuthGuard(child: RFIDCommissionScreen()),
      AppRoutes.settings: (context) => const AuthGuard(child: SettingsScreen()),
    };
  }

  // Generador de rutas personalizado
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // Aquí puedes manejar rutas dinámicas si es necesario
    return null;
  }

  // Ruta para casos no encontrados
  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const NotFoundScreen(),
    );
  }

  // Tema claro
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: UIConstants.elevationMedium,
          minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Botones outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Campos de entrada
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(UIConstants.paddingMD),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: UIConstants.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLG),
        ),
        margin: const EdgeInsets.all(UIConstants.paddingSM),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: UIConstants.elevationMedium,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: UIConstants.elevationMedium,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey600,
        backgroundColor: Colors.white,
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        elevation: UIConstants.elevationHigh,
        backgroundColor: Colors.white,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.grey300,
        thickness: 1,
        space: 1,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.headline1,
        displayMedium: AppTextStyles.headline2,
        displaySmall: AppTextStyles.headline3,
        headlineMedium: AppTextStyles.headline4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }

  // Tema oscuro
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

// ✅ CORREGIDO: Wrapper que usa AuthService directamente
class _AppWrapper extends StatelessWidget {
  final Widget? child;

  const _AppWrapper({this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Detectar taps para mantener sesión activa
        // Puedes implementar lógica adicional aquí si es necesario
      },
      child: child,
    );
  }
}

// ✅ CORREGIDO: Guard que usa AuthService directamente
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<auth_service.AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

// Pantalla de splash/carga
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(UIConstants.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: UIConstants.iconXL,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: UIConstants.paddingXL),

            Text(
              AppConstants.appName,
              style: AppTextStyles.headline1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: UIConstants.paddingSM),

            Text(
              AppConstants.companyName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: UIConstants.paddingXL * 2),

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: UIConstants.paddingMD),

            Text(
              'Inicializando...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para rutas no encontradas
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página no encontrada'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: UIConstants.iconXL * 2,
              color: AppColors.grey400,
            ),

            const SizedBox(height: UIConstants.paddingLG),

            Text(
              '404',
              style: AppTextStyles.headline1.copyWith(
                color: AppColors.grey600,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: UIConstants.paddingMD),

            Text(
              'Página no encontrada',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.grey600,
              ),
            ),

            const SizedBox(height: UIConstants.paddingSM),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingLG),
              child: Text(
                'La página que buscas no existe o ha sido movida.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: UIConstants.paddingXL),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ CORREGIDO: Widget de debug que usa AuthService e InventoryProvider
class DebugInfo extends StatelessWidget {
  const DebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DebugConstants.enableDebugLogs) {
      return const SizedBox.shrink();
    }

    final authService = Provider.of<auth_service.AuthService>(context, listen: false);

    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        return FutureBuilder<User?>(
          future: authService.getCurrentUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;

            return Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(UIConstants.paddingSM),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(UIConstants.radiusSM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DEBUG INFO',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auth: ${authService.isAuthenticated ? "✓" : "✗"}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                    Text(
                      'User: ${user?.username ?? "None"}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                    Text(
                      'SKUs: ${inventoryProvider.totalSKUs}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Inventory: ${inventoryProvider.totalInventoryItems}',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ));
          },
        );
      },
    );
  }
}