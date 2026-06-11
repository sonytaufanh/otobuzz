import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/mileage_record.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_schedule_repository.dart';
import 'package:otobuzz/domain/repositories/mileage_repository.dart';
import 'package:otobuzz/domain/repositories/vehicle_repository.dart';
import 'package:otobuzz/domain/usecases/add_daily_mileage_usecase.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockMileageRepository extends Mock implements MileageRepository {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockMaintenanceCalculator extends Mock implements MaintenanceCalculator {}

void main() {
  late MockVehicleRepository mockVehicleRepo;
  late MockMileageRepository mockMileageRepo;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockMaintenanceCalculator mockCalculator;
  late AddDailyMileageUseCase useCase;

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
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockCalculator = MockMaintenanceCalculator();
    useCase = AddDailyMileageUseCase(
      mockVehicleRepo,
      mockMileageRepo,
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
    registerFallbackValue(testVehicle);
  });

  group('AddDailyMileageUseCase', () {
    test('valid input succeeds', () async {
      final date = DateTime(2024, 1, 15);
      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', date))
          .thenAnswer((_) async => null);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);
      when(() => mockMileageRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockVehicleRepo.updateTotalMileage('v1', any()))
          .thenAnswer((_) async {});
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => []);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      final result = await useCase.execute(
        vehicleId: 'v1',
        km: 100,
        date: date,
      );

      expect(result.totalMileageKm, 50100);
      verify(() => mockMileageRepo.upsertMileageRecord(any())).called(1);
    });

    test('km <= 0 throws ArgumentError', () async {
      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          km: 0,
          date: DateTime(2024, 1, 15),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('km > 2000 throws ArgumentError', () async {
      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          km: 2001,
          date: DateTime(2024, 1, 15),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('future date throws ArgumentError', () async {
      final futureDate = DateTime.now().add(const Duration(days: 5));

      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          km: 50,
          date: futureDate,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('duplicate without replace throws DuplicateEntryException', () async {
      final date = DateTime(2024, 1, 15);
      final existingRecord = MileageRecord(
        id: 'r1',
        vehicleId: 'v1',
        km: 50,
        date: date,
      );

      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', date))
          .thenAnswer((_) async => existingRecord);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);

      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          km: 80,
          date: date,
          replaceDuplicate: false,
        ),
        throwsA(isA<DuplicateEntryException>()),
      );
    });

    test('duplicate with replace succeeds and adjusts total', () async {
      final date = DateTime(2024, 1, 15);
      final existingRecord = MileageRecord(
        id: 'r1',
        vehicleId: 'v1',
        km: 50,
        date: date,
      );

      when(() => mockMileageRepo.getRecordByVehicleAndDate('v1', date))
          .thenAnswer((_) async => existingRecord);
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);
      when(() => mockMileageRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockVehicleRepo.updateTotalMileage('v1', any()))
          .thenAnswer((_) async {});
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => []);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      final result = await useCase.execute(
        vehicleId: 'v1',
        km: 80,
        date: date,
        replaceDuplicate: true,
      );

      // Total should be 50000 + (80 - 50) = 50030
      expect(result.totalMileageKm, 50030);
      verify(() => mockVehicleRepo.updateTotalMileage('v1', 50030)).called(1);
    });

    test('non-existent vehicle throws ArgumentError', () async {
      final date = DateTime(2024, 1, 15);
      when(() => mockMileageRepo.getRecordByVehicleAndDate('v999', date))
          .thenAnswer((_) async => null);
      when(() => mockVehicleRepo.getVehicleById('v999'))
          .thenAnswer((_) async => null);

      expect(
        () => useCase.execute(
          vehicleId: 'v999',
          km: 50,
          date: date,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
