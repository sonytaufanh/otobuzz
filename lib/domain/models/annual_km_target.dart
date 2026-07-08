import 'package:equatable/equatable.dart';

class AnnualKmTarget extends Equatable {
  final String id;
  final String vehicleId;
  final int year;
  final double targetKm;
  final DateTime createdAt;

  const AnnualKmTarget({
    required this.id,
    required this.vehicleId,
    required this.year,
    required this.targetKm,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'year': year,
      'targetKm': targetKm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnnualKmTarget.fromMap(Map<String, dynamic> map) {
    return AnnualKmTarget(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      year: map['year'] as int,
      targetKm: (map['targetKm'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AnnualKmTarget copyWith({
    String? id,
    String? vehicleId,
    int? year,
    double? targetKm,
    DateTime? createdAt,
  }) {
    return AnnualKmTarget(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      year: year ?? this.year,
      targetKm: targetKm ?? this.targetKm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, year, targetKm, createdAt];
}
