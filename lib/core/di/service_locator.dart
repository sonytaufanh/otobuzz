import 'package:get_it/get_it.dart';

import '../../data/database/database_helper.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/cost_report_repository.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/annual_km_target_repository_impl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../data/repositories/trouble_log_repository_impl.dart';
import '../../domain/repositories/annual_km_target_repository.dart';
import '../../domain/repositories/trouble_log_repository.dart';
import '../../data/repositories/maintenance_history_repository_impl.dart';
import '../../data/repositories/maintenance_schedule_repository_impl.dart';
import '../../data/repositories/mileage_repository_impl.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../data/services/home_widget_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/theme_service.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/usecases.dart';
import '../../presentation/blocs/analytics/analytics_bloc.dart';
import '../../presentation/blocs/cost_report/cost_report_bloc.dart';
import '../../presentation/blocs/fuel/fuel_bloc.dart';
import '../../presentation/blocs/maintenance/maintenance_bloc.dart';
import '../../presentation/blocs/mileage/mileage_bloc.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';
import '../../presentation/blocs/trouble_log/trouble_log_bloc.dart';
import '../../presentation/blocs/vehicle/vehicle_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Database ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // ─── Services ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<ThemeService>(() => ThemeService());

  // ─── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<VehicleRepository>(
      () => VehicleRepositoryImpl(sl<DatabaseHelper>()));
  sl.registerLazySingleton<MileageRepository>(
      () => MileageRepositoryImpl(sl<DatabaseHelper>()));
  sl.registerLazySingleton<MaintenanceHistoryRepository>(
      () => MaintenanceHistoryRepositoryImpl(sl<DatabaseHelper>()));
  sl.registerLazySingleton<MaintenanceScheduleRepository>(
      () => MaintenanceScheduleRepositoryImpl(sl<DatabaseHelper>()));
  sl.registerLazySingleton<CostReportRepository>(
      () => CostReportRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<CustomIntervalRepository>(
      () => CustomIntervalRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<DriverRepository>(
      () => DriverRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<DriverAssignmentRepository>(
      () => DriverAssignmentRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<VehicleDocumentRepository>(
      () => VehicleDocumentRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<FuelRepository>(
      () => FuelRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<PhotoRepository>(
      () => PhotoRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<ChecklistRepository>(
      () => ChecklistRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<BudgetRepository>(
      () => BudgetRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepository(sl<DatabaseHelper>()));
  sl.registerLazySingleton<TroubleLogRepository>(
      () => TroubleLogRepositoryImpl(sl<DatabaseHelper>()));
  sl.registerLazySingleton<AnnualKmTargetRepository>(
      () => AnnualKmTargetRepositoryImpl(sl<DatabaseHelper>()));

  // ─── Use Cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MaintenanceCalculator>(() => MaintenanceCalculator(
        sl<MileageRepository>(),
        sl<MaintenanceHistoryRepository>(),
        customIntervalRepository: sl<CustomIntervalRepository>(),
      ));
  sl.registerLazySingleton<AddDailyMileageUseCase>(() => AddDailyMileageUseCase(
        sl<VehicleRepository>(),
        sl<MileageRepository>(),
        sl<MaintenanceScheduleRepository>(),
        sl<MaintenanceCalculator>(),
        notificationService: sl<NotificationService>(),
      ));
  sl.registerLazySingleton<RecordMaintenanceCompletedUseCase>(
      () => RecordMaintenanceCompletedUseCase(
            sl<VehicleRepository>(),
            sl<MaintenanceHistoryRepository>(),
            sl<MaintenanceScheduleRepository>(),
            sl<MaintenanceCalculator>(),
            notificationService: sl<NotificationService>(),
          ));
  sl.registerLazySingleton<GetVehicleSchedulesUseCase>(
      () => GetVehicleSchedulesUseCase(sl<MaintenanceScheduleRepository>()));
  sl.registerLazySingleton<PredictMaintenanceCostUseCase>(
      () => PredictMaintenanceCostUseCase(
        sl<MaintenanceScheduleRepository>(),
        sl<MaintenanceHistoryRepository>(),
      ));

  // ─── BLoCs (Factory - new instance each time) ──────────────────────────────
  sl.registerFactory<ThemeCubit>(
      () => ThemeCubit(sl<ThemeService>()));
  sl.registerFactory<VehicleBloc>(() => VehicleBloc(
        sl<VehicleRepository>(),
        sl<MaintenanceCalculator>(),
        sl<MaintenanceScheduleRepository>(),
        documentRepository: sl<VehicleDocumentRepository>(),
      ));
  sl.registerFactory<MileageBloc>(() => MileageBloc(
        sl<AddDailyMileageUseCase>(),
        sl<MileageRepository>(),
        sl<VehicleRepository>(),
        sl<MaintenanceScheduleRepository>(),
      ));
  sl.registerFactory<MaintenanceBloc>(() => MaintenanceBloc(
        sl<GetVehicleSchedulesUseCase>(),
        sl<RecordMaintenanceCompletedUseCase>(),
        sl<MaintenanceHistoryRepository>(),
      ));
  sl.registerFactory<CostReportBloc>(
      () => CostReportBloc(sl<CostReportRepository>()));
  sl.registerFactory<FuelBloc>(
      () => FuelBloc(sl<FuelRepository>()));
  sl.registerFactory<AnalyticsBloc>(() => AnalyticsBloc(
        sl<MileageRepository>(),
        sl<MaintenanceHistoryRepository>(),
        sl<FuelRepository>(),
      ));
  sl.registerFactory<TroubleLogBloc>(
      () => TroubleLogBloc(sl<TroubleLogRepository>()));

  // ─── Initialize async services ─────────────────────────────────────────────
  final dbHelper = sl<DatabaseHelper>();
  await dbHelper.database; // Ensure DB is created

  final notificationService = sl<NotificationService>();
  await notificationService.initialize();

  await HomeWidgetService.initialize();
}
