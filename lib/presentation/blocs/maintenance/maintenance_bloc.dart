import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/maintenance_history_repository.dart';
import '../../../domain/usecases/get_vehicle_schedules_usecase.dart';
import '../../../domain/usecases/record_maintenance_usecase.dart';
import 'maintenance_event.dart';
import 'maintenance_state.dart';

class MaintenanceBloc extends Bloc<MaintenanceEvent, MaintenanceState> {
  final GetVehicleSchedulesUseCase _getSchedulesUseCase;
  final RecordMaintenanceCompletedUseCase _recordMaintenanceUseCase;
  final MaintenanceHistoryRepository _historyRepository;

  MaintenanceBloc(
    this._getSchedulesUseCase,
    this._recordMaintenanceUseCase,
    this._historyRepository,
  ) : super(MaintenanceInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<RecordMaintenance>(_onRecordMaintenance);
    on<LoadMaintenanceHistory>(_onLoadHistory);
  }

  Future<void> _onLoadSchedules(
      LoadSchedules event, Emitter<MaintenanceState> emit) async {
    emit(MaintenanceLoading());
    try {
      final schedules = await _getSchedulesUseCase.execute(event.vehicleId);
      emit(MaintenanceSchedulesLoaded(schedules));
    } catch (e) {
      emit(MaintenanceError('Gagal memuat jadwal perawatan'));
    }
  }

  Future<void> _onRecordMaintenance(
      RecordMaintenance event, Emitter<MaintenanceState> emit) async {
    emit(MaintenanceLoading());
    try {
      await _recordMaintenanceUseCase.execute(
        vehicleId: event.vehicleId,
        type: event.type,
        currentMileage: event.mileageAtService,
        serviceDate: event.serviceDate,
        cost: event.cost,
        notes: event.notes,
        workshopName: event.workshopName,
      );
      emit(MaintenanceRecorded('Perawatan berhasil dicatat'));
      add(LoadSchedules(event.vehicleId));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
      LoadMaintenanceHistory event, Emitter<MaintenanceState> emit) async {
    emit(MaintenanceLoading());
    try {
      final records = await _historyRepository.getHistory(
        event.vehicleId,
        type: event.filterType,
      );
      final totalCost = records.fold<double>(
          0, (sum, record) => sum + (record.cost ?? 0));
      emit(MaintenanceHistoryLoaded(records: records, totalCost: totalCost));
    } catch (e) {
      emit(MaintenanceError('Gagal memuat riwayat perawatan'));
    }
  }
}
