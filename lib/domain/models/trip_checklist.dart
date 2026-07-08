import 'package:equatable/equatable.dart';

enum TripCheckItemCategory {
  engine,
  brakes,
  tires,
  fluids,
  electrical,
  safety,
  documents,
}

extension TripCheckItemCategoryExtension on TripCheckItemCategory {
  String get displayName {
    switch (this) {
      case TripCheckItemCategory.engine:
        return 'Mesin';
      case TripCheckItemCategory.brakes:
        return 'Rem';
      case TripCheckItemCategory.tires:
        return 'Ban';
      case TripCheckItemCategory.fluids:
        return 'Cairan';
      case TripCheckItemCategory.electrical:
        return 'Kelistrikan';
      case TripCheckItemCategory.safety:
        return 'Keselamatan';
      case TripCheckItemCategory.documents:
        return 'Dokumen';
    }
  }

  String get emoji {
    switch (this) {
      case TripCheckItemCategory.engine:
        return '⚙️';
      case TripCheckItemCategory.brakes:
        return '🛑';
      case TripCheckItemCategory.tires:
        return '🔄';
      case TripCheckItemCategory.fluids:
        return '💧';
      case TripCheckItemCategory.electrical:
        return '⚡';
      case TripCheckItemCategory.safety:
        return '🦺';
      case TripCheckItemCategory.documents:
        return '📄';
    }
  }
}

class TripCheckItem extends Equatable {
  final String id;
  final String label;
  final String description;
  final TripCheckItemCategory category;
  final bool isChecked;
  final bool isCritical;

  const TripCheckItem({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    this.isChecked = false,
    this.isCritical = false,
  });

  TripCheckItem copyWith({
    String? id,
    String? label,
    String? description,
    TripCheckItemCategory? category,
    bool? isChecked,
    bool? isCritical,
  }) {
    return TripCheckItem(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      isCritical: isCritical ?? this.isCritical,
    );
  }

  @override
  List<Object?> get props => [id, label, description, category, isChecked, isCritical];
}

class TripChecklist extends Equatable {
  final String id;
  final String vehicleId;
  final String destination;
  final int estimatedKm;
  final DateTime tripDate;
  final List<TripCheckItem> items;
  final DateTime createdAt;

  const TripChecklist({
    required this.id,
    required this.vehicleId,
    required this.destination,
    required this.estimatedKm,
    required this.tripDate,
    required this.items,
    required this.createdAt,
  });

  bool get isComplete => items.every((i) => i.isChecked);
  int get checkedCount => items.where((i) => i.isChecked).length;
  int get criticalUnchecked => items.where((i) => i.isCritical && !i.isChecked).length;

  TripChecklist copyWith({
    String? id,
    String? vehicleId,
    String? destination,
    int? estimatedKm,
    DateTime? tripDate,
    List<TripCheckItem>? items,
    DateTime? createdAt,
  }) {
    return TripChecklist(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      destination: destination ?? this.destination,
      estimatedKm: estimatedKm ?? this.estimatedKm,
      tripDate: tripDate ?? this.tripDate,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, destination, estimatedKm, tripDate, items, createdAt];
}

/// Default checklist items for pre-trip inspection
List<TripCheckItem> getDefaultTripCheckItems({bool isMotorcycle = false}) {
  final items = <TripCheckItem>[
    // Engine
    TripCheckItem(
      id: 'oil_level',
      label: 'Cek Oli Mesin',
      description: 'Pastikan level oli di antara tanda MIN dan MAX. Ganti jika warnanya hitam pekat.',
      category: TripCheckItemCategory.engine,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'air_filter',
      label: 'Filter Udara',
      description: 'Pastikan filter udara tidak terlalu kotor agar mesin tidak boros.',
      category: TripCheckItemCategory.engine,
    ),
    // Brakes
    TripCheckItem(
      id: 'brake_front',
      label: 'Rem Depan',
      description: 'Tekan tuas rem depan, pastikan responsif dan tidak terasa kosong.',
      category: TripCheckItemCategory.brakes,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'brake_rear',
      label: 'Rem Belakang',
      description: 'Injak/tekan tuas rem belakang, pastikan kendaraan berhenti dengan baik.',
      category: TripCheckItemCategory.brakes,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'brake_fluid',
      label: 'Minyak Rem',
      description: 'Cek level minyak rem di reservoir. Harus di antara MIN dan MAX.',
      category: TripCheckItemCategory.brakes,
      isCritical: true,
    ),
    // Tires
    TripCheckItem(
      id: 'tire_front_pressure',
      label: 'Tekanan Ban Depan',
      description: 'Cek tekanan angin sesuai rekomendasi pabrik (biasanya 28-32 psi untuk motor).',
      category: TripCheckItemCategory.tires,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'tire_rear_pressure',
      label: 'Tekanan Ban Belakang',
      description: 'Cek tekanan angin ban belakang. Ban kurang angin bikin boros BBM dan berbahaya.',
      category: TripCheckItemCategory.tires,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'tire_condition',
      label: 'Kondisi Ban',
      description: 'Periksa alur ban, pastikan tidak botak dan tidak ada tonjolan/retak di dinding ban.',
      category: TripCheckItemCategory.tires,
      isCritical: true,
    ),
    // Fluids
    TripCheckItem(
      id: 'fuel',
      label: 'BBM Penuh',
      description: 'Isi bensin penuh sebelum berangkat agar tidak khawatir kehabisan di perjalanan.',
      category: TripCheckItemCategory.fluids,
      isCritical: true,
    ),
    // Electrical
    TripCheckItem(
      id: 'headlight',
      label: 'Lampu Depan',
      description: 'Pastikan lampu depan menyala normal, baik lampu jauh maupun dekat.',
      category: TripCheckItemCategory.electrical,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'tail_light',
      label: 'Lampu Belakang & Rem',
      description: 'Minta bantuan orang lain untuk cek lampu rem belakang menyala saat rem ditekan.',
      category: TripCheckItemCategory.electrical,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'turn_signal',
      label: 'Lampu Sein',
      description: 'Pastikan kedua sein kiri dan kanan berfungsi dengan baik.',
      category: TripCheckItemCategory.electrical,
    ),
    // Safety
    TripCheckItem(
      id: 'helmet',
      label: 'Helm SNI',
      description: 'Pastikan helm dalam kondisi baik, tidak retak, dan gesper berfungsi.',
      category: TripCheckItemCategory.safety,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'rain_gear',
      label: 'Jas Hujan',
      description: 'Bawa jas hujan terutama di musim hujan. Pilih yang reflektif agar terlihat.',
      category: TripCheckItemCategory.safety,
    ),
    TripCheckItem(
      id: 'emergency_kit',
      label: 'Perlengkapan Darurat',
      description: 'Bawa ban serep/tambal ban portable, kotak P3K, dan nomor bengkel terdekat.',
      category: TripCheckItemCategory.safety,
    ),
    // Documents
    TripCheckItem(
      id: 'sim',
      label: 'SIM',
      description: 'Pastikan SIM tidak expired dan dibawa dalam dompet.',
      category: TripCheckItemCategory.documents,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'stnk',
      label: 'STNK',
      description: 'Pastikan STNK aktif/tidak mati pajak dan dibawa.',
      category: TripCheckItemCategory.documents,
      isCritical: true,
    ),
    TripCheckItem(
      id: 'insurance',
      label: 'Asuransi Kendaraan',
      description: 'Catat nomor polis asuransi dan nomor darurat untuk klaim.',
      category: TripCheckItemCategory.documents,
    ),
  ];

  if (!isMotorcycle) {
    // Car-specific items
    return [
      ...items,
      TripCheckItem(
        id: 'coolant',
        label: 'Air Radiator',
        description: 'Cek level air radiator di reservoir. Tambah jika kurang dari batas MIN.',
        category: TripCheckItemCategory.fluids,
        isCritical: true,
      ),
      TripCheckItem(
        id: 'wiper_fluid',
        label: 'Air Wiper',
        description: 'Pastikan reservoir air wiper cukup untuk perjalanan jauh.',
        category: TripCheckItemCategory.fluids,
      ),
      TripCheckItem(
        id: 'spare_tire',
        label: 'Ban Serep',
        description: 'Cek kondisi dan tekanan ban serep. Pastikan dongkrak dan kunci roda tersedia.',
        category: TripCheckItemCategory.tires,
        isCritical: true,
      ),
    ];
  }

  return items;
}
