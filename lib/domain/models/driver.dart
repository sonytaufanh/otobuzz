class Driver {
  final String id;
  final String name;
  final String? phone;
  final String? licenseNumber;
  final String? notes;
  final DateTime createdAt;

  const Driver({
    required this.id,
    required this.name,
    this.phone,
    this.licenseNumber,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? licenseNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
