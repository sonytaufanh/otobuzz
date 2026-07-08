import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/trouble_log.dart';
import '../../../domain/repositories/trouble_log_repository.dart';

part 'trouble_log_event.dart';
part 'trouble_log_state.dart';

class TroubleLogBloc extends Bloc<TroubleLogEvent, TroubleLogState> {
  final TroubleLogRepository _repository;

  TroubleLogBloc(this._repository) : super(TroubleLogInitial()) {
    on<LoadTroubleLogs>(_onLoadTroubleLogs);
    on<LoadUnresolvedLogs>(_onLoadUnresolvedLogs);
    on<AddTroubleLog>(_onAddTroubleLog);
    on<UpdateTroubleLog>(_onUpdateTroubleLog);
    on<DeleteTroubleLog>(_onDeleteTroubleLog);
    on<MarkTroubleLogResolved>(_onMarkTroubleLogResolved);
  }

  Future<void> _onLoadTroubleLogs(
    LoadTroubleLogs event,
    Emitter<TroubleLogState> emit,
  ) async {
    emit(TroubleLogLoading());
    try {
      final logs = await _repository.getTroubleLogsByVehicle(event.vehicleId);
      emit(TroubleLogLoaded(logs));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }

  Future<void> _onLoadUnresolvedLogs(
    LoadUnresolvedLogs event,
    Emitter<TroubleLogState> emit,
  ) async {
    emit(TroubleLogLoading());
    try {
      final logs = await _repository.getUnresolvedLogs(event.vehicleId);
      emit(TroubleLogLoaded(logs));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }

  Future<void> _onAddTroubleLog(
    AddTroubleLog event,
    Emitter<TroubleLogState> emit,
  ) async {
    try {
      await _repository.insertTroubleLog(event.log);
      add(LoadTroubleLogs(event.log.vehicleId));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }

  Future<void> _onUpdateTroubleLog(
    UpdateTroubleLog event,
    Emitter<TroubleLogState> emit,
  ) async {
    try {
      await _repository.updateTroubleLog(event.log);
      add(LoadTroubleLogs(event.log.vehicleId));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }

  Future<void> _onDeleteTroubleLog(
    DeleteTroubleLog event,
    Emitter<TroubleLogState> emit,
  ) async {
    try {
      await _repository.deleteTroubleLog(event.id);
      add(LoadTroubleLogs(event.vehicleId));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }

  Future<void> _onMarkTroubleLogResolved(
    MarkTroubleLogResolved event,
    Emitter<TroubleLogState> emit,
  ) async {
    try {
      await _repository.markAsResolved(
        event.id,
        event.resolvedDate,
        event.resolutionNotes,
        event.maintenanceRecordId,
      );
      add(LoadTroubleLogs(event.vehicleId));
    } catch (e) {
      emit(TroubleLogError(e.toString()));
    }
  }
}
