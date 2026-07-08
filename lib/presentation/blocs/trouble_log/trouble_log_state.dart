part of 'trouble_log_bloc.dart';

abstract class TroubleLogState extends Equatable {
  const TroubleLogState();
  @override
  List<Object?> get props => [];
}

class TroubleLogInitial extends TroubleLogState {}

class TroubleLogLoading extends TroubleLogState {}

class TroubleLogLoaded extends TroubleLogState {
  final List<TroubleLog> logs;
  const TroubleLogLoaded(this.logs);
  @override
  List<Object?> get props => [logs];
}

class TroubleLogError extends TroubleLogState {
  final String message;
  const TroubleLogError(this.message);
  @override
  List<Object?> get props => [message];
}
