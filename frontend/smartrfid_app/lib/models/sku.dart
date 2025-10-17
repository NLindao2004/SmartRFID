class SKU {
  final String code; // ✅ CAMBIADO: de skuCode a code
  final String description;
  final String uom; // Unit of measure (PCS, KG, LT, etc.)
  final String? category;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SKU({
    required this.code, // ✅ CAMBIADO
    required this.description, 
    required this.uom,
    this.category,
    this.isActive = true,
    this.createdAt,
    this.updatedAt, required String skuCode,
  });

  // ✅ AGREGADO: Getter para compatibilidad con código existente
  String get skuCode => code;

  factory SKU.fromJson(Map<String, dynamic> json) {
    return SKU(
      code: json['sku_code'] ?? json['code'] ?? '', // ✅ CAMBIADO: acepta ambos
      description: json['description'] ?? '',
      uom: json['uom'] ?? 'PCS',
      category: json['category'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null, skuCode: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku_code': code, // ✅ CAMBIADO: envía como sku_code para backend
      'code': code, // También incluye code
      'description': description,
      'uom': uom,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ✅ AGREGADO: Método copyWith
  SKU copyWith({
    String? code,
    String? description,
    String? uom,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SKU(
      code: code ?? this.code,
      description: description ?? this.description,
      uom: uom ?? this.uom,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, skuCode: '',
    );
  }

  @override
  String toString() {
    return '$code - $description ($uom)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SKU && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}