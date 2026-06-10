import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/fuel_repository.dart';
import '../../../domain/models/maintenance_type.dart';
import '../../../domain/repositories/maintenance_history_repository.dart';
import '../../../domain/repositories/mileage_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final MileageRepository _mileageRepository;
  final MaintenanceHistoryRepository _maintenanceHistoryRepository;
  final FuelRepository _fuelRepository;

  String? _currentVehicleId;
  int _currentPeriodDays = 30;

  AnalyticsBloc(
    this._mileageRepository,
    this._maintenanceHistoryRepository,
    this._fuelRepository,
  ) : super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoad);
    on<ChangeAnalyticsPeriod>(_onChangePeriod);
    on<ChangeAnalyticsVehicle>(_onChangeVehicle);
  }

  Future<void> _onLoad(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    _currentVehicleId = event.vehicleId;
    _currentPeriodDays = event.periodDays;
    await _loadData(emit);
  }

  Future<void> _onChangePeriod(
    ChangeAnalyticsPeriod event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    _currentPeriodDays = event.periodDays;
    await _loadData(emit);
  }

  Future<void> _onChangeVehicle(
    ChangeAnalyticsVehicle event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    _currentVehicleId = event.vehicleId;
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<AnalyticsState> emit) async {
    try {
      final now = DateTime.now();
      final startOfThisMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final periodStart = now.subtract(Duration(days: _currentPeriodDays));

      // Daily km data
      final dailyKmData = <DailyKm>[];
      final mileageRecords = await _mileageRepository.getRecordsByDateRange(
        periodStart,
        now,
        vehicleId: _currentVehicleId,
      );
      for (final r in mileageRecords) {
        dailyKmData.add(DailyKm(date: r.date, km: r.km));
      }

      // Total km this month & last month
      final thisMonthRecords = await _mileageRepository.getRecordsByDateRange(
        startOfThisMonth,
        now,
        vehicleId: _currentVehicleId,
      );
      final lastMonthRecords = await _mileageRepository.getRecordsByDateRange(
        startOfLastMonth,
        startOfThisMonth.subtract(const Duration(days: 1)),
        vehicleId: _currentVehicleId,
      );
      final totalKmThisMonth =
          thisMonthRecords.fold<double>(0, (s, r) => s + r.km);
      final totalKmLastMonth =
          lastMonthRecords.fold<double>(0, (s, r) => s + r.km);

      // Maintenance costs
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
      final maintenanceRecords =
          await _maintenanceHistoryRepository.getRecordsByDateRange(
        sixMonthsAgo,
        now,
        vehicleId: _currentVehicleId,
      );

      // Monthly costs
      final Map<String, double> monthlyCostMap = {};
      final Map<int, double> typeCostMap = {};
      double totalMaintenanceCostThisMonth = 0;

      for (final r in maintenanceRecords) {
        final key = '${r.serviceDate.year}-${r.serviceDate.month}';
        monthlyCostMap[key] = (monthlyCostMap[key] ?? 0) + (r.cost ?? 0);
        typeCostMap[r.type.index] =
            (typeCostMap[r.type.index] ?? 0) + (r.cost ?? 0);

        if (r.serviceDate.isAfter(startOfThisMonth)) {
          totalMaintenanceCostThisMonth += r.cost ?? 0;
        }
      }

      final monthlyCostData = monthlyCostMap.entries.map((e) {
        final parts = e.key.split('-');
        return MonthlyCost(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          cost: e.value,
        );
      }).toList()
        ..sort((a, b) {
          final y = a.year.compareTo(b.year);
          return y != 0 ? y : a.month.compareTo(b.month);
        });

      final typeCostData = typeCostMap.entries.map((e) {
        final type = MaintenanceType.values[e.key];
        return MaintenanceTypeCost(
          typeName: type.displayName,
          cost: e.value,
        );
      }).toList();

      // Fuel data
      final fuelRecords = await _fuelRepository.getAllFuelRecordsByPeriod(
        sixMonthsAgo,
        now,
      );

      double totalFuelCostThisMonth = 0;
      final Map<String, List<double>> monthlyFuelMap = {};
      final Map<String, List<double>> monthlyFuelKmPerLiter = {};

      for (final r in fuelRecords) {
        if (_currentVehicleId != null && r.vehicleId != _currentVehicleId) {
          continue;
        }
        final key = '${r.date.year}-${r.date.month}';
        monthlyFuelMap.putIfAbsent(key, () => []).add(r.totalCost);

        if (r.date.isAfter(startOfThisMonth)) {
          totalFuelCostThisMonth += r.totalCost;
        }
      }

      final monthlyFuelData = monthlyFuelMap.entries.map((e) {
        final parts = e.key.split('-');
        return MonthlyFuel(
          year: int.parse(parts[0]),
          month: int.parse(parts[1]),
          cost: e.value.fold<double>(0, (s, v) => s + v),
          kmPerLiter: 0, // Simplified, could add calculation
        );
      }).toList()
        ..sort((a, b) {
          final y = a.year.compareTo(b.year);
          return y != 0 ? y : a.month.compareTo(b.month);
        });

      // Average fleet km/liter (simplified)
      double averageFleetKmPerLiter = 0;
      final allFuelThisPeriod = fuelRecords.where((r) =>
          (_currentVehicleId == null || r.vehicleId == _currentVehicleId));
      final totalLiters =
          allFuelThisPeriod.fold<double>(0, (s, r) => s + r.liters);
      if (totalLiters > 0 && totalKmThisMonth > 0) {
        averageFleetKmPerLiter = totalKmThisMonth / totalLiters;
      }

      emit(AnalyticsLoaded(
        totalKmThisMonth: totalKmThisMonth,
        totalKmLastMonth: totalKmLastMonth,
        totalMaintenanceCostThisMonth: totalMaintenanceCostThisMonth,
        totalFuelCostThisMonth: totalFuelCostThisMonth,
        averageFleetKmPerLiter: averageFleetKmPerLiter,
        dailyKmData: dailyKmData,
        monthlyCostData: monthlyCostData,
        typeCostData: typeCostData,
        monthlyFuelData: monthlyFuelData,
        selectedVehicleId: _currentVehicleId,
        periodDays: _currentPeriodDays,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
