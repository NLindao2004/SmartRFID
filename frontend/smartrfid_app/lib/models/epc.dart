enum EPCStatus {
  active,
  inactive,
  commissioned,
  lost,
  damaged
}

class EPC {
  final String? id; // ✅ AGREGADO: ID opcional para base de datos
  final String epc;
  final String? skuCode;
  final String? lot;
  final int? quantity;
  final String? lastLocationCode;
  final DateTime? lastSeenAt;
  final EPCStatus status;
  final DateTime? commissionedAt;
  final String? commissionedBy;
  final int? rssi; // Señal RFID
  final String? antennaId; // ID de antena que lo leyó
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive; // ✅ AGREGADO: para compatibilidad con inventory_provider

  EPC({
    this.id, // ✅ AGREGADO
    required this.epc,
    this.skuCode,
    this.lot,
    this.quantity,
    this.lastLocationCode,
    this.lastSeenAt,
    this.status = EPCStatus.active,
    this.commissionedAt,
    this.commissionedBy,
    this.rssi,
    this.antennaId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isActive = true, // ✅ AGREGADO: por defecto true
  });

  factory EPC.fromJson(Map<String, dynamic> json) {
    return EPC(
      id: json['id']?.toString(), // ✅ AGREGADO
      epc: json['epc'] ?? '',
      skuCode: json['sku_code'],
      lot: json['lot'],
      quantity: json['quantity'],
      lastLocationCode: json['last_location_code'],
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at']) 
          : null,
      status: _parseStatus(json['status']),
      commissionedAt: json['commissioned_at'] != null 
          ? DateTime.parse(json['commissioned_at']) 
          : null,
      commissionedBy: json['commissioned_by'],
      rssi: json['rssi'],
      antennaId: json['antenna_id'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true, // ✅ AGREGADO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // ✅ AGREGADO
      'epc': epc,
      'sku_code': skuCode,
      'lot': lot,
      'quantity': quantity,
      'last_location_code': lastLocationCode,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'status': status.name,
      'commissioned_at': commissionedAt?.toIso8601String(),
      'commissioned_by': commissionedBy,
      'rssi': rssi,
      'antenna_id': antennaId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive, // ✅ AGREGADO
    };
  }

  // ✅ AGREGADO: Helper para parsear status
  static EPCStatus _parseStatus(dynamic status) {
    if (status == null) return EPCStatus.active;
    
    try {
      return EPCStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toString().toLowerCase(),
      );
    } catch (e) {
      return EPCStatus.active;
    }
  }

  bool get isCommissioned => skuCode != null && commissionedAt != null;
  
  String get statusDisplayName {
    switch (status) {
      case EPCStatus.active:
        return 'Activo';
      case EPCStatus.inactive:
        return 'Inactivo';
      case EPCStatus.commissioned:
        return 'Comisionado';
      case EPCStatus.lost:
        return 'Perdido';
      case EPCStatus.damaged:
        return 'Dañado';
    }
  }

  // ✅ AGREGADO: Método copyWith para inmutabilidad
  EPC copyWith({
    String? id,
    String? epc,
    String? skuCode,
    String? lot,
    int? quantity,
    String? lastLocationCode,
    DateTime? lastSeenAt,
    EPCStatus? status,
    DateTime? commissionedAt,
    String? commissionedBy,
    int? rssi,
    String? antennaId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return EPC(
      id: id ?? this.id,
      epc: epc ?? this.epc,
      skuCode: skuCode ?? this.skuCode,
      lot: lot ?? this.lot,
      quantity: quantity ?? this.quantity,
      lastLocationCode: lastLocationCode ?? this.lastLocationCode,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
      commissionedAt: commissionedAt ?? this.commissionedAt,
      commissionedBy: commissionedBy ?? this.commissionedBy,
      rssi: rssi ?? this.rssi,
      antennaId: antennaId ?? this.antennaId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return isCommissioned 
        ? '$epc ($skuCode - ${quantity ?? 0} unidades)'
        : '$epc (No comisionado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EPC && other.epc == epc;
  }

  @override
  int get hashCode => epc.hashCode;
}