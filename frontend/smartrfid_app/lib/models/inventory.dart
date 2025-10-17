class Inventory {
  final String id;
  final String skuCode;
  final String locationCode;
  final int quantity;
  final int reservedQuantity;
  final DateTime lastUpdated;
  final String? lot;
  final DateTime? expiryDate;
  final Map<String, dynamic>? metadata;

  Inventory({
    required this.id,
    required this.skuCode,
    required this.locationCode,
    required this.quantity,
    required this.reservedQuantity,
    required this.lastUpdated,
    this.lot,
    this.expiryDate,
    this.metadata,
  });

  // Cantidad disponible (total - reservado)
  int get availableQuantity => quantity - reservedQuantity;

  // ✅ AGREGADO: Verificar si hay stock disponible
  bool get hasAvailableStock => availableQuantity > 0;

  // ✅ AGREGADO: Verificar si hay stock suficiente
  bool hasEnoughStock(int requiredQuantity) {
    return availableQuantity >= requiredQuantity;
  }

  // ✅ AGREGADO: Método copyWith
  Inventory copyWith({
    String? id,
    String? skuCode,
    String? locationCode,
    int? quantity,
    int? reservedQuantity,
    DateTime? lastUpdated,
    String? lot,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
  }) {
    return Inventory(
      id: id ?? this.id,
      skuCode: skuCode ?? this.skuCode,
      locationCode: locationCode ?? this.locationCode,
      quantity: quantity ?? this.quantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lot: lot ?? this.lot,
      expiryDate: expiryDate ?? this.expiryDate,
      metadata: metadata ?? this.metadata,
    );
  }

  // Serialización
  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'].toString(),
      skuCode: json['sku_code'] ?? json['skuCode'] ?? '',
      locationCode: json['location_code'] ?? json['locationCode'] ?? '',
      quantity: json['quantity'] ?? 0,
      reservedQuantity: json['reserved_quantity'] ?? json['reservedQuantity'] ?? 0,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
      lot: json['lot'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku_code': skuCode,
      'location_code': locationCode,
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      'last_updated': lastUpdated.toIso8601String(),
      'lot': lot,
      'expiry_date': expiryDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'Inventory(id: $id, skuCode: $skuCode, locationCode: $locationCode, quantity: $quantity, available: $availableQuantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Inventory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}