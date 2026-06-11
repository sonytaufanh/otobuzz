import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/vehicle_repository.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository mockRepo;

  final testVehicle = Vehicle(
    id: 'v1',
    name: 'Avanza',
    type: VehicleType.car,
    plateNumber: 'B 1234 XYZ',
    year: 2020,
    totalMileageKm: 50000,
    createdAt: DateTime(2020, 1, 1),
  );

  final testVehicle2 = Vehicle(
    id: 'v2',
    name: 'Vario 150',
    type: VehicleType.motorcycle,
    plateNumber: 'B 5678 ABC',
    year: 2021,
    totalMileageKm: 20000,
    createdAt: DateTime(2021, 6, 1),
  );

  setUp(() {
    mockRepo = MockVehicleRepository();
  });

  setUpAll(() {
    registerFallbackValue(testVehicle);
  });

  group('VehicleRepository', () {
    test('addVehicle stores correctly', () async {
      when(() => mockRepo.addVehicle(any())).thenAnswer((_) async {});
      when(() => mockRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle]);

      await mockRepo.addVehicle(testVehicle);
      final vehicles = await mockRepo.getAllVehicles();

      verify(() => mockRepo.addVehicle(testVehicle)).called(1);
      expect(vehicles, contains(testVehicle));
    });

    test('getAllVehicles returns all vehicles', () async {
      when(() => mockRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle, testVehicle2]);

      final vehicles = await mockRepo.getAllVehicles();

      expect(vehicles.length, 2);
      expect(vehicles[0].name, 'Avanza');
      expect(vehicles[1].name, 'Vario 150');
    });

    test('getVehicleById returns correct vehicle', () async {
      when(() => mockRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle);

      final vehicle = await mockRepo.getVehicleById('v1');

      expect(vehicle, isNotNull);
      expect(vehicle!.id, 'v1');
      expect(vehicle.name, 'Avanza');
      expect(vehicle.plateNumber, 'B 1234 XYZ');
    });

    test('getVehicleById returns null for non-existent', () async {
      when(() => mockRepo.getVehicleById('v999'))
          .thenAnswer((_) async => null);

      final vehicle = await mockRepo.getVehicleById('v999');

      expect(vehicle, isNull);
    });

    test('updateVehicle updates fields', () async {
      final updated = testVehicle.copyWith(name: 'Avanza Veloz');
      when(() => mockRepo.updateVehicle(any())).thenAnswer((_) async {});
      when(() => mockRepo.getVehicleById('v1'))
          .thenAnswer((_) async => updated);

      await mockRepo.updateVehicle(updated);
      final vehicle = await mockRepo.getVehicleById('v1');

      verify(() => mockRepo.updateVehicle(updated)).called(1);
      expect(vehicle!.name, 'Avanza Veloz');
    });

    test('deleteVehicle removes vehicle', () async {
      when(() => mockRepo.deleteVehicle('v1')).thenAnswer((_) async {});
      when(() => mockRepo.getVehicleById('v1'))
          .thenAnswer((_) async => null);

      await mockRepo.deleteVehicle('v1');
      final vehicle = await mockRepo.getVehicleById('v1');

      verify(() => mockRepo.deleteVehicle('v1')).called(1);
      expect(vehicle, isNull);
    });

    test('updateTotalMileage updates correctly', () async {
      when(() => mockRepo.updateTotalMileage('v1', 55000))
          .thenAnswer((_) async {});
      when(() => mockRepo.getVehicleById('v1'))
          .thenAnswer((_) async => testVehicle.copyWith(totalMileageKm: 55000));

      await mockRepo.updateTotalMileage('v1', 55000);
      final vehicle = await mockRepo.getVehicleById('v1');

      verify(() => mockRepo.updateTotalMileage('v1', 55000)).called(1);
      expect(vehicle!.totalMileageKm, 55000);
    });

    test('deleteVehicle cascades (no orphaned records possible)', () async {
      when(() => mockRepo.deleteVehicle('v1')).thenAnswer((_) async {});
      when(() => mockRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle2]);

      await mockRepo.deleteVehicle('v1');
      final vehicles = await mockRepo.getAllVehicles();

      verify(() => mockRepo.deleteVehicle('v1')).called(1);
      expect(vehicles.every((v) => v.id != 'v1'), true);
    });
  });
}
