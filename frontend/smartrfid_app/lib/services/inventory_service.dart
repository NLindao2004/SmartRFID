import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../models/epc.dart';
import '../models/count.dart';
import 'api_service.dart';
import 'auth_service.dart';

class InventoryService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  // Cache keys
  static const String _skusCacheKey = 'cached_skus';
  static const String _locationsCacheKey = 'cached_locations';
  static const String _inventoryCacheKey = 'cached_inventory';
  
  // Cache duration
  static const Duration _cacheExpiration = Duration(hours: 4);

  // Singleton pattern
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  // =========================
  // SKU Management
  // =========================
  
  Future<List<SKU>> getSKUs({bool forceRefresh = false}) async {
    try {
      // Intentar desde caché primero
      if (!forceRefresh) {
        final cachedSKUs = await _getCachedSKUs();
        if (cachedSKUs.isNotEmpty) {
          return cachedSKUs;
        }
      }

      final response = await _apiService.get<List<dynamic>>('/inventory/skus');
      
      if (response.isSuccess && response.data != null) {
        final skus = response.data!
            .map<SKU>((json) => SKU.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Guardar en caché
        await _cacheSKUs(skus);
        return skus;
      } else {
        throw Exception(response.error ?? 'Error obteniendo SKUs');
      }
    } catch (e) {
      debugPrint('Error getting SKUs: $e');
      // Devolver caché como fallback
      return await _getCachedSKUs();
    }
  }

  Future<SKU?> getSKUByCode(String skuCode) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inventory/skus/$skuCode',
      );
      
      if (response.isSuccess && response.data != null) {
        return SKU.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint('Error getting SKU $skuCode: $e');
    }
    return null;
  }

  // =========================
  // Location Management
  // =========================
  
  Future<List<Location>> getLocations({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedLocations = await _getCachedLocations();
        if (cachedLocations.isNotEmpty) {
          return cachedLocations;
        }
      }

      final response = await _apiService.get<List<dynamic>>('/inventory/locations');
      
      if (response.isSuccess && response.data != null) {
        final locations = response.data!
            .map<Location>((json) => Location.fromJson(json as Map<String, dynamic>))
            .toList();
        
        await _cacheLocations(locations);
        return locations;
      } else {
        throw Exception(response.error ?? 'Error obteniendo ubicaciones');
      }
    } catch (e) {
      debugPrint('Error getting locations: $e');
      return await _getCachedLocations();
    }
  }

  Future<Location?> getLocationByCode(String locationCode) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inventory/locations/$locationCode',
      );
      
      if (response.isSuccess && response.data != null) {
        return Location.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint('Error getting location $locationCode: $e');
    }
    return null;
  }

  // =========================
  // Inventory Queries
  // =========================
  
  Future<List<Inventory>> getInventory({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedInventory = await _getCachedInventory();
        if (cachedInventory.isNotEmpty) {
          return cachedInventory;
        }
      }

      final response = await _apiService.get<List<dynamic>>('/inventory');
      
      if (response.isSuccess && response.data != null) {
        final inventory = response.data!
            .map<Inventory>((json) => Inventory.fromJson(json as Map<String, dynamic>))
            .toList();
        
        await _cacheInventory(inventory);
        return inventory;
      } else {
        throw Exception(response.error ?? 'Error obteniendo inventario');
      }
    } catch (e) {
      debugPrint('Error getting inventory: $e');
      return await _getCachedInventory();
    }
  }

  Future<List<Inventory>> getInventoryBySKU(String skuCode) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/inventory/by-sku/$skuCode',
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<Inventory>((json) => Inventory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting inventory by SKU $skuCode: $e');
    }
    return [];
  }

  Future<List<Inventory>> getInventoryByLocation(String locationCode) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/inventory/by-location/$locationCode',
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<Inventory>((json) => Inventory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting inventory by location $locationCode: $e');
    }
    return [];
  }

  Future<Inventory?> getInventoryByLocationAndSKU(
    String locationCode,
    String skuCode,
  ) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inventory/by-location-sku/$locationCode/$skuCode',
      );
      
      if (response.isSuccess && response.data != null) {
        return Inventory.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint('Error getting inventory by location-SKU: $e');
    }
    return null;
  }

  Future<List<Inventory>> searchInventory(String query) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '/inventory/search',
        queryParams: {'q': query},
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<Inventory>((json) => Inventory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching inventory: $e');
    }
    return [];
  }

  // =========================
  // Transaction Management
  // =========================
  
  Future<bool> createTransaction(Transaction transaction) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/inventory/transactions',
        body: transaction.toJson(),
      );
      
      if (response.isSuccess) {
        // Invalidar caché de inventario
        await _invalidateInventoryCache();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating transaction: $e');
    }
    return false;
  }

  Future<List<Transaction>> getTransactions({
    String? locationCode,
    String? skuCode,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (locationCode != null) queryParams['location'] = locationCode;
      if (skuCode != null) queryParams['sku'] = skuCode;
      if (fromDate != null) queryParams['from'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to'] = toDate.toIso8601String();

      final response = await _apiService.get<List<dynamic>>(
        '/inventory/transactions',
        queryParams: queryParams,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<Transaction>((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting transactions: $e');
    }
    return [];
  }

  // =========================
  // Reception Management
  // =========================
  
  Future<bool> createReception({
    required String skuCode,
    required String locationCode,
    required int quantity,
    String? lot,
    DateTime? expiryDate,
    String? supplierCode,
    String? notes,
    List<String>? epcs,
  }) async {
    try {
      // ✅ CORREGIDO: usar los parámetros correctos del constructor
      final transaction = Transaction(
        id: null, // Se generará en el servidor
        type: TransactionType.IN, // ✅ Usar IN para recepción
        skuCode: skuCode,
        quantity: quantity,
        fromLocation: null, // Recepción no tiene origen
        toLocation: locationCode, // ✅ Usar toLocation
        user: _authService.currentUser?.username ?? 'unknown', // ✅ Usar 'user'
        timestamp: DateTime.now(), // ✅ Agregar timestamp requerido
        epc: epcs?.isNotEmpty == true ? epcs!.first : null,
        lot: lot,
        notes: notes,
        referenceDocument: supplierCode,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      return await createTransaction(transaction);
    } catch (e) {
      debugPrint('Error creating reception: $e');
      return false;
    }
  }

  // =========================
  // Movement Management
  // =========================
  
  Future<bool> createMovement({
    required String skuCode,
    required String fromLocationCode,
    required String toLocationCode,
    required int quantity,
    String? notes,
    List<String>? epcs,
  }) async {
    try {
      // ✅ CORREGIDO: usar los parámetros correctos del constructor
      final transaction = Transaction(
        id: null,
        type: TransactionType.MOVE, // ✅ Usar MOVE para movimiento
        skuCode: skuCode,
        quantity: quantity,
        fromLocation: fromLocationCode, // ✅ Usar fromLocation
        toLocation: toLocationCode, // ✅ Usar toLocation
        user: _authService.currentUser?.username ?? 'unknown', // ✅ Usar 'user'
        timestamp: DateTime.now(), // ✅ Agregar timestamp requerido
        epc: epcs?.isNotEmpty == true ? epcs!.first : null,
        lot: null,
        notes: notes,
        referenceDocument: null,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      return await createTransaction(transaction);
    } catch (e) {
      debugPrint('Error creating movement: $e');
      return false;
    }
  }

  // =========================
  // Dispatch Management
  // =========================
  
  Future<bool> createDispatch({
    required String skuCode,
    required String fromLocationCode,
    required int quantity,
    String? referenceDocument,
    String? notes,
    List<String>? epcs,
  }) async {
    try {
      // ✅ NUEVO: método para crear despachos
      final transaction = Transaction(
        id: null,
        type: TransactionType.OUT, // ✅ Usar OUT para despacho
        skuCode: skuCode,
        quantity: quantity,
        fromLocation: fromLocationCode, // ✅ Despacho tiene origen
        toLocation: null, // Despacho no tiene destino interno
        user: _authService.currentUser?.username ?? 'unknown',
        timestamp: DateTime.now(),
        epc: epcs?.isNotEmpty == true ? epcs!.first : null,
        lot: null,
        notes: notes,
        referenceDocument: referenceDocument,
        isSynced: false,
        createdAt: DateTime.now(),
      );

      return await createTransaction(transaction);
    } catch (e) {
      debugPrint('Error creating dispatch: $e');
      return false;
    }
  }

  // =========================
  // Count Management
  // =========================
  
  Future<List<Count>> getActiveCounts() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/inventory/counts/active');
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<Count>((json) => Count.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting active counts: $e');
    }
    return [];
  }

  Future<bool> createCount(Count count) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/inventory/counts',
        body: count.toJson(),
      );
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error creating count: $e');
      return false;
    }
  }

  // =========================
  // EPC Management
  // =========================
  
  Future<List<EPC>> getCommissionedEPCs() async {
    try {
      final response = await _apiService.get<List<dynamic>>('/inventory/epcs');
      
      if (response.isSuccess && response.data != null) {
        return response.data!
            .map<EPC>((json) => EPC.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting EPCs: $e');
    }
    return [];
  }

  Future<bool> commissionEPC(EPC epc) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/inventory/epcs/commission',
        body: epc.toJson(),
      );
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error commissioning EPC: $e');
      return false;
    }
  }

  // =========================
  // Cache Management
  // =========================
  
  Future<List<SKU>> _getCachedSKUs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_skusCacheKey);
      final cacheTime = prefs.getInt('${_skusCacheKey}_time');
      
      if (cachedData != null && cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < _cacheExpiration.inMilliseconds) {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          return jsonList.map<SKU>((json) => SKU.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading cached SKUs: $e');
    }
    return [];
  }

  Future<void> _cacheSKUs(List<SKU> skus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(skus.map((sku) => sku.toJson()).toList());
      await prefs.setString(_skusCacheKey, jsonData);
      await prefs.setInt('${_skusCacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching SKUs: $e');
    }
  }

  Future<List<Location>> _getCachedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_locationsCacheKey);
      final cacheTime = prefs.getInt('${_locationsCacheKey}_time');
      
      if (cachedData != null && cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < _cacheExpiration.inMilliseconds) {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          return jsonList.map<Location>((json) => Location.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading cached locations: $e');
    }
    return [];
  }

  Future<void> _cacheLocations(List<Location> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(locations.map((loc) => loc.toJson()).toList());
      await prefs.setString(_locationsCacheKey, jsonData);
      await prefs.setInt('${_locationsCacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching locations: $e');
    }
  }

  Future<List<Inventory>> _getCachedInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_inventoryCacheKey);
      final cacheTime = prefs.getInt('${_inventoryCacheKey}_time');
      
      if (cachedData != null && cacheTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (age < _cacheExpiration.inMilliseconds) {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          return jsonList.map<Inventory>((json) => Inventory.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading cached inventory: $e');
    }
    return [];
  }

  Future<void> _cacheInventory(List<Inventory> inventory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(inventory.map((inv) => inv.toJson()).toList());
      await prefs.setString(_inventoryCacheKey, jsonData);
      await prefs.setInt('${_inventoryCacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching inventory: $e');
    }
  }

  Future<void> _invalidateInventoryCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_inventoryCacheKey);
      await prefs.remove('${_inventoryCacheKey}_time');
    } catch (e) {
      debugPrint('Error invalidating inventory cache: $e');
    }
  }

  // Limpiar todo el caché
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        _skusCacheKey,
        '${_skusCacheKey}_time',
        _locationsCacheKey,
        '${_locationsCacheKey}_time',
        _inventoryCacheKey,
        '${_inventoryCacheKey}_time',
      ];
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Sync offline transactions
  Future<bool> syncOfflineTransactions() async {
    try {
      // TODO: Implementar sincronización de transacciones offline
      return true;
    } catch (e) {
      debugPrint('Error syncing offline transactions: $e');
      return false;
    }
  }
}