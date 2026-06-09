import '../models/mileage_record.dart';

abstract class MileageRepository {
  Future<void> addMileageRecord(MileageRecord record);
  Future<void> upsertMileageRecord(MileageRecord record);
  Future<MileageRecord?> getRecordByVehicleAndDate(
      String vehicleId, DateTime date);
  Future<List<MileageRecord>> getMileageHistory(String vehicleId,
      {DateTime? from, DateTime? to});
  Future<double> getTotalMileage(String vehicleId);
  Future<double> getAverageDailyMileage(String vehicleId, {int lastDays = 30});
}
