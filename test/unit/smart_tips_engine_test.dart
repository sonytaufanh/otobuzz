import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/budget_repository.dart';
import 'package:otobuzz/data/repositories/checklist_repository.dart';
import 'package:otobuzz/data/repositories/fuel_repository.dart';
import 'package:otobuzz/data/repositories/vehicle_document_repository.dart';
import 'package:otobuzz/domain/models/models.dart';
import 'package:otobuzz/domain/repositories/repositories.dart';
import 'package:otobuzz/domain/usecases/smart_tips_engine.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockMileageRepository extends Mock implements MileageRepository {}

class MockMaintenanceHistoryRepository extends Mock
    implements MaintenanceHistoryRepository {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockFuelRepository extends Mock implements FuelRepository {}

class MockChecklistRepository extends Mock implements ChecklistRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockVehicleDocumentRepository extends Mock
    implements VehicleDocumentRepository {}

void main() {
  late MockVehicleRepository mockVehicleRepo;
  late MockMileageRepository mockMileageRepo;
  late MockMaintenanceHistoryRepository mockHistoryRepo;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockFuelRepository mockFuelRepo;
  late MockChecklistRepository mockChecklistRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockVehicleDocumentRepository mockDocRepo;
  late SmartTipsEngine engine;

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
    mockVehicleRepo = MockVehicleRepository();
    mockMileageRepo = MockMileageRepository();
    mockHistoryRepo = MockMaintenanceHistoryRepository();
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockFuelRepo = MockFuelRepository();
    mockChecklistRepo = MockChecklistRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockDocRepo = MockVehicleDocumentRepository();

    engine = SmartTipsEngine(
      vehicleRepository: mockVehicleRepo,
      mileageRepository: mockMileageRepo,
      maintenanceRepository: mockHistoryRepo,
      scheduleRepository: mockScheduleRepo,
      fuelRepository: mockFuelRepo,
      checklistRepository: mockChecklistRepo,
      budgetRepository: mockBudgetRepo,
      documentRepository: mockDocRepo,
    );
  });

  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  group('maintenance tips - overdue items', () {
    test('generates tips when there are multiple overdue items', () async {
      when(() => mockVehicleRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle]);

      // 3 overdue schedules to trigger "multiple overdue" tip
      final overdueSchedules = [
        MaintenanceSchedule(
          id: 's1',
          vehicleId: 'v1',
          type: MaintenanceType.oilChange,
          dueAtKm: 9000,
          dueByDate: DateTime.now().subtract(const Duration(days: 10)),
          remainingKm: 0,
          remainingDays: 0,
          isOverdue: true,
        ),
        MaintenanceSchedule(
          id: 's2',
          vehicleId: 'v1',
          type: MaintenanceType.brakePads,
          dueAtKm: 8500,
          dueByDate: DateTime.now().subtract(const Duration(days: 20)),
          remainingKm: 0,
          remainingDays: 0,
          isOverdue: true,
        ),
        MaintenanceSchedule(
          id: 's3',
          vehicleId: 'v1',
          type: MaintenanceType.airFilter,
          dueAtKm: 9000,
          dueByDate: DateTime.now().subtract(const Duration(days: 5)),
          remainingKm: 0,
          remainingDays: 0,
          isOverdue: true,
        ),
      ];

      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => overdueSchedules);
      when(() => mockHistoryRepo.getHistory('v1',
              type: any(named: 'type')))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getAverageDailyMileage('v1'))
          .thenAnswer((_) async => 50.0);
      when(() => mockChecklistRepo.getChecklistHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);
      when(() => mockMileageRepo.getMileageHistory('v1'))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getAverageDailyMileage('v1', lastDays: 7))
          .thenAnswer((_) async => 50.0);
      when(() => mockFuelRepo.getFuelRecordsByPeriod(
            'v1',
            any(),
            any(),
          )).thenAnswer((_) async => []);
      when(() => mockBudgetRepo.getBudgetStatus(any(), any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockHistoryRepo.getRecordsByDateRange(
            any(),
            any(),
            vehicleId: any(named: 'vehicleId'),
          )).thenAnswer((_) async => []);
      when(() => mockHistoryRepo.getRecordsByDateRange(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockChecklistRepo.getIncompleteToday())
          .thenAnswer((_) async => []);
      when(() => mockFuelRepo.getStatistics('v1'))
          .thenAnswer((_) async => FuelStatistics.empty());

      final tips = await engine.generateTips();

      // Should have at least one maintenance tip about multiple overdue items
      final maintenanceTips = tips
          .where((t) => t.category == SmartTipCategory.maintenance)
          .toList();
      expect(maintenanceTips, isNotEmpty);
      expect(
        maintenanceTips.any((t) => t.title.contains('terlambat')),
        true,
      );
    });
  });

  group('safety tips - document expiry', () {
    test('generates safety tip when documents are expiring soon', () async {
      when(() => mockVehicleRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle]);
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => []);
      when(() => mockHistoryRepo.getHistory('v1',
              type: any(named: 'type')))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getAverageDailyMileage('v1'))
          .thenAnswer((_) async => 50.0);
      when(() => mockChecklistRepo.getChecklistHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      // Document expiring in 5 days
      when(() => mockDocRepo.getDocuments('v1')).thenAnswer((_) async => [
            VehicleDocument(
              id: 'doc-1',
              vehicleId: 'v1',
              documentType: DocumentType.pajak,
              expiryDate: DateTime.now().add(const Duration(days: 5)),
            ),
          ]);

      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);
      when(() => mockMileageRepo.getMileageHistory('v1'))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getAverageDailyMileage('v1', lastDays: 7))
          .thenAnswer((_) async => 50.0);
      when(() => mockFuelRepo.getFuelRecordsByPeriod(
            'v1',
            any(),
            any(),
          )).thenAnswer((_) async => []);
      when(() => mockBudgetRepo.getBudgetStatus(any(), any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockHistoryRepo.getRecordsByDateRange(
            any(),
            any(),
            vehicleId: any(named: 'vehicleId'),
          )).thenAnswer((_) async => []);
      when(() => mockHistoryRepo.getRecordsByDateRange(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockChecklistRepo.getIncompleteToday())
          .thenAnswer((_) async => []);
      when(() => mockFuelRepo.getStatistics('v1'))
          .thenAnswer((_) async => FuelStatistics.empty());

      final tips = await engine.generateTips();

      final safetyTips =
          tips.where((t) => t.category == SmartTipCategory.safety).toList();
      expect(safetyTips, isNotEmpty);
      expect(
        safetyTips.any((t) => t.title.contains('expire')),
        true,
      );
    });
  });

  group('usage tips - idle vehicle', () {
    test('generates usage tip when vehicle is idle for 14+ days', () async {
      when(() => mockVehicleRepo.getAllVehicles())
          .thenAnswer((_) async => [testVehicle]);
      when(() => mockScheduleRepo.getSchedules('v1'))
          .thenAnswer((_) async => []);
      when(() => mockHistoryRepo.getHistory('v1',
              type: any(named: 'type')))
          .thenAnswer((_) async => []);
      when(() => mockMileageRepo.getAverageDailyMileage('v1'))
          .thenAnswer((_) async => 0.0);
      when(() => mockChecklistRepo.getChecklistHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);
      when(() => mockDocRepo.getDocuments('v1'))
          .thenAnswer((_) async => []);

      // No mileage in last 30 days (returns empty for "from: 30 days ago")
      when(() => mockMileageRepo.getMileageHistory(
            'v1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      // But has old mileage records (last record was 20 days ago)
      when(() => mockMileageRepo.getMileageHistory('v1'))
          .thenAnswer((_) async => [
                MileageRecord(
                  id: 'mr-old',
                  vehicleId: 'v1',
                  km: 50,
                  date: DateTime.now().subtract(const Duration(days: 20)),
                ),
              ]);

      when(() => mockMileageRepo.getAverageDailyMileage('v1', lastDays: 7))
          .thenAnswer((_) async => 0.0);
      when(() => mockFuelRepo.getFuelRecordsByPeriod(
            'v1',
            any(),
            any(),
          )).thenAnswer((_) async => []);
      when(() => mockBudgetRepo.getBudgetStatus(any(), any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockHistoryRepo.getRecordsByDateRange(
            any(),
            any(),
            vehicleId: any(named: 'vehicleId'),
          )).thenAnswer((_) async => []);
      when(() => mockHistoryRepo.getRecordsByDateRange(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockChecklistRepo.getIncompleteToday())
          .thenAnswer((_) async => []);
      when(() => mockFuelRepo.getStatistics('v1'))
          .thenAnswer((_) async => FuelStatistics.empty());

      final tips = await engine.generateTips();

      final usageTips =
          tips.where((t) => t.category == SmartTipCategory.usage).toList();
      expect(usageTips, isNotEmpty);
      expect(
        usageTips.any((t) => t.title.contains('tidak dipakai')),
        true,
      );
    });
  });
}
