import 'package:uuid/uuid.dart';
import '../../data/services/notification_service.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'maintenance_calculator.dart';

class RecordMaintenanceCompletedUseCase {
  final VehicleRepository _vehicleRepository;
  final MaintenanceHistoryRepository _maintenanceRepository;
  final MaintenanceScheduleRepository _scheduleRepository;
  final MaintenanceCalculator _calculator;
  final NotificationService? _notificationService;
  final Uuid _uuid = const Uuid();

  RecordMaintenanceCompletedUseCase(
    this._vehicleRepository,
    this._maintenanceRepository,
    this._scheduleRepository,
    this._calculator, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService;

  Future<void> execute({
    required String vehicleId,
    required MaintenanceType type,
    required double currentMileage,
    required DateTime serviceDate,
    double? cost,
    String? notes,
    String? workshopName,
  }) async {
    // Validate
    if (serviceDate.isAfter(DateTime.now())) {
      throw ArgumentError('Tanggal servis tidak boleh di masa depan');
    }

    final vehicle = await _vehicleRepository.getVehicleById(vehicleId);
    if (vehicle == null) {
      throw ArgumentError('Kendaraan tidak ditemukan');
    }

    if (currentMileage > vehicle.totalMileageKm) {
      throw ArgumentError(
          'Kilometer servis tidak boleh lebih dari total km kendaraan');
    }

    // Record the maintenance
    final record = MaintenanceRecord(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      type: type,
      mileageAtService: currentMileage,
      serviceDate: serviceDate,
      cost: cost,
      notes: notes,
      workshopName: workshopName,
    );
    await _maintenanceRepository.addMaintenanceRecord(record);

    // Recalculate schedules
    final schedules = await _calculator.recalculateAllSchedules(vehicle);
    await _scheduleRepository.updateSchedules(vehicleId, schedules);

    // Reschedule notifications
    await _notificationService?.rescheduleAllForVehicle(
      vehicleId: vehicleId,
      vehicleName: vehicle.name,
      vehicleType: vehicle.type,
      schedules: schedules,
    );
  }
}
