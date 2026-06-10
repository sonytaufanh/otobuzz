import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/fuel_repository.dart';
import 'fuel_event.dart';
import 'fuel_state.dart';

class FuelBloc extends Bloc<FuelEvent, FuelState> {
  final FuelRepository _fuelRepository;

  FuelBloc(this._fuelRepository) : super(FuelInitial()) {
    on<LoadFuelRecords>(_onLoadFuelRecords);
    on<AddFuelRecord>(_onAddFuelRecord);
    on<DeleteFuelRecord>(_onDeleteFuelRecord);
    on<LoadFuelStatistics>(_onLoadFuelStatistics);
  }

  Future<void> _onLoadFuelRecords(
    LoadFuelRecords event,
    Emitter<FuelState> emit,
  ) async {
    emit(FuelLoading());
    try {
      final records = await _fuelRepository.getFuelRecords(event.vehicleId);
      final statistics = await _fuelRepository.getStatistics(event.vehicleId);
      emit(FuelLoaded(records: records, statistics: statistics));
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  Future<void> _onAddFuelRecord(
    AddFuelRecord event,
    Emitter<FuelState> emit,
  ) async {
    try {
      await _fuelRepository.insertFuelRecord(event.record);
      add(LoadFuelRecords(event.record.vehicleId));
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  Future<void> _onDeleteFuelRecord(
    DeleteFuelRecord event,
    Emitter<FuelState> emit,
  ) async {
    try {
      await _fuelRepository.deleteFuelRecord(event.id);
      add(LoadFuelRecords(event.vehicleId));
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }

  Future<void> _onLoadFuelStatistics(
    LoadFuelStatistics event,
    Emitter<FuelState> emit,
  ) async {
    emit(FuelLoading());
    try {
      final records = await _fuelRepository.getFuelRecords(event.vehicleId);
      final statistics = await _fuelRepository.getStatistics(
        event.vehicleId,
        start: event.start,
        end: event.end,
      );
      emit(FuelLoaded(records: records, statistics: statistics));
    } catch (e) {
      emit(FuelError(e.toString()));
    }
  }
}
