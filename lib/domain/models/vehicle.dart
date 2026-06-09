import 'package:equatable/equatable.dart';
import 'vehicle_type.dart';

class Vehicle extends Equatable {
  final String id;
  final String name;
  final VehicleType type;
  final String plateNumber;
  final int year;
  final double totalMileageKm;
  final DateTime createdAt;

  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.plateNumber,
    required this.year,
    required this.totalMileageKm,
    required this.createdAt,
  });

  Vehicle copyWith({
    String? id,
    String? name,
    VehicleType? type,
    String? plateNumber,
    int? year,
    double? totalMileageKm,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      plateNumber: plateNumber ?? this.plateNumber,
      year: year ?? this.year,
      totalMileageKm: totalMileageKm ?? this.totalMileageKm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'plateNumber': plateNumber,
      'year': year,
      'totalMileageKm': totalMileageKm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      name: map['name'] as String,
      type: VehicleType.values[map['type'] as int],
      plateNumber: map['plateNumber'] as String,
      year: map['year'] as int,
      totalMileageKm: (map['totalMileageKm'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, type, plateNumber, year, totalMileageKm, createdAt];
}
