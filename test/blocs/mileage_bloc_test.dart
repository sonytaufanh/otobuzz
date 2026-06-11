import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/mileage_record.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/mileage_repository.dart';
import 'package:otobuzz/domain/usecases/add_daily_mileage_usecase.dart';
import 'package:otobuzz/presentation/blocs/mileage/mileage_bloc.dart';
import 'package:otobuzz/presentation/blocs/mileage/mileage_event.dart';
import 'package:otobuzz/presentation/blocs/mileage/mileage_state.dart';

class MockAddDailyMileageUseCase extends Mock
    implements AddDailyMileageUseCase {}

class MockMileageRepository extends Mock implements MileageRepository {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  late MockAddDailyMileageUseCase mockUseCase;
  late MockMileageRepository mockRepo;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'Avanza',
    type: VehicleType.car,
    plateNumber: 'B 1234 XYZ',
    year: 2020,
    totalMileageKm: 50100,
    createdAt: DateTime(2020, 1, 1),
  );

  final testDate = DateTime(2024, 1, 15);

  final testRecord = MileageRecord(
    id: 'r1',
    vehicleId: 'v1',
    km: 50,
    date: testDate,
  );

  setUp(() {
    mockUseCase = MockAddDailyMileageUseCase();
    mockRepo = MockMileageRepository();
  });

  MileageBloc buildBloc() => MileageBloc(mockUseCase, mockRepo);

  group('MileageBloc', () {
    blocTest<MileageBloc, MileageState>(
      'AddMileage succeeds - use case is called correctly',
      build: () {
        when(() => mockUseCase.execute(
              vehicleId: any(named: 'vehicleId'),
              km: any(named: 'km'),
              date: any(named: 'date'),
              notes: any(named: 'notes'),
              replaceDuplicate: any(named: 'replaceDuplicate'),
            )).thenAnswer((_) async => testVehicle);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMileage(
        vehicleId: 'v1',
        km: 100,
        date: testDate,
      )),
      wait: const Duration(milliseconds: 300),
      verify: (_) {
        verify(() => mockUseCase.execute(
              vehicleId: 'v1',
              km: 100,
              date: testDate,
              notes: null,
              replaceDuplicate: false,
            )).called(1);
      },
    );

    blocTest<MileageBloc, MileageState>(
      'AddMileage with duplicate emits MileageDuplicateFound',
      build: () {
        when(() => mockUseCase.execute(
              vehicleId: any(named: 'vehicleId'),
              km: any(named: 'km'),
              date: any(named: 'date'),
              notes: any(named: 'notes'),
              replaceDuplicate: any(named: 'replaceDuplicate'),
            )).thenThrow(DuplicateEntryException('Sudah ada catatan'));
        when(() => mockRepo.getRecordByVehicleAndDate('v1', testDate))
            .thenAnswer((_) async => testRecord);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMileage(
        vehicleId: 'v1',
        km: 100,
        date: testDate,
      )),
      expect: () => [
        isA<MileageLoading>(),
        isA<MileageDuplicateFound>().having(
          (s) => s.existingKm,
          'existing km',
          50,
        ),
      ],
    );

    blocTest<MileageBloc, MileageState>(
      'AddMileage with replaceDuplicate calls use case with flag',
      build: () {
        when(() => mockUseCase.execute(
              vehicleId: any(named: 'vehicleId'),
              km: any(named: 'km'),
              date: any(named: 'date'),
              notes: any(named: 'notes'),
              replaceDuplicate: any(named: 'replaceDuplicate'),
            )).thenAnswer((_) async => testVehicle);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMileage(
        vehicleId: 'v1',
        km: 120,
        date: testDate,
        replaceDuplicate: true,
      )),
      wait: const Duration(milliseconds: 300),
      verify: (_) {
        verify(() => mockUseCase.execute(
              vehicleId: 'v1',
              km: 120,
              date: testDate,
              notes: null,
              replaceDuplicate: true,
            )).called(1);
      },
    );

    blocTest<MileageBloc, MileageState>(
      'AddMileage with invalid km emits MileageError',
      build: () {
        when(() => mockUseCase.execute(
              vehicleId: any(named: 'vehicleId'),
              km: any(named: 'km'),
              date: any(named: 'date'),
              notes: any(named: 'notes'),
              replaceDuplicate: any(named: 'replaceDuplicate'),
            )).thenThrow(ArgumentError('Masukkan jarak yang valid'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMileage(
        vehicleId: 'v1',
        km: -5,
        date: testDate,
      )),
      expect: () => [
        isA<MileageLoading>(),
        isA<MileageError>(),
      ],
    );

    blocTest<MileageBloc, MileageState>(
      'LoadMileageHistory returns records with stats',
      build: () {
        when(() => mockRepo.getMileageHistory(
              'v1',
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => [testRecord]);
        when(() => mockRepo.getTotalMileage('v1'))
            .thenAnswer((_) async => 50000.0);
        when(() => mockRepo.getAverageDailyMileage('v1'))
            .thenAnswer((_) async => 45.0);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadMileageHistory(vehicleId: 'v1')),
      expect: () => [
        isA<MileageLoading>(),
        isA<MileageHistoryLoaded>()
            .having((s) => s.records.length, 'records', 1)
            .having((s) => s.totalKm, 'totalKm', 50000.0)
            .having((s) => s.avgDailyKm, 'avgDailyKm', 45.0),
      ],
    );

    blocTest<MileageBloc, MileageState>(
      'LoadMileageHistory emits error on failure',
      build: () {
        when(() => mockRepo.getMileageHistory(
              'v1',
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenThrow(Exception('DB error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadMileageHistory(vehicleId: 'v1')),
      expect: () => [
        isA<MileageLoading>(),
        isA<MileageError>(),
      ],
    );

    blocTest<MileageBloc, MileageState>(
      'CheckDuplicateEntry emits MileageDuplicateFound when exists',
      build: () {
        when(() => mockUseCase.checkDuplicateEntry('v1', testDate))
            .thenAnswer((_) async => true);
        when(() => mockRepo.getRecordByVehicleAndDate('v1', testDate))
            .thenAnswer((_) async => testRecord);
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckDuplicateEntry(
        vehicleId: 'v1',
        date: testDate,
      )),
      expect: () => [
        isA<MileageDuplicateFound>().having(
          (s) => s.existingKm,
          'existing km',
          50,
        ),
      ],
    );

    blocTest<MileageBloc, MileageState>(
      'CheckDuplicateEntry emits nothing when not exists',
      build: () {
        when(() => mockUseCase.checkDuplicateEntry('v1', testDate))
            .thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(CheckDuplicateEntry(
        vehicleId: 'v1',
        date: testDate,
      )),
      expect: () => <MileageState>[],
    );

    blocTest<MileageBloc, MileageState>(
      'AddMileage with general exception emits MileageError',
      build: () {
        when(() => mockUseCase.execute(
              vehicleId: any(named: 'vehicleId'),
              km: any(named: 'km'),
              date: any(named: 'date'),
              notes: any(named: 'notes'),
              replaceDuplicate: any(named: 'replaceDuplicate'),
            )).thenThrow(Exception('Network error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMileage(
        vehicleId: 'v1',
        km: 50,
        date: testDate,
      )),
      expect: () => [
        isA<MileageLoading>(),
        isA<MileageError>(),
      ],
    );
  });
}
