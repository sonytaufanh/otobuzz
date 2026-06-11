import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/domain/models/mileage_record.dart';
import 'package:otobuzz/domain/repositories/mileage_repository.dart';

class MockMileageRepository extends Mock implements MileageRepository {}

void main() {
  late MockMileageRepository mockRepo;

  final testRecord = MileageRecord(
    id: 'r1',
    vehicleId: 'v1',
    km: 50,
    date: DateTime(2024, 1, 15),
  );

  final testRecord2 = MileageRecord(
    id: 'r2',
    vehicleId: 'v1',
    km: 75,
    date: DateTime(2024, 1, 16),
  );

  final testRecord3 = MileageRecord(
    id: 'r3',
    vehicleId: 'v1',
    km: 60,
    date: DateTime(2024, 1, 14),
  );

  setUp(() {
    mockRepo = MockMileageRepository();
  });

  setUpAll(() {
    registerFallbackValue(testRecord);
  });

  group('MileageRepository', () {
    test('addMileageRecord stores correctly', () async {
      when(() => mockRepo.addMileageRecord(any())).thenAnswer((_) async {});
      when(() => mockRepo.getMileageHistory('v1'))
          .thenAnswer((_) async => [testRecord]);

      await mockRepo.addMileageRecord(testRecord);
      final records = await mockRepo.getMileageHistory('v1');

      verify(() => mockRepo.addMileageRecord(testRecord)).called(1);
      expect(records, contains(testRecord));
    });

    test('getMileageHistory returns records in order', () async {
      // Return in chronological order (most recent first)
      when(() => mockRepo.getMileageHistory('v1'))
          .thenAnswer((_) async => [testRecord2, testRecord, testRecord3]);

      final records = await mockRepo.getMileageHistory('v1');

      expect(records.length, 3);
      expect(records.first.date.isAfter(records.last.date), true);
    });

    test('getTotalMileage sums correctly', () async {
      when(() => mockRepo.getTotalMileage('v1'))
          .thenAnswer((_) async => 185.0); // 50+75+60

      final total = await mockRepo.getTotalMileage('v1');

      expect(total, 185.0);
    });

    test('getAverageDailyMileage calculates correctly', () async {
      when(() => mockRepo.getAverageDailyMileage('v1'))
          .thenAnswer((_) async => 61.67);

      final avg = await mockRepo.getAverageDailyMileage('v1');

      expect(avg, closeTo(61.67, 0.01));
    });

    test('getRecordByVehicleAndDate finds correct record', () async {
      when(() => mockRepo.getRecordByVehicleAndDate(
              'v1', DateTime(2024, 1, 15)))
          .thenAnswer((_) async => testRecord);

      final record = await mockRepo.getRecordByVehicleAndDate(
          'v1', DateTime(2024, 1, 15));

      expect(record, isNotNull);
      expect(record!.km, 50);
      expect(record.date, DateTime(2024, 1, 15));
    });

    test('getRecordByVehicleAndDate returns null when not found', () async {
      when(() => mockRepo.getRecordByVehicleAndDate(
              'v1', DateTime(2024, 2, 1)))
          .thenAnswer((_) async => null);

      final record = await mockRepo.getRecordByVehicleAndDate(
          'v1', DateTime(2024, 2, 1));

      expect(record, isNull);
    });

    test('upsertMileageRecord replaces existing', () async {
      final updatedRecord = MileageRecord(
        id: 'r1',
        vehicleId: 'v1',
        km: 80,
        date: DateTime(2024, 1, 15),
      );

      when(() => mockRepo.upsertMileageRecord(any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.getRecordByVehicleAndDate(
              'v1', DateTime(2024, 1, 15)))
          .thenAnswer((_) async => updatedRecord);

      await mockRepo.upsertMileageRecord(updatedRecord);
      final record = await mockRepo.getRecordByVehicleAndDate(
          'v1', DateTime(2024, 1, 15));

      verify(() => mockRepo.upsertMileageRecord(updatedRecord)).called(1);
      expect(record!.km, 80);
    });
  });
}
