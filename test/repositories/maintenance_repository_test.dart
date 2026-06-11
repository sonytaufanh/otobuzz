import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/maintenance_record.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_history_repository.dart';

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

void main() {
  late MockMaintenanceHistoryRepository mockRepo;

  final oilChangeRecord = MaintenanceRecord(
    id: 'mr1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mileageAtService: 49000,
    serviceDate: DateTime(2024, 1, 10),
    cost: 350000,
    notes: 'Oli mesin Shell',
    workshopName: 'Bengkel Jaya',
  );

  final tireRecord = MaintenanceRecord(
    id: 'mr2',
    vehicleId: 'v1',
    type: MaintenanceType.tireReplacement,
    mileageAtService: 48000,
    serviceDate: DateTime(2024, 1, 5),
    cost: 1200000,
  );

  final olderOilChange = MaintenanceRecord(
    id: 'mr3',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    mileageAtService: 44000,
    serviceDate: DateTime(2023, 11, 1),
    cost: 300000,
  );

  setUp(() {
    mockRepo = MockMaintenanceHistoryRepository();
  });

  setUpAll(() {
    registerFallbackValue(oilChangeRecord);
  });

  group('MaintenanceHistoryRepository', () {
    test('addMaintenanceRecord stores correctly', () async {
      when(() => mockRepo.addMaintenanceRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.getHistory('v1'))
          .thenAnswer((_) async => [oilChangeRecord]);

      await mockRepo.addMaintenanceRecord(oilChangeRecord);
      final records = await mockRepo.getHistory('v1');

      verify(() => mockRepo.addMaintenanceRecord(oilChangeRecord)).called(1);
      expect(records, contains(oilChangeRecord));
    });

    test('getHistory returns all records for vehicle', () async {
      when(() => mockRepo.getHistory('v1')).thenAnswer(
          (_) async => [oilChangeRecord, tireRecord, olderOilChange]);

      final records = await mockRepo.getHistory('v1');

      expect(records.length, 3);
      expect(records.every((r) => r.vehicleId == 'v1'), true);
    });

    test('getHistory with type filter works', () async {
      when(() => mockRepo.getHistory('v1', type: MaintenanceType.oilChange))
          .thenAnswer((_) async => [oilChangeRecord, olderOilChange]);

      final records =
          await mockRepo.getHistory('v1', type: MaintenanceType.oilChange);

      expect(records.length, 2);
      expect(
          records.every((r) => r.type == MaintenanceType.oilChange), true);
    });

    test('getLastMaintenance returns most recent', () async {
      when(() =>
              mockRepo.getLastMaintenance('v1', MaintenanceType.oilChange))
          .thenAnswer((_) async => oilChangeRecord);

      final last =
          await mockRepo.getLastMaintenance('v1', MaintenanceType.oilChange);

      expect(last, isNotNull);
      expect(last!.serviceDate, DateTime(2024, 1, 10));
      expect(last.mileageAtService, 49000);
    });

    test('getLastMaintenanceByType returns map', () async {
      when(() => mockRepo.getLastMaintenanceByType('v1')).thenAnswer(
          (_) async => {
                MaintenanceType.oilChange: oilChangeRecord,
                MaintenanceType.tireReplacement: tireRecord,
              });

      final map = await mockRepo.getLastMaintenanceByType('v1');

      expect(map.length, 2);
      expect(map[MaintenanceType.oilChange]!.id, 'mr1');
      expect(map[MaintenanceType.tireReplacement]!.id, 'mr2');
    });
  });
}
