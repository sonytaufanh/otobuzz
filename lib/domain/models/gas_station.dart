import 'package:equatable/equatable.dart';

enum GasStationBrand { pertamina, bp, vivo, shell, other }

class GasStation extends Equatable {
  final String id;
  final String name;
  final GasStationBrand brand;
  final double latitude;
  final double longitude;
  final String? address;
  final String? operator;

  const GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.latitude,
    required this.longitude,
    this.address,
    this.operator,
  });

  @override
  List<Object?> get props => [id, name, brand, latitude, longitude, address, operator];

  /// Detect brand from Overpass API tags
  static GasStationBrand detectBrand(Map<String, dynamic> tags) {
    final brand = (tags['brand'] ?? '').toString().toLowerCase();
    final op = (tags['operator'] ?? '').toString().toLowerCase();
    final name = (tags['name'] ?? '').toString().toLowerCase();
    final combined = '$brand $op $name';

    if (combined.contains('pertamina')) return GasStationBrand.pertamina;
    if (combined.contains('bp') || combined.contains('british petroleum')) {
      return GasStationBrand.bp;
    }
    if (combined.contains('vivo')) return GasStationBrand.vivo;
    if (combined.contains('shell')) return GasStationBrand.shell;
    return GasStationBrand.other;
  }

  /// Create from Overpass API element
  factory GasStation.fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    final brand = detectBrand(tags);
    final name = tags['name'] ?? tags['brand'] ?? 'SPBU';

    return GasStation(
      id: element['id'].toString(),
      name: name,
      brand: brand,
      latitude: (element['lat'] as num).toDouble(),
      longitude: (element['lon'] as num).toDouble(),
      address: tags['addr:street'] ?? tags['addr:full'],
      operator: tags['operator'],
    );
  }

  String get brandDisplayName {
    switch (brand) {
      case GasStationBrand.pertamina:
        return 'Pertamina';
      case GasStationBrand.bp:
        return 'BP';
      case GasStationBrand.vivo:
        return 'Vivo';
      case GasStationBrand.shell:
        return 'Shell';
      case GasStationBrand.other:
        return 'Lainnya';
    }
  }
}
