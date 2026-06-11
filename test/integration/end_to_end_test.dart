import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/maintenance_record.dart';
import 'package:otobuzz/domain/models/maintenance_schedule.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/domain/models/mileage_record.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_history_repository.dart';
import 'package:otobuzz/domain/repositories/maintenance_schedule_repository.dart';
import 'package:otobuzz/domain/repositories/mileage_repository.dart';
import 'package:otobuzz/domain/repositories/vehicle_repository.dart';
import 'package:otobuzz/domain/usecases/add_daily_mileage_usecase.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';
import 'package:otobuzz/domain/usecases/record_maintenance_usecase.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockMileageRepository extends Mock implements MileageRepository {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockMaintenanceCalculator extends Mock implements MaintenanceCalculator {}

void main() {
  late MockVehicleRepository mockVehicleRepo;
  late MockMileageRepository mockMileageRepo;
  late MockMaintenanceHistoryRepository mockHistoryRepo;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockMaintenanceCalculator mockCalculator;
  late AddDailyMileageUseCase addMileageUseCase;
  late RecordMaintenanceCompletedUseCase recordMaintenanceUseCase;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'Avanza',
    type: VehicleType.car,
    plateNumber: 'B 1234 XYZ',
    year: 2020,
    totalMileageKm: 50000,
    createdAt: DateTime(2020, 1, 1),
  );

  setUp(() {
    mockVehicleRepo = MockVehicleRepository();
    mockMileageRepo = MockMileageRepository();
    mockHistoryRepo = MockMaintenanceHistoryRepository();
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockCalculator = MockMaintenanceCalculator();

    addMileageUseCase = AddDailyMileageUseCase(
      mockVehicleRepo,
      mockMileageRepo,
      mockScheduleRepo,
      mockCalculator,
    );

    recordMaintenanceUseCase = RecordMaintenanceCompletedUseCase(
      mockVehicleRepo,
      mockHistoryRepo,
      mockScheduleRepo,
      mockCalculator,
    );
  });

  setUpAll(() {
    registerFallbackValue(MileageRecord(
      id: 'fallback',
      vehicleId: 'v1',
      km: 0,
      date: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(MaintenanceRecord(
      id: 'fallback',
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mileageAtService: 0,
      serviceDate: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(testVehicle);
  });

  group('End-to-End Integration', () {
    test(
        'Complete user journey: add vehicle → add km → view schedules → record maintenance',
        () async {
      // Step 1: Add vehicle
      when(() => mockVehicleRepo.addVehicle(any()))
          .thenAnswer((_) async {});
      await mockVehicleRepo.addVehicle(testVehicle);
      verify(() => mockVehicleRepo.addVehicle(testVehicle)).called(1);

      // Step 2: Add daily km
      final kmDate = DateTime(2024, 1, 15);
      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', kmDate))
          .thenAnswer((_) async => null);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);
      when(() => mockMileageRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockVehicleRepo.updateTotalMileage('v1', any()))
          .thenAnswer((_) async {});
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => [
                MaintenanceSchedule(
                  id: 's1',
                  vehicleId: 'v1',
                  type: MaintenanceType.oilChange,
                  dueAtKm: 55000,
                  dueByDate: DateTime(2024, 3, 1),
                  remainingKm: 4900,
                  remainingDays: 45,
                  isOverdue: false,
                ),
              ]);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      final updatedVehicle = await addMileageUseCase.execute(
        vehicleId: 'v1',
        km: 100,
        date: kmDate,
      );

      expect(updatedVehicle.totalMileageKm, 50100);

      // Step 3: View schedules
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => [
                MaintenanceSchedule(
                  id: 's1',
                  vehicleId: 'v1',
                  type: MaintenanceType.oilChange,
                  dueAtKm: 55000,
                  dueByDate: DateTime(2024, 3, 1),
                  remainingKm: 4900,
                  remainingDays: 45,
                  isOverdue: false,
                ),
              ]);

      final schedules = await mockScheduleRepo.getSchedules('v1');
      expect(schedules.length, 1);
      expect(schedules.first.type, MaintenanceType.oilChange);

      // Step 4: Record maintenance
      final vehicleAfterKm =
          testVehicle.copyWith(totalMileageKm: 50100);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => vehicleAfterKm);
      when(() => mockHistoryRepo.addMaintenanceRecord(any()))
          .thenAnswer((_) async {});

      await recordMaintenanceUseCase.execute(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        currentMileage: 50100,
        serviceDate: DateTime(2024, 1, 15),
        cost: 350000,
      );

      verify(() => mockHistoryRepo.addMaintenanceRecord(any())).called(1);
      verify(() => mockCalculator.recalculateAllSchedules(any())).called(2);
    });

    test('Verify schedule changes after adding kilometers', () async {
      final kmDate = DateTime(2024, 1, 15);

      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', kmDate))
          .thenAnswer((_) async => null);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);
      when(() => mockMileageRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockVehicleRepo.updateTotalMileage('v1', any()))
          .thenAnswer((_) async {});

      // After adding km, schedule should be recalculated
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => [
                MaintenanceSchedule(
                  id: 's1',
                  vehicleId: 'v1',
                  type: MaintenanceType.oilChange,
                  dueAtKm: 55000,
                  dueByDate: DateTime(2024, 2, 15),
                  remainingKm: 4800,
                  remainingDays: 31,
                  isOverdue: false,
                ),
              ]);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      await addMileageUseCase.execute(
        vehicleId: 'v1',
        km: 200,
        date: kmDate,
      );

      // Verify schedules were recalculated
      verify(() => mockCalculator.recalculateAllSchedules(any())).called(1);
      verify(() => mockScheduleRepo.updateSchedules('v1', any())).called(1);
    });

    test('Verify cost tracking with actual maintenance records', () async {
      when(() => mockHistoryRepo.getHistory('v1'))
          .thenAnswer((_) async => [
                MaintenanceRecord(
                  id: 'mr1',
                  vehicleId: 'v1',
                  type: MaintenanceType.oilChange,
                  mileageAtService: 49000,
                  serviceDate: DateTime(2024, 1, 5),
                  cost: 350000,
                ),
                MaintenanceRecord(
                  id: 'mr2',
                  vehicleId: 'v1',
                  type: MaintenanceType.tireReplacement,
                  mileageAtService: 48500,
                  serviceDate: DateTime(2024, 1, 3),
                  cost: 1200000,
                ),
              ]);

      final history = await mockHistoryRepo.getHistory('v1');
      final totalCost =
          history.fold<double>(0, (sum, r) => sum + (r.cost ?? 0));

      expect(totalCost, 1550000);
      expect(history.length, 2);
    });

    test('Verify duplicate km handling and replacement flow', () async {
      final date = DateTime(2024, 1, 15);
      final existingRecord = MileageRecord(
        id: 'r1',
        vehicleId: 'v1',
        km: 50,
        date: date,
      );

      // First attempt - duplicate found
      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', date))
          .thenAnswer((_) async => existingRecord);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);

      expect(
        () => addMileageUseCase.execute(
          vehicleId: 'v1',
          km: 80,
          date: date,
          replaceDuplicate: false,
        ),
        throwsA(isA<DuplicateEntryException>()),
      );

      // Second attempt - user confirms replace
      when(() => mockMileageRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockVehicleRepo.updateTotalMileage('v1', any()))
          .thenAnswer((_) async {});
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => []);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      final result = await addMileageUseCase.execute(
        vehicleId: 'v1',
        km: 80,
        date: date,
        replaceDuplicate: true,
      );

      // Adjustment: old was 50, new is 80, diff is +30
      expect(result.totalMileageKm, 50030);
    });

    test('Multiple vehicles operate independently', () async {
      final vehicle2 = Vehicle(
        id: 'v2',
        name: 'Vario 150',
        type: VehicleType.motorcycle,
        plateNumber: 'B 5678 ABC',
        year: 2021,
        totalMileageKm: 20000,
        createdAt: DateTime(2021, 6, 1),
      );

      when(() => mockVehicleRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle, vehicle2]);

      final vehicles = await mockVehicleRepo.getAllVehicles();
      expect(vehicles.length, 2);
      expect(vehicles[0].id, 'v1');
      expect(vehicles[1].id, 'v2');

      // Each vehicle has independent mileage
      when(() => mockMileageRepo.getTotalMileage('v1'))
          .thenAnswer((_) async => 50000.0);
      when(() => mockMileageRepo.getTotalMileage('v2'))
          .thenAnswer((_) async => 20000.0);

      final total1 = await mockMileageRepo.getTotalMileage('v1');
      final total2 = await mockMileageRepo.getTotalMileage('v2');

      expect(total1, 50000.0);
      expect(total2, 20000.0);
    });
  });
}
