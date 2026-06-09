import '../models/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getAllVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<void> addVehicle(Vehicle vehicle);
  Future<void> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
  Future<void> updateTotalMileage(String vehicleId, double totalKm);
}
