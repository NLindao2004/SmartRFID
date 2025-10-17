import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/sku.dart';
import '../models/location.dart';

class InventoryCard extends StatelessWidget {
  final Inventory inventory;
  final SKU? sku;
  final Location? location;
  final VoidCallback? onTap;
  final bool showLocation;
  final bool showSKU;
  final bool showActions;
  final List<Widget>? actions;
  final int? minStockLevel; // ✅ AGREGADO: Para determinar stock bajo

  const InventoryCard({
    super.key,
    required this.inventory,
    this.sku,
    this.location,
    this.onTap,
    this.showLocation = true,
    this.showSKU = true,
    this.showActions = false,
    this.actions,
    this.minStockLevel, // ✅ AGREGADO
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con SKU y estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showSKU) ...[
                          Text(
                            inventory.skuCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sku?.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              sku!.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                        
                        if (showLocation && location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${location!.code} - ${location!.area}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  _buildStatusIndicator(),
                ],
              ),

              const SizedBox(height: 12),

              // Información de cantidades
              _buildQuantityInfo(context),

              // Información adicional
              if (inventory.lot != null || 
                  inventory.expiryDate != null) ...[
                const SizedBox(height: 12),
                _buildAdditionalInfo(context),
              ],

              // Acciones personalizadas
              if (showActions && actions != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ CORREGIDO: Eliminar referencia a isLowStock y usar minStockLevel
  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (inventory.hasAvailableStock) {
      // ✅ CORREGIDO: Verificar stock bajo usando minStockLevel si está disponible
      final isLowStock = minStockLevel != null && 
                         inventory.availableQuantity <= minStockLevel!;
      
      if (isLowStock) {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Stock Bajo';
      } else {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Disponible';
      }
    } else if (inventory.quantity > 0) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'Reservado';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle;
      statusText = 'Sin Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Cantidad total
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Total: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                '${inventory.quantity} ${sku?.uom ?? 'PCS'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // ✅ CORREGIDO: availableQuantity siempre existe (es un getter)
          // Cantidad disponible si es diferente del total
          if (inventory.availableQuantity != inventory.quantity) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Disponible: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${inventory.availableQuantity} ${sku?.uom ?? 'PCS'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],

          // ✅ CORREGIDO: reservedQuantity siempre existe
          // Cantidad reservada si existe
          if (inventory.reservedQuantity > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Reservado: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${inventory.reservedQuantity} ${sku?.uom ?? 'PCS'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lote
        if (inventory.lot != null)
          _buildInfoRow(
            Icons.batch_prediction,
            'Lote',
            inventory.lot!,
            Colors.blue,
          ),

        // Fecha de vencimiento
        if (inventory.expiryDate != null) ...[
          if (inventory.lot != null) const SizedBox(height: 4),
          _buildInfoRow(
            Icons.schedule,
            'Vence',
            _formatDate(inventory.expiryDate!),
            _getExpiryColor(),
          ),
        ],

        // ✅ CORREGIDO: lastUpdated siempre existe
        // Última actualización
        if (inventory.lot != null || inventory.expiryDate != null) 
          const SizedBox(height: 4),
        _buildInfoRow(
          Icons.update,
          'Actualizado',
          _formatDateTime(inventory.lastUpdated),
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ ELIMINADO: _buildEPCInfo porque el modelo no tiene epcs

  Color _getExpiryColor() {
    if (inventory.expiryDate == null) return Colors.grey;
    
    final daysToExpiry = inventory.expiryDate!.difference(DateTime.now()).inDays;
    
    if (daysToExpiry <= 7) return Colors.red;
    if (daysToExpiry <= 30) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Variante compacta para listas densas
class CompactInventoryCard extends StatelessWidget {
  final Inventory inventory;
  final SKU? sku;
  final Location? location;
  final VoidCallback? onTap;

  const CompactInventoryCard({
    super.key,
    required this.inventory,
    this.sku,
    this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: inventory.hasAvailableStock 
              ? Colors.green.shade100 
              : Colors.grey.shade200,
          child: Icon(
            Icons.inventory_2,
            size: 20,
            color: inventory.hasAvailableStock ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          inventory.skuCode,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          location?.code ?? 'Sin ubicación',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${inventory.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              sku?.uom ?? 'PCS',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar una lista de inventarios
class InventoryList extends StatelessWidget {
  final List<Inventory> inventories;
  final List<SKU> skus;
  final List<Location> locations;
  final Function(Inventory)? onTap;
  final bool compact;
  final bool showActions;
  final int? minStockLevel; // ✅ AGREGADO

  const InventoryList({
    super.key,
    required this.inventories,
    required this.skus,
    required this.locations,
    this.onTap,
    this.compact = false,
    this.showActions = false,
    this.minStockLevel, // ✅ AGREGADO
  });

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron registros de inventario',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: inventories.length,
      itemBuilder: (context, index) {
        final inventory = inventories[index];
        // ✅ CORREGIDO: usar .code en lugar de .skuCode
        final sku = skus.firstWhere(
          (s) => s.code == inventory.skuCode,
          orElse: () => SKU(
            code: inventory.skuCode, // ✅ CORREGIDO
            description: 'SKU no encontrado',
            uom: 'PCS', skuCode: '',
          ),
        );
        final location = locations.firstWhere(
          (l) => l.code == inventory.locationCode,
          orElse: () => Location(
            code: inventory.locationCode,
            area: 'Área desconocida',
          ),
        );

        if (compact) {
          return CompactInventoryCard(
            inventory: inventory,
            sku: sku,
            location: location,
            onTap: () => onTap?.call(inventory),
          );
        }

        return InventoryCard(
          inventory: inventory,
          sku: sku,
          location: location,
          onTap: () => onTap?.call(inventory),
          showActions: showActions,
          minStockLevel: minStockLevel, // ✅ AGREGADO
        );
      },
    );
  }
}