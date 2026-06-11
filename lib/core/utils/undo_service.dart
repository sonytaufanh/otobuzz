import 'package:flutter/material.dart';

/// Service for showing undo-able actions via snackbar.
///
/// When a destructive action is performed (e.g., delete), the data is removed
/// immediately and a snackbar is shown with an undo button. If the user taps
/// "Batalkan" within the timeout, the [undoAction] restores the data.
class UndoService {
  UndoService._();

  /// Shows a snackbar with undo button. If undo is pressed within [timeout],
  /// executes the [undoAction] to restore deleted data.
  ///
  /// [context] - BuildContext with access to ScaffoldMessenger
  /// [message] - Text to display in the snackbar
  /// [undoAction] - Async function that restores the deleted data
  /// [timeout] - Duration before the snackbar auto-dismisses (default: 5s)
  static void showUndoSnackbar({
    required BuildContext context,
    required String message,
    required Future<void> Function() undoAction,
    Duration timeout = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: timeout,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Batalkan',
          onPressed: () async {
            await undoAction();
          },
        ),
      ),
    );
  }
}
