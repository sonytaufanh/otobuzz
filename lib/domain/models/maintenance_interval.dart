import 'maintenance_type.dart';
import 'transmission_type.dart';
import 'vehicle_type.dart';

class MaintenanceInterval {
  final MaintenanceType type;
  final VehicleType vehicleType;
  final TransmissionType? transmissionType;
  final double kmInterval;
  final int monthsInterval;
  final double warningBeforeKm;
  final int warningBeforeDays;

  const MaintenanceInterval({
    required this.type,
    required this.vehicleType,
    this.transmissionType,
    required this.kmInterval,
    required this.monthsInterval,
    required this.warningBeforeKm,
    required this.warningBeforeDays,
  });
}

/// Default maintenance intervals following Indonesian market standards.
///
/// Intervals without [transmissionType] apply to all transmissions of that
/// vehicle type. Intervals with [transmissionType] only apply when the
/// vehicle's transmission matches.
final List<MaintenanceInterval> defaultIntervals = [
  // ===========================================================================
  // MOTORCYCLE — all transmissions
  // ===========================================================================
  const MaintenanceInterval(
    type: MaintenanceType.oilChange,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 2000,
    monthsInterval: 2,
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
    type: MaintenanceType.brakeFluidFlush,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.valveAdjust,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 12000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.throttleBodyClean,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 10000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.injectorClean,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 10000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.battery,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.wheelBearing,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 30000,
    monthsInterval: 36,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.suspension,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 30000,
    monthsInterval: 36,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),

  // Motorcycle — manual & semi-auto only (chain)
  const MaintenanceInterval(
    type: MaintenanceType.chainLube,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.manual,
    kmInterval: 500,
    monthsInterval: 1,
    warningBeforeKm: 50,
    warningBeforeDays: 7,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.chainLube,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.semiAuto,
    kmInterval: 500,
    monthsInterval: 1,
    warningBeforeKm: 50,
    warningBeforeDays: 7,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.chainAdjust,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.manual,
    kmInterval: 2000,
    monthsInterval: 3,
    warningBeforeKm: 200,
    warningBeforeDays: 14,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.chainAdjust,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.semiAuto,
    kmInterval: 2000,
    monthsInterval: 3,
    warningBeforeKm: 200,
    warningBeforeDays: 14,
  ),

  // Motorcycle — manual & semi-auto: clutch plate
  const MaintenanceInterval(
    type: MaintenanceType.clutchPlate,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.manual,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.clutchPlate,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.semiAuto,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),

  // Motorcycle — matic: CVT components
  const MaintenanceInterval(
    type: MaintenanceType.cvtRoller,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 15000,
    monthsInterval: 18,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtVBelt,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 24000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtClutchShoe,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtDrivePlate,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtSpring,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 20000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),

  // Motorcycle — matic: final drive oil (gardan)
  const MaintenanceInterval(
    type: MaintenanceType.finalDriveOil,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.matic,
    kmInterval: 8000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),

  // Motorcycle — manual/semi: transmission oil
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.manual,
    kmInterval: 10000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.motorcycle,
    transmissionType: TransmissionType.semiAuto,
    kmInterval: 10000,
    monthsInterval: 12,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),

  // ===========================================================================
  // CAR — all transmissions
  // ===========================================================================
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
    type: MaintenanceType.brakeFluidFlush,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.battery,
    vehicleType: VehicleType.car,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.wheelBearing,
    vehicleType: VehicleType.car,
    kmInterval: 60000,
    monthsInterval: 48,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.suspension,
    vehicleType: VehicleType.car,
    kmInterval: 60000,
    monthsInterval: 48,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.injectorClean,
    vehicleType: VehicleType.car,
    kmInterval: 25000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.throttleBodyClean,
    vehicleType: VehicleType.car,
    kmInterval: 25000,
    monthsInterval: 24,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),

  // Car — manual: transmission oil + clutch
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.car,
    transmissionType: TransmissionType.manual,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.clutchPlate,
    vehicleType: VehicleType.car,
    transmissionType: TransmissionType.manual,
    kmInterval: 60000,
    monthsInterval: 48,
    warningBeforeKm: 1000,
    warningBeforeDays: 30,
  ),

  // Car — matic: ATF + CVT components
  const MaintenanceInterval(
    type: MaintenanceType.transmission,
    vehicleType: VehicleType.car,
    transmissionType: TransmissionType.matic,
    kmInterval: 40000,
    monthsInterval: 24,
    warningBeforeKm: 500,
    warningBeforeDays: 30,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtVBelt,
    vehicleType: VehicleType.car,
    transmissionType: TransmissionType.matic,
    kmInterval: 80000,
    monthsInterval: 60,
    warningBeforeKm: 2000,
    warningBeforeDays: 60,
  ),
  const MaintenanceInterval(
    type: MaintenanceType.cvtClutchShoe,
    vehicleType: VehicleType.car,
    transmissionType: TransmissionType.matic,
    kmInterval: 80000,
    monthsInterval: 60,
    warningBeforeKm: 2000,
    warningBeforeDays: 60,
  ),
];

/// Returns the default interval for a [type] + [vehicleType] combination.
///
/// If multiple intervals exist for the same type (e.g. chainLube for manual
/// vs semi-auto), pass [transmissionType] to disambiguate. If no
/// transmission-specific match is found, falls back to the generic one.
MaintenanceInterval getDefaultInterval(
  MaintenanceType type,
  VehicleType vehicleType, {
  TransmissionType? transmissionType,
}) {
  // Try transmission-specific first
  if (transmissionType != null) {
    final match = defaultIntervals.where(
      (i) =>
          i.type == type &&
          i.vehicleType == vehicleType &&
          i.transmissionType == transmissionType,
    );
    if (match.isNotEmpty) return match.first;
  }
  // Fall back to generic (no transmissionType)
  return defaultIntervals.firstWhere(
    (i) =>
        i.type == type &&
        i.vehicleType == vehicleType &&
        i.transmissionType == null,
  );
}

/// Returns all [MaintenanceType]s applicable for a [vehicleType] +
/// [transmissionType] combination.
///
/// Rules:
/// - chainLube / chainAdjust: only manual & semi-auto motorcycles
/// - CVT types (roller, v-belt, clutchShoe, drivePlate, spring): only matic
/// - finalDriveOil: only matic motorcycles
/// - clutchPlate: only manual & semi-auto
/// - transmission: all (but interval differs)
List<MaintenanceType> getApplicableTypes(
  VehicleType vehicleType, {
  TransmissionType? transmissionType,
}) {
  final applicable = <MaintenanceType>{};

  for (final interval in defaultIntervals) {
    if (interval.vehicleType != vehicleType) continue;

    // If interval has a transmissionType constraint, check it
    if (interval.transmissionType != null) {
      if (transmissionType != null &&
          interval.transmissionType == transmissionType) {
        applicable.add(interval.type);
      }
    } else {
      // Generic interval — always applicable for this vehicle type
      applicable.add(interval.type);
    }
  }

  return applicable.toList();
}
