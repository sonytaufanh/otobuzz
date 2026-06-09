import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/mileage_repository.dart';
import '../../../domain/usecases/add_daily_mileage_usecase.dart';
import 'mileage_event.dart';
import 'mileage_state.dart';

class MileageBloc extends Bloc<MileageEvent, MileageState> {
  final AddDailyMileageUseCase _addMileageUseCase;
  final MileageRepository _mileageRepository;

  MileageBloc(this._addMileageUseCase, this._mileageRepository)
      : super(MileageInitial()) {
    on<AddMileage>(_onAddMileage);
    on<LoadMileageHistory>(_onLoadHistory);
    on<CheckDuplicateEntry>(_onCheckDuplicate);
  }

  Future<void> _onAddMileage(
      AddMileage event, Emitter<MileageState> emit) async {
    emit(MileageLoading());
    try {
      final updatedVehicle = await _addMileageUseCase.execute(
        vehicleId: event.vehicleId,
        km: event.km,
        date: event.date,
        notes: event.notes,
        replaceDuplicate: event.replaceDuplicate,
      );
      emit(MileageAdded(updatedVehicle));
    } on DuplicateEntryException {
      final existing = await _mileageRepository.getRecordByVehicleAndDate(
          event.vehicleId, event.date);
      emit(MileageDuplicateFound(
        vehicleId: event.vehicleId,
        date: event.date,
        existingKm: existing?.km ?? 0,
      ));
    } catch (e) {
      emit(MileageError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
      LoadMileageHistory event, Emitter<MileageState> emit) async {
    emit(MileageLoading());
    try {
      final records = await _mileageRepository.getMileageHistory(
        event.vehicleId,
        from: event.from,
        to: event.to,
      );
      final totalKm = await _mileageRepository.getTotalMileage(event.vehicleId);
      final avgKm =
          await _mileageRepository.getAverageDailyMileage(event.vehicleId);
      emit(MileageHistoryLoaded(
        records: records,
        totalKm: totalKm,
        avgDailyKm: avgKm,
      ));
    } catch (e) {
      emit(MileageError('Gagal memuat riwayat km'));
    }
  }

  Future<void> _onCheckDuplicate(
      CheckDuplicateEntry event, Emitter<MileageState> emit) async {
    final isDuplicate = await _addMileageUseCase.checkDuplicateEntry(
        event.vehicleId, event.date);
    if (isDuplicate) {
      final existing = await _mileageRepository.getRecordByVehicleAndDate(
          event.vehicleId, event.date);
      emit(MileageDuplicateFound(
        vehicleId: event.vehicleId,
        date: event.date,
        existingKm: existing?.km ?? 0,
      ));
    }
  }
}
