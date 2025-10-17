import 'package:flutter/foundation.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../models/inventory.dart';
import '../models/transaction.dart';
import '../models/epc.dart';
import '../models/count.dart';
import '../services/inventory_service.dart';
import '../utils/constants.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _inventoryService;
  
  // Estado de datos
  List<SKU> _skus = [];
  List<Location> _locations = [];
  List<Inventory> _inventoryItems = [];
  List<Transaction> _transactions = [];
  List<EPC> _epcs = [];
  List<Count> _counts = [];
  
  // Estado de filtros y búsqueda
  String _searchQuery = '';
  String? _selectedLocationCode;
  String? _selectedSKUCode;
  TransactionType? _selectedTransactionType; // ✅ CAMBIADO: ahora es TransactionType?
  DateTime? _dateFrom;
  DateTime? _dateTo;
  
  // Estado de operaciones
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  DateTime? _lastSync;
  
  // Transacción pendiente (para operaciones offline)
  Transaction? _pendingTransaction;

  InventoryProvider(this._inventoryService) {
    _loadInitialData();
  }

  // Getters
  List<SKU> get skus => _skus;
  List<Location> get locations => _locations;
  List<Inventory> get inventoryItems => _filteredInventoryItems;
  List<Transaction> get transactions => _filteredTransactions;
  List<EPC> get epcs => _epcs;
  List<Count> get counts => _counts;
  
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  
  String get searchQuery => _searchQuery;
  String? get selectedLocationCode => _selectedLocationCode;
  String? get selectedSKUCode => _selectedSKUCode;
  TransactionType? get selectedTransactionType => _selectedTransactionType; // ✅ CAMBIADO
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  
  Transaction? get pendingTransaction => _pendingTransaction;

  // Inventario filtrado
  List<Inventory> get _filteredInventoryItems {
    var items = _inventoryItems.where((item) {
      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final sku = getSKUByCode(item.skuCode);
        
        final matchesCode = item.skuCode.toLowerCase().contains(query);
        final matchesDescription = sku?.description.toLowerCase().contains(query) ?? false;
        final matchesLocation = item.locationCode.toLowerCase().contains(query);
        
        if (!matchesCode && !matchesDescription && !matchesLocation) {
          return false;
        }
      }
      
      // Filtro por ubicación
      if (_selectedLocationCode != null && 
          item.locationCode != _selectedLocationCode) {
        return false;
      }
      
      // Filtro por SKU
      if (_selectedSKUCode != null && 
          item.skuCode != _selectedSKUCode) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Ordenar por cantidad (críticos primero)
    items.sort((a, b) {
      if (a.quantity <= InventoryConstants.stockCriticalThreshold &&
          b.quantity > InventoryConstants.stockCriticalThreshold) {
        return -1;
      } else if (b.quantity <= InventoryConstants.stockCriticalThreshold &&
                 a.quantity > InventoryConstants.stockCriticalThreshold) {
        return 1;
      }
      return a.skuCode.compareTo(b.skuCode);
    });
    
    return items;
  }

  // Transacciones filtradas - ✅ CORREGIDO
  List<Transaction> get _filteredTransactions {
    var items = _transactions.where((transaction) {
      // Filtro por tipo
      if (_selectedTransactionType != null && 
          transaction.type != _selectedTransactionType) {
        return false;
      }
      
      // Filtro por fechas
      if (_dateFrom != null && transaction.timestamp.isBefore(_dateFrom!)) {
        return false;
      }
      if (_dateTo != null && transaction.timestamp.isAfter(_dateTo!)) {
        return false;
      }
      
      // Filtro por ubicación - ✅ CORREGIDO: usar fromLocation y toLocation
      if (_selectedLocationCode != null) {
        final matchesFrom = transaction.fromLocation == _selectedLocationCode;
        final matchesTo = transaction.toLocation == _selectedLocationCode;
        if (!matchesFrom && !matchesTo) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Ordenar por fecha (más recientes primero)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return items;
  }

  // Cargar datos iniciales
  Future<void> _loadInitialData() async {
    _setLoading(true);
    
    try {
      await Future.wait([
        loadSKUs(),
        loadLocations(),
        loadInventory(),
        loadRecentTransactions(),
      ]);
    } catch (e) {
      _setError('Error al cargar datos iniciales: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar SKUs
  Future<void> loadSKUs() async {
    try {
      _skus = await _inventoryService.getSKUs();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar SKUs: ${e.toString()}');
    }
  }

  // Cargar ubicaciones
  Future<void> loadLocations() async {
    try {
      _locations = await _inventoryService.getLocations();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar ubicaciones: ${e.toString()}');
    }
  }

  // Cargar inventario
  Future<void> loadInventory() async {
    try {
      _inventoryItems = await _inventoryService.getInventory();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar inventario: ${e.toString()}');
    }
  }

  // Cargar transacciones recientes
  Future<void> loadRecentTransactions() async {
    try {
      _transactions = await _inventoryService.getTransactions(limit: 100);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar transacciones: ${e.toString()}');
    }
  }

  // Crear transacción
  Future<bool> createTransaction(Transaction transaction) async {
    _clearError();
    
    try {
      final success = await _inventoryService.createTransaction(transaction);
      
      if (success) {
        // Actualizar inventario local
        await _updateLocalInventory(transaction);
        
        // Agregar transacción a la lista
        _transactions.insert(0, transaction);
        
        notifyListeners();
        return true;
      } else {
        _setError('No se pudo crear la transacción');
        return false;
      }
    } catch (e) {
      _setError('Error al crear transacción: ${e.toString()}');
      
      // Guardar transacción como pendiente si está offline
      if (FeatureFlags.enableOfflineMode) {
        _pendingTransaction = transaction;
        notifyListeners();
      }
      
      return false;
    }
  }

  // Actualizar inventario local después de una transacción - ✅ CORREGIDO
  Future<void> _updateLocalInventory(Transaction transaction) async {
    // Determinar la ubicación objetivo según el tipo de transacción
    String? targetLocation;
    
    switch (transaction.type) {
      case TransactionType.IN:
        targetLocation = transaction.toLocation;
        break;
      case TransactionType.OUT:
        targetLocation = transaction.fromLocation;
        break;
      case TransactionType.MOVE:
        // Para movimientos, necesitamos actualizar ambas ubicaciones
        if (transaction.fromLocation != null) {
          await _updateInventoryForLocation(
            transaction.skuCode,
            transaction.fromLocation!,
            -transaction.quantity,
          );
        }
        if (transaction.toLocation != null) {
          await _updateInventoryForLocation(
            transaction.skuCode,
            transaction.toLocation!,
            transaction.quantity,
          );
        }
        return;
      case TransactionType.COUNT:
      case TransactionType.ADJUST:
        targetLocation = transaction.toLocation ?? transaction.fromLocation;
        break;
    }
    
    if (targetLocation == null) return;
    
    // Buscar el item de inventario existente
    final existingIndex = _inventoryItems.indexWhere(
      (item) => item.skuCode == transaction.skuCode &&
                item.locationCode == targetLocation,
    );
    
    if (existingIndex != -1) {
      final existingItem = _inventoryItems[existingIndex];
      int newQuantity = existingItem.quantity;
      
      switch (transaction.type) {
        case TransactionType.IN:
          newQuantity += transaction.quantity;
          break;
        case TransactionType.OUT:
          newQuantity -= transaction.quantity;
          break;
        case TransactionType.COUNT:
        case TransactionType.ADJUST:
          newQuantity = transaction.quantity;
          break;
        case TransactionType.MOVE:
          // Ya manejado arriba
          break;
      }
      
      // Actualizar el item existente
      final updatedItem = existingItem.copyWith(
        quantity: newQuantity,
        lastUpdated: DateTime.now(),
      );
      
      _inventoryItems[existingIndex] = updatedItem;
    } else {
      // Crear nuevo item de inventario si no existe
      if (transaction.type == TransactionType.IN || 
          transaction.type == TransactionType.ADJUST) {
        final newItem = Inventory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          skuCode: transaction.skuCode,
          locationCode: targetLocation,
          quantity: transaction.quantity,
          reservedQuantity: 0,
          lastUpdated: DateTime.now(),
        );
        
        _inventoryItems.add(newItem);
      }
    }
  }

  // Método auxiliar para actualizar inventario en una ubicación específica
  Future<void> _updateInventoryForLocation(
    String skuCode,
    String locationCode,
    int quantityChange,
  ) async {
    final existingIndex = _inventoryItems.indexWhere(
      (item) => item.skuCode == skuCode && item.locationCode == locationCode,
    );
    
    if (existingIndex != -1) {
      final existingItem = _inventoryItems[existingIndex];
      final newQuantity = existingItem.quantity + quantityChange;
      
      final updatedItem = existingItem.copyWith(
        quantity: newQuantity > 0 ? newQuantity : 0,
        lastUpdated: DateTime.now(),
      );
      
      _inventoryItems[existingIndex] = updatedItem;
    } else if (quantityChange > 0) {
      // Crear nuevo item solo si es un incremento
      final newItem = Inventory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        skuCode: skuCode,
        locationCode: locationCode,
        quantity: quantityChange,
        reservedQuantity: 0,
        lastUpdated: DateTime.now(),
      );
      
      _inventoryItems.add(newItem);
    }
  }

  // Comisionar EPC
  Future<bool> commissionEPC(String epc, String skuCode, int quantity, String? lot) async {
    _clearError();
    
    try {
      final epcModel = EPC(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        epc: epc,
        skuCode: skuCode,
        quantity: quantity,
        lot: lot,
        lastLocationCode: null,
        lastSeenAt: DateTime.now(),
        isActive: true,
      );
      
      final success = await _inventoryService.commissionEPC(epcModel);
      
      if (success) {
        _epcs.add(epcModel);
        notifyListeners();
        return true;
      } else {
        _setError('No se pudo comisionar el EPC');
        return false;
      }
    } catch (e) {
      _setError('Error al comisionar EPC: ${e.toString()}');
      return false;
    }
  }

  // Realizar conteo - ✅ CORREGIDO
  Future<bool> performCount(Count count) async {
    _clearError();
    
    try {
      final success = await _inventoryService.createCount(count);
      
      if (success) {
        _counts.add(count);
        
        // Si hay discrepancias, crear transacciones de ajuste
        for (final item in count.items) {
          if (item.discrepancy != 0) {
            final adjustmentTransaction = Transaction(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: TransactionType.ADJUST, // ✅ CAMBIADO: usar enum
              skuCode: item.skuCode,
              quantity: item.countedQuantity,
              fromLocation: null,
              toLocation: count.locationCode, // ✅ CAMBIADO: usar toLocation
              user: count.userId,
              timestamp: DateTime.now(),
              notes: 'Ajuste por conteo: ${item.discrepancy > 0 ? "+" : ""}${item.discrepancy}',
            );
            
            await createTransaction(adjustmentTransaction);
          }
        }
        
        notifyListeners();
        return true;
      } else {
        _setError('No se pudo guardar el conteo');
        return false;
      }
    } catch (e) {
      _setError('Error al realizar conteo: ${e.toString()}');
      return false;
    }
  }

  // Sincronizar datos
  Future<void> syncData() async {
    _setSyncing(true);
    _clearError();
    
    try {
      // Sincronizar transacciones pendientes
      if (_pendingTransaction != null) {
        final success = await _inventoryService.createTransaction(_pendingTransaction!);
        if (success) {
          _transactions.insert(0, _pendingTransaction!);
          _pendingTransaction = null;
        }
      }
      
      // Recargar todos los datos
      await _loadInitialData();
      
      _lastSync = DateTime.now();
    } catch (e) {
      _setError('Error al sincronizar: ${e.toString()}');
    } finally {
      _setSyncing(false);
    }
  }

  // Métodos de filtrado
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setLocationFilter(String? locationCode) {
    _selectedLocationCode = locationCode;
    notifyListeners();
  }

  void setSKUFilter(String? skuCode) {
    _selectedSKUCode = skuCode;
    notifyListeners();
  }

  // ✅ CORREGIDO: ahora acepta TransactionType?
  void setTransactionTypeFilter(TransactionType? type) {
    _selectedTransactionType = type;
    notifyListeners();
  }

  void setDateFilter(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedLocationCode = null;
    _selectedSKUCode = null;
    _selectedTransactionType = null; // ✅ CAMBIADO
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  // Métodos de utilidad
  SKU? getSKUByCode(String code) {
    try {
      return _skus.firstWhere((sku) => sku.code == code);
    } catch (e) {
      return null;
    }
  }

  Location? getLocationByCode(String code) {
    try {
      return _locations.firstWhere((location) => location.code == code);
    } catch (e) {
      return null;
    }
  }

  Inventory? getInventoryItem(String skuCode, String locationCode) {
    try {
      return _inventoryItems.firstWhere(
        (item) => item.skuCode == skuCode && item.locationCode == locationCode,
      );
    } catch (e) {
      return null;
    }
  }

  EPC? getEPCByCode(String epc) {
    try {
      return _epcs.firstWhere((epcItem) => epcItem.epc == epc);
    } catch (e) {
      return null;
    }
  }

  // Estadísticas
  int get totalSKUs => _skus.length;
  int get totalLocations => _locations.length;
  int get totalInventoryItems => _inventoryItems.length;
  int get lowStockItems => _inventoryItems
      .where((item) => item.quantity <= InventoryConstants.stockLowThreshold)
      .length;
  int get criticalStockItems => _inventoryItems
      .where((item) => item.quantity <= InventoryConstants.stockCriticalThreshold)
      .length;
  int get outOfStockItems => _inventoryItems
      .where((item) => item.quantity == 0)
      .length;

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}