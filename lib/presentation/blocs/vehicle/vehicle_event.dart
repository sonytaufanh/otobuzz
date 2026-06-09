import 'package:equatable/equatable.dart';
import '../../../domain/models/vehicle.dart';

abstract class VehicleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleEvent {}

class AddVehicle extends VehicleEvent {
  final Vehicle vehicle;
  AddVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class UpdateVehicle extends VehicleEvent {
  final Vehicle vehicle;
  UpdateVehicle(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class DeleteVehicle extends VehicleEvent {
  final String vehicleId;
  DeleteVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}
