import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/trouble_log.dart';
import '../../domain/models/vehicle.dart';
import '../blocs/trouble_log/trouble_log_bloc.dart';
import 'trouble_log_form_screen.dart';

class TroubleLogScreen extends StatelessWidget {
  final Vehicle vehicle;

  const TroubleLogScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TroubleLogBloc>()..add(LoadTroubleLogs(vehicle.id)),
      child: _TroubleLogScreenContent(vehicle: vehicle),
    );
  }
}

class _TroubleLogScreenContent extends StatefulWidget {
  final Vehicle vehicle;

  const _TroubleLogScreenContent({required this.vehicle});

  @override
  State<_TroubleLogScreenContent> createState() => _TroubleLogScreenContentState();
}

class _TroubleLogScreenContentState extends State<_TroubleLogScreenContent> {
  bool _showResolvedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Kerusakan'),
        actions: [
          IconButton(
            icon: Icon(_showResolvedOnly ? Icons.check_circle : Icons.check_circle_outline),
            tooltip: _showResolvedOnly ? 'Tampilkan Semua' : 'Hanya Terselesaikan',
            onPressed: () {
              setState(() {
                _showResolvedOnly = !_showResolvedOnly;
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<TroubleLogBloc, TroubleLogState>(
        builder: (context, state) {
          if (state is TroubleLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TroubleLogError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is TroubleLogLoaded) {
            final logs = _showResolvedOnly
                ? state.logs.where((l) => l.isResolved).toList()
                : state.logs;

            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _showResolvedOnly
                          ? 'Belum ada kerusakan yang terselesaikan'
                          : 'Belum ada catatan kerusakan',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) => _buildLogCard(context, logs[index]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TroubleLogFormScreen(vehicle: widget.vehicle),
            ),
          );
          if (result == true && context.mounted) {
            context.read<TroubleLogBloc>().add(LoadTroubleLogs(widget.vehicle.id));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Kerusakan'),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, TroubleLog log) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: log.isResolved ? Colors.green : _getSeverityColor(log.severity),
          child: Icon(
            log.isResolved ? Icons.check : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          log.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: log.isResolved ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${log.severity.emoji} ${log.severity.displayName} • ${dateFormat.format(log.reportedDate)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(log.description),
                if (log.odometerKm != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 16),
                      const SizedBox(width: 4),
                      Text('${log.odometerKm!.toStringAsFixed(0)} km'),
                    ],
                  ),
                ],
                if (log.isResolved) ...[
                  const Divider(height: 24),
                  Text(
                    'Terselesaikan:',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text('Tanggal: ${dateFormat.format(log.resolvedDate!)}'),
                  if (log.resolutionNotes != null) ...[
                    const SizedBox(height: 4),
                    Text('Catatan: ${log.resolutionNotes}'),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!log.isResolved)
                      TextButton.icon(
                        onPressed: () => _markAsResolved(context, log),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Tandai Selesai'),
                      ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, log),
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(TroubleSeverity severity) {
    switch (severity) {
      case TroubleSeverity.low:
        return Colors.green;
      case TroubleSeverity.medium:
        return Colors.orange;
      case TroubleSeverity.high:
        return Colors.deepOrange;
      case TroubleSeverity.critical:
        return Colors.red;
    }
  }

  Future<void> _markAsResolved(BuildContext context, TroubleLog log) async {
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tandai kerusakan ini sudah diperbaiki?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Ganti oli, servis di bengkel X',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tandai Selesai'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      context.read<TroubleLogBloc>().add(
            MarkTroubleLogResolved(
              id: log.id,
              vehicleId: log.vehicleId,
              resolvedDate: DateTime.now(),
              resolutionNotes: noteController.text.isEmpty ? null : noteController.text,
            ),
          );
    }
  }

  Future<void> _confirmDelete(BuildContext context, TroubleLog log) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Hapus catatan "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      context.read<TroubleLogBloc>().add(DeleteTroubleLog(log.id, log.vehicleId));
    }
  }
}
