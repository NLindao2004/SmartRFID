class Location {
  final String code;
  final String area;
  final String? zone;
  final String? description;
  final bool isActive;
  final int? capacity; // Capacidad máxima
  final String? locationType; // RACK, FLOOR, DOCK, etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Location({
    required this.code,
    required this.area,
    this.zone,
    this.description,
    this.isActive = true,
    this.capacity,
    this.locationType,
    this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      code: json['code'],
      area: json['area'],
      zone: json['zone'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      capacity: json['capacity'],
      locationType: json['location_type'],
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
      'code': code,
      'area': area,
      'zone': zone,
      'description': description,
      'is_active': isActive,
      'capacity': capacity,
      'location_type': locationType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullLocation {
    return zone != null ? '$area-$zone-$code' : '$area-$code';
  }

  @override
  String toString() {
    return '$code ($area)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}