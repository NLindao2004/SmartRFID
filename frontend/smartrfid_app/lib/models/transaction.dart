enum TransactionType { 
  IN,     // Entrada/Recepción
  MOVE,   // Movimiento interno
  OUT,    // Salida/Despacho
  COUNT,  // Conteo/Ajuste
  ADJUST  // Ajuste manual
}

class Transaction {
  final String? id;
  final TransactionType type;
  final String skuCode;
  final int quantity;
  final String? fromLocation;
  final String? toLocation;
  final String user;
  final DateTime timestamp;
  final String? epc; // Para RFID
  final String? lot; // Lote/Batch
  final String? notes;
  final String? referenceDocument; // Orden, factura, etc.
  final bool isSynced; // Para control offline
  final DateTime? createdAt;

  Transaction({
    this.id,
    required this.type,
    required this.skuCode,
    required this.quantity,
    this.fromLocation,
    this.toLocation,
    required this.user,
    required this.timestamp,
    this.epc,
    this.lot,
    this.notes,
    this.referenceDocument,
    this.isSynced = false,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.ADJUST,
      ),
      skuCode: json['sku_code'],
      quantity: json['quantity'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      user: json['user'],
      timestamp: DateTime.parse(json['timestamp']),
      epc: json['epc'],
      lot: json['lot'],
      notes: json['notes'],
      referenceDocument: json['reference_document'],
      isSynced: json['is_synced'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'sku_code': skuCode,
      'quantity': quantity,
      'from_location': fromLocation,
      'to_location': toLocation,
      'user': user,
      'timestamp': timestamp.toIso8601String(),
      'epc': epc,
      'lot': lot,
      'notes': notes,
      'reference_document': referenceDocument,
      'is_synced': isSynced,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.IN:
        return 'Entrada';
      case TransactionType.MOVE:
        return 'Movimiento';
      case TransactionType.OUT:
        return 'Salida';
      case TransactionType.COUNT:
        return 'Conteo';
      case TransactionType.ADJUST:
        return 'Ajuste';
    }
  }

  String get locationInfo {
    if (type == TransactionType.IN) {
      return 'Hacia: ${toLocation ?? 'N/A'}';
    } else if (type == TransactionType.OUT) {
      return 'Desde: ${fromLocation ?? 'N/A'}';
    } else if (type == TransactionType.MOVE) {
      return '${fromLocation ?? 'N/A'} → ${toLocation ?? 'N/A'}';
    }
    return toLocation ?? fromLocation ?? 'N/A';
  }

  @override
  String toString() {
    return '$typeDisplayName: $skuCode ($quantity) - $locationInfo';
  }
}