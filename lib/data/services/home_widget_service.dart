import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String _appGroupId = 'com.otobuzz.otobuzz';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    HomeWidget.registerInteractivityCallback(interactivityCallback);
  }

  static Future<void> updateWidget({
    required String vehicleName,
    required String totalKm,
    required String nextMaintenance,
  }) async {
    await HomeWidget.saveWidgetData('vehicle_name', vehicleName);
    await HomeWidget.saveWidgetData('total_km', totalKm);
    await HomeWidget.saveWidgetData('next_maintenance', nextMaintenance);
    await HomeWidget.updateWidget(
      androidName: 'OtoBuzzWidgetProvider',
    );
  }

  @pragma('vm:entry-point')
  static Future<void> interactivityCallback(Uri? uri) async {
    // Handle widget tap — this opens the app to AddKmScreen
  }
}
