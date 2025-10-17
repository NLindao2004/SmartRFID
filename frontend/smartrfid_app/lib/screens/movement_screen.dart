import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../adapters/barcode_adapter.dart';
import '../widgets/scan_button.dart';
import '../widgets/quantity_input.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key});

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _inventoryService = InventoryService();
  final _barcodeAdapter = CameraBarcodeAdapter();
  
  SKU? _selectedSKU;
  Location? _fromLocation;
  Location? _toLocation;
  List<SKU> _skus = [];
  List<Location> _locations = [];
  Inventory? _currentInventory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _inventoryService.getSKUs(),
        _inventoryService.getLocations(),
      ]);
      
      setState(() {
        _skus = results[0] as List<SKU>;
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
        title: const Text('Movimientos'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Card de selección de SKU y ubicación origen
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Origen',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // SKU Selection
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedSKU?.toString() ?? 'SKU no seleccionado',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                ScanButton(
                                  onPressed: _scanSKU,
                                  icon: Icons.qr_code_scanner,
                                  label: 'Escanear',
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // From Location
                            DropdownButtonFormField<Location>(
                              value: _fromLocation,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación origen',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              items: _locations.map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Text(location.toString()),
                                );
                              }).toList(),
                              onChanged: (location) {
                                setState(() => _fromLocation = location);
                                if (_selectedSKU != null && location != null) {
                                  _loadInventory();
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione ubicación origen';
                                }
                                return null;
                              },
                            ),

                            // Mostrar inventario actual
                            if (_currentInventory != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Stock disponible: ${_currentInventory!.availableQuantity} ${_selectedSKU!.uom}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de destino
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destino',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // To Location
                            DropdownButtonFormField<Location>(
                              value: _toLocation,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación destino',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              items: _locations.where((loc) => loc != _fromLocation).map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Text(location.toString()),
                                );
                              }).toList(),
                              onChanged: (location) {
                                setState(() => _toLocation = location);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Seleccione ubicación destino';
                                }
                                if (value == _fromLocation) {
                                  return 'Destino debe ser diferente al origen';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Quantity
                            QuantityInput(
                              controller: _quantityController,
                              label: 'Cantidad a mover',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la cantidad';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Cantidad debe ser mayor a 0';
                                }
                                if (_currentInventory != null && 
                                    qty > (_currentInventory!.availableQuantity ?? 0)) {
                                  return 'No hay suficiente stock disponible';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 2,
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

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canConfirm() ? _confirmMovement : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirmar Movimiento',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  bool _canConfirm() {
    return _selectedSKU != null &&
           _fromLocation != null &&
           _toLocation != null &&
           _quantityController.text.isNotEmpty &&
           _currentInventory != null &&
           _currentInventory!.hasAvailableStock;
  }

  Future<void> _scanSKU() async {
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
        
        setState(() {
          _selectedSKU = sku;
          _currentInventory = null;
        });

        if (_fromLocation != null) {
          _loadInventory();
        }

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Error en escaneo: $e');
    }
  }

  Future<void> _loadInventory() async {
    if (_selectedSKU == null || _fromLocation == null) return;

    try {
      final inventory = await _inventoryService.getInventoryByLocationAndSKU(
        _fromLocation!.code,
        _selectedSKU!.skuCode,
      );
      
      setState(() {
        _currentInventory = inventory;
      });
    } catch (e) {
      setState(() {
        _currentInventory = null;
      });
    }
  }

  Future<void> _confirmMovement() async {
    if (!_formKey.currentState!.validate() || !_canConfirm()) return;

    setState(() => _isLoading = true);

    try {
      final transaction = Transaction(
        type: TransactionType.MOVE,
        skuCode: _selectedSKU!.skuCode,
        quantity: int.parse(_quantityController.text),
        fromLocation: _fromLocation!.code,
        toLocation: _toLocation!.code,
        user: 'current_user', // TODO: Obtener del contexto
        timestamp: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final success = await _inventoryService.createTransaction(transaction);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearForm();
      }
    } catch (e) {
      _showError('Error registrando movimiento: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedSKU = null;
      _fromLocation = null;
      _toLocation = null;
      _currentInventory = null;
    });
    _quantityController.clear();
    _notesController.clear();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}