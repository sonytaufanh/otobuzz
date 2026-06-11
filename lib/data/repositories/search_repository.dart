import '../database/database_helper.dart';

enum SearchResultType { vehicle, maintenance, workshop }

class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String id;
  final String? parentId; // vehicleId for maintenance/mileage

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.id,
    this.parentId,
  });
}

class SearchRepository {
  final DatabaseHelper _dbHelper;

  SearchRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Search across vehicles, maintenance_records, and mileage_records.
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final db = await _dbHelper.database;
    final searchTerm = '%${query.trim()}%';
    final results = <SearchResult>[];

    // Search vehicles by name or plate number
    final vehicles = await db.query(
      'vehicles',
      where: 'name LIKE ? OR plateNumber LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      limit: 10,
    );

    for (final v in vehicles) {
      results.add(SearchResult(
        type: SearchResultType.vehicle,
        title: v['name'] as String,
        subtitle: '${v['plateNumber']} • ${(v['totalMileageKm'] as num).round()} km',
        id: v['id'] as String,
      ));
    }

    // Search maintenance records by workshopName or type
    final maintenance = await db.rawQuery('''
      SELECT m.id, m.vehicleId, m.type, m.workshopName, m.serviceDate, v.name as vehicleName
      FROM maintenance_records m
      JOIN vehicles v ON m.vehicleId = v.id
      WHERE m.workshopName LIKE ? OR m.notes LIKE ?
      LIMIT 10
    ''', [searchTerm, searchTerm]);

    for (final m in maintenance) {
      final workshopName = m['workshopName'] as String?;
      final vehicleName = m['vehicleName'] as String;
      results.add(SearchResult(
        type: SearchResultType.maintenance,
        title: workshopName ?? 'Perawatan',
        subtitle: '$vehicleName • ${m['serviceDate']}',
        id: m['id'] as String,
        parentId: m['vehicleId'] as String?,
      ));
    }

    // Search workshops (distinct workshop names)
    final workshops = await db.rawQuery('''
      SELECT DISTINCT workshopName, vehicleId, id
      FROM maintenance_records
      WHERE workshopName LIKE ? AND workshopName IS NOT NULL
      LIMIT 10
    ''', [searchTerm]);

    // Deduplicate workshops already in maintenance results
    final seenWorkshops = <String>{};
    for (final m in maintenance) {
      final name = m['workshopName'] as String?;
      if (name != null) seenWorkshops.add(name);
    }

    for (final w in workshops) {
      final name = w['workshopName'] as String;
      if (!seenWorkshops.contains(name)) {
        results.add(SearchResult(
          type: SearchResultType.workshop,
          title: name,
          subtitle: 'Bengkel',
          id: w['id'] as String,
          parentId: w['vehicleId'] as String?,
        ));
      }
    }

    return results;
  }
}
