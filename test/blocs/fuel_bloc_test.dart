import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/fuel_repository.dart';
import 'package:otobuzz/domain/models/fuel_record.dart';
import 'package:otobuzz/domain/models/fuel_statistics.dart';
import 'package:otobuzz/presentation/blocs/fuel/fuel_bloc.dart';
import 'package:otobuzz/presentation/blocs/fuel/fuel_event.dart';
import 'package:otobuzz/presentation/blocs/fuel/fuel_state.dart';

class MockFuelRepository extends Mock implements FuelRepository {}

void main() {
  late MockFuelRepository mockRepo;

  final testRecord = FuelRecord(
    id: 'f1',
    vehicleId: 'v1',
    liters: 40,
    pricePerLiter: 13000,
    totalCost: 520000,
    odometerKm: 50000,
    date: DateTime(2024, 1, 15),
    isFullTank: true,
  );

  final testRecord2 = FuelRecord(
    id: 'f2',
    vehicleId: 'v1',
    liters: 35,
    pricePerLiter: 13000,
    totalCost: 455000,
    odometerKm: 50500,
    date: DateTime(2024, 1, 20),
    isFullTank: true,
  );

  final testStats = FuelStatistics(
    averageKmPerLiter: 12.5,
    totalLiters: 75,
    totalCost: 975000,
    averageCostPerKm: 1040,
    trend: 'stable',
    monthlySummaries: [],
  );

  setUp(() {
    mockRepo = MockFuelRepository();
  });

  setUpAll(() {
    registerFallbackValue(testRecord);
  });

  FuelBloc buildBloc() => FuelBloc(mockRepo);

  group('FuelBloc', () {
    blocTest<FuelBloc, FuelState>(
      'AddFuelRecord succeeds and reloads records',
      build: () {
        when(() => mockRepo.insertFuelRecord(any()))
            .thenAnswer((_) async {});
        when(() => mockRepo.getFuelRecords('v1'))
            .thenAnswer((_) async => [testRecord, testRecord2]);
        when(() => mockRepo.getStatistics('v1'))
            .thenAnswer((_) async => testStats);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddFuelRecord(testRecord)),
      expect: () => [
        isA<FuelLoading>(),
        isA<FuelLoaded>().having(
          (s) => s.records.length,
          'records',
          2,
        ),
      ],
    );

    blocTest<FuelBloc, FuelState>(
      'LoadFuelRecords returns records with statistics',
      build: () {
        when(() => mockRepo.getFuelRecords('v1'))
            .thenAnswer((_) async => [testRecord, testRecord2]);
        when(() => mockRepo.getStatistics('v1'))
            .thenAnswer((_) async => testStats);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadFuelRecords('v1')),
      expect: () => [
        isA<FuelLoading>(),
        isA<FuelLoaded>()
            .having((s) => s.records.length, 'records', 2)
            .having(
                (s) => s.statistics.averageKmPerLiter, 'kmPerLiter', 12.5),
      ],
    );

    blocTest<FuelBloc, FuelState>(
      'LoadFuelStatistics returns correct values',
      build: () {
        when(() => mockRepo.getFuelRecords('v1'))
            .thenAnswer((_) async => [testRecord, testRecord2]);
        when(() => mockRepo.getStatistics(
              'v1',
              start: any(named: 'start'),
              end: any(named: 'end'),
            )).thenAnswer((_) async => testStats);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadFuelStatistics(
        'v1',
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      )),
      expect: () => [
        isA<FuelLoading>(),
        isA<FuelLoaded>()
            .having((s) => s.statistics.totalCost, 'totalCost', 975000)
            .having((s) => s.statistics.trend, 'trend', 'stable'),
      ],
    );

    blocTest<FuelBloc, FuelState>(
      'LoadFuelRecords emits error on failure',
      build: () {
        when(() => mockRepo.getFuelRecords('v1'))
            .thenThrow(Exception('DB error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadFuelRecords('v1')),
      expect: () => [
        isA<FuelLoading>(),
        isA<FuelError>(),
      ],
    );

    blocTest<FuelBloc, FuelState>(
      'DeleteFuelRecord succeeds and reloads',
      build: () {
        when(() => mockRepo.deleteFuelRecord('f1'))
            .thenAnswer((_) async {});
        when(() => mockRepo.getFuelRecords('v1'))
            .thenAnswer((_) async => [testRecord2]);
        when(() => mockRepo.getStatistics('v1'))
            .thenAnswer((_) async => testStats);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const DeleteFuelRecord(id: 'f1', vehicleId: 'v1')),
      expect: () => [
        isA<FuelLoading>(),
        isA<FuelLoaded>().having((s) => s.records.length, 'records', 1),
      ],
    );
  });
}
