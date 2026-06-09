import 'maintenance_type.dart';

class CustomInterval {
  final String id;
  final String vehicleId;
  final MaintenanceType type;
  final double kmInterval;
  final int monthsInterval;
  final double warningBeforeKm;
  final int warningBeforeDays;

  const CustomInterval({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.kmInterval,
    required this.monthsInterval,
    required this.warningBeforeKm,
    required this.warningBeforeDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.index,
      'kmInterval': kmInterval,
      'monthsInterval': monthsInterval,
      'warningBeforeKm': warningBeforeKm,
      'warningBeforeDays': warningBeforeDays,
    };
  }

  factory CustomInterval.fromMap(Map<String, dynamic> map) {
    return CustomInterval(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      type: MaintenanceType.values[map['type'] as int],
      kmInterval: (map['kmInterval'] as num).toDouble(),
      monthsInterval: map['monthsInterval'] as int,
      warningBeforeKm: (map['warningBeforeKm'] as num).toDouble(),
      warningBeforeDays: map['warningBeforeDays'] as int,
    );
  }

  CustomInterval copyWith({
    String? id,
    String? vehicleId,
    MaintenanceType? type,
    double? kmInterval,
    int? monthsInterval,
    double? warningBeforeKm,
    int? warningBeforeDays,
  }) {
    return CustomInterval(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      kmInterval: kmInterval ?? this.kmInterval,
      monthsInterval: monthsInterval ?? this.monthsInterval,
      warningBeforeKm: warningBeforeKm ?? this.warningBeforeKm,
      warningBeforeDays: warningBeforeDays ?? this.warningBeforeDays,
    );
  }
}
