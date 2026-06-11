import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/vehicle_document_repository.dart';
import '../../../domain/models/maintenance_schedule.dart';
import '../../../domain/repositories/vehicle_repository.dart';
import '../../../domain/usecases/maintenance_calculator.dart';
import '../../../domain/repositories/maintenance_schedule_repository.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository _vehicleRepository;
  final MaintenanceCalculator _calculator;
  final MaintenanceScheduleRepository _scheduleRepository;
  final VehicleDocumentRepository? _documentRepository;

  /// Expose calculator for health score computation.
  MaintenanceCalculator get calculator => _calculator;

  /// Expose vehicle repository for smart tips and other features.
  VehicleRepository get vehicleRepository => _vehicleRepository;

  VehicleBloc(
    this._vehicleRepository,
    this._calculator,
    this._scheduleRepository, {
    VehicleDocumentRepository? documentRepository,
  })  : _documentRepository = documentRepository,
        super(VehicleInitial()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<AddVehicle>(_onAddVehicle);
    on<UpdateVehicle>(_onUpdateVehicle);
    on<DeleteVehicle>(_onDeleteVehicle);
  }

  Future<void> _onLoadVehicles(
      LoadVehicles event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    try {
      final vehicles = await _vehicleRepository.getAllVehicles();
      // Load schedules for each vehicle for fleet overview
      final Map<String, List<MaintenanceSchedule>> scheduleMap = {};
      for (final vehicle in vehicles) {
        final schedules =
            await _scheduleRepository.getSchedules(vehicle.id);
        scheduleMap[vehicle.id] = schedules;
      }

      // Load document expiry counts
      int expiredDocCount = 0;
      int expiringSoonDocCount = 0;
      if (_documentRepository != null) {
        final docRepo = _documentRepository;
        final expired = await docRepo.getAllExpired();
        final expiringSoon = await docRepo.getExpiringSoon(30);
        expiredDocCount = expired.length;
        expiringSoonDocCount = expiringSoon.length;
      }

      emit(VehicleLoaded(
        vehicles,
        vehicleSchedules: scheduleMap,
        expiredDocumentCount: expiredDocCount,
        expiringSoonDocumentCount: expiringSoonDocCount,
      ));
    } catch (e) {
      emit(VehicleError('Gagal memuat daftar kendaraan'));
    }
  }

  Future<void> _onAddVehicle(
      AddVehicle event, Emitter<VehicleState> emit) async {
    try {
      await _vehicleRepository.addVehicle(event.vehicle);
      // Initialize maintenance schedules for new vehicle
      final schedules =
          await _calculator.recalculateAllSchedules(event.vehicle);
      await _scheduleRepository.updateSchedules(event.vehicle.id, schedules);
      emit(VehicleOperationSuccess('Kendaraan berhasil ditambahkan'));
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Gagal menambahkan kendaraan'));
    }
  }

  Future<void> _onUpdateVehicle(
      UpdateVehicle event, Emitter<VehicleState> emit) async {
    try {
      await _vehicleRepository.updateVehicle(event.vehicle);
      emit(VehicleOperationSuccess('Kendaraan berhasil diperbarui'));
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Gagal memperbarui kendaraan'));
    }
  }

  Future<void> _onDeleteVehicle(
      DeleteVehicle event, Emitter<VehicleState> emit) async {
    try {
      await _vehicleRepository.deleteVehicle(event.vehicleId);
      emit(VehicleOperationSuccess('Kendaraan berhasil dihapus'));
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Gagal menghapus kendaraan'));
    }
  }
}
