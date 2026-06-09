import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/cost_report_repository.dart';
import 'cost_report_event.dart';
import 'cost_report_state.dart';

class CostReportBloc extends Bloc<CostReportEvent, CostReportState> {
  final CostReportRepository _repository;

  CostReportBloc(this._repository) : super(CostReportInitial()) {
    on<LoadCostReport>(_onLoadCostReport);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoadCostReport(
      LoadCostReport event, Emitter<CostReportState> emit) async {
    emit(CostReportLoading());
    try {
      final totalCost =
          await _repository.getTotalCost(event.vehicleId, event.from, event.to);
      final byType =
          await _repository.getCostByType(event.vehicleId, event.from, event.to);
      final byVehicle =
          await _repository.getCostByVehicle(event.from, event.to);
      final monthly = await _repository.getMonthlyCostSummary(
          event.vehicleId, event.from.year);

      emit(CostReportLoaded(
        totalCost: totalCost,
        byType: byType,
        byVehicle: byVehicle,
        monthly: monthly,
        period: CostReportPeriod.thisMonth,
        vehicleId: event.vehicleId,
        from: event.from,
        to: event.to,
      ));
    } catch (e) {
      emit(CostReportError('Gagal memuat laporan biaya'));
    }
  }

  Future<void> _onChangePeriod(
      ChangePeriod event, Emitter<CostReportState> emit) async {
    final now = DateTime.now();
    DateTime from;
    DateTime to = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (event.period) {
      case CostReportPeriod.thisMonth:
        from = DateTime(now.year, now.month, 1);
        break;
      case CostReportPeriod.threeMonths:
        from = DateTime(now.year, now.month - 2, 1);
        break;
      case CostReportPeriod.thisYear:
        from = DateTime(now.year, 1, 1);
        break;
      case CostReportPeriod.custom:
        // Custom period is handled by LoadCostReport directly
        return;
    }

    // Preserve the current vehicle filter if we have a loaded state
    String? vehicleId;
    if (state is CostReportLoaded) {
      vehicleId = (state as CostReportLoaded).vehicleId;
    }

    add(LoadCostReport(vehicleId: vehicleId, from: from, to: to));
  }
}
