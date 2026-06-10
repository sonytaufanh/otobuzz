import 'package:equatable/equatable.dart';
import '../../../domain/models/fuel_record.dart';
import '../../../domain/models/fuel_statistics.dart';

abstract class FuelState extends Equatable {
  const FuelState();

  @override
  List<Object?> get props => [];
}

class FuelInitial extends FuelState {}

class FuelLoading extends FuelState {}

class FuelLoaded extends FuelState {
  final List<FuelRecord> records;
  final FuelStatistics statistics;

  const FuelLoaded({required this.records, required this.statistics});

  @override
  List<Object?> get props => [records, statistics];
}

class FuelError extends FuelState {
  final String message;

  const FuelError(this.message);

  @override
  List<Object?> get props => [message];
}
