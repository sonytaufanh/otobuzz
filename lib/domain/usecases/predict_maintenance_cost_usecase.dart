import '../models/models.dart';
import '../repositories/repositories.dart';

class UpcomingMaintenanceWithCost {
  final MaintenanceType type;
  final MaintenanceSchedule schedule;
  final double? estimatedCost;
  final int daysUntilDue;

  const UpcomingMaintenanceWithCost({
    required this.type,
    required this.schedule,
    this.estimatedCost,
    required this.daysUntilDue,
  });
}

class MaintenanceCostPrediction {
  final int daysAhead;
  final List<UpcomingMaintenanceWithCost> upcomingMaintenance;
  final double totalEstimatedCost;

  const MaintenanceCostPrediction({
    required this.daysAhead,
    required this.upcomingMaintenance,
    required this.totalEstimatedCost,
  });
}

class PredictMaintenanceCostUseCase {
  final MaintenanceScheduleRepository _scheduleRepository;
  final MaintenanceHistoryRepository _historyRepository;

  PredictMaintenanceCostUseCase(
    this._scheduleRepository,
    this._historyRepository,
  );

  Future<MaintenanceCostPrediction> execute({
    required String vehicleId,
    required int daysAhead,
  }) async {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: daysAhead));

    // Get all schedules for vehicle
    final schedules = await _scheduleRepository.getSchedules(vehicleId);

    // Filter schedules due within the target period
    final upcoming = <UpcomingMaintenanceWithCost>[];
    for (final schedule in schedules) {
      final daysUntil = schedule.dueByDate.difference(now).inDays;
      if (daysUntil >= 0 && daysUntil <= daysAhead) {
        // Get average cost from history
        final history = await _historyRepository.getHistory(
          vehicleId,
          type: schedule.type,
          limit: 5,
        );
        final costsWithValue = history.where((r) => r.cost != null).toList();
        final avgCost = costsWithValue.isEmpty
            ? null
            : costsWithValue.fold<double>(0, (sum, r) => sum + r.cost!) /
                costsWithValue.length;

        upcoming.add(UpcomingMaintenanceWithCost(
          type: schedule.type,
          schedule: schedule,
          estimatedCost: avgCost,
          daysUntilDue: daysUntil,
        ));
      }
    }

    // Sort by days until due
    upcoming.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));

    // Calculate total
    final total = upcoming.fold<double>(
      0,
      (sum, item) => sum + (item.estimatedCost ?? 0),
    );

    return MaintenanceCostPrediction(
      daysAhead: daysAhead,
      upcomingMaintenance: upcoming,
      totalEstimatedCost: total,
    );
  }
}
