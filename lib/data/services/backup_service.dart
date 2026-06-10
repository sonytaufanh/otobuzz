import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper;

  static const String _lastBackupKey = 'last_backup_timestamp';
  static const int _backupVersion = 2;

  BackupService(this._dbHelper);

  /// Exports all data from the database to a JSON string.
  Future<String> exportData() async {
    final db = await _dbHelper.database;

    final vehicles = await db.query('vehicles');
    final mileageRecords = await db.query('mileage_records');
    final maintenanceRecords = await db.query('maintenance_records');
    final maintenanceSchedules = await db.query('maintenance_schedules');
    final fuelRecords = await db.query('fuel_records');
    final maintenancePhotos = await db.query('maintenance_photos');
    final vehicleDocuments = await db.query('vehicle_documents');
    final drivers = await db.query('drivers');
    final driverAssignments = await db.query('driver_assignments');
    final customIntervals = await db.query('custom_intervals');

    final backupData = {
      'version': _backupVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'vehicles': vehicles,
        'mileage_records': mileageRecords,
        'maintenance_records': maintenanceRecords,
        'maintenance_schedules': maintenanceSchedules,
        'fuel_records': fuelRecords,
        'maintenance_photos': maintenancePhotos,
        'vehicle_documents': vehicleDocuments,
        'drivers': drivers,
        'driver_assignments': driverAssignments,
        'custom_intervals': customIntervals,
      },
    };

    return jsonEncode(backupData);
  }

  /// Imports data from a JSON string, replacing all existing data.
  Future<void> importData(String jsonData) async {
    final Map<String, dynamic> backupData = jsonDecode(jsonData);

    // Validate backup structure
    if (!backupData.containsKey('version') ||
        !backupData.containsKey('data')) {
      throw const FormatException('Format backup tidak valid');
    }

    final data = backupData['data'] as Map<String, dynamic>;
    final requiredTables = [
      'vehicles',
      'mileage_records',
      'maintenance_records',
      'maintenance_schedules',
    ];

    for (final table in requiredTables) {
      if (!data.containsKey(table)) {
        throw FormatException('Tabel "$table" tidak ditemukan dalam backup');
      }
    }

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Clear all existing data (order matters due to foreign keys)
      await txn.delete('maintenance_photos');
      await txn.delete('fuel_records');
      await txn.delete('driver_assignments');
      await txn.delete('drivers');
      await txn.delete('custom_intervals');
      await txn.delete('vehicle_documents');
      await txn.delete('maintenance_schedules');
      await txn.delete('maintenance_records');
      await txn.delete('mileage_records');
      await txn.delete('vehicles');

      // Insert backup data
      for (final vehicle in (data['vehicles'] as List)) {
        await txn.insert('vehicles', Map<String, dynamic>.from(vehicle));
      }
      for (final record in (data['mileage_records'] as List)) {
        await txn.insert('mileage_records', Map<String, dynamic>.from(record));
      }
      for (final record in (data['maintenance_records'] as List)) {
        await txn.insert(
            'maintenance_records', Map<String, dynamic>.from(record));
      }
      for (final schedule in (data['maintenance_schedules'] as List)) {
        await txn.insert(
            'maintenance_schedules', Map<String, dynamic>.from(schedule));
      }
      // New tables - import if present in backup
      if (data.containsKey('fuel_records')) {
        for (final record in (data['fuel_records'] as List)) {
          await txn.insert('fuel_records', Map<String, dynamic>.from(record));
        }
      }
      if (data.containsKey('maintenance_photos')) {
        for (final photo in (data['maintenance_photos'] as List)) {
          await txn.insert(
              'maintenance_photos', Map<String, dynamic>.from(photo));
        }
      }
      if (data.containsKey('vehicle_documents')) {
        for (final doc in (data['vehicle_documents'] as List)) {
          await txn.insert(
              'vehicle_documents', Map<String, dynamic>.from(doc));
        }
      }
      if (data.containsKey('drivers')) {
        for (final driver in (data['drivers'] as List)) {
          await txn.insert('drivers', Map<String, dynamic>.from(driver));
        }
      }
      if (data.containsKey('driver_assignments')) {
        for (final assignment in (data['driver_assignments'] as List)) {
          await txn.insert(
              'driver_assignments', Map<String, dynamic>.from(assignment));
        }
      }
      if (data.containsKey('custom_intervals')) {
        for (final interval in (data['custom_intervals'] as List)) {
          await txn.insert(
              'custom_intervals', Map<String, dynamic>.from(interval));
        }
      }
    });
  }

  /// Returns the file path where backups are saved.
  Future<String> getBackupFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/otobuzz_backup.json';
  }

  /// Exports data to a file and shares it via the system share sheet.
  Future<void> shareBackup() async {
    final jsonData = await exportData();
    final filePath = await getBackupFilePath();
    final file = File(filePath);
    await file.writeAsString(jsonData);

    // Save last backup timestamp
    await _saveLastBackupTimestamp();

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'OtoBuzz Backup',
    );
  }

  /// Returns the last backup timestamp, or null if never backed up.
  Future<DateTime?> getLastBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastBackupKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Returns the backup file size in bytes, or null if no backup exists.
  Future<int?> getBackupFileSize() async {
    final filePath = await getBackupFilePath();
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return null;
  }

  Future<void> _saveLastBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }
}
