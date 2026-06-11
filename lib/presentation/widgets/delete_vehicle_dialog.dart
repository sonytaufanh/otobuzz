import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';

/// A confirmation dialog for deleting a vehicle.
///
/// Shows a warning that all maintenance history will be lost.
/// Returns `true` if the user confirms deletion, `false` or `null` otherwise.
class DeleteVehicleDialog extends StatelessWidget {
  final String vehicleName;

  const DeleteVehicleDialog({super.key, required this.vehicleName});

  /// Shows the delete confirmation dialog.
  ///
  /// Returns `true` if confirmed, `null` or `false` if cancelled.
  static Future<bool?> show(BuildContext context, String vehicleName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteVehicleDialog(vehicleName: vehicleName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
      title: Text('Hapus $vehicleName?'),
      content: const Text(
        'Hapus kendaraan ini? Semua riwayat perawatan akan hilang.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            AppHaptics.heavyImpact();
            Navigator.of(context).pop(true);
          },
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
