import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/service_locator.dart';
import 'core/error/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/checklist_repository.dart';
import 'data/repositories/custom_interval_repository.dart';
import 'data/repositories/driver_assignment_repository.dart';
import 'data/repositories/driver_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/fuel_repository.dart';
import 'data/repositories/photo_repository.dart';
import 'data/repositories/vehicle_document_repository.dart';
import 'domain/repositories/repositories.dart';
import 'presentation/blocs/analytics/analytics_bloc.dart';
import 'presentation/blocs/cost_report/cost_report_bloc.dart';
import 'presentation/blocs/fuel/fuel_bloc.dart';
import 'presentation/blocs/maintenance/maintenance_bloc.dart';
import 'presentation/blocs/mileage/mileage_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/vehicle/vehicle_bloc.dart';
import 'presentation/screens/demo_home.dart';
// ignore: unused_import
import 'presentation/screens/splash_screen.dart'; // TODO: revert when demo is done

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handler
  GlobalErrorHandler.initialize();

  // Setup dependency injection
  await setupServiceLocator();

  runApp(const OtoBuzzApp());
}

class OtoBuzzApp extends StatelessWidget {
  const OtoBuzzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CustomIntervalRepository>.value(
          value: sl<CustomIntervalRepository>(),
        ),
        RepositoryProvider<DriverRepository>.value(
          value: sl<DriverRepository>(),
        ),
        RepositoryProvider<DriverAssignmentRepository>.value(
          value: sl<DriverAssignmentRepository>(),
        ),
        RepositoryProvider<VehicleDocumentRepository>.value(
          value: sl<VehicleDocumentRepository>(),
        ),
        RepositoryProvider<MaintenanceHistoryRepository>.value(
          value: sl<MaintenanceHistoryRepository>(),
        ),
        RepositoryProvider<MaintenanceScheduleRepository>.value(
          value: sl<MaintenanceScheduleRepository>(),
        ),
        RepositoryProvider<MileageRepository>.value(
          value: sl<MileageRepository>(),
        ),
        RepositoryProvider<FuelRepository>.value(
          value: sl<FuelRepository>(),
        ),
        RepositoryProvider<PhotoRepository>.value(
          value: sl<PhotoRepository>(),
        ),
        RepositoryProvider<ChecklistRepository>.value(
          value: sl<ChecklistRepository>(),
        ),
        RepositoryProvider<BudgetRepository>.value(
          value: sl<BudgetRepository>(),
        ),
        RepositoryProvider<ExpenseRepository>.value(
          value: sl<ExpenseRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => sl<ThemeCubit>()..loadTheme(),
          ),
          BlocProvider(
            create: (_) => sl<VehicleBloc>(),
          ),
          BlocProvider(
            create: (_) => sl<MileageBloc>(),
          ),
          BlocProvider(
            create: (_) => sl<MaintenanceBloc>(),
          ),
          BlocProvider(
            create: (_) => sl<CostReportBloc>(),
          ),
          BlocProvider(
            create: (_) => sl<FuelBloc>(),
          ),
          BlocProvider(
            create: (_) => sl<AnalyticsBloc>(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'OtoBuzz',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
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
              home: const DemoHomeScreen(), // TODO: revert to SplashScreen()
            );
          },
        ),
      ),
    );
  }
}
