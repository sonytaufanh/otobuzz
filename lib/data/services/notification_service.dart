import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) { return (await android.requestNotificationsPermission()) ?? false; }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) { return (await ios.requestPermissions(alert: true, badge: true, sound: true)) ?? false; }
    return false;
  }

  Future<void> scheduleMaintenanceReminder({required int notificationId, required String vehicleName, required VehicleType vehicleType, required MaintenanceType maintenanceType, required MaintenanceSchedule schedule}) async {
    final message = generateNotificationMessage(vehicleName: vehicleName, vehicleType: vehicleType, maintenanceType: maintenanceType, remainingKm: schedule.remainingKm, remainingDays: schedule.remainingDays);
    await _plugin.show(notificationId, 'Perawatan Kendaraan', message, const NotificationDetails(android: AndroidNotificationDetails('maintenance_channel', 'Pengingat Perawatan', channelDescription: 'Notifikasi pengingat perawatan kendaraan', importance: Importance.high, priority: Priority.high), iOS: DarwinNotificationDetails()));
  }

  Future<void> cancelNotification(int id) async { await _plugin.cancel(id); }

  Future<void> cancelAllForVehicle(int vehicleBaseId, int count) async {
    for (int i = 0; i < count; i++) { await _plugin.cancel(vehicleBaseId + i); }
  }

  Future<void> rescheduleAllForVehicle({required String vehicleId, required String vehicleName, required VehicleType vehicleType, required List<MaintenanceSchedule> schedules, TransmissionType? transmissionType}) async {
    final baseId = vehicleId.hashCode.abs() % 100000;
    await cancelAllForVehicle(baseId, MaintenanceType.values.length);
    for (int i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      if (!schedule.isOverdue) {
        final interval = getDefaultInterval(schedule.type, vehicleType, transmissionType: transmissionType);
        if (schedule.remainingKm <= interval.warningBeforeKm || schedule.remainingDays <= interval.warningBeforeDays) {
          await scheduleMaintenanceReminder(notificationId: baseId + i, vehicleName: vehicleName, vehicleType: vehicleType, maintenanceType: schedule.type, schedule: schedule);
        }
      }
    }
  }

  static String generateNotificationMessage({required String vehicleName, required VehicleType vehicleType, required MaintenanceType maintenanceType, required double remainingKm, required int remainingDays}) {
    final prefix = vehicleType == VehicleType.motorcycle ? 'Motor' : 'Mobil';
    final action = maintenanceType.actionText;
    return '$prefix $vehicleName harus $action ${remainingKm.round()}km / ${formatRemainingTime(remainingDays)} lagi';
  }

  static String formatRemainingTime(int days) {
    if (days <= 0) return 'sudah lewat';
    if (days < 7) return '$days hari';
    if (days < 30) return '${(days / 7).round()} minggu';
    if (days < 365) return '${(days / 30).round()} bulan';
    return '${(days / 365).round()} tahun';
  }

  Future<void> showImmediateMaintenanceAlert({
    required int notificationId,
    required String vehicleName,
    required VehicleType vehicleType,
    required MaintenanceType maintenanceType,
    required bool isOverdue,
    required double remainingKm,
  }) async {
    final prefix = vehicleType == VehicleType.motorcycle ? 'Motor' : 'Mobil';
    final action = maintenanceType.actionText;

    String title;
    String body;
    if (isOverdue) {
      title = '⚠️ Perawatan Terlambat!';
      body = '$prefix $vehicleName - $action sudah terlambat! Segera servis.';
    } else {
      title = '🔔 Perawatan Segera';
      body = '$prefix $vehicleName perlu $action dalam ${remainingKm.round()} km lagi.';
    }

    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_alert_channel',
          'Peringatan Perawatan',
          channelDescription: 'Notifikasi peringatan perawatan mendesak',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showDocumentReminder({required int notificationId, required String message}) async {
    await _plugin.show(notificationId, 'Pengingat Dokumen Kendaraan', message, const NotificationDetails(android: AndroidNotificationDetails('document_channel', 'Pengingat Pajak & STNK', channelDescription: 'Notifikasi pengingat pajak dan STNK kendaraan', importance: Importance.high, priority: Priority.high), iOS: DarwinNotificationDetails()));
  }
}
