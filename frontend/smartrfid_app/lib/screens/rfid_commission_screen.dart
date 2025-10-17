 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/epc.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../adapters/rfid_adapter.dart';
import '../adapters/barcode_adapter.dart';
import '../widgets/scan_button.dart';
import '../widgets/quantity_input.dart';

class RFIDCommissionScreen extends StatefulWidget {
  const RFIDCommissionScreen({super.key});

  @override
  State<RFIDCommissionScreen> createState() => _RFIDCommissionScreenState();
}

class _RFIDCommissionScreenState extends State<RFIDCommissionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _quantityController = TextEditingController();
  final _lotController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _inventoryService = InventoryService();
  final _rfidAdapter = PortableRFIDAdapter();
  final _barcodeAdapter = CameraBarcodeAdapter();
  
  List<SKU> _skus = [];
  List<Location> _locations = [];
  List<String> _scannedEPCs = [];
  List<EPC> _commissionedEPCs = [];
  SKU? _selectedSKU;
  Location? _selectedLocation;
  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _lotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _inventoryService.getSKUs(),
        _inventoryService.getLocations(),
        _inventoryService.getCommissionedEPCs(),
      ]);
      
      setState(() {
        _skus = results[0] as List<SKU>;
        _locations = results[1] as List<Location>;
        _commissionedEPCs = results[2] as List<EPC>;
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
        title: const Text('RFID Commission'),
        backgroundColor: Colors.teal.shade100,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Comisionar'),
            Tab(icon: Icon(Icons.search), text: 'Buscar EPC'),
            Tab(icon: Icon(Icons.list), text: 'Comisionados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommissionTab(),
          _buildFinderTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildCommissionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de escaneo de EPCs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Etiquetas RFID Escaneadas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ScanButton(
                        onPressed: _isScanning ? null : _scanRFIDTags,
                        icon: Icons.nfc,
                        label: _isScanning ? 'Escaneando...' : 'Escanear',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_scannedEPCs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.nfc, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No hay etiquetas escaneadas',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            'Presiona "Escanear" para comenzar',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        itemCount: _scannedEPCs.length,
                        itemBuilder: (context, index) {
                          final epc = _scannedEPCs[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.nfc, color: Colors.teal),
                            title: Text(
                              epc,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _scannedEPCs.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card de información del producto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Producto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // SKU Selection
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SKU>(
                          value: _selectedSKU,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          items: _skus.map((sku) {
                            return DropdownMenuItem(
                              value: sku,
                              child: Text('${sku.skuCode} - ${sku.description}'),
                            );
                          }).toList(),
                          onChanged: (sku) {
                            setState(() => _selectedSKU = sku);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Seleccione un SKU';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScanButton(
                        onPressed: _scanSKUBarcode,
                        icon: Icons.qr_code_scanner,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location Selection
                  DropdownButtonFormField<Location>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación Inicial',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text('${location.code} - ${location.area}'),
                      );
                    }).toList(),
                    onChanged: (location) {
                      setState(() => _selectedLocation = location);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quantity per EPC
                  QuantityInput(
                    controller: _quantityController,
                    label: 'Cantidad por etiqueta',
                    helperText: 'Cantidad de unidades que representa cada EPC',
                  ),

                  const SizedBox(height: 16),

                  // Lot/Batch
                  TextFormField(
                    controller: _lotController,
                    decoration: const InputDecoration(
                      labelText: 'Lote/Batch (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.batch_prediction),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Commission Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _canCommission() ? _commissionEPCs : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Comisionar ${_scannedEPCs.length} Etiqueta${_scannedEPCs.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinderTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de búsqueda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Buscar Etiqueta RFID',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use el modo "Geiger" del lector RFID para localizar una etiqueta específica. '
                    'La intensidad de la señal aumentará cuando se acerque a la etiqueta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _startGeigerMode,
                      icon: const Icon(Icons.radar),
                      label: const Text('Iniciar Modo Geiger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Resultados de búsqueda/señal
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Intensidad de Señal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Simulación de medidor de señal
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.signal_cellular_off, size: 48, color: Colors.grey),
                            Text('Sin señal - Inicie el modo Geiger'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Instrucciones:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Mueva el lector lentamente por el área\n'
                      '• La señal se intensificará cerca de la etiqueta\n'
                      '• Un pitido continuo indica que encontró la etiqueta',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        // Header con estadísticas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', '${_commissionedEPCs.length}'),
              _buildStatCard('Activos', '${_commissionedEPCs.where((e) => e.isActive).length}'),
              _buildStatCard('Perdidos', '${_commissionedEPCs.where((e) => e.status == EPCStatus.lost).length}'),
            ],
          ),
        ),

        // Lista de EPCs comisionados
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _commissionedEPCs.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay etiquetas comisionadas',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _commissionedEPCs.length,
                      itemBuilder: (context, index) {
                        final epc = _commissionedEPCs[index];
                        return _buildEPCTile(epc);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEPCTile(EPC epc) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEPCStatusColor(epc.status),
          child: Icon(
            _getEPCStatusIcon(epc.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          epc.epc,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (epc.skuCode != null) Text('SKU: ${epc.skuCode}'),
            if (epc.quantity != null) Text('Cantidad: ${epc.quantity}'),
            if (epc.lastLocationCode != null) Text('Ubicación: ${epc.lastLocationCode}'),
            Text('Estado: ${epc.statusDisplayName}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleEPCAction(epc, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'find',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Buscar'),
                ],
              ),
            ),
            if (epc.isActive)
              const PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 8),
                    Text('Desactivar'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('Detalles'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showEPCDetails(epc),
      ),
    );
  }

  Color _getEPCStatusColor(EPCStatus status) {
    switch (status) {
      case EPCStatus.active:
        return Colors.green;
      case EPCStatus.inactive:
        return Colors.grey;
      case EPCStatus.commissioned:
        return Colors.blue;
      case EPCStatus.lost:
        return Colors.red;
      case EPCStatus.damaged:
        return Colors.orange;
    }
  }

  IconData _getEPCStatusIcon(EPCStatus status) {
    switch (status) {
      case EPCStatus.active:
        return Icons.check_circle;
      case EPCStatus.inactive:
        return Icons.pause_circle;
      case EPCStatus.commissioned:
        return Icons.verified;
      case EPCStatus.lost:
        return Icons.error;
      case EPCStatus.damaged:
        return Icons.warning;
    }
  }

  Future<void> _scanRFIDTags() async {
    setState(() => _isScanning = true);
    
    try {
      final tags = await _rfidAdapter.scanRFIDTags();
      
      setState(() {
        // Filtrar tags ya comisionados y duplicados
        for (final tag in tags) {
          if (!_scannedEPCs.contains(tag) && 
              !_commissionedEPCs.any((epc) => epc.epc == tag)) {
            _scannedEPCs.add(tag);
          }
        }
      });

      HapticFeedback.lightImpact();
      
      if (tags.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tags.length} etiqueta${tags.length != 1 ? 's' : ''} encontrada${tags.length != 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error escaneando RFID: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _scanSKUBarcode() async {
    try {
      final result = await _barcodeAdapter.scanBarcode();
      if (result != null) {
        final sku = _skus.firstWhere(
          (s) => s.skuCode == result,
          orElse: () => SKU(
            skuCode: result,
            description: 'SKU Escaneado',
            uom: 'PCS', code: '',
          ),
        );
        
        setState(() => _selectedSKU = sku);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Error escaneando código: $e');
    }
  }

  bool _canCommission() {
    return _scannedEPCs.isNotEmpty &&
           _selectedSKU != null &&
           _quantityController.text.isNotEmpty;
  }

  Future<void> _commissionEPCs() async {
    if (!_canCommission()) return;

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      _showError('Cantidad debe ser mayor a 0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (final epcString in _scannedEPCs) {
        final success = await _rfidAdapter.commissionTag(
          epcString,
          _selectedSKU!.skuCode,
          quantity,
        );
        
        if (success) {
          // Crear objeto EPC comisionado
          final epc = EPC(
            epc: epcString,
            skuCode: _selectedSKU!.skuCode,
            quantity: quantity,
            lot: _lotController.text.isNotEmpty ? _lotController.text : null,
            lastLocationCode: _selectedLocation?.code,
            status: EPCStatus.commissioned,
            commissionedAt: DateTime.now(),
            commissionedBy: 'current_user', // TODO: Obtener del contexto
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
          
          setState(() {
            _commissionedEPCs.add(epc);
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_scannedEPCs.length} etiqueta${_scannedEPCs.length != 1 ? 's' : ''} comisionada${_scannedEPCs.length != 1 ? 's' : ''} exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearCommissionForm();
      }
    } catch (e) {
      _showError('Error comisionando etiquetas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearCommissionForm() {
    setState(() {
      _scannedEPCs.clear();
      _selectedSKU = null;
      _selectedLocation = null;
    });
    _quantityController.clear();
    _lotController.clear();
    _notesController.clear();
  }

  Future<void> _startGeigerMode() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo Geiger activado - Mueva el lector para localizar etiquetas'),
          duration: Duration(seconds: 3),
        ),
      );
      
      // TODO: Implementar modo Geiger real con el SDK del lector
      // Por ahora solo simulamos
      await Future.delayed(const Duration(seconds: 2));
      
    } catch (e) {
      _showError('Error iniciando modo Geiger: $e');
    }
  }

  void _handleEPCAction(EPC epc, String action) {
    switch (action) {
      case 'find':
        _findEPC(epc);
        break;
      case 'deactivate':
        _deactivateEPC(epc);
        break;
      case 'details':
        _showEPCDetails(epc);
        break;
    }
  }

  Future<void> _findEPC(EPC epc) async {
    try {
      await _rfidAdapter.findTag(epc.epc);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando etiqueta: ${epc.epc}')),
      );
    } catch (e) {
      _showError('Error buscando etiqueta: $e');
    }
  }

  void _deactivateEPC(EPC epc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Etiqueta'),
        content: Text('¿Está seguro que desea desactivar la etiqueta ${epc.epc}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar desactivación
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Etiqueta desactivada')),
              );
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _showEPCDetails(EPC epc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Etiqueta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('EPC:', epc.epc),
              _buildDetailRow('SKU:', epc.skuCode ?? 'N/A'),
              _buildDetailRow('Cantidad:', '${epc.quantity ?? 0}'),
              _buildDetailRow('Lote:', epc.lot ?? 'N/A'),
              _buildDetailRow('Estado:', epc.statusDisplayName),
              _buildDetailRow('Ubicación:', epc.lastLocationCode ?? 'N/A'),
              if (epc.lastSeenAt != null)
                _buildDetailRow('Última lectura:', 
                    '${epc.lastSeenAt!.day}/${epc.lastSeenAt!.month}/${epc.lastSeenAt!.year}'),
              if (epc.commissionedAt != null)
                _buildDetailRow('Comisionado:', 
                    '${epc.commissionedAt!.day}/${epc.commissionedAt!.month}/${epc.commissionedAt!.year}'),
              if (epc.commissionedBy != null)
                _buildDetailRow('Por:', epc.commissionedBy!),
              if (epc.notes != null)
                _buildDetailRow('Notas:', epc.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: label == 'EPC:' 
                  ? const TextStyle(fontFamily: 'monospace', fontSize: 12)
                  : null,
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