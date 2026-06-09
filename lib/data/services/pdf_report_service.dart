import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/maintenance_record.dart';
import '../../domain/models/maintenance_schedule.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../repositories/cost_report_repository.dart';

/// Service for generating PDF reports in Indonesian for OtoBuzz.
class PdfReportService {
  static const _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const _headerBgColor = PdfColor.fromInt(0xFF1976D2);
  static const _altRowColor = PdfColor.fromInt(0xFFF5F5F5);
  static const _white = PdfColors.white;

  // ============================================================
  // Maintenance Cost Report
  // ============================================================

  /// Generates a professional PDF cost report.
  Future<Uint8List> generateMaintenanceCostReport({
    required double totalCost,
    required List<CostByType> costByType,
    required List<CostByVehicle> costByVehicle,
    required List<MaintenanceRecord> records,
    required DateTime from,
    required DateTime to,
    String? vehicleName,
  }) async {
    final pdf = pw.Document(
      author: 'OtoBuzz',
      title: 'Laporan Biaya Perawatan',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          'Laporan Biaya Perawatan',
          from: from,
          to: to,
          vehicleName: vehicleName,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary section
          _buildSummarySection(totalCost),
          pw.SizedBox(height: 20),

          // Records table
          if (records.isNotEmpty) ...[
            _buildSectionTitle('Detail Perawatan'),
            pw.SizedBox(height: 8),
            _buildRecordsTable(records),
            pw.SizedBox(height: 20),
          ],

          // Breakdown by type
          if (costByType.isNotEmpty) ...[
            _buildSectionTitle('Rincian Per Jenis Perawatan'),
            pw.SizedBox(height: 8),
            _buildCostByTypeTable(costByType, totalCost),
            pw.SizedBox(height: 20),
          ],

          // Breakdown by vehicle
          if (costByVehicle.isNotEmpty && vehicleName == null) ...[
            _buildSectionTitle('Rincian Per Kendaraan'),
            pw.SizedBox(height: 8),
            _buildCostByVehicleTable(costByVehicle, totalCost),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // Vehicle Report
  // ============================================================

  /// Generates a vehicle-specific PDF report.
  Future<Uint8List> generateVehicleReport({
    required Vehicle vehicle,
    required List<MaintenanceSchedule> schedules,
    required List<MaintenanceRecord> recentHistory,
    required double totalMileage,
    required double avgDailyMileage,
  }) async {
    final pdf = pw.Document(
      author: 'OtoBuzz',
      title: 'Laporan Kendaraan - ${vehicle.name}',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          'Laporan Kendaraan',
          subtitle: vehicle.name,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Vehicle info
          _buildVehicleInfoSection(vehicle),
          pw.SizedBox(height: 20),

          // Mileage summary
          _buildMileageSummarySection(totalMileage, avgDailyMileage),
          pw.SizedBox(height: 20),

          // Maintenance schedule status
          if (schedules.isNotEmpty) ...[
            _buildSectionTitle('Status Jadwal Perawatan'),
            pw.SizedBox(height: 8),
            _buildScheduleTable(schedules),
            pw.SizedBox(height: 20),
          ],

          // Recent maintenance history
          if (recentHistory.isNotEmpty) ...[
            _buildSectionTitle('Riwayat Perawatan Terakhir'),
            pw.SizedBox(height: 8),
            _buildRecentHistoryTable(recentHistory),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // Header & Footer
  // ============================================================

  pw.Widget _buildReportHeader(
    String title, {
    DateTime? from,
    DateTime? to,
    String? vehicleName,
    String? subtitle,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'OtoBuzz',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Fleet Maintenance Tracker',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: _primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _primaryColor, thickness: 2),
          pw.SizedBox(height: 8),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          if (from != null && to != null)
            pw.Text(
              'Periode: ${_formatDate(from)} - ${_formatDate(to)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          if (vehicleName != null)
            pw.Text(
              'Kendaraan: $vehicleName',
              style: const pw.TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final now = DateTime.now();
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dibuat oleh OtoBuzz pada ${_formatDate(now)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Cost Report Sections
  // ============================================================

  pw.Widget _buildSummarySection(double totalCost) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE3F2FD),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _primaryColor, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'Total Biaya',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Rp ${_formatCurrency(totalCost)}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRecordsTable(List<MaintenanceRecord> records) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: _white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
      headerPadding: const pw.EdgeInsets.all(6),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _altRowColor),
      headers: ['Tanggal', 'Jenis Perawatan', 'Biaya', 'Bengkel'],
      data: records.map((r) {
        return [
          _formatDate(r.serviceDate),
          r.type.displayName,
          r.cost != null ? 'Rp ${_formatCurrency(r.cost!)}' : '-',
          r.workshopName ?? '-',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildCostByTypeTable(
      List<CostByType> costByType, double totalCost) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: _white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
      headerPadding: const pw.EdgeInsets.all(6),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _altRowColor),
      headers: ['Jenis Perawatan', 'Jumlah', 'Total Biaya', 'Persentase'],
      data: costByType.map((item) {
        final percentage = totalCost > 0
            ? (item.totalCost / totalCost * 100).toStringAsFixed(1)
            : '0.0';
        return [
          item.type.displayName,
          '${item.count}x',
          'Rp ${_formatCurrency(item.totalCost)}',
          '$percentage%',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildCostByVehicleTable(
      List<CostByVehicle> costByVehicle, double totalCost) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: _white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
      headerPadding: const pw.EdgeInsets.all(6),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _altRowColor),
      headers: ['Kendaraan', 'Jumlah', 'Total Biaya', 'Persentase'],
      data: costByVehicle.map((item) {
        final percentage = totalCost > 0
            ? (item.totalCost / totalCost * 100).toStringAsFixed(1)
            : '0.0';
        return [
          item.vehicleName,
          '${item.count}x',
          'Rp ${_formatCurrency(item.totalCost)}',
          '$percentage%',
        ];
      }).toList(),
    );
  }

  // ============================================================
  // Vehicle Report Sections
  // ============================================================

  pw.Widget _buildVehicleInfoSection(Vehicle vehicle) {
    final typeLabel =
        vehicle.type == VehicleType.car ? 'Mobil' : 'Motor';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE3F2FD),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _primaryColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informasi Kendaraan',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Nama', vehicle.name),
          _buildInfoRow('Plat Nomor', vehicle.plateNumber),
          _buildInfoRow('Jenis', typeLabel),
          _buildInfoRow('Tahun', vehicle.year.toString()),
          _buildInfoRow(
              'Total Kilometer', '${vehicle.totalMileageKm.round()} km'),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            ': $value',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMileageSummarySection(
      double totalMileage, double avgDailyMileage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'Total Kilometer',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${totalMileage.round()} km',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Container(width: 1, height: 40, color: PdfColors.grey400),
          pw.Column(
            children: [
              pw.Text(
                'Rata-rata Harian',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${avgDailyMileage.toStringAsFixed(1)} km/hari',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScheduleTable(List<MaintenanceSchedule> schedules) {
    // Separate overdue and due items
    final overdue = schedules.where((s) => s.isOverdue).toList();
    final upcoming = schedules.where((s) => !s.isOverdue).toList();

    final allItems = [...overdue, ...upcoming];

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: _white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
      headerPadding: const pw.EdgeInsets.all(6),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _altRowColor),
      headers: ['Jenis Perawatan', 'Status', 'Sisa KM', 'Sisa Hari'],
      data: allItems.map((s) {
        final status = s.isOverdue ? 'TERLAMBAT' : 'Terjadwal';
        return [
          s.type.displayName,
          status,
          '${s.remainingKm.round()} km',
          '${s.remainingDays} hari',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildRecentHistoryTable(List<MaintenanceRecord> records) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: _white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _headerBgColor),
      headerPadding: const pw.EdgeInsets.all(6),
      cellPadding: const pw.EdgeInsets.all(6),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _altRowColor),
      headers: ['Tanggal', 'Jenis Perawatan', 'KM', 'Biaya', 'Bengkel'],
      data: records.map((r) {
        return [
          _formatDate(r.serviceDate),
          r.type.displayName,
          '${r.mileageAtService.round()} km',
          r.cost != null ? 'Rp ${_formatCurrency(r.cost!)}' : '-',
          r.workshopName ?? '-',
        ];
      }).toList(),
    );
  }

  // ============================================================
  // Common Helpers
  // ============================================================

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: _primaryColor, width: 3),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  /// Formats a date in Indonesian format: DD MMMM YYYY
  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Formats currency with Indonesian dot separators: 1.250.000
  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
