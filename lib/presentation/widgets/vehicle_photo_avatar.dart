import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/vehicle_type.dart';

class VehiclePhotoAvatar extends StatelessWidget {
  final String? photoPath;
  final VehicleType vehicleType;
  final double radius;

  const VehiclePhotoAvatar({
    super.key,
    this.photoPath,
    required this.vehicleType,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && File(photoPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photoPath!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        vehicleType == VehicleType.motorcycle
            ? Icons.two_wheeler
            : Icons.directions_car,
        color: Theme.of(context).colorScheme.primary,
        size: radius,
      ),
    );
  }
}
