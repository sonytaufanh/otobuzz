import '../models/annual_km_target.dart';

abstract class AnnualKmTargetRepository {
  Future<AnnualKmTarget?> getTarget(String vehicleId, int year);
  Future<List<AnnualKmTarget>> getAllTargets(String vehicleId);
  Future<void> setTarget(AnnualKmTarget target);
  Future<void> deleteTarget(String id);
}
