class DriverAssignment {
  final String id;
  final String vehicleId;
  final String driverId;
  final DateTime date;
  final String? notes;

  const DriverAssignment({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'date': _dateToString(date),
      'notes': notes,
    };
  }

  factory DriverAssignment.fromMap(Map<String, dynamic> map) {
    return DriverAssignment(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      driverId: map['driverId'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }

  DriverAssignment copyWith({
    String? id,
    String? vehicleId,
    String? driverId,
    DateTime? date,
    String? notes,
  }) {
    return DriverAssignment(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  /// Formats date as yyyy-MM-dd for storage
  static String _dateToString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
