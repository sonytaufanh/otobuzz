import 'maintenance_type.dart';
import 'vehicle_type.dart';

class MaintenanceInterval {
  final MaintenanceType type;
  final VehicleType vehicleType;
  final double kmInterval;
  final int monthsInterval;
  final double warningBeforeKm;
  final int warningBeforeDays;

  const MaintenanceInterval({
    required this.type,
    required this.vehicleType,
    required this.kmInterval,
    required this.monthsInterval,
    required this.warningBeforeKm,
    required this.warningBeforeDays,
  });
}

/// Default maintenance intervals following Indonesian market standards.
final List<MaintenanceInterval> defaultIntervals = [
  // Motorcycle intervals
  const MaintenanceInterval(
    type: MaintenanceType.oilChange,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 2000,
    monthsInterval: 3,
    warningBeforeKm: 200,
    warningBeforeDays: 14,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.tireReplacement,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 15000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 90,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.brakePads,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 15000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.airFilter,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 8000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.sparkPlug,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 8000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.chainLube,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 500,
    monthsInterval: 1,
    warningBeforeKm: 50,
    warningBeforeDays: 7,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.coolant,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.brakeFluid,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 10000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  // Car intervals
  const MaintenanceInterval(
    type: MaintenanceType.oilChange,
    vehicleType: VehicleType.car,
    kmInterval: 5000,
    monthsInterval: 6,
    warningBeforeKm: 200,
    warningBeforeDays: 14,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.tireReplacement,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 48,
    warningBeforeKm: 1000,
    warningBeforeDays: 90,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.brakePads,
    vehicleType: VehicleType.car,
    kmInterval: 30000,
    monthsInterval: 36,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.airFilter,
    vehicleType: VehicleType.car,
    kmInterval: 20000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.sparkPlug,
    vehicleType: VehicleType.car,
    kmInterval: 30000,
    monthsInterval: 24,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.coolant,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.brakeFluid,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 48,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
];

MaintenanceInterval getDefaultInterval(
    MaintenanceType type, VehicleType vehicleType) {
  return defaultIntervals.firstWhere(
    (i) => i.type == type && i.vehicleType == vehicleType,
  );
}

List<MaintenanceType> getApplicableTypes(VehicleType vehicleType) {
  final allTypes = MaintenanceType.values.toList();
  if (vehicleType == VehicleType.car) {
    allTypes.remove(MaintenanceType.chainLube);
  }
  return allTypes;
}
