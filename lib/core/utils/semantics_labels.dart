/// Centralized accessibility semantics labels for OtoBuzz app.
/// Uses Bahasa Indonesia for local accessibility.
class AppSemantics {
  AppSemantics._();

  // ─── Home Screen ───────────────────────────────────────────────────────────
  static const String fleetOverviewTitle = 'Ringkasan armada';
  static const String totalVehiclesCount = 'Total kendaraan';
  static const String overdueMaintenanceCount =
      'Jumlah kendaraan dengan perawatan terlambat';
  static const String upcomingMaintenanceCount =
      'Jumlah kendaraan dengan perawatan segera';
  static String fleetHealthScore(int score) =>
      'Skor kesehatan armada $score dari 100';
  static String vehicleCard(String name, String plate) =>
      'Kendaraan $name, plat nomor $plate';

  // ─── Action Buttons ────────────────────────────────────────────────────────
  static const String addVehicleButton = 'Tambah kendaraan baru';
  static const String inputKmButton = 'Input kilometer harian';
  static const String deleteVehicleButton = 'Hapus kendaraan';
  static const String editVehicleButton = 'Edit kendaraan';
  static const String recordMaintenanceButton = 'Catat perawatan selesai';
  static const String viewHistoryButton = 'Lihat riwayat perawatan';
  static const String addFuelButton = 'Tambah catatan BBM';
  static const String searchButton = 'Cari kendaraan atau catatan';
  static const String settingsButton = 'Pengaturan aplikasi';
  static const String exportButton = 'Ekspor data';

  // ─── Add KM Screen ─────────────────────────────────────────────────────────
  static const String kmInputField = 'Masukkan jarak tempuh dalam kilometer';
  static const String vehicleSelector = 'Pilih kendaraan';
  static const String dateSelector = 'Pilih tanggal';
  static const String submitKmButton = 'Simpan kilometer harian';

  // ─── Vehicle Detail ────────────────────────────────────────────────────────
  static String vehicleHealthScore(String name, int score) =>
      'Skor kesehatan $name: $score dari 100';
  static const String maintenanceScheduleCard = 'Jadwal perawatan';
  static const String mileageHistoryCard = 'Riwayat kilometer';
  static const String costSummaryCard = 'Ringkasan biaya perawatan';

  // ─── Bottom Navigation ─────────────────────────────────────────────────────
  static const String navHome = 'Tab beranda';
  static const String navVehicles = 'Tab daftar kendaraan';
  static const String navInputKm = 'Tab input kilometer';
  static const String navFuel = 'Tab BBM';
  static const String navReport = 'Tab laporan biaya';

  // ─── Undo Actions ──────────────────────────────────────────────────────────
  static const String undoDeleteVehicle = 'Batalkan hapus kendaraan';
  static const String undoDeleteMileage = 'Batalkan hapus catatan km';
  static const String undoDeleteMaintenance = 'Batalkan hapus catatan perawatan';
}
