import 'package:home_widget/home_widget.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';

class HomeWidgetService {
  static const String _appGroupId = 'com.otobuzz.otobuzz';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.registerInteractivityCallback(interactivityCallback);
  }

  /// Update widget with basic data (used from mileage bloc)
  static Future<void> updateWidget({
    required String vehicleName,
    required String totalKm,
    required String nextMaintenance,
    String? oilKmRemaining,
    String? nextMaintenanceType,
  }) async {
    await HomeWidget.saveWidgetData<String>('vehicle_name', vehicleName);
    await HomeWidget.saveWidgetData<String>('total_km', totalKm);
    await HomeWidget.saveWidgetData<String>('next_maintenance', nextMaintenance);
    await HomeWidget.saveWidgetData<String>(
        'oil_km_remaining', oilKmRemaining ?? '-');
    await HomeWidget.saveWidgetData<String>(
        'next_maintenance_type', nextMaintenanceType ?? '');
    await HomeWidget.updateWidget(
      androidName: 'OtoBuzzWidgetProvider',
    );
  }

  /// Full update using repositories — call after significant data changes
  static Future<void> updateWidgetFull({
    required String vehicleId,
    required VehicleRepository vehicleRepository,
    required MaintenanceScheduleRepository scheduleRepository,
  }) async {
    try {
      final vehicle = await vehicleRepository.getVehicleById(vehicleId);
      if (vehicle == null) return;

      final schedules = await scheduleRepository.getSchedules(vehicleId);
      schedules.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));

      final nearest = schedules.isNotEmpty ? schedules.first : null;
      String nextMaintenance = 'Tidak ada jadwal';
      String? nextType;
      String? oilRemaining;

      if (nearest != null) {
        final km = nearest.remainingKm.round();
        if (nearest.isOverdue) {
          nextMaintenance = '⚠️ Terlambat ${km.abs()} km';
        } else {
          nextMaintenance = 'Sisa $km km';
        }
        nextType = nearest.type.displayName;
      }

      // Find oil change specifically
      final oilList = schedules.where(
        (s) => s.type.name.toLowerCase().contains('oli'),
      ).toList();
      final oilSchedule = oilList.isNotEmpty ? oilList.first : null;
      if (oilSchedule != null) {
        final kmLeft = oilSchedule.remainingKm.round();
        oilRemaining = kmLeft < 0
            ? 'Terlambat ${kmLeft.abs()} km'
            : '$kmLeft km lagi';
      }

      await updateWidget(
        vehicleName: vehicle.name,
        totalKm: '${vehicle.totalMileageKm.round()} km',
        nextMaintenance: nextMaintenance,
        oilKmRemaining: oilRemaining,
        nextMaintenanceType: nextType,
      );
    } catch (_) {
      // Silently fail — widget update is non-critical
    }
  }

  @pragma('vm:entry-point')
  static Future<void> interactivityCallback(Uri? uri) async {
    // Handle widget tap — opens app to main screen
  }
}
