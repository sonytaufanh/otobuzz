import 'package:equatable/equatable.dart';
import 'maintenance_type.dart';

class MaintenanceSchedule extends Equatable {
  final String id;
  final String vehicleId;
  final MaintenanceType type;
  final double dueAtKm;
  final DateTime dueByDate;
  final double remainingKm;
  final int remainingDays;
  final bool isOverdue;
  final DateTime? estimatedDueDate;

  const MaintenanceSchedule({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.dueAtKm,
    required this.dueByDate,
    required this.remainingKm,
    required this.remainingDays,
    required this.isOverdue,
    this.estimatedDueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.index,
      'dueAtKm': dueAtKm,
      'dueByDate': dueByDate.toIso8601String(),
      'remainingKm': remainingKm,
      'remainingDays': remainingDays,
      'isOverdue': isOverdue ? 1 : 0,
      'estimatedDueDate': estimatedDueDate?.toIso8601String(),
    };
  }

  factory MaintenanceSchedule.fromMap(Map<String, dynamic> map) {
    return MaintenanceSchedule(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      type: MaintenanceType.values[map['type'] as int],
      dueAtKm: (map['dueAtKm'] as num).toDouble(),
      dueByDate: DateTime.parse(map['dueByDate'] as String),
      remainingKm: (map['remainingKm'] as num).toDouble(),
      remainingDays: map['remainingDays'] as int,
      isOverdue: (map['isOverdue'] as int) == 1,
      estimatedDueDate: map['estimatedDueDate'] != null
          ? DateTime.parse(map['estimatedDueDate'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        type,
        dueAtKm,
        dueByDate,
        remainingKm,
        remainingDays,
        isOverdue,
        estimatedDueDate,
      ];
}
