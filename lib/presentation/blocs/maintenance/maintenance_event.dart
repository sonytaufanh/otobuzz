import 'package:equatable/equatable.dart';
import '../../../domain/models/maintenance_type.dart';

abstract class MaintenanceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSchedules extends MaintenanceEvent {
  final String vehicleId;
  LoadSchedules(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class RecordMaintenance extends MaintenanceEvent {
  final String vehicleId;
  final MaintenanceType type;
  final double mileageAtService;
  final DateTime serviceDate;
  final double? cost;
  final String? notes;
  final String? workshopName;

  RecordMaintenance({
    required this.vehicleId,
    required this.type,
    required this.mileageAtService,
    required this.serviceDate,
    this.cost,
    this.notes,
    this.workshopName,
  });

  @override
  List<Object?> get props =>
      [vehicleId, type, mileageAtService, serviceDate, cost, notes, workshopName];
}

class LoadMaintenanceHistory extends MaintenanceEvent {
  final String vehicleId;
  final MaintenanceType? filterType;

  LoadMaintenanceHistory({required this.vehicleId, this.filterType});

  @override
  List<Object?> get props => [vehicleId, filterType];
}
