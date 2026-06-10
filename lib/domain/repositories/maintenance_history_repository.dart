import '../models/maintenance_record.dart';
import '../models/maintenance_type.dart';

abstract class MaintenanceHistoryRepository {
  Future<void> addMaintenanceRecord(MaintenanceRecord record);
  Future<List<MaintenanceRecord>> getHistory(String vehicleId,
      {MaintenanceType? type});
  Future<MaintenanceRecord?> getLastMaintenance(
      String vehicleId, MaintenanceType type);
  Future<Map<MaintenanceType, MaintenanceRecord>> getLastMaintenanceByType(
      String vehicleId);
  Future<List<MaintenanceRecord>> getRecordsByDateRange(
      DateTime start, DateTime end,
      {String? vehicleId});
}
