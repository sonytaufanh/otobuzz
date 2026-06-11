import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/cost_report_repository.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/presentation/blocs/cost_report/cost_report_bloc.dart';
import 'package:otobuzz/presentation/blocs/cost_report/cost_report_event.dart';
import 'package:otobuzz/presentation/blocs/cost_report/cost_report_state.dart';

class MockCostReportRepository extends Mock implements CostReportRepository {}

void main() {
  late MockCostReportRepository mockRepo;

  final from = DateTime(2024, 1, 1);
  final to = DateTime(2024, 1, 31);

  final testByType = [
    CostByType(
      type: MaintenanceType.oilChange,
      totalCost: 350000,
      count: 2,
    ),
  ];

  final testByVehicle = [
    CostByVehicle(
      vehicleId: 'v1',
      vehicleName: 'Avanza',
      totalCost: 500000,
      count: 3,
    ),
  ];

  final testMonthly = [
    MonthlyCostSummary(month: 1, year: 2024, totalCost: 500000),
  ];

  setUp(() {
    mockRepo = MockCostReportRepository();
  });

  CostReportBloc buildBloc() => CostReportBloc(mockRepo);

  group('CostReportBloc', () {
    blocTest<CostReportBloc, CostReportState>(
      'LoadCostReport returns totals',
      build: () {
        when(() => mockRepo.getTotalCost(null, from, to))
            .thenAnswer((_) async => 500000.0);
        when(() => mockRepo.getCostByType(null, from, to))
            .thenAnswer((_) async => testByType);
        when(() => mockRepo.getCostByVehicle(from, to))
            .thenAnswer((_) async => testByVehicle);
        when(() => mockRepo.getMonthlyCostSummary(null, 2024))
            .thenAnswer((_) async => testMonthly);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadCostReport(from: from, to: to)),
      expect: () => [
        isA<CostReportLoading>(),
        isA<CostReportLoaded>()
            .having((s) => s.totalCost, 'totalCost', 500000.0)
            .having((s) => s.byType.length, 'byType', 1)
            .having((s) => s.byVehicle.length, 'byVehicle', 1),
      ],
    );

    blocTest<CostReportBloc, CostReportState>(
      'LoadCostReport with vehicle filter works',
      build: () {
        when(() => mockRepo.getTotalCost('v1', from, to))
            .thenAnswer((_) async => 350000.0);
        when(() => mockRepo.getCostByType('v1', from, to))
            .thenAnswer((_) async => testByType);
        when(() => mockRepo.getCostByVehicle(from, to))
            .thenAnswer((_) async => testByVehicle);
        when(() => mockRepo.getMonthlyCostSummary('v1', 2024))
            .thenAnswer((_) async => testMonthly);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(LoadCostReport(vehicleId: 'v1', from: from, to: to)),
      expect: () => [
        isA<CostReportLoading>(),
        isA<CostReportLoaded>()
            .having((s) => s.totalCost, 'totalCost', 350000.0)
            .having((s) => s.vehicleId, 'vehicleId', 'v1'),
      ],
    );

    blocTest<CostReportBloc, CostReportState>(
      'LoadCostReport emits error on failure',
      build: () {
        when(() => mockRepo.getTotalCost(any(), any(), any()))
            .thenThrow(Exception('DB error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadCostReport(from: from, to: to)),
      expect: () => [
        isA<CostReportLoading>(),
        isA<CostReportError>(),
      ],
    );

    blocTest<CostReportBloc, CostReportState>(
      'ChangePeriod triggers new LoadCostReport',
      build: () {
        when(() => mockRepo.getTotalCost(any(), any(), any()))
            .thenAnswer((_) async => 100000.0);
        when(() => mockRepo.getCostByType(any(), any(), any()))
            .thenAnswer((_) async => []);
        when(() => mockRepo.getCostByVehicle(any(), any()))
            .thenAnswer((_) async => []);
        when(() => mockRepo.getMonthlyCostSummary(any(), any()))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChangePeriod(CostReportPeriod.thisYear)),
      expect: () => [
        isA<CostReportLoading>(),
        isA<CostReportLoaded>(),
      ],
    );
  });
}
