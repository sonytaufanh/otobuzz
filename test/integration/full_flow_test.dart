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

  group('Full Flow Integration Test', () {
    test(
        'add vehicle → input daily km → view schedule updates → record maintenance → verify schedule reset',
        () async {
      // Step 1: Add a motorcycle
      final vehicle = Vehicle(
        id: 'v001',
        name: 'Vario 160',
        type: VehicleType.motorcycle,
        plateNumber: 'B 1234 XYZ',
        year: 2023,
        totalMileageKm: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      await vehicleRepo.addVehicle(vehicle);

      // Verify vehicle creation
      final stored = await vehicleRepo.getVehicleById('v001');
      expect(stored, isNotNull);
      expect(stored!.name, 'Vario 160');
      expect(stored.totalMileageKm, 0);

      // Step 2: Input daily km
      final today = DateTime.now().subtract(const Duration(days: 1));
      final updatedVehicle = await addMileageUseCase.execute(
        vehicleId: 'v001',
        km: 45,
        date: today,
      );

      // Verify mileage recording increases total
      expect(updatedVehicle.totalMileageKm, 45);
      final vehicleAfterKm = await vehicleRepo.getVehicleById('v001');
      expect(vehicleAfterKm!.totalMileageKm, 45);

      // Step 3: View schedule updates - remainingKm should decrease
      final schedules = await scheduleRepo.getSchedules('v001');
      expect(schedules, isNotEmpty);

      // Oil change for motorcycle: interval 2000km, so remaining should be 2000 - 45 = 1955
      final oilSchedule = schedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      expect(oilSchedule.dueAtKm, 2000); // base 0 + interval 2000
      expect(oilSchedule.remainingKm, 1955); // 2000 - 45

      // Step 4: Add more km to see schedule decrease further
      final day2 = today.subtract(const Duration(days: 1));
      await addMileageUseCase.execute(
        vehicleId: 'v001',
        km: 55,
        date: day2,
      );

      final vehicleAfter2 = await vehicleRepo.getVehicleById('v001');
      expect(vehicleAfter2!.totalMileageKm, 100);

      final schedulesAfter2 = await scheduleRepo.getSchedules('v001');
      final oilSchedule2 = schedulesAfter2.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      expect(oilSchedule2.remainingKm, 1900); // 2000 - 100

      // Step 5: Record maintenance completion - schedule should reset
      await recordMaintenanceUseCase.execute(
        vehicleId: 'v001',
        type: MaintenanceType.oilChange,
        currentMileage: 100,
        serviceDate: DateTime.now().subtract(const Duration(days: 1)),
        cost: 75000,
        workshopName: 'Bengkel Pak Joko',
      );

      // Verify schedule reset with new due point
      final schedulesAfterMaint = await scheduleRepo.getSchedules('v001');
      final oilScheduleReset = schedulesAfterMaint.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      // After maintenance at km 100, next due at 100 + 2000 = 2100
      expect(oilScheduleReset.dueAtKm, 2100);
      expect(oilScheduleReset.remainingKm, 2000); // 2100 - 100
    });

    test('vehicle creation works with correct defaults', () async {
      final vehicle = Vehicle(
        id: 'v002',
        name: 'Avanza 2020',
        type: VehicleType.car,
        plateNumber: 'B 5678 ABC',
        year: 2020,
        totalMileageKm: 0,
        createdAt: DateTime.now(),
      );
      await vehicleRepo.addVehicle(vehicle);

      final stored = await vehicleRepo.getVehicleById('v002');
      expect(stored, isNotNull);
      expect(stored!.name, 'Avanza 2020');
      expect(stored.type, VehicleType.car);
      expect(stored.totalMileageKm, 0);
      expect(stored.year, 2020);
    });

    test('mileage recording increases total correctly', () async {
      final vehicle = Vehicle(
        id: 'v003',
        name: 'Beat 2022',
        type: VehicleType.motorcycle,
        plateNumber: 'D 9999 ZZZ',
        year: 2022,
        totalMileageKm: 1000,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      await vehicleRepo.addVehicle(vehicle);

      final updated = await addMileageUseCase.execute(
        vehicleId: 'v003',
        km: 30,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(updated.totalMileageKm, 1030);
    });

    test('schedule remainingKm decreases after mileage input', () async {
      final vehicle = Vehicle(
        id: 'v004',
        name: 'PCX 160',
        type: VehicleType.motorcycle,
        plateNumber: 'F 1111 AAA',
        year: 2023,
        totalMileageKm: 500,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      );
      await vehicleRepo.addVehicle(vehicle);

      // First add mileage to generate schedules
      final updated = await addMileageUseCase.execute(
        vehicleId: 'v004',
        km: 100,
        date: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(updated.totalMileageKm, 600);

      final schedulesBefore = await scheduleRepo.getSchedules('v004');

      // Chain lube interval is 500km, base is 0 (no last service), due at 500km
      // Since totalMileageKm is 600, remainingKm = 500 - 600 = clamped to 0 (overdue)
      // OR we check oil change: due at 2000, remaining = 2000 - 600 = 1400
      final oilBefore = schedulesBefore.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );
      final remainingBefore = oilBefore.remainingKm;

      // Add more km
      await addMileageUseCase.execute(
        vehicleId: 'v004',
        km: 50,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      final schedulesAfter = await scheduleRepo.getSchedules('v004');
      final oilAfter = schedulesAfter.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );

      // remainingKm should have decreased by 50
      expect(oilAfter.remainingKm, remainingBefore - 50);
    });

    test(
        'after maintenance recording, schedule resets with new due point',
        () async {
      final vehicle = Vehicle(
        id: 'v005',
        name: 'Supra X',
        type: VehicleType.motorcycle,
        plateNumber: 'AB 2222 BBB',
        year: 2021,
        totalMileageKm: 5000,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      );
      await vehicleRepo.addVehicle(vehicle);

      // Record maintenance at current mileage
      await recordMaintenanceUseCase.execute(
        vehicleId: 'v005',
        type: MaintenanceType.oilChange,
        currentMileage: 5000,
        serviceDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final schedules = await scheduleRepo.getSchedules('v005');
      final oilSchedule = schedules.firstWhere(
        (s) => s.type == MaintenanceType.oilChange,
      );

      // Next due should be current km + interval = 5000 + 2000 = 7000
      expect(oilSchedule.dueAtKm, 7000);
      expect(oilSchedule.remainingKm, 2000); // 7000 - 5000
      expect(oilSchedule.isOverdue, false);
    });
  });
}
