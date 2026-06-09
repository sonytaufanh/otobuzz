import 'package:uuid/uuid.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class MaintenanceCalculator {
  final MileageRepository _mileageRepository;
  final MaintenanceHistoryRepository _maintenanceRepository;
  final CustomIntervalRepository? _customIntervalRepository;
  final Uuid _uuid = const Uuid();

  MaintenanceCalculator(
    this._mileageRepository,
    this._maintenanceRepository, {
    CustomIntervalRepository? customIntervalRepository,
  }) : _customIntervalRepository = customIntervalRepository;

  /// Calculates the next maintenance schedule for a given type based on
  /// km-based and time-based intervals.
  MaintenanceSchedule calculateNextMaintenanceSchedule({
    required MaintenanceType type,
    required Vehicle vehicle,
    required MaintenanceRecord? lastService,
    required MaintenanceInterval interval,
    required double avgDailyKm,
  }) {
    // Step 1: Determine baseline (last service or vehicle creation)
    final double baseKm = lastService?.mileageAtService ?? 0;
    final DateTime baseDate = lastService?.serviceDate ?? vehicle.createdAt;

    // Step 2: Calculate km-based due point
    final double dueAtKm = baseKm + interval.kmInterval;
    final double remainingKm = dueAtKm - vehicle.totalMileageKm;

    // Step 3: Calculate time-based due point
    final DateTime dueByDate = DateTime(
      baseDate.year,
      baseDate.month + interval.monthsInterval,
      baseDate.day,
    );
    final int remainingDays = dueByDate.difference(DateTime.now()).inDays;

    // Step 4: Determine overdue status
    final bool isOverdue = remainingKm <= 0 || remainingDays <= 0;

    // Step 5: Estimate calendar date for km-based due
    final DateTime? estimatedDueDate = predictDueDate(
      remainingKm: remainingKm,
      avgDailyKm: avgDailyKm,
    );

    return MaintenanceSchedule(
      id: _uuid.v4(),
      vehicleId: vehicle.id,
      type: type,
      dueAtKm: dueAtKm,
      dueByDate: dueByDate,
      remainingKm: remainingKm.clamp(0, double.infinity),
      remainingDays: remainingDays.clamp(0, 99999),
      isOverdue: isOverdue,
      estimatedDueDate: estimatedDueDate,
    );
  }

  /// Recalculates all maintenance schedules for a vehicle.
  ///
  /// Gets avgDailyKm from the mileage repository (last 30 days),
  /// determines applicable types based on vehicle type,
  /// retrieves last maintenance records, calculates schedules,
  /// and sorts by urgency (overdue first, then by remainingKm ascending).
  Future<List<MaintenanceSchedule>> recalculateAllSchedules(
      Vehicle vehicle) async {
    // Step 1: Get average daily km (last 30 days)
    final double avgDailyKm =
        await _mileageRepository.getAverageDailyMileage(vehicle.id,
            lastDays: 30);

    // Step 2: Get applicable maintenance types for this vehicle
    final List<MaintenanceType> applicableTypes =
        getApplicableMaintenanceTypes(vehicle.type);

    // Step 3: Get last maintenance record for each type
    final Map<MaintenanceType, MaintenanceRecord> lastServices =
        await _maintenanceRepository.getLastMaintenanceByType(vehicle.id);

    // Step 4: Calculate schedule for each maintenance type
    final List<MaintenanceSchedule> schedules = [];

    for (final type in applicableTypes) {
      // Check for custom interval first, fall back to default
      MaintenanceInterval interval;
      if (_customIntervalRepository != null) {
        final custom =
            await _customIntervalRepository.getCustomInterval(vehicle.id, type);
        if (custom != null) {
          interval = MaintenanceInterval(
            type: type,
            vehicleType: vehicle.type,
            kmInterval: custom.kmInterval,
            monthsInterval: custom.monthsInterval,
            warningBeforeKm: custom.warningBeforeKm,
            warningBeforeDays: custom.warningBeforeDays,
          );
        } else {
          interval = getDefaultInterval(type, vehicle.type);
        }
      } else {
        interval = getDefaultInterval(type, vehicle.type);
      }
      final lastService = lastServices[type];

      final schedule = calculateNextMaintenanceSchedule(
        type: type,
        vehicle: vehicle,
        lastService: lastService,
        interval: interval,
        avgDailyKm: avgDailyKm,
      );

      schedules.add(schedule);
    }

    // Step 5: Sort by urgency (overdue first, then by remaining km)
    schedules.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.remainingKm.compareTo(b.remainingKm);
    });

    return schedules;
  }

  /// Predicts the estimated due date given remaining km and average daily km.
  ///
  /// Returns null if avgDailyKm is 0 (cannot predict) or if remainingKm <= 0
  /// (already overdue, no future date to predict).
  DateTime? predictDueDate({
    required double remainingKm,
    required double avgDailyKm,
  }) {
    if (avgDailyKm <= 0 || remainingKm <= 0) {
      return null;
    }
    final int estimatedDays = (remainingKm / avgDailyKm).ceil();
    return DateTime.now().add(Duration(days: estimatedDays));
  }

  /// Returns all applicable MaintenanceType values for a given vehicle type.
  ///
  /// All types are applicable for motorcycles.
  /// For cars, chainLube is excluded (cars don't have chains).
  List<MaintenanceType> getApplicableMaintenanceTypes(VehicleType vehicleType) {
    return getApplicableTypes(vehicleType);
  }
}
