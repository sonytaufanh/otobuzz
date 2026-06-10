# Implementation Plan

## Overview

Implementasi 4 fitur premium OtoBuzz: Fuel/BBM Tracking, Dashboard Analytics (fl_chart), Dark Mode Toggle, dan Foto Attachment. Mengikuti arsitektur Clean Architecture yang sudah ada.

## Tasks

- [ ] 1. Database migration & new models
  - [ ] 1.1. Tambah tabel `fuel_records` di database helper (migration v5)
  - [ ] 1.2. Tambah tabel `maintenance_photos` di database helper
  - [ ] 1.3. Tambah kolom `photoPath` ke tabel `vehicles`
  - [ ] 1.4. Buat model `FuelRecord` dengan equatable di `domain/models/`
  - [ ] 1.5. Buat model `FuelStatistics` dan `MonthlyFuelSummary` di `domain/models/`
  - [ ] 1.6. Buat model `MaintenancePhoto` di `domain/models/`
- [ ] 2. Fuel/BBM repository & business logic
  - [ ] 2.1. Buat `FuelRepository` di `data/repositories/` dengan CRUD operations
  - [ ] 2.2. Implementasi kalkulasi konsumsi BBM (km/liter) dari data full-tank
  - [ ] 2.3. Implementasi statistik BBM: total, rata-rata, trend (improving/worsening/stable)
  - [ ] 2.4. Implementasi filter periode (bulan ini, 3 bulan, tahun ini, custom range)
- [ ] 3. Dark Mode Toggle
  - [ ] 3.1. Buat `ThemeService` menggunakan SharedPreferences untuk persist pilihan tema
  - [ ] 3.2. Buat `ThemeCubit` dengan state: light, dark, system
  - [ ] 3.3. Integrasikan ThemeCubit ke `MaterialApp` di main.dart (themeMode dynamic)
  - [ ] 3.4. Buat `SettingsScreen` dengan opsi tema (Terang/Gelap/Ikuti Sistem) dan navigasi ke Backup/Restore
  - [ ] 3.5. Tambah icon settings di AppBar HomeScreen yang navigasi ke SettingsScreen
- [ ] 4. Photo service & repository
  - [ ] 4.1. Tambah dependency `image_picker` dan `image` di pubspec.yaml
  - [ ] 4.2. Buat `ImageService` (pick from camera/gallery, resize, save to app directory)
  - [ ] 4.3. Buat `PhotoRepository` untuk CRUD maintenance_photos di database
  - [ ] 4.4. Update `VehicleRepositoryImpl` untuk handle photoPath (save/update/delete foto kendaraan)
- [ ] 5. Fuel/BBM UI
  - [ ] 5.1. Buat `FuelBloc` (events: Load, Add, Delete, LoadStats; states: Initial, Loading, Loaded, Error)
  - [ ] 5.2. Buat `FuelScreen` - halaman utama BBM dengan stats card di atas dan list riwayat
  - [ ] 5.3. Buat `FuelFormScreen` - form input pengisian BBM (liter, harga, odometer, SPBU, jenis BBM, full tank)
  - [ ] 5.4. Update bottom navigation di HomeScreen: tambah tab "BBM" (5 tab total)
  - [ ] 5.5. Register FuelBloc dan FuelRepository di main.dart
- [ ] 6. Foto Attachment UI
  - [ ] 6.1. Buat `PhotoPickerWidget` - reusable widget untuk pilih foto (kamera/galeri) dengan preview
  - [ ] 6.2. Buat `VehiclePhotoAvatar` - widget circular avatar yang tampilkan foto atau icon default
  - [ ] 6.3. Buat `PhotoViewerScreen` - full screen image viewer dengan pinch-to-zoom
  - [ ] 6.4. Integrasikan PhotoPickerWidget ke VehicleFormScreen (1 foto utama kendaraan)
  - [ ] 6.5. Integrasikan PhotoPickerWidget ke form maintenance (1-3 foto bukti service)
  - [ ] 6.6. Tampilkan VehiclePhotoAvatar di vehicle list card dan vehicle detail header
- [ ] 7. Dashboard Analytics
  - [ ] 7.1. Tambah dependency `fl_chart` di pubspec.yaml
  - [ ] 7.2. Buat `AnalyticsBloc` (events: Load, ChangePeriod, ChangeVehicle; states: Initial, Loading, Loaded)
  - [ ] 7.3. Buat `KmChartWidget` - line chart km harian/mingguan dengan filter periode
  - [ ] 7.4. Buat `CostChartWidget` - bar chart biaya bulanan + pie chart per tipe maintenance
  - [ ] 7.5. Buat `FuelChartWidget` - line chart km/liter dan bar chart pengeluaran BBM per bulan
  - [ ] 7.6. Buat `AnalyticsScreen` - layout scroll: summary cards, km chart, cost chart, fuel chart
  - [ ] 7.7. Tambah tombol navigasi ke Analytics di Beranda (HomeScreen fleet overview)
- [ ] 8. Integration & polish
  - [ ] 8.1. Update backup/restore untuk include fuel_records dan maintenance_photos paths
  - [ ] 8.2. Update fleet overview summary cards dengan info BBM (total biaya BBM bulan ini)
  - [ ] 8.3. Update vehicle detail screen dengan info konsumsi BBM terakhir
  - [ ] 8.4. Pastikan semua screen responsive terhadap dark/light theme
  - [ ] 8.5. Update AndroidManifest.xml untuk permission kamera (jika belum ada)

## Task Dependency Graph

```json
{"waves":[[1],[2,3,4],[5,6],[7],[8]]}
```

## Notes

- Semua UI text dalam Bahasa Indonesia
- Menggunakan arsitektur dan pattern yang sama dengan fitur existing (BLoC, Repository, SQLite)
- fl_chart untuk semua visualisasi chart
- image_picker + image package untuk foto
- Database migration dari v4 ke v5
- Bottom navigation berubah dari 4 tab menjadi 5 tab
