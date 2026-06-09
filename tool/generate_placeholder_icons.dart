// ignore_for_file: avoid_print

// Script to generate placeholder icon PNGs for OtoBuzz.
//
// Run with: dart run tool/generate_placeholder_icons.dart
//
// NOTE: These are minimal 1x1 blue placeholder PNGs.
// Replace them with proper 1024x1024 designed icons before release.
// See assets/icon/README.md for detailed specifications.

import 'dart:io';
import 'dart:typed_data';

/// Minimal valid PNG file (1x1 pixel, blue #1565C0)
final Uint8List placeholderIcon = Uint8List.fromList([
  // PNG Signature
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  // IHDR chunk (1x1, 8-bit RGB)
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
  0xDE,
  // IDAT chunk (pixel data: filter=0, R=0x15, G=0x65, B=0xC0)
  0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
  0x08, 0xD7, 0x63, 0x28, 0xC9, 0x60, 0x00, 0x00,
  0x00, 0x24, 0x00, 0x01, 0xA5, 0x34, 0x27, 0x88,
  // IEND chunk
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
  0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  final iconDir = Directory('assets/icon');
  if (!iconDir.existsSync()) {
    iconDir.createSync(recursive: true);
  }

  File('assets/icon/app_icon.png').writeAsBytesSync(placeholderIcon);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(placeholderIcon);

  print('✓ Placeholder icons created in assets/icon/');
  print('  - app_icon.png (1x1 blue pixel placeholder)');
  print('  - app_icon_foreground.png (1x1 blue pixel placeholder)');
  print('');
  print('IMPORTANT: Replace these with proper 1024x1024 designed icons.');
  print('See assets/icon/README.md for specifications.');
}
