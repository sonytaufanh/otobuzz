import '../models/maintenance_schedule.dart';
import '../repositories/maintenance_schedule_repository.dart';

class GetVehicleSchedulesUseCase {
  final MaintenanceScheduleRepository _scheduleRepository;

  GetVehicleSchedulesUseCase(this._scheduleRepository);

  /// Fetches schedules for a vehicle, returns sorted by urgency
  /// (overdue first, then by remainingKm ascending).
  Future<List<MaintenanceSchedule>> execute(String vehicleId) async {
    final schedules = await _scheduleRepository.getSchedules(vehicleId);

    // Sort by urgency: overdue first, then by remaining km ascending
    schedules.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.remainingKm.compareTo(b.remainingKm);
    });

    return schedules;
  }
}
