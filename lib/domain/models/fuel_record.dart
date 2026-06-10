import 'package:equatable/equatable.dart';

class FuelRecord extends Equatable {
  final String id;
  final String vehicleId;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final double odometerKm;
  final DateTime date;
  final String? stationName;
  final String? fuelType;
  final bool isFullTank;
  final String? notes;

  const FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.odometerKm,
    required this.date,
    this.stationName,
    this.fuelType,
    this.isFullTank = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'odometerKm': odometerKm,
      'date': date.toIso8601String(),
      'stationName': stationName,
      'fuelType': fuelType,
      'isFullTank': isFullTank ? 1 : 0,
      'notes': notes,
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      odometerKm: (map['odometerKm'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      stationName: map['stationName'] as String?,
      fuelType: map['fuelType'] as String?,
      isFullTank: (map['isFullTank'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        liters,
        pricePerLiter,
        totalCost,
        odometerKm,
        date,
        stationName,
        fuelType,
        isFullTank,
        notes,
      ];
}
