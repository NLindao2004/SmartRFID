import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/sku.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../adapters/barcode_adapter.dart';
import '../adapters/rfid_adapter.dart';
import '../widgets/scan_button.dart';
import '../widgets/quantity_input.dart';

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();
  
  final _inventoryService = InventoryService();
  final _barcodeAdapter = CameraBarcodeAdapter();
  final _rfidAdapter = PortableRFIDAdapter();
  
  SKU? _selectedSKU;
  Location? _selectedLocation;
  List<SKU> _skus = [];
  List<Location> _locations = [];
  bool _isLoading = false;
  bool _useRFID = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
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
        title: const Text('Recepción'),
        backgroundColor: Colors.green.shade100,
        actions: [
          Switch(
            value: _useRFID,
            onChanged: (value) => setState(() => _useRFID = value),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.nfc),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Card principal de recepción
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar Recepción',
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
                                  icon: _useRFID ? Icons.nfc : Icons.qr_code_scanner,
                                  label: 'Escanear',
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),

                            // Location Selection
                            DropdownButtonFormField<Location>(
                              value: _selectedLocation,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación de destino',
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
                                setState(() => _selectedLocation = location);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor seleccione una ubicación';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Quantity Input
                            QuantityInput(
                              controller: _quantityController,
                              label: 'Cantidad recibida',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la cantidad';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty <= 0) {
                                  return 'Cantidad debe ser mayor a 0';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Reference Document
                            TextFormField(
                              controller: _referenceController,
                              decoration: const InputDecoration(
                                labelText: 'Documento de referencia (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt),
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

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canConfirm() ? _confirmReception : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Confirmar Recepción',
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
           _selectedLocation != null &&
           _quantityController.text.isNotEmpty;
  }

  Future<void> _scanSKU() async {
    try {
      String? result;
      
      if (_useRFID) {
        final tags = await _rfidAdapter.scanRFIDTags();
        if (tags.isNotEmpty) {
          result = tags.first; // Por simplicidad, tomar el primer tag
          // TODO: Buscar SKU asociado al EPC
        }
      } else {
        result = await _barcodeAdapter.scanBarcode();
      }

      if (result != null) {
        final sku = _skus.firstWhere(
          (s) => s.skuCode == result,
          orElse: () => SKU(
            skuCode: result!,
            description: 'SKU Escaneado',
            uom: 'PCS', code: '',
          ),
        );
        
        setState(() {
          _selectedSKU = sku;
        });

        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Error en escaneo: $e');
    }
  }

  Future<void> _confirmReception() async {
    if (!_formKey.currentState!.validate() || !_canConfirm()) return;

    setState(() => _isLoading = true);

    try {
      final transaction = Transaction(
        type: TransactionType.IN,
        skuCode: _selectedSKU!.skuCode,
        quantity: int.parse(_quantityController.text),
        toLocation: _selectedLocation!.code,
        user: 'current_user', // TODO: Obtener del contexto
        timestamp: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        referenceDocument: _referenceController.text.isNotEmpty 
            ? _referenceController.text 
            : null,
      );

      final success = await _inventoryService.createTransaction(transaction);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearForm();
      }
    } catch (e) {
      _showError('Error registrando recepción: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedSKU = null;
      _selectedLocation = null;
    });
    _quantityController.clear();
    _notesController.clear();
    _referenceController.clear();
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
}