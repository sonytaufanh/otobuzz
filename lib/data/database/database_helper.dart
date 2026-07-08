import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  /// Creates a DatabaseHelper with a pre-initialized database (for testing).
  DatabaseHelper.withDatabase(Database db) : _database = db;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'otobuzz.db');

    final db = await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return db;
  }

  static Future<void> createTables(Database db) async {
    await _createTablesInternal(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTablesInternal(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCustomIntervalsTable(db);
    }
    if (oldVersion < 3) {
      await _createVehicleDocumentsTable(db);
    }
    if (oldVersion < 4) {
      await _createDriverTables(db);
    }
    if (oldVersion < 5) {
      await _createFuelTables(db);
      await _createMaintenancePhotosTable(db);
      await _addVehiclePhotoColumn(db);
    }
    if (oldVersion < 6) {
      await _createDailyChecklistsTable(db);
      await _createMaintenanceBudgetsTable(db);
    }
    if (oldVersion < 7) {
      await _createExpenseRecordsTable(db);
    }
    if (oldVersion < 8) {
      await _addVehicleTransmissionColumn(db);
    }
    if (oldVersion < 9) {
      await _createTroubleLogsTable(db);
    }
    if (oldVersion < 10) {
      await _addWorkshopRatingColumns(db);
    }
    if (oldVersion < 11) {
      await _createAnnualKmTargetsTable(db);
    }
  }

  static Future<void> _createFuelTables(Database db) async {
    await db.execute('''
      CREATE TABLE fuel_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        liters REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        totalCost REAL NOT NULL,
        odometerKm REAL NOT NULL,
        date TEXT NOT NULL,
        stationName TEXT,
        fuelType TEXT,
        isFullTank INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_fuel_vehicle_date ON fuel_records(vehicleId, date)');
  }

  static Future<void> _createMaintenancePhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance_photos (
        id TEXT PRIMARY KEY,
        maintenanceRecordId TEXT NOT NULL,
        photoPath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (maintenanceRecordId) REFERENCES maintenance_records(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_photos_maintenance ON maintenance_photos(maintenanceRecordId)');
  }

  static Future<void> _addVehiclePhotoColumn(Database db) async {
    await db.execute('ALTER TABLE vehicles ADD COLUMN photoPath TEXT');
  }

  static Future<void> _addVehicleTransmissionColumn(Database db) async {
    await db.execute(
        'ALTER TABLE vehicles ADD COLUMN transmissionType INTEGER');
  }

  static Future<void> _createAnnualKmTargetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE annual_km_targets (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        year INTEGER NOT NULL,
        targetKm REAL NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE,
        UNIQUE(vehicleId, year)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_annual_km_targets_vehicle ON annual_km_targets(vehicleId)');
  }

  static Future<void> _addWorkshopRatingColumns(Database db) async {
    await db.execute('ALTER TABLE maintenance_records ADD COLUMN workshopRating INTEGER');
    await db.execute('ALTER TABLE maintenance_records ADD COLUMN workshopReview TEXT');
  }

  static Future<void> _createTroubleLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE trouble_logs (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        severity INTEGER NOT NULL,
        reportedDate TEXT NOT NULL,
        odometerKm REAL,
        isResolved INTEGER NOT NULL DEFAULT 0,
        resolvedDate TEXT,
        resolutionNotes TEXT,
        maintenanceRecordId TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_trouble_vehicle_date ON trouble_logs(vehicleId, reportedDate)');
  }

  static Future<void> _createDailyChecklistsTable(Database db) async {
    await db.execute('''
      CREATE TABLE daily_checklists (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        driverId TEXT,
        date TEXT NOT NULL,
        items TEXT NOT NULL,
        overallStatus TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE,
        UNIQUE(vehicleId, date)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_checklists_vehicle_date ON daily_checklists(vehicleId, date)');
  }

  static Future<void> _createMaintenanceBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance_budgets (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        monthlyBudget REAL NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        notes TEXT,
        UNIQUE(vehicleId, year, month)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_budgets_vehicle_year_month ON maintenance_budgets(vehicleId, year, month)');
  }

  static Future<void> _createExpenseRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE expense_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_expense_vehicle_date ON expense_records(vehicleId, date)');
  }

  static Future<void> _createVehicleDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE vehicle_documents (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        documentType TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        lastPaidDate TEXT,
        cost REAL,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createDriverTables(Database db) async {
    await db.execute('''
      CREATE TABLE drivers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        licenseNumber TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE driver_assignments (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        driverId TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE,
        FOREIGN KEY (driverId) REFERENCES drivers(id) ON DELETE CASCADE,
        UNIQUE(vehicleId, date)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_driver_assignments_vehicle_date ON driver_assignments(vehicleId, date)');
  }

  static Future<void> _createCustomIntervalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE custom_intervals (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        type INTEGER NOT NULL,
        kmInterval REAL NOT NULL,
        monthsInterval INTEGER NOT NULL,
        warningBeforeKm REAL NOT NULL,
        warningBeforeDays INTEGER NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE,
        UNIQUE(vehicleId, type)
      )
    ''');
  }

  static Future<void> _createTablesInternal(Database db) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        transmissionType INTEGER,
        plateNumber TEXT NOT NULL,
        year INTEGER NOT NULL,
        totalMileageKm REAL NOT NULL DEFAULT 0,
        photoPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mileage_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        km REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        type INTEGER NOT NULL,
        mileageAtService REAL NOT NULL,
        serviceDate TEXT NOT NULL,
        cost REAL,
        notes TEXT,
        workshopName TEXT,
        workshopRating INTEGER,
        workshopReview TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_schedules (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        type INTEGER NOT NULL,
        dueAtKm REAL NOT NULL,
        dueByDate TEXT NOT NULL,
        remainingKm REAL NOT NULL,
        remainingDays INTEGER NOT NULL,
        isOverdue INTEGER NOT NULL DEFAULT 0,
        estimatedDueDate TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_mileage_vehicle_date ON mileage_records(vehicleId, date)');
    await db.execute(
        'CREATE INDEX idx_maintenance_vehicle_type ON maintenance_records(vehicleId, type)');
    await db.execute(
        'CREATE INDEX idx_schedules_vehicle ON maintenance_schedules(vehicleId)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_mileage_unique ON mileage_records(vehicleId, date)');

    // Custom intervals table
    await _createCustomIntervalsTable(db);

    // Vehicle documents table (pajak & STNK)
    await _createVehicleDocumentsTable(db);

    // Driver tables
    await _createDriverTables(db);

    // Fuel records table
    await _createFuelTables(db);

    // Maintenance photos table
    await _createMaintenancePhotosTable(db);

    // Daily checklists table
    await _createDailyChecklistsTable(db);

    // Maintenance budgets table
    await _createMaintenanceBudgetsTable(db);

    // Expense records table
    await _createExpenseRecordsTable(db);

    // Trouble logs table
    await _createTroubleLogsTable(db);

    // Annual km targets table
    await _createAnnualKmTargetsTable(db);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
