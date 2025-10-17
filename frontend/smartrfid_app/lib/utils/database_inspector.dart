// lib/utils/database_inspector.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class DatabaseInspector {
  static Future<void> inspectDatabase() async {
    if (!kDebugMode) return;

    try {
      final dbService = DatabaseService();

      debugPrint('\n🔍 ===== INSPECCIÓN DE BASE DE DATOS (WEB) =====');

      // Para web, mostrar usuarios hardcodeados
      final users = await dbService.getAllUsers();
      debugPrint('👥 USUARIOS ENCONTRADOS: ${users.length}');
      for (var user in users) {
        debugPrint('  • ${user.username} (${user.role.toString().split('.').last}) - ${user.email}');
      }

      debugPrint('🔍 ===== FIN INSPECCIÓN =====\n');

    } catch (e) {
      debugPrint('❌ Error inspeccionando base de datos: $e');
    }
  }

  static Future<void> resetDatabase() async {
    try {
      debugPrint('🗑️ Reset no necesario en web (usuarios hardcodeados)');
    } catch (e) {
      debugPrint('❌ Error reseteando base de datos: $e');
    }
  }
}