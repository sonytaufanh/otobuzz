import 'package:equatable/equatable.dart';
import '../../../domain/models/mileage_record.dart';
import '../../../domain/models/vehicle.dart';

abstract class MileageState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MileageInitial extends MileageState {}

class MileageLoading extends MileageState {}

class MileageAdded extends MileageState {
  final Vehicle updatedVehicle;
  MileageAdded(this.updatedVehicle);

  @override
  List<Object?> get props => [updatedVehicle];
}

class MileageHistoryLoaded extends MileageState {
  final List<MileageRecord> records;
  final double totalKm;
  final double avgDailyKm;

  MileageHistoryLoaded({
    required this.records,
    required this.totalKm,
    required this.avgDailyKm,
  });

  @override
  List<Object?> get props => [records, totalKm, avgDailyKm];
}

class MileageDuplicateFound extends MileageState {
  final String vehicleId;
  final DateTime date;
  final double existingKm;

  MileageDuplicateFound({
    required this.vehicleId,
    required this.date,
    required this.existingKm,
  });

  @override
  List<Object?> get props => [vehicleId, date, existingKm];
}

class MileageError extends MileageState {
  final String message;
  MileageError(this.message);

  @override
  List<Object?> get props => [message];
}
