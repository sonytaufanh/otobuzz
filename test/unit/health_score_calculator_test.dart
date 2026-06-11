import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/custom_interval_repository.dart';
import 'package:otobuzz/data/repositories/vehicle_document_repository.dart';
import 'package:otobuzz/domain/models/models.dart';
import 'package:otobuzz/domain/repositories/repositories.dart';
import 'package:otobuzz/domain/usecases/health_score_calculator.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';

class MockMileageRepository extends Mock implements MileageRepository {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

class MockVehicleDocumentRepository extends Mock
    implements VehicleDocumentRepository {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockCustomIntervalRepository extends Mock
    implements CustomIntervalRepository {}

void main() {
  late MockMileageRepository mockMileageRepo;
  late MockMaintenanceHistoryRepository mockHistoryRepo;
  late MockVehicleDocumentRepository mockDocRepo;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockCustomIntervalRepository mockCustomIntervalRepo;
  late MaintenanceCalculator maintenanceCalculator;
  late HealthScoreCalculator calculator;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'Honda Beat',
    type: VehicleType.motorcycle,
    plateNumber: 'B 1234 ABC',
    year: 2022,
    totalMileageKm: 10000,
    createdAt: DateTime(2022, 1, 1),
  );

  setUp(() {
    mockMileageRepo = MockMileageRepository();
    mockHistoryRepo = MockMaintenanceHistoryRepository();
    mockDocRepo = MockVehicleDocumentRepository();
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockCustomIntervalRepo = MockCustomIntervalRepository();

    maintenanceCalculator = MaintenanceCalculator(
      mockMileageRepo,
      mockHistoryRepo,
      customIntervalRepository: mockCustomIntervalRepo,
    );

    calculator = HealthScoreCalculator(
      maintenanceCalculator: maintenanceCalculator,
      mileageRepository: mockMileageRepo,
      documentRepository: mockDocRepo,
      scheduleRepository: mockScheduleRepo,
    );
  });

  group('calculateScore', () {
    test('all items on-time should produce high score', () async {
      // All schedules not overdue and with plenty of remaining km
      final schedules = MaintenanceType.values.map((type) {
        return MaintenanceSchedule(
          id: 'sched-$type',
          vehicleId: 'v1',
          type: type,
          dueAtKm: 15000,
          dueByDate: DateTime.now().add(const Duration(days: 90)),
          remainingKm: 5000, // Well above half of any interval
          remainingDays: 90,
          isOverdue: false,
        );
      }).toList();

      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => schedules);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);

      // 10 days of mileage records for consistency bonus
      final now = DateTime.now();
      final mileageRecords = List.generate(
        10,
        (i) => MileageRecord(
          id: 'mr-$i',
          vehicleId: 'v1',
          km: 50,
          date: now.subtract(Duration(days: i)),
        ),
      );
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => mileageRecords);

      final result = await calculator.calculateScore(testVehicle);

      // Should be high score (>= 90)
      expect(result.score, greaterThanOrEqualTo(90));
      expect(result.grade, 'A');
    });

    test('overdue items should lower score with penalty', () async {
      // 3 overdue schedules
      final schedules = [
        MaintenanceSchedule(
          id: 'sched-1',
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          dueAtKm: 9000,
          dueByDate: DateTime.now().subtract(const Duration(days: 10)),
          remainingKm: 0,
          remainingDays: 0,
          isOverdue: true,
        ),
        MaintenanceSchedule(
          id: 'sched-2',
          vehicleId: 'v1',
          type: MaintenanceType.brakePads,
          dueAtKm: 8500,
          dueByDate: DateTime.now().subtract(const Duration(days: 20)),
          remainingKm: 0,
          remainingDays: 0,
          isOverdue: true,
        ),
        MaintenanceSchedule(
          id: 'sched-3',
          vehicleId: 'v1',
          type: MaintenanceType.airFilter,
          dueAtKm: 9500,
          dueByDate: DateTime.now().add(const Duration(days: 60)),
          remainingKm: 3000,
          remainingDays: 60,
          isOverdue: false,
        ),
      ];

      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => schedules);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      final result = await calculator.calculateScore(testVehicle);

      // 2 overdue items * 15 penalty = 30 penalty
      // Score should be noticeably lower
      expect(result.score, lessThan(80));
      expect(result.issues, isNotEmpty);
    });

    test('expired documents should apply penalty', () async {
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => []);
      when(() => mockDocRepo.getDocuments('v1')).thenAnswer((_) async => [
            VehicleDocument(
              id: 'doc-1',
              vehicleId: 'v1',
              documentType: DocumentType.pajak,
              expiryDate: DateTime.now().subtract(const Duration(days: 30)),
            ),
            VehicleDocument(
              id: 'doc-2',
              vehicleId: 'v1',
              documentType: DocumentType.stnk,
              expiryDate: DateTime.now().subtract(const Duration(days: 10)),
            ),
          ]);
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      final result = await calculator.calculateScore(testVehicle);

      // Both pajak and stnk expired = 20 penalty
      expect(result.score, lessThanOrEqualTo(80));
      expect(result.breakdown.pajakExpired, true);
      expect(result.breakdown.stnkExpired, true);
      expect(result.breakdown.documentPenalty, 20);
    });

    test('consistency bonus awarded for 7+ days logging', () async {
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => []);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);

      final now = DateTime.now();
      final mileageRecords = List.generate(
        8,
        (i) => MileageRecord(
          id: 'mr-$i',
          vehicleId: 'v1',
          km: 50,
          date: now.subtract(Duration(days: i)),
        ),
      );
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => mileageRecords);

      final result = await calculator.calculateScore(testVehicle);

      expect(result.breakdown.consistencyBonus, 10);
      expect(result.breakdown.kmLoggingStreak, greaterThanOrEqualTo(7));
    });

    test('grade boundaries are correct', () async {
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => []);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      final result = await calculator.calculateScore(testVehicle);

      // With no schedules, no docs, no mileage: score = 100 + 0 - 0 - 0 + 0 = 100
      // But no consistency bonus since 0 days logged
      // Score should be 100 (no penalties, no bonuses except consistency=0)
      expect(result.score, 100);
      expect(result.grade, 'A');
      expect(result.description, 'Sangat Baik');
    });
  });
}
