enum CountStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class CountItem {
  final String skuCode;
  final int systemQuantity; // Cantidad del sistema
  final int countedQuantity; // Cantidad contada
  final int discrepancy; // Diferencia
  final String? lot;
  final String? notes;

  CountItem({
    required this.skuCode,
    required this.systemQuantity,
    required this.countedQuantity,
    this.lot,
    this.notes,
  }) : discrepancy = countedQuantity - systemQuantity;

  factory CountItem.fromJson(Map<String, dynamic> json) {
    return CountItem(
      skuCode: json['sku_code'] ?? json['skuCode'] ?? '',
      systemQuantity: json['system_quantity'] ?? json['systemQuantity'] ?? 0,
      countedQuantity: json['counted_quantity'] ?? json['countedQuantity'] ?? 0,
      lot: json['lot'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku_code': skuCode,
      'system_quantity': systemQuantity,
      'counted_quantity': countedQuantity,
      'discrepancy': discrepancy,
      'lot': lot,
      'notes': notes,
    };
  }

  CountItem copyWith({
    String? skuCode,
    int? systemQuantity,
    int? countedQuantity,
    String? lot,
    String? notes,
  }) {
    return CountItem(
      skuCode: skuCode ?? this.skuCode,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      lot: lot ?? this.lot,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'CountItem(skuCode: $skuCode, system: $systemQuantity, counted: $countedQuantity, discrepancy: $discrepancy)';
  }
}

class Count {
  final String? id;
  final String locationCode;
  final String userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final CountStatus status;
  final List<CountItem> items; // ✅ AGREGADO: Lista de items contados
  final String? notes;
  final int totalItemsCounted;
  final int totalDiscrepancies;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Count({
    this.id,
    required this.locationCode,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    this.status = CountStatus.pending,
    required this.items, // ✅ AGREGADO: requerido
    this.notes,
    int? totalItemsCounted,
    int? totalDiscrepancies,
    this.createdAt,
    this.updatedAt,
  })  : totalItemsCounted = totalItemsCounted ?? items.length,
        totalDiscrepancies = totalDiscrepancies ?? 
            items.where((item) => item.discrepancy != 0).length;

  // Getters calculados
  int get itemsWithDiscrepancies => 
      items.where((item) => item.discrepancy != 0).length;
  
  int get totalPositiveDiscrepancy => 
      items.where((item) => item.discrepancy > 0)
           .fold(0, (sum, item) => sum + item.discrepancy);
  
  int get totalNegativeDiscrepancy => 
      items.where((item) => item.discrepancy < 0)
           .fold(0, (sum, item) => sum + item.discrepancy.abs());

  bool get hasDiscrepancies => itemsWithDiscrepancies > 0;

  bool get isCompleted => status == CountStatus.completed;

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(
      id: json['id']?.toString(),
      locationCode: json['location_code'] ?? json['locationCode'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      status: _parseStatus(json['status']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CountItem.fromJson(item as Map<String, dynamic>))
              .toList() ?? 
          [], // ✅ AGREGADO: parsear lista de items
      notes: json['notes'],
      totalItemsCounted: json['total_items_counted'] ?? json['totalItemsCounted'],
      totalDiscrepancies: json['total_discrepancies'] ?? json['totalDiscrepancies'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_code': locationCode,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.name,
      'items': items.map((item) => item.toJson()).toList(), // ✅ AGREGADO
      'notes': notes,
      'total_items_counted': totalItemsCounted,
      'total_discrepancies': totalDiscrepancies,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static CountStatus _parseStatus(dynamic status) {
    if (status == null) return CountStatus.pending;
    
    try {
      return CountStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toString().toLowerCase(),
      );
    } catch (e) {
      return CountStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CountStatus.pending:
        return 'Pendiente';
      case CountStatus.inProgress:
        return 'En Progreso';
      case CountStatus.completed:
        return 'Completado';
      case CountStatus.cancelled:
        return 'Cancelado';
    }
  }

  Count copyWith({
    String? id,
    String? locationCode,
    String? userId,
    DateTime? startedAt,
    DateTime? completedAt,
    CountStatus? status,
    List<CountItem>? items,
    String? notes,
    int? totalItemsCounted,
    int? totalDiscrepancies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Count(
      id: id ?? this.id,
      locationCode: locationCode ?? this.locationCode,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      totalItemsCounted: totalItemsCounted ?? this.totalItemsCounted,
      totalDiscrepancies: totalDiscrepancies ?? this.totalDiscrepancies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Count(id: $id, location: $locationCode, status: ${statusDisplayName}, items: ${items.length}, discrepancies: $itemsWithDiscrepancies)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Count && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}