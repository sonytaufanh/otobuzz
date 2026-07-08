import 'package:equatable/equatable.dart';
import '../../../domain/models/maintenance_record.dart';
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
  final int? workshopRating;
  final String? workshopReview;

  RecordMaintenance({
    required this.vehicleId,
    required this.type,
    required this.mileageAtService,
    required this.serviceDate,
    this.cost,
    this.notes,
    this.workshopName,
    this.workshopRating,
    this.workshopReview,
  });

  @override
  List<Object?> get props =>
      [vehicleId, type, mileageAtService, serviceDate, cost, notes, workshopName, workshopRating, workshopReview];
}

class LoadMaintenanceHistory extends MaintenanceEvent {
  final String vehicleId;
  final MaintenanceType? filterType;

  LoadMaintenanceHistory({required this.vehicleId, this.filterType});

  @override
  List<Object?> get props => [vehicleId, filterType];
}

class UpdateMaintenanceRecord extends MaintenanceEvent {
  final MaintenanceRecord record;

  UpdateMaintenanceRecord(this.record);

  @override
  List<Object?> get props => [record];
}
