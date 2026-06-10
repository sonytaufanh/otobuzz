import 'package:equatable/equatable.dart';
import '../../../domain/models/fuel_record.dart';

abstract class FuelEvent extends Equatable {
  const FuelEvent();

  @override
  List<Object?> get props => [];
}

class LoadFuelRecords extends FuelEvent {
  final String vehicleId;

  const LoadFuelRecords(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class AddFuelRecord extends FuelEvent {
  final FuelRecord record;

  const AddFuelRecord(this.record);

  @override
  List<Object?> get props => [record];
}

class DeleteFuelRecord extends FuelEvent {
  final String id;
  final String vehicleId;

  const DeleteFuelRecord({required this.id, required this.vehicleId});

  @override
  List<Object?> get props => [id, vehicleId];
}

class LoadFuelStatistics extends FuelEvent {
  final String vehicleId;
  final DateTime? start;
  final DateTime? end;

  const LoadFuelStatistics(this.vehicleId, {this.start, this.end});

  @override
  List<Object?> get props => [vehicleId, start, end];
}
