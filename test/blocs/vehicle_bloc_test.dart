import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otobuzz/data/repositories/vehicle_document_repository.dart';
import 'package:otobuzz/domain/models/maintenance_schedule.dart';
import 'package:otobuzz/domain/models/maintenance_type.dart';
import 'package:otobuzz/domain/models/vehicle.dart';
import 'package:otobuzz/domain/models/vehicle_type.dart';
import 'package:otobuzz/domain/repositories/maintenance_schedule_repository.dart';
import 'package:otobuzz/domain/repositories/vehicle_repository.dart';
import 'package:otobuzz/domain/usecases/maintenance_calculator.dart';
import 'package:otobuzz/presentation/blocs/vehicle/vehicle_bloc.dart';
import 'package:otobuzz/presentation/blocs/vehicle/vehicle_event.dart';
import 'package:otobuzz/presentation/blocs/vehicle/vehicle_state.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockMaintenanceCalculator extends Mock implements MaintenanceCalculator {}

class MockMaintenanceScheduleRepository extends Mock
    implements MaintenanceScheduleRepository {}

class MockVehicleDocumentRepository extends Mock
    implements VehicleDocumentRepository {}

void main() {
  late MockVehicleRepository mockVehicleRepo;
  late MockMaintenanceCalculator mockCalculator;
  late MockMaintenanceScheduleRepository mockScheduleRepo;
  late MockVehicleDocumentRepository mockDocRepo;

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

  final overdueSchedule = MaintenanceSchedule(
    id: 's1',
    vehicleId: 'v1',
    type: MaintenanceType.oilChange,
    dueAtKm: 45000,
    dueByDate: DateTime(2023, 1, 1),
    remainingKm: -5000,
    remainingDays: -30,
    isOverdue: true,
  );

  final upcomingSchedule = MaintenanceSchedule(
    id: 's2',
    vehicleId: 'v2',
    type: MaintenanceType.oilChange,
    dueAtKm: 21000,
    dueByDate: DateTime.now().add(const Duration(days: 15)),
    remainingKm: 1000,
    remainingDays: 15,
    isOverdue: false,
  );

  setUp(() {
    mockVehicleRepo = MockVehicleRepository();
    mockCalculator = MockMaintenanceCalculator();
    mockScheduleRepo = MockMaintenanceScheduleRepository();
    mockDocRepo = MockVehicleDocumentRepository();
  });

  setUpAll(() {
    registerFallbackValue(testVehicle);
  });

  VehicleBloc buildBloc() => VehicleBloc(
        mockVehicleRepo,
        mockCalculator,
        mockScheduleRepo,
        documentRepository: mockDocRepo,
      );

  group('VehicleBloc', () {
    blocTest<VehicleBloc, VehicleState>(
      'emits [VehicleLoading, VehicleLoaded] when LoadVehicles succeeds',
      build: () {
        when(() => mockVehicleRepo.getAllVehicles())
            .thenAnswer((_) async => [testVehicle, testVehicle2]);
        when(() => mockScheduleRepo.getSchedules('v1'))
            .thenAnswer((_) async => [overdueSchedule]);
        when(() => mockScheduleRepo.getSchedules('v2'))
            .thenAnswer((_) async => [upcomingSchedule]);
        when(() => mockDocRepo.getAllExpired()).thenAnswer((_) async => []);
        when(() => mockDocRepo.getExpiringSoon(30))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadVehicles()),
      expect: () => [
        isA<VehicleLoading>(),
        isA<VehicleLoaded>().having(
          (s) => s.vehicles.length,
          'vehicle count',
          2,
        ),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'emits [VehicleLoading, VehicleError] when LoadVehicles fails',
      build: () {
        when(() => mockVehicleRepo.getAllVehicles())
            .thenThrow(Exception('DB error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadVehicles()),
      expect: () => [
        isA<VehicleLoading>(),
        isA<VehicleError>(),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'AddVehicle succeeds and reloads vehicles',
      build: () {
        when(() => mockVehicleRepo.addVehicle(any()))
            .thenAnswer((_) async {});
        when(() => mockCalculator.recalculateAllSchedules(any()))
            .thenAnswer((_) async => []);
        when(() => mockScheduleRepo.updateSchedules(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockVehicleRepo.getAllVehicles())
            .thenAnswer((_) async => [testVehicle]);
        when(() => mockScheduleRepo.getSchedules(any()))
            .thenAnswer((_) async => []);
        when(() => mockDocRepo.getAllExpired()).thenAnswer((_) async => []);
        when(() => mockDocRepo.getExpiringSoon(30))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddVehicle(testVehicle)),
      expect: () => [
        isA<VehicleOperationSuccess>(),
        isA<VehicleLoading>(),
        isA<VehicleLoaded>(),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'AddVehicle emits VehicleError on failure',
      build: () {
        when(() => mockVehicleRepo.addVehicle(any()))
            .thenThrow(Exception('Insert failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddVehicle(testVehicle)),
      expect: () => [isA<VehicleError>()],
    );

    blocTest<VehicleBloc, VehicleState>(
      'UpdateVehicle succeeds and reloads',
      build: () {
        when(() => mockVehicleRepo.updateVehicle(any()))
            .thenAnswer((_) async {});
        when(() => mockVehicleRepo.getAllVehicles())
            .thenAnswer((_) async => [testVehicle]);
        when(() => mockScheduleRepo.getSchedules(any()))
            .thenAnswer((_) async => []);
        when(() => mockDocRepo.getAllExpired()).thenAnswer((_) async => []);
        when(() => mockDocRepo.getExpiringSoon(30))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(UpdateVehicle(testVehicle)),
      expect: () => [
        isA<VehicleOperationSuccess>(),
        isA<VehicleLoading>(),
        isA<VehicleLoaded>(),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'DeleteVehicle succeeds and reloads',
      build: () {
        when(() => mockVehicleRepo.deleteVehicle(any()))
            .thenAnswer((_) async {});
        when(() => mockVehicleRepo.getAllVehicles())
            .thenAnswer((_) async => []);
        when(() => mockDocRepo.getAllExpired()).thenAnswer((_) async => []);
        when(() => mockDocRepo.getExpiringSoon(30))
            .thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteVehicle('v1')),
      expect: () => [
        isA<VehicleOperationSuccess>(),
        isA<VehicleLoading>(),
        isA<VehicleLoaded>(),
      ],
    );

    blocTest<VehicleBloc, VehicleState>(
      'DeleteVehicle emits VehicleError on failure',
      build: () {
        when(() => mockVehicleRepo.deleteVehicle(any()))
            .thenThrow(Exception('Delete failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(DeleteVehicle('v1')),
      expect: () => [isA<VehicleError>()],
    );

    test('VehicleLoaded.overdueCount returns correct count', () {
      final state = VehicleLoaded(
        [testVehicle, testVehicle2],
        vehicleSchedules: {
          'v1': [overdueSchedule],
          'v2': [upcomingSchedule],
        },
      );
      expect(state.overdueCount, 1);
    });

    test('VehicleLoaded.upcomingCount returns correct count', () {
      final state = VehicleLoaded(
        [testVehicle, testVehicle2],
        vehicleSchedules: {
          'v1': [overdueSchedule],
          'v2': [upcomingSchedule],
        },
      );
      expect(state.upcomingCount, 1);
    });

    test('VehicleLoaded.overdueCount returns 0 when no overdue', () {
      final state = VehicleLoaded(
        [testVehicle2],
        vehicleSchedules: {
          'v2': [upcomingSchedule],
        },
      );
      expect(state.overdueCount, 0);
    });

    test('VehicleLoaded.upcomingCount returns 0 when no upcoming', () {
      final normalSchedule = MaintenanceSchedule(
        id: 's3',
        vehicleId: 'v2',
        type: MaintenanceType.oilChange,
        dueAtKm: 25000,
        dueByDate: DateTime.now().add(const Duration(days: 60)),
        remainingKm: 5000,
        remainingDays: 60,
        isOverdue: false,
      );
      final state = VehicleLoaded(
        [testVehicle2],
        vehicleSchedules: {
          'v2': [normalSchedule],
        },
      );
      expect(state.upcomingCount, 0);
    });
  });
}
