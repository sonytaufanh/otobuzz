enum MaintenanceType {
  oilChange,
  tireReplacement,
  brakePads,
  airFilter,
  sparkPlug,
  chainLube,
  coolant,
  brakeFluid,
  transmission,
}

extension MaintenanceTypeExtension on MaintenanceType {
  String get displayName {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'Ganti Oli';
      case MaintenanceType.tireReplacement:
        return 'Ganti Ban';
      case MaintenanceType.brakePads:
        return 'Ganti Kampas Rem';
      case MaintenanceType.airFilter:
        return 'Ganti Filter Udara';
      case MaintenanceType.sparkPlug:
        return 'Ganti Busi';
      case MaintenanceType.chainLube:
        return 'Pelumas Rantai';
      case MaintenanceType.coolant:
        return 'Ganti Coolant';
      case MaintenanceType.brakeFluid:
        return 'Ganti Minyak Rem';
      case MaintenanceType.transmission:
        return 'Ganti Oli Transmisi';
    }
  }

  String get actionText {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'ganti oli';
      case MaintenanceType.tireReplacement:
        return 'ganti ban';
      case MaintenanceType.brakePads:
        return 'ganti kampas rem';
      case MaintenanceType.airFilter:
        return 'ganti filter udara';
      case MaintenanceType.sparkPlug:
        return 'ganti busi';
      case MaintenanceType.chainLube:
        return 'pelumas rantai';
      case MaintenanceType.coolant:
        return 'ganti coolant';
      case MaintenanceType.brakeFluid:
        return 'ganti minyak rem';
      case MaintenanceType.transmission:
        return 'ganti oli transmisi';
    }
  }
}
