import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/cost_report_repository.dart';
import 'data/repositories/custom_interval_repository.dart';
import 'data/repositories/driver_assignment_repository.dart';
import 'data/repositories/driver_repository.dart';
import 'data/repositories/maintenance_history_repository_impl.dart';
import 'data/repositories/maintenance_schedule_repository_impl.dart';
import 'data/repositories/mileage_repository_impl.dart';
import 'data/repositories/vehicle_document_repository.dart';
import 'data/repositories/vehicle_repository_impl.dart';
import 'data/services/notification_service.dart';
import 'domain/repositories/repositories.dart';
import 'domain/usecases/usecases.dart';
import 'presentation/blocs/cost_report/cost_report_bloc.dart';
import 'presentation/blocs/maintenance/maintenance_bloc.dart';
import 'presentation/blocs/mileage/mileage_bloc.dart';
import 'presentation/blocs/vehicle/vehicle_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Ensure DB is created
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Create repositories
  final vehicleRepository = VehicleRepositoryImpl(dbHelper);
  final mileageRepository = MileageRepositoryImpl(dbHelper);
  final maintenanceHistoryRepository =
      MaintenanceHistoryRepositoryImpl(dbHelper);
  final scheduleRepository = MaintenanceScheduleRepositoryImpl(dbHelper);
  final costReportRepository = CostReportRepository(dbHelper);
  final customIntervalRepository = CustomIntervalRepository(dbHelper);
  final driverRepository = DriverRepository(dbHelper);
  final driverAssignmentRepository = DriverAssignmentRepository(dbHelper);
  final vehicleDocumentRepository = VehicleDocumentRepository(dbHelper);

  // Create use cases
  final calculator = MaintenanceCalculator(
    mileageRepository,
    maintenanceHistoryRepository,
    customIntervalRepository: customIntervalRepository,
  );
  final addMileageUseCase = AddDailyMileageUseCase(
    vehicleRepository,
    mileageRepository,
    scheduleRepository,
    calculator,
    notificationService: notificationService,
  );
  final recordMaintenanceUseCase = RecordMaintenanceCompletedUseCase(
    vehicleRepository,
    maintenanceHistoryRepository,
    scheduleRepository,
    calculator,
    notificationService: notificationService,
  );
  final getSchedulesUseCase = GetVehicleSchedulesUseCase(scheduleRepository);

  runApp(OtoBuzzApp(
    vehicleRepository: vehicleRepository,
    mileageRepository: mileageRepository,
    maintenanceHistoryRepository: maintenanceHistoryRepository,
    scheduleRepository: scheduleRepository,
    costReportRepository: costReportRepository,
    customIntervalRepository: customIntervalRepository,
    driverRepository: driverRepository,
    driverAssignmentRepository: driverAssignmentRepository,
    vehicleDocumentRepository: vehicleDocumentRepository,
    calculator: calculator,
    addMileageUseCase: addMileageUseCase,
    recordMaintenanceUseCase: recordMaintenanceUseCase,
    getSchedulesUseCase: getSchedulesUseCase,
  ));
}

class OtoBuzzApp extends StatelessWidget {
  final VehicleRepository vehicleRepository;
  final MileageRepository mileageRepository;
  final MaintenanceHistoryRepository maintenanceHistoryRepository;
  final MaintenanceScheduleRepository scheduleRepository;
  final CostReportRepository costReportRepository;
  final CustomIntervalRepository customIntervalRepository;
  final DriverRepository driverRepository;
  final DriverAssignmentRepository driverAssignmentRepository;
  final VehicleDocumentRepository vehicleDocumentRepository;
  final MaintenanceCalculator calculator;
  final AddDailyMileageUseCase addMileageUseCase;
  final RecordMaintenanceCompletedUseCase recordMaintenanceUseCase;
  final GetVehicleSchedulesUseCase getSchedulesUseCase;

  const OtoBuzzApp({
    super.key,
    required this.vehicleRepository,
    required this.mileageRepository,
    required this.maintenanceHistoryRepository,
    required this.scheduleRepository,
    required this.costReportRepository,
    required this.customIntervalRepository,
    required this.driverRepository,
    required this.driverAssignmentRepository,
    required this.vehicleDocumentRepository,
    required this.calculator,
    required this.addMileageUseCase,
    required this.recordMaintenanceUseCase,
    required this.getSchedulesUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CustomIntervalRepository>.value(
          value: customIntervalRepository,
        ),
        RepositoryProvider<DriverRepository>.value(
          value: driverRepository,
        ),
        RepositoryProvider<DriverAssignmentRepository>.value(
          value: driverAssignmentRepository,
        ),
        RepositoryProvider<VehicleDocumentRepository>.value(
          value: vehicleDocumentRepository,
        ),
        RepositoryProvider<MaintenanceHistoryRepository>.value(
          value: maintenanceHistoryRepository,
        ),
        RepositoryProvider<MaintenanceScheduleRepository>.value(
          value: scheduleRepository,
        ),
        RepositoryProvider<MileageRepository>.value(
          value: mileageRepository,
        ),
      ],
      child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => VehicleBloc(
            vehicleRepository,
            calculator,
            scheduleRepository,
            documentRepository: vehicleDocumentRepository,
          ),
        ),
        BlocProvider(
          create: (_) => MileageBloc(addMileageUseCase, mileageRepository),
        ),
        BlocProvider(
          create: (_) => MaintenanceBloc(
            getSchedulesUseCase,
            recordMaintenanceUseCase,
            maintenanceHistoryRepository,
          ),
        ),
        BlocProvider(
          create: (_) => CostReportBloc(costReportRepository),
        ),
      ],
      child: MaterialApp(
        title: 'OtoBuzz',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        locale: const Locale('id', 'ID'),
        home: const SplashScreen(),
      ),
      ),
    );
  }
}
