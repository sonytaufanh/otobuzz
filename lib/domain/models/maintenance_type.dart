enum MaintenanceType {
  // Umum (motor & mobil)
  oilChange,
  tireReplacement,
  brakePads,
  airFilter,
  sparkPlug,
  coolant,
  brakeFluid,
  brakeFluidFlush,

  // Motor rantai
  chainLube,
  chainAdjust,

  // Oli gardan & transmisi
  transmission, // oli transmisi (mobil manual / motor)
  finalDriveOil, // oli gardan (motor matic / mobil)

  // CVT (matic)
  cvtRoller,
  cvtVBelt,
  cvtClutchShoe, // kampas ganda
  cvtDrivePlate, // mangkok ganda
  cvtSpring, // per CVT

  // Kopling
  clutchPlate, // kampas kopling

  // Lain-lain
  valveAdjust,
  throttleBodyClean,
  injectorClean,
  battery,
  wheelBearing,
  suspension,
}

extension MaintenanceTypeExtension on MaintenanceType {
  String get displayName {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'Ganti Oli Mesin';
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
      case MaintenanceType.chainAdjust:
        return 'Adjust Rantai';
      case MaintenanceType.coolant:
        return 'Ganti Coolant';
      case MaintenanceType.brakeFluid:
        return 'Ganti Minyak Rem';
      case MaintenanceType.brakeFluidFlush:
        return 'Kuras Sistem Rem';
      case MaintenanceType.transmission:
        return 'Ganti Oli Transmisi';
      case MaintenanceType.finalDriveOil:
        return 'Ganti Oli Gardan';
      case MaintenanceType.cvtRoller:
        return 'Ganti Roller CVT';
      case MaintenanceType.cvtVBelt:
        return 'Ganti V-Belt';
      case MaintenanceType.cvtClutchShoe:
        return 'Ganti Kampas Ganda';
      case MaintenanceType.cvtDrivePlate:
        return 'Ganti Mangkok Ganda';
      case MaintenanceType.cvtSpring:
        return 'Ganti Per CVT';
      case MaintenanceType.clutchPlate:
        return 'Ganti Kampas Kopling';
      case MaintenanceType.valveAdjust:
        return 'Klep (Valve) Adjustment';
      case MaintenanceType.throttleBodyClean:
        return 'Bersihkan Throttle Body';
      case MaintenanceType.injectorClean:
        return 'Bersihkan Injektor';
      case MaintenanceType.battery:
        return 'Ganti Aki';
      case MaintenanceType.wheelBearing:
        return 'Ganti Bearing Roda';
      case MaintenanceType.suspension:
        return 'Servis Suspensi';
    }
  }

  String get actionText {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'ganti oli mesin';
      case MaintenanceType.tireReplacement:
        return 'ganti ban';
      case MaintenanceType.brakePads:
        return 'ganti kampas rem';
      case MaintenanceType.airFilter:
        return 'ganti filter udara';
      case MaintenanceType.sparkPlug:
        return 'ganti busi';
      case MaintenanceType.chainLube:
        return 'lumasi rantai';
      case MaintenanceType.chainAdjust:
        return 'adjust rantai';
      case MaintenanceType.coolant:
        return 'ganti coolant';
      case MaintenanceType.brakeFluid:
        return 'ganti minyak rem';
      case MaintenanceType.brakeFluidFlush:
        return 'kuras sistem rem';
      case MaintenanceType.transmission:
        return 'ganti oli transmisi';
      case MaintenanceType.finalDriveOil:
        return 'ganti oli gardan';
      case MaintenanceType.cvtRoller:
        return 'ganti roller CVT';
      case MaintenanceType.cvtVBelt:
        return 'ganti V-belt';
      case MaintenanceType.cvtClutchShoe:
        return 'ganti kampas ganda';
      case MaintenanceType.cvtDrivePlate:
        return 'ganti mangkok ganda';
      case MaintenanceType.cvtSpring:
        return 'ganti per CVT';
      case MaintenanceType.clutchPlate:
        return 'ganti kampas kopling';
      case MaintenanceType.valveAdjust:
        return 'adjust klep';
      case MaintenanceType.throttleBodyClean:
        return 'bersihkan throttle body';
      case MaintenanceType.injectorClean:
        return 'bersihkan injektor';
      case MaintenanceType.battery:
        return 'ganti aki';
      case MaintenanceType.wheelBearing:
        return 'ganti bearing roda';
      case MaintenanceType.suspension:
        return 'servis suspensi';
    }
  }

  /// Penjelasan fungsi part dalam bahasa sederhana
  /// agar mudah dipahami anak & wanita.
  String get description {
    switch (this) {
      case MaintenanceType.oilChange:
        return 'Oli itu seperti darah di tubuh kita. Tugasnya melicinkan '
            'bagian dalam mesin biar tidak gesekan dan panas. Kalau sudah '
            'kotor atau lama, mesin bisa rusak.';
      case MaintenanceType.tireReplacement:
        return 'Ban itu seperti sepatu buat kendaraan. Kalau sudah botak '
            '(tidak bergaris lagi), kendaraan gampang slip apalagi saat '
            'jalan basah. Ban botak = bahaya!';
      case MaintenanceType.brakePads:
        return 'Kampas rem itu seperti rem sepeda. Ini yang menjepit roda '
            'biar berhenti. Kalau sudah tipis/habis, rem jauh lebih lama '
            'berhenti — sangat berbahaya!';
      case MaintenanceType.airFilter:
        return 'Filter udara itu seperti hidung. Tugasnya menyaring debu '
            'sebelum udara masuk ke mesin. Kalau kotor, mesin "sesak napas" '
            'dan boros bensin.';
      case MaintenanceType.sparkPlug:
        return 'Busi itu seperti korek api kecil di dalam mesin. Tugasnya '
            'memercik api untuk membakar bensin. Kalau sudah tua, motor '
            'susah nyala dan nggak bertenaga.';
      case MaintenanceType.chainLube:
        return 'Rantai motor itu seperti sendi tubuh kita. Kalau kering '
            '(tidak dilumasi), berisik, cepat aus, dan bisa putus. Dilumasi '
            '= awet dan halus.';
      case MaintenanceType.chainAdjust:
        return 'Rantai motor bisa melar pakai. Kalau terlalu kendor, bisa '
            'lepas dari gir. Kalau terlalu keras, tarikan berat dan boros. '
            'Harus disetel pas.';
      case MaintenanceType.coolant:
        return 'Coolant itu seperti air keringat buat mesin. Cairan ini '
            'mengalir di dalam mesin untuk menyerap panas, lalu didinginkan '
            'oleh radiator. Tanpa coolant, mesin bisa kepanasan dan rusak.';
      case MaintenanceType.brakeFluid:
        return 'Minyak rem itu yang bikin rem bisa berfungsi. Saat kita '
            'rem, minyak ini dorong kampas rem ke roda. Kalau habis atau '
            'tua, rem terasa dalam dan kurang pakem.';
      case MaintenanceType.brakeFluidFlush:
        return 'Lama-lama minyak rem bisa kotor dan menyerap air, bikin rem '
            'tidak pakem. Kuras = buang semua minyak lama, ganti dengan '
            'yang baru bersih. Rem jadi kembali pakem!';
      case MaintenanceType.transmission:
        return 'Oli transmisi itu pelumas untuk gir-gir di dalam kotak '
            'persneling. Tanpa pelumas, gir bergesekan dan cepat rusak. '
            'Harus diganti berkala.';
      case MaintenanceType.finalDriveOil:
        return 'Gardan itu bagian yang putar roda belakang motor matic. '
            'Di dalamnya ada gir yang butuh oli pelumas. Kalau kering, '
            'berisik dan bisa rusak parah.';
      case MaintenanceType.cvtRoller:
        return 'Roller itu bulatan kecil di dalam CVT motor matic. '
            'Tugasnya bikin motor bisa ganti gigi otomatis (tanpa kita '
            'pindah gigi). Kalau sudah gepeng, motor tarikan berat dan '
            'nggak responsif.';
      case MaintenanceType.cvtVBelt:
        return 'V-Belt itu seperti sabuk karet yang putar roda belakang '
            'motor matic. Kalau sudah tua, sabuk bisa melar atau putus. '
            'Kalau putus = motor tidak bisa jalan sama sekali!';
      case MaintenanceType.cvtClutchShoe:
        return 'Kampas ganda itu seperti "sepatu nempel" di motor matic. '
            'Saat mesin putar, ini nempel ke mangkok untuk putar roda. '
            'Kalau habis, motor susah jalan atau slip saat akselerasi.';
      case MaintenanceType.cvtDrivePlate:
        return 'Mangkok ganda itu pasangan dari kampas ganda. Ini tempat '
            'kampas ganda nempel. Kalau permukaannya sudah kasar/berlekuk, '
            'putaran tidak halus dan motor terasa "ngedrak".';
      case MaintenanceType.cvtSpring:
        return 'Per CVT itu pegas yang dorong mangkok ganda biar nempel ke '
            'kampas ganda. Kalau per sudah lemah, dorongan kurang kuat, '
            'motor tarikan berat dan top speed turun.';
      case MaintenanceType.clutchPlate:
        return 'Kampas kopling itu yang bikin motor manual bisa ganti gigi '
            'tanpa mesin mati. Saat kita tarik kopling, ini lepas dari '
            'mesin. Kalau habis, kopling slip dan ganti gigi susah.';
      case MaintenanceType.valveAdjust:
        return 'Klep itu seperti pintu masuk/keluar udara dan bensin di '
            'dalam mesin. Buka-tutupnya harus pas. Kalau terlalu renggang '
            'atau rapat, mesin berisik dan tidak bertenaga. Harus disetel.';
      case MaintenanceType.throttleBodyClean:
        return 'Throttle body itu seperti "keran udara" yang diatur oleh '
            'gas. Kalau kotor (berkarat/berjelaga), gas terasa berat dan '
            'putaran mesin tidak stabil. Dibersihkan = gas halus lagi.';
      case MaintenanceType.injectorClean:
        return 'Injektor itu seperti selang semprot kecil yang masukin '
            'bensin ke mesin. Kalau kotor, semprotan tidak rata, motor '
            'ngelitik dan boros. Dibersihkan = bensin terpakai efisien.';
      case MaintenanceType.battery:
        return 'Aki itu seperti baterai mainan. Tugasnya kasih listrik '
            'untuk starter, lampu, dan klakson. Kalau lemah, motor susah '
            'distarter dan lampu redup. Harus diganti sebelum habis total.';
      case MaintenanceType.wheelBearing:
        return 'Bearing roda itu seperti bantalan bola di dalam roda sepatu '
            'roda. Bikin roda putar mulus tanpa bergesekan. Kalau rusak, '
            'roda bergoyang dan berisik — bahaya saat kecepatan tinggi.';
      case MaintenanceType.suspension:
        return 'Suspensi itu seperti bantal peredam. Saat jalan bergelombang '
            'atau lubang, suspensi meredam benturan biar tidak keras. Kalau '
            'bocor/lemah, naik kendaraan jadi tidak nyaman dan tidak stabil.';
    }
  }
}
