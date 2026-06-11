import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/maintenance_record.dart';
import 'package:otobuzz/domain/models/maintenance_schedule.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_history_repository.dart';
import 'package:otobuzz/domain/usecases/get_vehicle_schedules_usecase.dart';
import 'package:otobuzz/domain/usecases/record_maintenance_usecase.dart';
import 'package:otobuzz/presentation/blocs/maintenance/maintenance_bloc.dart';
import 'package:otobuzz/presentation/blocs/maintenance/maintenance_event.dart';
import 'package:otobuzz/presentation/blocs/maintenance/maintenance_state.dart';

class MockGetVehicleSchedulesUseCase extends Mock
    implements GetVehicleSchedulesUseCase {}

class MockRecordMaintenanceCompletedUseCase extends Mock
    implements RecordMaintenanceCompletedUseCase {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

void main() {
  late MockGetVehicleSchedulesUseCase mockGetSchedules;
  late MockRecordMaintenanceCompletedUseCase mockRecordMaintenance;
  late MockMaintenanceHistoryRepository mockHistoryRepo;

  final overdueSchedule = MaintenanceSchedule(
    id: 's1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    dueAtKm: 45000,
    dueByDate: DateTime(2023, 1, 1),
    remainingKm: -5000,
    remainingDays: -30,
    isOverdue: true,
  );

  final upcomingSchedule = MaintenanceSchedule(
    id: 's2',
    vehicleId: 'v1',
    type: MaintenanceType.tireReplacement,
    dueAtKm: 55000,
    dueByDate: DateTime.now().add(const Duration(days: 45)),
    remainingKm: 5000,
    remainingDays: 45,
    isOverdue: false,
  );

  final testRecord = MaintenanceRecord(
    id: 'mr1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mileageAtService: 49000,
    serviceDate: DateTime(2024, 1, 10),
    cost: 350000,
    notes: 'Oli mesin',
  );

  final testRecord2 = MaintenanceRecord(
    id: 'mr2',
    vehicleId: 'v1',
    type: MaintenanceType.tireReplacement,
    mileageAtService: 48000,
    serviceDate: DateTime(2024, 1, 5),
    cost: 1200000,
  );

  setUp(() {
    mockGetSchedules = MockGetVehicleSchedulesUseCase();
    mockRecordMaintenance = MockRecordMaintenanceCompletedUseCase();
    mockHistoryRepo = MockMaintenanceHistoryRepository();
  });

  setUpAll(() {
    registerFallbackValue(MaintenanceType.oilChange);
  });

  MaintenanceBloc buildBloc() => MaintenanceBloc(
        mockGetSchedules,
        mockRecordMaintenance,
        mockHistoryRepo,
      );

  group('MaintenanceBloc', () {
    blocTest<MaintenanceBloc, MaintenanceState>(
      'LoadSchedules returns sorted schedules (overdue first)',
      build: () {
        when(() => mockGetSchedules.execute('v1'))
            .thenAnswer((_) async => [overdueSchedule, upcomingSchedule]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadSchedules('v1')),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceSchedulesLoaded>().having(
          (s) => s.schedules.first.isOverdue,
          'first is overdue',
          true,
        ),
      ],
    );

    blocTest<MaintenanceBloc, MaintenanceState>(
      'LoadSchedules emits error on failure',
      build: () {
        when(() => mockGetSchedules.execute('v1'))
            .thenThrow(Exception('Failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadSchedules('v1')),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceError>(),
      ],
    );

    blocTest<MaintenanceBloc, MaintenanceState>(
      'RecordMaintenance succeeds and reloads schedules',
      build: () {
        when(() => mockRecordMaintenance.execute(
              vehicleId: any(named: 'vehicleId'),
              type: any(named: 'type'),
              currentMileage: any(named: 'currentMileage'),
              serviceDate: any(named: 'serviceDate'),
              cost: any(named: 'cost'),
              notes: any(named: 'notes'),
              workshopName: any(named: 'workshopName'),
            )).thenAnswer((_) async {});
        when(() => mockGetSchedules.execute('v1'))
            .thenAnswer((_) async => [upcomingSchedule]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(RecordMaintenance(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mileageAtService: 49000,
        serviceDate: DateTime(2024, 1, 10),
        cost: 350000,
      )),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceRecorded>(),
        isA<MaintenanceLoading>(),
        isA<MaintenanceSchedulesLoaded>(),
      ],
    );

    blocTest<MaintenanceBloc, MaintenanceState>(
      'RecordMaintenance with future date emits error',
      build: () {
        when(() => mockRecordMaintenance.execute(
              vehicleId: any(named: 'vehicleId'),
              type: any(named: 'type'),
              currentMileage: any(named: 'currentMileage'),
              serviceDate: any(named: 'serviceDate'),
              cost: any(named: 'cost'),
              notes: any(named: 'notes'),
              workshopName: any(named: 'workshopName'),
            )).thenThrow(
            ArgumentError('Tanggal servis tidak boleh di masa depan'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(RecordMaintenance(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mileageAtService: 49000,
        serviceDate: DateTime.now().add(const Duration(days: 10)),
      )),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceError>(),
      ],
    );

    blocTest<MaintenanceBloc, MaintenanceState>(
      'LoadMaintenanceHistory returns records with total cost',
      build: () {
        when(() => mockHistoryRepo.getHistory(
              'v1',
              type: any(named: 'type'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => [testRecord, testRecord2]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadMaintenanceHistory(vehicleId: 'v1')),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceHistoryLoaded>()
            .having((s) => s.records.length, 'records', 2)
            .having((s) => s.totalCost, 'totalCost', 1550000),
      ],
    );

    blocTest<MaintenanceBloc, MaintenanceState>(
      'LoadMaintenanceHistory with type filter works',
      build: () {
        when(() => mockHistoryRepo.getHistory(
              'v1',
              type: MaintenanceType.oilChange,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => [testRecord]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadMaintenanceHistory(
        vehicleId: 'v1',
        filterType: MaintenanceType.oilChange,
      )),
      expect: () => [
        isA<MaintenanceLoading>(),
        isA<MaintenanceHistoryLoaded>()
            .having((s) => s.records.length, 'records', 1)
            .having((s) => s.totalCost, 'totalCost', 350000),
      ],
    );
  });
}
