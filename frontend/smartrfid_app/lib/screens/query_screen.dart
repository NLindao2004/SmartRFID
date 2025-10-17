import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../adapters/barcode_adapter.dart';
import '../widgets/scan_button.dart';
import '../widgets/inventory_card.dart';

class QueryScreen extends StatefulWidget {
  const QueryScreen({super.key});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _inventoryService = InventoryService();
  final _barcodeAdapter = CameraBarcodeAdapter();
  
  List<Inventory> _inventoryResults = [];
  List<SKU> _skus = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _inventoryService.getSKUs(),
        _inventoryService.getLocations(),
        _inventoryService.getInventory(), // ✅ CORREGIDO: cambiar getAllInventory() por getInventory()
      ]);
      
      setState(() {
        _skus = results[0] as List<SKU>;
        _locations = results[1] as List<Location>;
        _inventoryResults = results[2] as List<Inventory>;
      });
    } catch (e) {
      _showError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas'),
        backgroundColor: Colors.purple.shade100,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Buscar'),
            Tab(icon: Icon(Icons.inventory), text: 'Por SKU'),
            Tab(icon: Icon(Icons.location_on), text: 'Por Ubicación'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildSKUTab(),
          _buildLocationTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar SKU o Ubicación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Ingrese código o descripción',
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _performSearch();
                  },
                  onSubmitted: (value) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ScanButton(
                onPressed: _scanForSearch,
                icon: Icons.qr_code_scanner,
              ),
            ],
          ),
        ),

        // Resultados de búsqueda
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inventoryResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Ingrese un término de búsqueda'
                                : 'No se encontraron resultados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _inventoryResults.length,
                      itemBuilder: (context, index) {
                        final inventory = _inventoryResults[index];
                        return InventoryCard(
                          inventory: inventory,
                          sku: _skus.firstWhere(
                            (s) => s.code == inventory.skuCode, // ✅ CORREGIDO: usar .code
                            orElse: () => SKU(
                              code: inventory.skuCode, // ✅ CORREGIDO
                              description: 'SKU no encontrado',
                              uom: 'PCS', skuCode: '',
                            ),
                          ),
                          location: _locations.firstWhere(
                            (l) => l.code == inventory.locationCode,
                            orElse: () => Location(
                              code: inventory.locationCode,
                              area: 'Área desconocida',
                            ),
                          ),
                          onTap: () => _showInventoryDetails(inventory),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSKUTab() {
    return Column(
      children: [
        // Selector de SKU
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<SKU>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar SKU',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
            ),
            isExpanded: true,
            items: _skus.map((sku) {
              return DropdownMenuItem(
                value: sku,
                child: Text(
                  '${sku.code} - ${sku.description}', // ✅ CORREGIDO: usar .code
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (sku) {
              if (sku != null) {
                _searchBySKU(sku.code); // ✅ CORREGIDO: usar .code
              }
            },
          ),
        ),

        // Resultados por SKU
        Expanded(
          child: _buildInventoryList(),
        ),
      ],
    );
  }

  Widget _buildLocationTab() {
    return Column(
      children: [
        // Selector de ubicación
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<Location>(
            decoration: const InputDecoration(
              labelText: 'Seleccionar Ubicación',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            isExpanded: true,
            items: _locations.map((location) {
              return DropdownMenuItem(
                value: location,
                child: Text(
                  '${location.code} - ${location.area}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (location) {
              if (location != null) {
                _searchByLocation(location.code);
              }
            },
          ),
        ),

        // Resultados por ubicación
        Expanded(
          child: _buildInventoryList(),
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_inventoryResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione un criterio de búsqueda',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _inventoryResults.length,
      itemBuilder: (context, index) {
        final inventory = _inventoryResults[index];
        return InventoryCard(
          inventory: inventory,
          sku: _skus.firstWhere(
            (s) => s.code == inventory.skuCode, // ✅ CORREGIDO: usar .code
            orElse: () => SKU(
              code: inventory.skuCode, // ✅ CORREGIDO
              description: 'SKU no encontrado',
              uom: 'PCS', skuCode: '',
            ),
          ),
          location: _locations.firstWhere(
            (l) => l.code == inventory.locationCode,
            orElse: () => Location(
              code: inventory.locationCode,
              area: 'Área desconocida',
            ),
          ),
          onTap: () => _showInventoryDetails(inventory),
        );
      },
    );
  }

  Future<void> _scanForSearch() async {
    try {
      final result = await _barcodeAdapter.scanBarcode();
      if (result != null) {
        _searchController.text = result;
        setState(() => _searchQuery = result);
        _performSearch();
      }
    } catch (e) {
      _showError('Error en escaneo: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() => _inventoryResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _inventoryService.searchInventory(_searchQuery);
      setState(() => _inventoryResults = results);
    } catch (e) {
      _showError('Error en búsqueda: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchBySKU(String skuCode) async {
    setState(() => _isLoading = true);

    try {
      final results = await _inventoryService.getInventoryBySKU(skuCode);
      setState(() => _inventoryResults = results);
      
      if (results.isEmpty) {
        _showError('No se encontró inventario para este SKU');
      }
    } catch (e) {
      _showError('Error buscando por SKU: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchByLocation(String locationCode) async {
    setState(() => _isLoading = true);

    try {
      final results = await _inventoryService.getInventoryByLocation(locationCode);
      setState(() => _inventoryResults = results);
      
      if (results.isEmpty) {
        _showError('No se encontró inventario en esta ubicación');
      }
    } catch (e) {
      _showError('Error buscando por ubicación: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showInventoryDetails(Inventory inventory) {
    final sku = _skus.firstWhere(
      (s) => s.code == inventory.skuCode, // ✅ CORREGIDO
      orElse: () => SKU(
        code: inventory.skuCode, // ✅ CORREGIDO
        description: 'SKU no encontrado',
        uom: 'PCS', skuCode: '',
      ),
    );
    
    final location = _locations.firstWhere(
      (l) => l.code == inventory.locationCode,
      orElse: () => Location(
        code: inventory.locationCode,
        area: 'Área desconocida',
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Text(
                  'Detalle de Inventario',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('SKU:', '${inventory.skuCode} - ${sku.description}'),
                        _buildDetailRow('Ubicación:', '${inventory.locationCode} - ${location.area}'),
                        _buildDetailRow('UOM:', sku.uom),
                        const Divider(),
                        _buildDetailRow('Cantidad Total:', '${inventory.quantity}'),
                        _buildDetailRow('Disponible:', '${inventory.availableQuantity}'),
                        _buildDetailRow('Reservado:', '${inventory.reservedQuantity}'),
                        if (inventory.lot != null) ...[
                          const Divider(),
                          _buildDetailRow('Lote:', inventory.lot!),
                        ],
                        if (inventory.expiryDate != null)
                          _buildDetailRow(
                            'Vencimiento:',
                            '${inventory.expiryDate!.day}/${inventory.expiryDate!.month}/${inventory.expiryDate!.year}',
                          ),
                        const Divider(),
                        _buildDetailRow(
                          'Última Actualización:',
                          '${inventory.lastUpdated.day}/${inventory.lastUpdated.month}/${inventory.lastUpdated.year} ${inventory.lastUpdated.hour}:${inventory.lastUpdated.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}