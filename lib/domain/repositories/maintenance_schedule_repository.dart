import '../models/maintenance_schedule.dart';

abstract class MaintenanceScheduleRepository {
  Future<void> updateSchedules(
      String vehicleId, List<MaintenanceSchedule> schedules);
  Future<List<MaintenanceSchedule>> getSchedules(String vehicleId);
  Future<void> deleteSchedulesForVehicle(String vehicleId);
}
