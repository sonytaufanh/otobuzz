import 'package:flutter/material.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/usecases/health_score_calculator.dart';
import '../widgets/health_score_widget.dart';

/// Detail screen showing full health score breakdown, issues,
/// recommendations, and tips for a vehicle.
class HealthScoreScreen extends StatelessWidget {
  final Vehicle vehicle;
  final HealthScoreResult result;

  const HealthScoreScreen({
    super.key,
    required this.vehicle,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skor Kesehatan Kendaraan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle name
          Text(
            vehicle.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            vehicle.plateNumber,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Large animated health score circle
          Center(
            child: HealthScoreWidget(
              result: result,
              size: 200,
            ),
          ),
          const SizedBox(height: 32),

          // Score breakdown section
          _buildBreakdownSection(context),
          const SizedBox(height: 24),

          // Issues section
          if (result.issues.isNotEmpty) ...[
            _buildIssuesSection(context),
            const SizedBox(height: 24),
          ],

          // Recommendations section
          if (result.recommendations.isNotEmpty) ...[
            _buildRecommendationsSection(context),
            const SizedBox(height: 24),
          ],

          // Tips section
          _buildTipsSection(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {
    final b = result.breakdown;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Perhitungan Skor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _BreakdownRow(
              label: 'Skor dasar',
              value: '${b.baseScore}',
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (b.overduePenalty > 0)
              _BreakdownRow(
                label:
                    'Perawatan terlambat (${b.overdueCount} item × -15)',
                value: '-${b.overduePenalty}',
                color: Colors.red,
              ),
            if (b.warningPenalty > 0)
              _BreakdownRow(
                label:
                    'Perawatan segera jatuh tempo (${b.warningCount} item × -5)',
                value: '-${b.warningPenalty}',
                color: Colors.orange,
              ),
            if (b.onTimeBonus > 0)
              _BreakdownRow(
                label:
                    'Perawatan tepat waktu (${b.onTimeCount} item × +5)',
                value: '+${b.onTimeBonus}',
                color: Colors.green,
              ),
            if (b.consistencyBonus > 0)
              _BreakdownRow(
                label:
                    'Bonus konsistensi (${b.kmLoggingStreak} hari logging)',
                value: '+${b.consistencyBonus}',
                color: Colors.green,
              ),
            if (b.consistencyBonus == 0)
              _BreakdownRow(
                label:
                    'Bonus konsistensi (${b.kmLoggingStreak}/7 hari)',
                value: '+0',
                color: Theme.of(context).colorScheme.outline,
              ),
            if (b.documentPenalty > 0)
              _BreakdownRow(
                label: 'Dokumen expired'
                    '${b.pajakExpired ? ' (Pajak)' : ''}'
                    '${b.stnkExpired ? ' (STNK)' : ''}',
                value: '-${b.documentPenalty}',
                color: Colors.red,
              ),
            const Divider(),
            _BreakdownRow(
              label: 'Skor akhir',
              value: '${result.score}/100',
              color: result.color,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Masalah',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...result.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(issue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                ),
              ],
            ),
            const Divider(),
            ...result.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(rec),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    const tips = [
      'Catat km harian secara rutin untuk mendapatkan bonus konsistensi (+10 poin).',
      'Lakukan perawatan sebelum jatuh tempo untuk menjaga skor tetap tinggi.',
      'Perpanjang pajak & STNK sebelum expired untuk menghindari penalti -10 poin.',
      'Perawatan yang tepat waktu meningkatkan umur kendaraan dan mengurangi biaya jangka panjang.',
      'Gunakan fitur jadwal perawatan untuk mendapatkan pengingat otomatis.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tips Perawatan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Breakdown Row Widget
// =============================================================================

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
