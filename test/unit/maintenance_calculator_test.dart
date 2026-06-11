import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/custom_interval_repository.dart';
import 'package:otobuzz/domain/models/models.dart';
import 'package:otobuzz/domain/repositories/repositories.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';

class MockMileageRepository extends Mock implements MileageRepository {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

class MockCustomIntervalRepository extends Mock
    implements CustomIntervalRepository {}

void main() {
  late MockMileageRepository mockMileageRepo;
  late MockMaintenanceHistoryRepository mockHistoryRepo;
  late MockCustomIntervalRepository mockCustomIntervalRepo;
  late MaintenanceCalculator calculator;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'Honda Beat',
    type: VehicleType.motorcycle,
    plateNumber: 'B 1234 ABC',
    year: 2022,
    totalMileageKm: 10000,
    createdAt: DateTime(2022, 1, 1),
  );

  final testCarVehicle = Vehicle(
    id: 'v2',
    name: 'Toyota Avanza',
    type: VehicleType.car,
    plateNumber: 'B 5678 DEF',
    year: 2021,
    totalMileageKm: 25000,
    createdAt: DateTime(2021, 6, 1),
  );

  final oilInterval = const MaintenanceInterval(
    type: MaintenanceType.oilChange,
    vehicleType: VehicleType.motorcycle,
    kmInterval: 2000,
    monthsInterval: 3,
    warningBeforeKm: 200,
    warningBeforeDays: 14,
  );

  setUp(() {
    mockMileageRepo = MockMileageRepository();
    mockHistoryRepo = MockMaintenanceHistoryRepository();
    mockCustomIntervalRepo = MockCustomIntervalRepository();
    calculator = MaintenanceCalculator(
      mockMileageRepo,
      mockHistoryRepo,
      customIntervalRepository: mockCustomIntervalRepo,
    );
  });

  setUpAll(() {
    registerFallbackValue(MaintenanceType.oilChange);
  });

  group('calculateNextMaintenanceSchedule', () {
    test('normal case - calculates correct due km and remaining', () {
      final lastService = MaintenanceRecord(
        id: 'r1',
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mileageAtService: 8000,
        serviceDate: DateTime(2024, 6, 1),
      );

      final schedule = calculator.calculateNextMaintenanceSchedule(
        type: MaintenanceType.oilChange,
        vehicle: testVehicle,
        lastService: lastService,
        interval: oilInterval,
        avgDailyKm: 50,
      );

      expect(schedule.dueAtKm, 10000); // 8000 + 2000
      expect(schedule.remainingKm, 0); // 10000 - 10000 = 0, clamped to 0
      expect(schedule.vehicleId, 'v1');
      expect(schedule.type, MaintenanceType.oilChange);
    });

    test('overdue case - vehicle km exceeds due km', () {
      final lastService = MaintenanceRecord(
        id: 'r2',
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mileageAtService: 7000,
        serviceDate: DateTime(2024, 1, 1),
      );

      final schedule = calculator.calculateNextMaintenanceSchedule(
        type: MaintenanceType.oilChange,
        vehicle: testVehicle,
        lastService: lastService,
        interval: oilInterval,
        avgDailyKm: 50,
      );

      // dueAtKm = 7000 + 2000 = 9000, vehicle is at 10000
      expect(schedule.dueAtKm, 9000);
      expect(schedule.isOverdue, true);
    });

    test('no prior service - uses vehicle creation as baseline', () {
      final schedule = calculator.calculateNextMaintenanceSchedule(
        type: MaintenanceType.oilChange,
        vehicle: testVehicle,
        lastService: null,
        interval: oilInterval,
        avgDailyKm: 50,
      );

      // dueAtKm = 0 (no last service mileage) + 2000 = 2000
      expect(schedule.dueAtKm, 2000);
      // vehicle is at 10000, so this is definitely overdue
      expect(schedule.isOverdue, true);
    });

    test('zero avgDailyKm - estimatedDueDate is null', () {
      final lastService = MaintenanceRecord(
        id: 'r3',
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        mileageAtService: 9500,
        serviceDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      final schedule = calculator.calculateNextMaintenanceSchedule(
        type: MaintenanceType.oilChange,
        vehicle: testVehicle,
        lastService: lastService,
        interval: oilInterval,
        avgDailyKm: 0,
      );

      expect(schedule.estimatedDueDate, isNull);
    });
  });

  group('recalculateAllSchedules', () {
    test('motorcycle types include chainLube', () async {
      when(() => mockMileageRepo.getAverageDailyMileage('v1', lastDays: 30))
          .thenAnswer((_) async => 50.0);
      when(() => mockHistoryRepo.getLastMaintenanceByType('v1'))
          .thenAnswer((_) async => {});
      when(() => mockCustomIntervalRepo.getCustomInterval(any(), any()))
          .thenAnswer((_) async => null);

      final schedules = await calculator.recalculateAllSchedules(testVehicle);

      // Motorcycle should have all 9 types including chainLube
      final types = schedules.map((s) => s.type).toSet();
      expect(types.contains(MaintenanceType.chainLube), true);
      expect(schedules.length, MaintenanceType.values.length);
    });

    test('car types exclude chainLube', () async {
      when(() => mockMileageRepo.getAverageDailyMileage('v2', lastDays: 30))
          .thenAnswer((_) async => 30.0);
      when(() => mockHistoryRepo.getLastMaintenanceByType('v2'))
          .thenAnswer((_) async => {});
      when(() => mockCustomIntervalRepo.getCustomInterval(any(), any()))
          .thenAnswer((_) async => null);

      final schedules =
          await calculator.recalculateAllSchedules(testCarVehicle);

      // Car should not have chainLube
      final types = schedules.map((s) => s.type).toSet();
      expect(types.contains(MaintenanceType.chainLube), false);
      expect(schedules.length, MaintenanceType.values.length - 1);
    });
  });

  group('predictDueDate', () {
    test('positive case - returns future date', () {
      final result = calculator.predictDueDate(
        remainingKm: 1000,
        avgDailyKm: 50,
      );

      expect(result, isNotNull);
      // Should be approximately 20 days from now
      final daysUntil = result!.difference(DateTime.now()).inDays;
      expect(daysUntil, greaterThanOrEqualTo(19));
      expect(daysUntil, lessThanOrEqualTo(21));
    });

    test('zero avgDailyKm - returns null', () {
      final result = calculator.predictDueDate(
        remainingKm: 1000,
        avgDailyKm: 0,
      );

      expect(result, isNull);
    });

    test('negative remainingKm (overdue) - returns null', () {
      final result = calculator.predictDueDate(
        remainingKm: -500,
        avgDailyKm: 50,
      );

      expect(result, isNull);
    });
  });
}
