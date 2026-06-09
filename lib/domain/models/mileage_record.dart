import 'package:equatable/equatable.dart';

class MileageRecord extends Equatable {
  final String id;
  final String vehicleId;
  final double km;
  final DateTime date;
  final String? notes;

  const MileageRecord({
    required this.id,
    required this.vehicleId,
    required this.km,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'km': km,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory MileageRecord.fromMap(Map<String, dynamic> map) {
    return MileageRecord(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      km: (map['km'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, km, date, notes];
}
