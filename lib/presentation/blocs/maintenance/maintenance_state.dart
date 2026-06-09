import 'package:equatable/equatable.dart';
import '../../../domain/models/maintenance_record.dart';
import '../../../domain/models/maintenance_schedule.dart';

abstract class MaintenanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}

class MaintenanceLoading extends MaintenanceState {}

class MaintenanceSchedulesLoaded extends MaintenanceState {
  final List<MaintenanceSchedule> schedules;
  MaintenanceSchedulesLoaded(this.schedules);

  @override
  List<Object?> get props => [schedules];
}

class MaintenanceHistoryLoaded extends MaintenanceState {
  final List<MaintenanceRecord> records;
  final double totalCost;

  MaintenanceHistoryLoaded({required this.records, required this.totalCost});

  @override
  List<Object?> get props => [records, totalCost];
}

class MaintenanceRecorded extends MaintenanceState {
  final String message;
  MaintenanceRecorded(this.message);

  @override
  List<Object?> get props => [message];
}

class MaintenanceError extends MaintenanceState {
  final String message;
  MaintenanceError(this.message);

  @override
  List<Object?> get props => [message];
}
