part of 'trouble_log_bloc.dart';

abstract class TroubleLogEvent extends Equatable {
  const TroubleLogEvent();
  @override
  List<Object?> get props => [];
}

class LoadTroubleLogs extends TroubleLogEvent {
  final String vehicleId;
  const LoadTroubleLogs(this.vehicleId);
  @override
  List<Object?> get props => [vehicleId];
}

class LoadUnresolvedLogs extends TroubleLogEvent {
  final String vehicleId;
  const LoadUnresolvedLogs(this.vehicleId);
  @override
  List<Object?> get props => [vehicleId];
}

class AddTroubleLog extends TroubleLogEvent {
  final TroubleLog log;
  const AddTroubleLog(this.log);
  @override
  List<Object?> get props => [log];
}

class UpdateTroubleLog extends TroubleLogEvent {
  final TroubleLog log;
  const UpdateTroubleLog(this.log);
  @override
  List<Object?> get props => [log];
}

class DeleteTroubleLog extends TroubleLogEvent {
  final String id;
  final String vehicleId;
  const DeleteTroubleLog(this.id, this.vehicleId);
  @override
  List<Object?> get props => [id, vehicleId];
}

class MarkTroubleLogResolved extends TroubleLogEvent {
  final String id;
  final String vehicleId;
  final DateTime resolvedDate;
  final String? resolutionNotes;
  final String? maintenanceRecordId;
  const MarkTroubleLogResolved({
    required this.id,
    required this.vehicleId,
    required this.resolvedDate,
    this.resolutionNotes,
    this.maintenanceRecordId,
  });
  @override
  List<Object?> get props => [id, vehicleId, resolvedDate, resolutionNotes, maintenanceRecordId];
}
