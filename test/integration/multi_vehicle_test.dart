import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:otobuzz/data/database/database_helper.dart';
import 'package:otobuzz/data/repositories/maintenance_history_repository_impl.dart';
import 'package:otobuzz/data/repositories/maintenance_schedule_repository_impl.dart';
import 'package:otobuzz/data/repositories/mileage_repository_impl.dart';
import 'package:otobuzz/data/repositories/vehicle_repository_impl.dart';
import 'package:otobuzz/domain/models/models.dart';
import 'package:otobuzz/domain/usecases/usecases.dart';

void main() {
  late Database db;
  late DatabaseHelper dbHelper;
  late VehicleRepositoryImpl vehicleRepo;
  late MileageRepositoryImpl mileageRepo;
  late MaintenanceHistoryRepositoryImpl maintenanceHistoryRepo;
  late MaintenanceScheduleRepositoryImpl scheduleRepo;
  late MaintenanceCalculator calculator;
  late AddDailyMileageUseCase addMileageUseCase;
  late RecordMaintenanceCompletedUseCase recordMaintenanceUseCase;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await DatabaseHelper.createTables(db);
        },
      ),
    );

    dbHelper = DatabaseHelper.withDatabase(db);
    vehicleRepo = VehicleRepositoryImpl(dbHelper);
    mileageRepo = MileageRepositoryImpl(dbHelper);
    maintenanceHistoryRepo = MaintenanceHistoryRepositoryImpl(dbHelper);
    scheduleRepo = MaintenanceScheduleRepositoryImpl(dbHelper);
    calculator = MaintenanceCalculator(mileageRepo, maintenanceHistoryRepo);
    addMileageUseCase = AddDailyMileageUseCase(
      vehicleRepo,
      mileageRepo,
      scheduleRepo,
      calculator,
    );
    recordMaintenanceUseCase = RecordMaintenanceCompletedUseCase(
      vehicleRepo,
      maintenanceHistoryRepo,
      scheduleRepo,
      calculator,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Multi-Vehicle Isolation Test', () {
    late Vehicle motorcycle;
    late Vehicle car;

    setUp(() async {
      motorcycle = Vehicle(
        id: 'motor-001',
        name: 'Vario 160',
        type: VehicleType.motorcycle,
        plateNumber: 'B 1234 XYZ',
        year: 2023,
        totalMileageKm: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      car = Vehicle(
        id: 'car-001',
        name: 'Avanza 2020',
        type: VehicleType.car,
        plateNumber: 'B 5678 ABC',
        year: 2020,
        totalMileageKm: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );

      await vehicleRepo.addVehicle(motorcycle);
      await vehicleRepo.addVehicle(car);
    });

    test('mileage input on one vehicle does not affect another', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Add mileage to motorcycle only
      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 45,
        date: yesterday,
      );

      // Verify motorcycle total changed
      final updatedMotor = await vehicleRepo.getVehicleById('motor-001');
      expect(updatedMotor!.totalMileageKm, 45);

      // Verify car total is unchanged
      final updatedCar = await vehicleRepo.getVehicleById('car-001');
      expect(updatedCar!.totalMileageKm, 0);
    });

    test('maintenance recording on one vehicle does not affect another',
        () async {
      // Add mileage to both vehicles first
      final day1 = DateTime.now().subtract(const Duration(days: 2));
      final day2 = DateTime.now().subtract(const Duration(days: 1));

      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 100,
        date: day1,
      );
      await addMileageUseCase.execute(
        vehicleId: 'car-001',
        km: 200,
        date: day1,
      );

      // Record maintenance on motorcycle only
      await recordMaintenanceUseCase.execute(
        vehicleId: 'motor-001',
        type: MaintenanceType.oilChange,
        currentMileage: 100,
        serviceDate: day2,
      );

      // Get schedules for both vehicles
      final motorSchedules = await scheduleRepo.getSchedules('motor-001');
      final carSchedules = await scheduleRepo.getSchedules('car-001');

      // Motor oil change should be reset: due at 100 + 2000 = 2100
      final motorOil = motorSchedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      expect(motorOil.dueAtKm, 2100);

      // Car oil change should not be affected: due at 0 + 5000 = 5000
      final carOil = carSchedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      expect(carOil.dueAtKm, 5000);
    });

    test('each vehicle has independent schedules', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Add mileage to both
      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 50,
        date: yesterday,
      );
      await addMileageUseCase.execute(
        vehicleId: 'car-001',
        km: 80,
        date: yesterday,
      );

      final motorSchedules = await scheduleRepo.getSchedules('motor-001');
      final carSchedules = await scheduleRepo.getSchedules('car-001');

      // Motorcycle should have chainLube schedule (motorcycle-only)
      expect(
        motorSchedules.any((s) => s.type == MaintenanceType.chainLube),
        true,
      );

      // Car should NOT have chainLube schedule
      expect(
        carSchedules.any((s) => s.type == MaintenanceType.chainLube),
        false,
      );

      // Both should have oil change with different remaining km
      final motorOil = motorSchedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      final carOil = carSchedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );

      // Motor: 2000 - 50 = 1950
      expect(motorOil.remainingKm, 1950);
      // Car: 5000 - 80 = 4920
      expect(carOil.remainingKm, 4920);
    });

    test('mileage histories are independent per vehicle', () async {
      final day1 = DateTime.now().subtract(const Duration(days: 3));
      final day2 = DateTime.now().subtract(const Duration(days: 2));
      final day3 = DateTime.now().subtract(const Duration(days: 1));

      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 30,
        date: day1,
      );
      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 40,
        date: day2,
      );
      await addMileageUseCase.execute(
        vehicleId: 'car-001',
        km: 100,
        date: day3,
      );

      final motorHistory =
          await mileageRepo.getMileageHistory('motor-001');
      final carHistory = await mileageRepo.getMileageHistory('car-001');

      expect(motorHistory.length, 2);
      expect(carHistory.length, 1);

      final motorTotal = await mileageRepo.getTotalMileage('motor-001');
      final carTotal = await mileageRepo.getTotalMileage('car-001');

      expect(motorTotal, 70); // 30 + 40
      expect(carTotal, 100);
    });

    test('maintenance history is independent per vehicle', () async {
      // Setup: add mileage first
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await addMileageUseCase.execute(
        vehicleId: 'motor-001',
        km: 100,
        date: yesterday,
      );
      await addMileageUseCase.execute(
        vehicleId: 'car-001',
        km: 100,
        date: yesterday,
      );

      // Record maintenance on motorcycle
      await recordMaintenanceUseCase.execute(
        vehicleId: 'motor-001',
        type: MaintenanceType.oilChange,
        currentMileage: 100,
        serviceDate: yesterday,
      );

      final motorHistory =
          await maintenanceHistoryRepo.getHistory('motor-001');
      final carHistory = await maintenanceHistoryRepo.getHistory('car-001');

      expect(motorHistory.length, 1);
      expect(carHistory.length, 0);
    });
  });
}
