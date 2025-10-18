import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/count.dart';
import '../models/location.dart';
import '../models/sku.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../adapters/barcode_adapter.dart';
import '../adapters/rfid_adapter.dart';
import '../widgets/scan_button.dart';
import '../widgets/quantity_input.dart';

class CountScreen extends StatefulWidget {
  const CountScreen({super.key});

  @override
  State<CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<CountScreen> {
  final _inventoryService = InventoryService();
  final _barcodeAdapter = CameraBarcodeAdapter();
  final _rfidAdapter = PortableRFIDAdapter();
  
  List<Count> _activeCounts = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  bool _useRFID = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _inventoryService.getActiveCounts(),
        _inventoryService.getLocations(),
      ]);
      
      setState(() {
        _activeCounts = results[0] as List<Count>;
        _locations = results[1] as List<Location>;
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
        title: const Text('Conteos'),
        backgroundColor: const Color.fromARGB(255, 233, 52, 52),
        actions: [
          Switch(
            value: _useRFID,
            onChanged: (value) => setState(() => _useRFID = value),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.nfc),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewCount,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selector de modo de conteo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _startSpotCount(),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.search, size: 32, color: Colors.orange),
                                  SizedBox(height: 8),
                                  Text('Conteo Puntual', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Contar ubicación específica', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _startBlindCount(),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.visibility_off, size: 32, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('Conteo Ciego', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Sin ver stock sistema', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de conteos activos
                Expanded(
                  child: _activeCounts.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay conteos activos',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeCounts.length,
                          itemBuilder: (context, index) {
                            final count = _activeCounts[index];
                            return _buildCountCard(count);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // ✅ CORREGIDO: Usar propiedades que existen en el modelo Count
  Widget _buildCountCard(Count count) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(count.status),
          child: Icon(
            _getStatusIcon(count.status),
            color: Colors.white,
          ),
        ),
        // ✅ CORREGIDO: Usar locationCode y fecha en lugar de 'name'
        title: Text('Conteo - ${count.locationCode}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ CORREGIDO: Usar statusDisplayName que existe en el modelo
            Text('${count.statusDisplayName} • ${count.totalItemsCounted} items'),
            const SizedBox(height: 4),
            // ✅ CORREGIDO: Mostrar progreso basado en items completados
            if (count.status == CountStatus.inProgress) ...[
              LinearProgressIndicator(
                value: count.totalItemsCounted > 0 
                    ? (count.totalItemsCounted - count.itemsWithDiscrepancies) / count.totalItemsCounted
                    : 0,
                backgroundColor: Colors.grey.shade300,
              ),
              Text(
                'Iniciado: ${_formatDateTime(count.startedAt)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            // ✅ AGREGADO: Mostrar discrepancias si hay
            if (count.hasDiscrepancies)
              Text(
                '⚠️ ${count.itemsWithDiscrepancies} discrepancias',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ CORREGIDO: Usar status del modelo
            if (count.status == CountStatus.pending)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _startCount(count),
              ),
            if (count.status == CountStatus.inProgress)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _continueCount(count),
              ),
            if (count.isCompleted)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => _viewCountDetails(count),
              ),
          ],
        ),
        onTap: () => _viewCountDetails(count),
      ),
    );
  }

  Color _getStatusColor(CountStatus status) {
    switch (status) {
      case CountStatus.pending:
        return Colors.grey;
      case CountStatus.inProgress:
        return Colors.orange;
      case CountStatus.completed:
        return Colors.green;
      case CountStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(CountStatus status) {
    switch (status) {
      case CountStatus.pending:
        return Icons.schedule;
      case CountStatus.inProgress:
        return Icons.play_arrow;
      case CountStatus.completed:
        return Icons.check;
      case CountStatus.cancelled:
        return Icons.cancel;
    }
  }

  // ✅ AGREGADO: Método para formatear fechas
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _startSpotCount() async {
    final location = await _selectLocation();
    if (location != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpotCountScreen(
            location: location,
            useRFID: _useRFID,
          ),
        ),
      );
      
      if (result == true) {
        _loadData(); // Recargar lista de conteos
      }
    }
  }

  Future<void> _startBlindCount() async {
    final location = await _selectLocation();
    if (location != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlindCountScreen(
            location: location,
            useRFID: _useRFID,
          ),
        ),
      );
      
      if (result == true) {
        _loadData(); // Recargar lista de conteos
      }
    }
  }

  Future<Location?> _selectLocation() async {
    return showDialog<Location>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Ubicación'),
        content: SizedBox(
          width: double.maxFinite,
          child: _locations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay ubicaciones disponibles'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return ListTile(
                      title: Text(location.code),
                      subtitle: Text(location.area),
                      onTap: () => Navigator.pop(context, location),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _createNewCount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use "Conteo Puntual" o "Conteo Ciego" para iniciar un nuevo conteo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startCount(Count count) {
    // Buscar la ubicación para navegar a la pantalla de conteo
    final location = _locations.firstWhere(
      (loc) => loc.code == count.locationCode,
      orElse: () => Location(code: count.locationCode, area: 'Área desconocida'),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpotCountScreen(
          location: location,
          useRFID: _useRFID,
          existingCount: count,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _continueCount(Count count) {
    _startCount(count); // Mismo comportamiento que iniciar
  }

  void _viewCountDetails(Count count) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
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
                  'Detalle del Conteo',
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
                        _buildDetailRow('Ubicación:', count.locationCode),
                        _buildDetailRow('Usuario:', count.userId),
                        _buildDetailRow('Estado:', count.statusDisplayName),
                        _buildDetailRow('Iniciado:', _formatDateTime(count.startedAt)),
                        if (count.completedAt != null)
                          _buildDetailRow('Finalizado:', _formatDateTime(count.completedAt!)),
                        const Divider(),
                        _buildDetailRow('Items Contados:', '${count.totalItemsCounted}'),
                        _buildDetailRow('Discrepancias:', '${count.itemsWithDiscrepancies}'),
                        if (count.hasDiscrepancies) ...[
                          _buildDetailRow('Sobrantes:', '+${count.totalPositiveDiscrepancy}'),
                          _buildDetailRow('Faltantes:', '-${count.totalNegativeDiscrepancy}'),
                        ],
                        if (count.notes != null) ...[
                          const Divider(),
                          _buildDetailRow('Notas:', count.notes!),
                        ],
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Items (${count.items.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...count.items.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: item.discrepancy != 0 ? Colors.orange.shade50 : null,
                          child: ListTile(
                            title: Text(item.skuCode),
                            subtitle: Text(
                              'Sistema: ${item.systemQuantity} | Contado: ${item.countedQuantity}',
                            ),
                            trailing: item.discrepancy != 0
                                ? Chip(
                                    label: Text(
                                      item.discrepancy > 0 ? '+${item.discrepancy}' : '${item.discrepancy}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: item.discrepancy > 0 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                  )
                                : const Icon(Icons.check_circle, color: Colors.green),
                          ),
                        )),
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
            width: 120,
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

// Pantalla de conteo puntual
class SpotCountScreen extends StatefulWidget {
  final Location location;
  final bool useRFID;
  final Count? existingCount; // ✅ AGREGADO: para continuar conteos existentes

  const SpotCountScreen({
    super.key,
    required this.location,
    required this.useRFID,
    this.existingCount,
  });

  @override
  State<SpotCountScreen> createState() => _SpotCountScreenState();
}

class _SpotCountScreenState extends State<SpotCountScreen> {
  final _quantityController = TextEditingController();
  final _inventoryService = InventoryService();
  final _barcodeAdapter = CameraBarcodeAdapter();
  final _rfidAdapter = PortableRFIDAdapter();
  
  List<Inventory> _locationInventory = [];
  List<CountItem> _countItems = []; // ✅ CORREGIDO: usar CountItem del modelo
  bool _isLoading = false;
  String? _currentUserId; // ✅ AGREGADO

  @override
  void initState() {
    super.initState();
    // ✅ AGREGADO: Si hay un conteo existente, cargar sus items
    if (widget.existingCount != null) {
      _countItems = List.from(widget.existingCount!.items);
    }
    _loadLocationInventory();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // TODO: Obtener del AuthService
    setState(() {
      _currentUserId = 'current_user';
    });
  }

  Future<void> _loadLocationInventory() async {
    setState(() => _isLoading = true);
    
    try {
      final inventory = await _inventoryService.getInventoryByLocation(
        widget.location.code,
      );
      
      setState(() {
        _locationInventory = inventory;
        
        // ✅ CORREGIDO: Solo crear nuevos items si no hay un conteo existente
        if (widget.existingCount == null) {
          _countItems = inventory.map((inv) => CountItem(
            skuCode: inv.skuCode,
            systemQuantity: inv.quantity,
            countedQuantity: 0, // Sin contar aún
          )).toList();
        }
      });
    } catch (e) {
      _showError('Error cargando inventario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _countItems.where((item) => item.countedQuantity > 0).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Conteo: ${widget.location.code}'),
        backgroundColor: Colors.orange.shade100,
        actions: [
          if (widget.useRFID)
            IconButton(
              icon: const Icon(Icons.nfc),
              onPressed: _scanAllRFID,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con información de la ubicación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación: ${widget.location.code}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Área: ${widget.location.area}'),
                      Text('SKUs a contar: ${_countItems.length}'),
                      Text('Completados: $completedCount'),
                      // ✅ AGREGADO: Mostrar progreso
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _countItems.isEmpty ? 0 : completedCount / _countItems.length,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),

                // Lista de items a contar
                Expanded(
                  child: ListView.builder(
                    itemCount: _countItems.length,
                    itemBuilder: (context, index) {
                      final item = _countItems[index];
                      return _buildCountItemTile(item, index);
                    },
                  ),
                ),

                // Botón de finalizar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: completedCount == _countItems.length ? _finishCount : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Finalizar Conteo ($completedCount/${_countItems.length})'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ✅ CORREGIDO: usar CountItem en lugar de CountDetail
  Widget _buildCountItemTile(CountItem item, int index) {
    final isCompleted = item.countedQuantity > 0;
    final hasDiscrepancy = item.discrepancy != 0 && isCompleted;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isCompleted 
          ? (hasDiscrepancy ? Colors.red.shade50 : Colors.green.shade50)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted 
              ? (hasDiscrepancy ? Colors.red : Colors.green)
              : Colors.grey,
          child: Icon(
            isCompleted ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(item.skuCode),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sistema: ${item.systemQuantity}'),
            if (isCompleted) ...[
              Text('Contado: ${item.countedQuantity}'),
              if (hasDiscrepancy)
                Text(
                  'Diferencia: ${item.discrepancy > 0 ? "+" : ""}${item.discrepancy}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ],
        ),
        trailing: isCompleted
            ? Icon(
                hasDiscrepancy ? Icons.warning : Icons.check_circle,
                color: hasDiscrepancy ? Colors.red : Colors.green,
              )
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _countItem(item, index),
              ),
        onTap: isCompleted ? null : () => _countItem(item, index),
      ),
    );
  }

  Future<void> _countItem(CountItem item, int index) async {
    _quantityController.text = item.systemQuantity.toString();
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contar: ${item.skuCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cantidad en sistema: ${item.systemQuantity}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QuantityInput(
                    controller: _quantityController,
                    label: 'Cantidad contada',
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                ScanButton(
                  onPressed: () async {
                    if (widget.useRFID) {
                      await _scanRFIDForItem(item);
                    } else {
                      final scanned = await _barcodeAdapter.scanBarcode();
                      if (scanned == item.skuCode) {
                        HapticFeedback.lightImpact();
                      }
                    }
                  },
                  icon: widget.useRFID ? Icons.nfc : Icons.qr_code_scanner,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(_quantityController.text);
              if (qty != null && qty >= 0) {
                Navigator.pop(context, qty);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        // ✅ CORREGIDO: Crear nuevo CountItem con la cantidad contada
        _countItems[index] = CountItem(
          skuCode: item.skuCode,
          systemQuantity: item.systemQuantity,
          countedQuantity: result,
          lot: item.lot,
          notes: item.notes,
        );
      });
    }
  }

  Future<void> _scanRFIDForItem(CountItem item) async {
    try {
      final tags = await _rfidAdapter.scanRFIDTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tags.length} etiquetas encontradas')),
        );
      }
    } catch (e) {
      _showError('Error en escaneo RFID: $e');
    }
  }

  Future<void> _scanAllRFID() async {
    if (!widget.useRFID) return;
    
    try {
      setState(() => _isLoading = true);
      
      final tags = await _rfidAdapter.scanRFIDTags();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escaneo completo: ${tags.length} etiquetas')),
        );
      }
      
    } catch (e) {
      _showError('Error en escaneo masivo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finishCount() async {
    final hasDiscrepancies = _countItems.any((item) => item.discrepancy != 0);
    
    if (hasDiscrepancies) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discrepancias Encontradas'),
          content: Text(
            'Se encontraron ${_countItems.where((item) => item.discrepancy != 0).length} '
            'diferencias entre el sistema y el conteo. '
            '¿Desea finalizar el conteo de todas formas?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Revisar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }

    try {
      setState(() => _isLoading = true);
      
      // ✅ CORREGIDO: Crear Count con el modelo correcto
      final count = Count(
        id: widget.existingCount?.id,
        locationCode: widget.location.code,
        userId: _currentUserId ?? 'unknown',
        startedAt: widget.existingCount?.startedAt ?? DateTime.now(),
        completedAt: DateTime.now(),
        status: CountStatus.completed,
        items: _countItems,
        notes: null,
      );
      
      final success = await _inventoryService.createCount(count);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conteo finalizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ✅ Retornar true para recargar lista
      } else {
        _showError('Error finalizando conteo');
      }
    } catch (e) {
      _showError('Error finalizando conteo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}

// Pantalla de conteo ciego
class BlindCountScreen extends StatefulWidget {
  final Location location;
  final bool useRFID;

  const BlindCountScreen({
    super.key,
    required this.location,
    required this.useRFID,
  });

  @override
  State<BlindCountScreen> createState() => _BlindCountScreenState();
}

class _BlindCountScreenState extends State<BlindCountScreen> {
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _barcodeAdapter = CameraBarcodeAdapter();
  final _inventoryService = InventoryService();
  
  // ✅ CORREGIDO: usar CountItem en lugar de Map
  final List<CountItem> _countedItems = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // TODO: Obtener del AuthService
    setState(() {
      _currentUserId = 'current_user';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conteo Ciego: ${widget.location.code}'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Column(
        children: [
          // Formulario de entrada
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScanButton(
                        onPressed: _scanSKU,
                        icon: Icons.qr_code_scanner,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuantityInput(
                          controller: _quantityController,
                          label: 'Cantidad',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addItem,
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lista de items contados
          Expanded(
            child: _countedItems.isEmpty
                ? const Center(
                    child: Text(
                      'Escanee o ingrese SKUs para comenzar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _countedItems.length,
                    itemBuilder: (context, index) {
                      final item = _countedItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(item.skuCode),
                          subtitle: Text('Cantidad: ${item.countedQuantity}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _countedItems.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botón finalizar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _countedItems.isNotEmpty ? _finishBlindCount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Finalizar Conteo Ciego (${_countedItems.length} items)'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanSKU() async {
    try {
      final result = await _barcodeAdapter.scanBarcode();
      if (result != null) {
        _skuController.text = result;
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Error en escaneo: $e');
    }
  }

  void _addItem() {
    if (_skuController.text.isNotEmpty && _quantityController.text.isNotEmpty) {
      final qty = int.tryParse(_quantityController.text);
      if (qty != null && qty > 0) {
        setState(() {
          // ✅ CORREGIDO: Crear CountItem en lugar de Map
          // Buscar si ya existe el SKU
          final existingIndex = _countedItems.indexWhere(
            (item) => item.skuCode == _skuController.text,
          );
          
          if (existingIndex >= 0) {
            // Actualizar cantidad existente
            final existing = _countedItems[existingIndex];
            _countedItems[existingIndex] = CountItem(
              skuCode: existing.skuCode,
              systemQuantity: 0, // No conocemos el sistema en conteo ciego
              countedQuantity: existing.countedQuantity + qty,
            );
          } else {
            // Agregar nuevo item
            _countedItems.add(CountItem(
              skuCode: _skuController.text,
              systemQuantity: 0, // No conocemos el sistema en conteo ciego
              countedQuantity: qty,
            ));
          }
        });
        
        _skuController.clear();
        _quantityController.clear();
        
        // Focus en SKU para siguiente entrada
        FocusScope.of(context).requestFocus(FocusNode());
      }
    }
  }

  Future<void> _finishBlindCount() async {
    try {
      // ✅ CORREGIDO: Crear Count con el modelo correcto
      final count = Count(
        locationCode: widget.location.code,
        userId: _currentUserId ?? 'unknown',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        status: CountStatus.completed,
        items: _countedItems,
        notes: 'Conteo ciego',
      );
      
      final success = await _inventoryService.createCount(count);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conteo ciego finalizado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ✅ Retornar true para recargar lista
      } else {
        _showError('Error finalizando conteo ciego');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}