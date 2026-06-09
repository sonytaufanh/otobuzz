import 'package:equatable/equatable.dart';
import '../../../data/repositories/cost_report_repository.dart';
import 'cost_report_event.dart';

abstract class CostReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CostReportInitial extends CostReportState {}

class CostReportLoading extends CostReportState {}

class CostReportLoaded extends CostReportState {
  final double totalCost;
  final List<CostByType> byType;
  final List<CostByVehicle> byVehicle;
  final List<MonthlyCostSummary> monthly;
  final CostReportPeriod period;
  final String? vehicleId;
  final DateTime from;
  final DateTime to;

  CostReportLoaded({
    required this.totalCost,
    required this.byType,
    required this.byVehicle,
    required this.monthly,
    required this.period,
    this.vehicleId,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props =>
      [totalCost, byType, byVehicle, monthly, period, vehicleId, from, to];
}

class CostReportError extends CostReportState {
  final String message;
  CostReportError(this.message);

  @override
  List<Object?> get props => [message];
}
