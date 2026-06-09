import 'package:flutter/material.dart';

/// Dialog shown when a mileage record already exists for the same vehicle and date.
/// Asks user to confirm replacement of existing record.
class DuplicateEntryDialog extends StatelessWidget {
  final double existingKm;
  final VoidCallback onReplace;
  final VoidCallback onCancel;

  const DuplicateEntryDialog({
    super.key,
    required this.existingKm,
    required this.onReplace,
    required this.onCancel,
  });

  /// Shows the duplicate entry dialog and returns true if user chose to replace.
  static Future<bool> show(BuildContext context, {required double existingKm}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DuplicateEntryDialog(
        existingKm: existingKm,
        onReplace: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Data Sudah Ada'),
      content: Text(
        'Sudah ada catatan km untuk tanggal ini. Ganti dengan yang baru?',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: onReplace,
          child: const Text('Ganti'),
        ),
      ],
    );
  }
}
