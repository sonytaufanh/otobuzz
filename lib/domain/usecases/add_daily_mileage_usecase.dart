import 'package:uuid/uuid.dart';
import '../../data/services/notification_service.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'maintenance_calculator.dart';

class AddDailyMileageUseCase {
  final VehicleRepository _vehicleRepository;
  final MileageRepository _mileageRepository;
  final MaintenanceScheduleRepository _scheduleRepository;
  final MaintenanceCalculator _calculator;
  final NotificationService? _notificationService;
  final Uuid _uuid = const Uuid();

  AddDailyMileageUseCase(
    this._vehicleRepository,
    this._mileageRepository,
    this._scheduleRepository,
    this._calculator, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService;

  /// Returns true if a record already exists for this vehicle and date.
  Future<bool> checkDuplicateEntry(String vehicleId, DateTime date) async {
    final existing =
        await _mileageRepository.getRecordByVehicleAndDate(vehicleId, date);
    return existing != null;
  }

  Future<Vehicle> execute({
    required String vehicleId,
    required double km,
    required DateTime date,
    String? notes,
    bool replaceDuplicate = false,
  }) async {
    // Validate input
    if (km <= 0 || km > 2000) {
      throw ArgumentError('Masukkan jarak yang valid (1-2000 km)');
    }
    if (date.isAfter(DateTime.now())) {
      throw ArgumentError('Tanggal tidak boleh di masa depan');
    }

    // Normalize date to midnight
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check for duplicate
    final existing = await _mileageRepository.getRecordByVehicleAndDate(
        vehicleId, normalizedDate);
    if (existing != null && !replaceDuplicate) {
      throw DuplicateEntryException(
          'Sudah ada catatan km untuk tanggal ini. Ganti dengan yang baru?');
    }

    // Get current vehicle
    final vehicle = await _vehicleRepository.getVehicleById(vehicleId);
    if (vehicle == null) {
      throw ArgumentError('Kendaraan tidak ditemukan');
    }

    // Calculate the adjustment if replacing
    double kmAdjustment = km;
    if (existing != null) {
      kmAdjustment = km - existing.km;
    }

    // Create record
    final record = MileageRecord(
      id: existing?.id ?? _uuid.v4(),
      vehicleId: vehicleId,
      km: km,
      date: normalizedDate,
      notes: notes,
    );

    // Save mileage record (upsert)
    await _mileageRepository.upsertMileageRecord(record);

    // Update vehicle total
    final updatedTotal = vehicle.totalMileageKm + kmAdjustment;
    await _vehicleRepository.updateTotalMileage(vehicleId, updatedTotal);

    // Recalculate schedules
    final updatedVehicle = vehicle.copyWith(totalMileageKm: updatedTotal);
    final schedules =
        await _calculator.recalculateAllSchedules(updatedVehicle);
    await _scheduleRepository.updateSchedules(vehicleId, schedules);

    // Reschedule notifications
    await _notificationService?.rescheduleAllForVehicle(
      vehicleId: vehicleId,
      vehicleName: updatedVehicle.name,
      vehicleType: updatedVehicle.type,
      schedules: schedules,
    );

    return updatedVehicle;
  }
}

class DuplicateEntryException implements Exception {
  final String message;
  DuplicateEntryException(this.message);

  @override
  String toString() => message;
}
