import '../models/trouble_log.dart';

abstract class TroubleLogRepository {
  Future<List<TroubleLog>> getTroubleLogsByVehicle(String vehicleId);
  Future<List<TroubleLog>> getUnresolvedLogs(String vehicleId);
  Future<TroubleLog?> getTroubleLogById(String id);
  Future<void> insertTroubleLog(TroubleLog log);
  Future<void> updateTroubleLog(TroubleLog log);
  Future<void> deleteTroubleLog(String id);
  Future<void> markAsResolved(String id, DateTime resolvedDate, String? resolutionNotes, String? maintenanceRecordId);
}
