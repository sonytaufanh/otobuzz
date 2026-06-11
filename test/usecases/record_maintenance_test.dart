import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/maintenance_record.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_history_repository.dart';
import 'package:otobuzz/domain/repositories/maintenance_schedule_repository.dart';
import 'package:otobuzz/domain/repositories/vehicle_repository.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';
import 'package:otobuzz/domain/usecases/record_maintenance_usecase.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockMaintenanceCalculator extends Mock implements MaintenanceCalculator {}

void main() {
  late MockVehicleRepository mockVehicleRepo;
  late MockMaintenanceHistoryRepository mockHistoryRepo;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockMaintenanceCalculator mockCalculator;
  late RecordMaintenanceCompletedUseCase useCase;

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
    mockHistoryRepo = MockMaintenanceHistoryRepository();
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockCalculator = MockMaintenanceCalculator();
    useCase = RecordMaintenanceCompletedUseCase(
      mockVehicleRepo,
      mockHistoryRepo,
      mockScheduleRepo,
      mockCalculator,
    );
  });

  setUpAll(() {
    registerFallbackValue(MaintenanceRecord(
      id: 'fallback',
      vehicleId: 'v1',
      type: MaintenanceType.oilChange,
      mileageAtService: 0,
      serviceDate: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(testVehicle);
  });

  group('RecordMaintenanceCompletedUseCase', () {
    test('valid recording succeeds', () async {
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);
      when(() => mockHistoryRepo.addMaintenanceRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockCalculator.recalculateAllSchedules(any()))
          .thenAnswer((_) async => []);
      when(() => mockScheduleRepo.updateSchedules('v1', any()))
          .thenAnswer((_) async {});

      await useCase.execute(
        vehicleId: 'v1',
        type: MaintenanceType.oilChange,
        currentMileage: 49000,
        serviceDate: DateTime(2024, 1, 10),
        cost: 350000,
        notes: 'Oli Shell',
      );

      verify(() => mockHistoryRepo.addMaintenanceRecord(any())).called(1);
      verify(() => mockCalculator.recalculateAllSchedules(any())).called(1);
    });

    test('future service date throws ArgumentError', () async {
      final futureDate = DateTime.now().add(const Duration(days: 10));

      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          currentMileage: 49000,
          serviceDate: futureDate,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('mileage > vehicle total throws ArgumentError', () async {
      when(() => mockVehicleRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);

      expect(
        () => useCase.execute(
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          currentMileage: 60000, // More than vehicle's 50000
          serviceDate: DateTime(2024, 1, 10),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('non-existent vehicle throws ArgumentError', () async {
      when(() => mockVehicleRepo.getVehicleById('v999'))
          .thenAnswer((_) async => null);

      expect(
        () => useCase.execute(
          vehicleId: 'v999',
          type: MaintenanceType.oilChange,
          currentMileage: 49000,
          serviceDate: DateTime(2024, 1, 10),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
