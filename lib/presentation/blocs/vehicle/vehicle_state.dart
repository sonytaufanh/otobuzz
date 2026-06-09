import 'package:equatable/equatable.dart';
import '../../../domain/models/maintenance_schedule.dart';
import '../../../domain/models/vehicle.dart';

abstract class VehicleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {}

class VehicleLoaded extends VehicleState {
  final List<Vehicle> vehicles;

  /// Maintenance schedules per vehicle (vehicleId -> list of schedules)
  final Map<String, List<MaintenanceSchedule>> vehicleSchedules;

  /// Expired document count across all vehicles
  final int expiredDocumentCount;

  /// Expiring soon (within 30 days) document count across all vehicles
  final int expiringSoonDocumentCount;

  VehicleLoaded(
    this.vehicles, {
    this.vehicleSchedules = const {},
    this.expiredDocumentCount = 0,
    this.expiringSoonDocumentCount = 0,
  });

  /// Number of vehicles with at least one overdue schedule
  int get overdueCount => vehicles.where((v) {
        final schedules = vehicleSchedules[v.id] ?? [];
        return schedules.any((s) => s.isOverdue);
      }).length;

  /// Number of vehicles with upcoming maintenance within warning threshold
  /// (not overdue, but remainingKm <= warningBeforeKm or remainingDays <= warningBeforeDays)
  int get upcomingCount => vehicles.where((v) {
        final schedules = vehicleSchedules[v.id] ?? [];
        // Has at least one schedule in warning zone but not overdue
        final hasOverdue = schedules.any((s) => s.isOverdue);
        if (hasOverdue) return false;
        return schedules.any((s) => !s.isOverdue && s.remainingDays <= 30);
      }).length;

  /// Get the most urgent schedule for a vehicle
  MaintenanceSchedule? getMostUrgentSchedule(String vehicleId) {
    final schedules = vehicleSchedules[vehicleId];
    if (schedules == null || schedules.isEmpty) return null;
    return schedules.first; // Already sorted by urgency from repository
  }

  @override
  List<Object?> get props => [vehicles, vehicleSchedules, expiredDocumentCount, expiringSoonDocumentCount];
}

class VehicleError extends VehicleState {
  final String message;
  VehicleError(this.message);

  @override
  List<Object?> get props => [message];
}

class VehicleOperationSuccess extends VehicleState {
  final String message;
  VehicleOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
