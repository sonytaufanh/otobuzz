import 'package:flutter/material.dart';

/// A swipeable list item widget.
/// Swipe left to delete (red), swipe right for a quick action (green).
class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final String itemId;
  final String deleteLabel;
  final String? actionLabel;
  final IconData deleteIcon;
  final IconData? actionIcon;
  final VoidCallback onDelete;
  final VoidCallback? onAction;
  final String confirmDeleteTitle;
  final String confirmDeleteMessage;

  const SwipeableListItem({
    super.key,
    required this.child,
    required this.itemId,
    this.deleteLabel = 'Hapus',
    this.actionLabel,
    this.deleteIcon = Icons.delete,
    this.actionIcon,
    required this.onDelete,
    this.onAction,
    this.confirmDeleteTitle = 'Konfirmasi Hapus',
    this.confirmDeleteMessage = 'Yakin ingin menghapus item ini?',
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: Text(confirmDeleteTitle),
        content: Text(confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(itemId),
      direction: onAction != null
          ? DismissDirection.horizontal
          : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        } else if (direction == DismissDirection.startToEnd) {
          onAction?.call();
          return false; // Don't dismiss, just trigger the action
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: onAction != null
          ? Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.green,
              child: Row(
                children: [
                  Icon(actionIcon ?? Icons.edit, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    actionLabel ?? 'Aksi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : null,
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              deleteLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(deleteIcon, color: Colors.white),
          ],
        ),
      ),
      child: child,
    );
  }
}
