# Requirements Document: Premium Features

## Introduction

Paket fitur premium untuk OtoBuzz yang mencakup: Fuel/BBM Tracking, Dashboard Analytics dengan grafik interaktif, Dark Mode Toggle, dan Foto Attachment untuk bukti service. Fitur-fitur ini meningkatkan profesionalitas dan kelengkapan aplikasi fleet management.

## Requirements

### 1. Fuel/BBM Tracking

#### Requirement 1.1: Catat Pengisian BBM
**Given** user memiliki kendaraan terdaftar
**When** mereka mengisi BBM dan mencatat di aplikasi
**Then** data pengisian tersimpan dengan detail lengkap

**Acceptance Criteria:**
- Input: jumlah liter (wajib, > 0, max 200 liter)
- Input: harga per liter (wajib, dalam IDR)
- Input: total biaya (auto-calculate dari liter × harga, bisa di-override)
- Input: odometer saat isi (wajib, harus >= total km kendaraan terakhir)
- Input: tanggal (default hari ini, tidak boleh masa depan)
- Input: SPBU/lokasi (opsional, text)
- Input: jenis BBM (opsional: Pertalite, Pertamax, Pertamax Turbo, Solar, Dexlite, dll)
- Input: full tank (checkbox, untuk kalkulasi konsumsi yang akurat)
- Data tersimpan di SQLite lokal

#### Requirement 1.2: Kalkulasi Konsumsi BBM
**Given** kendaraan memiliki minimal 2 record pengisian full tank
**When** user melihat statistik BBM
**Then** ditampilkan konsumsi BBM rata-rata (km/liter)

**Acceptance Criteria:**
- Konsumsi dihitung: jarak tempuh antara 2 full tank / liter yang diisi
- Ditampilkan dalam km/liter (standar Indonesia)
- Rata-rata konsumsi 3 bulan terakhir
- Trend konsumsi: membaik/memburuk/stabil
- Jika data kurang dari 2 full tank, tampilkan pesan "Data belum cukup"

#### Requirement 1.3: Riwayat & Statistik BBM
**Given** user memiliki data pengisian BBM
**When** mereka membuka halaman BBM
**Then** ditampilkan riwayat dan ringkasan statistik

**Acceptance Criteria:**
- Daftar riwayat pengisian (terbaru di atas)
- Total pengeluaran BBM per bulan
- Rata-rata biaya BBM per km
- Filter berdasarkan periode (bulan ini, 3 bulan, tahun ini, custom)
- Ringkasan: total liter, total biaya, rata-rata km/liter

#### Requirement 1.4: BBM di Fleet Overview
**Given** user memiliki data BBM untuk kendaraan
**When** mereka melihat fleet overview atau vehicle detail
**Then** info konsumsi BBM ditampilkan

**Acceptance Criteria:**
- Vehicle detail menampilkan konsumsi BBM terakhir
- Fleet overview menampilkan total pengeluaran BBM bulan ini
- Kendaraan dengan konsumsi memburuk ditandai warning

### 2. Dashboard Analytics

#### Requirement 2.1: Chart KM Harian/Mingguan
**Given** user memiliki data mileage
**When** mereka membuka dashboard analytics
**Then** ditampilkan line chart km per hari dan per minggu

**Acceptance Criteria:**
- Line chart km harian (7 hari terakhir default)
- Line chart km mingguan (4 minggu terakhir)
- Bisa pilih rentang waktu: 7 hari, 30 hari, 3 bulan
- Bisa filter per kendaraan atau semua kendaraan
- Tooltip saat tap data point menampilkan nilai exact
- Sumbu Y auto-scale, sumbu X menampilkan tanggal/minggu

#### Requirement 2.2: Chart Biaya Maintenance
**Given** user memiliki data maintenance dengan biaya
**When** mereka membuka dashboard analytics
**Then** ditampilkan visualisasi biaya maintenance

**Acceptance Criteria:**
- Bar chart biaya per bulan (6 bulan terakhir)
- Pie chart distribusi biaya per tipe maintenance
- Bisa filter per kendaraan
- Menampilkan total dan rata-rata bulanan
- Warna berbeda per tipe maintenance

#### Requirement 2.3: Chart Konsumsi BBM
**Given** user memiliki data BBM
**When** mereka membuka dashboard analytics
**Then** ditampilkan trend konsumsi BBM

**Acceptance Criteria:**
- Line chart km/liter per bulan (6 bulan terakhir)
- Perbandingan antar kendaraan (jika > 1 kendaraan)
- Bar chart pengeluaran BBM per bulan
- Indikator trend (naik/turun/stabil)

#### Requirement 2.4: Fleet Summary Cards
**Given** user membuka dashboard analytics
**When** halaman dimuat
**Then** ditampilkan summary cards di bagian atas

**Acceptance Criteria:**
- Card: Total km bulan ini (vs bulan lalu, dengan persentase perubahan)
- Card: Total biaya maintenance bulan ini
- Card: Total biaya BBM bulan ini
- Card: Rata-rata konsumsi BBM fleet
- Cards menggunakan warna dan icon yang informatif
- Animasi angka saat pertama kali load

### 3. Dark Mode Toggle

#### Requirement 3.1: Pengaturan Tema
**Given** user membuka halaman pengaturan
**When** mereka memilih tema aplikasi
**Then** tema berubah sesuai pilihan

**Acceptance Criteria:**
- 3 opsi: Terang (Light), Gelap (Dark), Ikuti Sistem (System)
- Default: Ikuti Sistem
- Perubahan tema langsung diterapkan tanpa restart
- Pilihan tersimpan di SharedPreferences
- Semua halaman dan komponen menyesuaikan tema

#### Requirement 3.2: Halaman Pengaturan
**Given** user ingin mengakses pengaturan
**When** mereka tap ikon settings di home screen
**Then** halaman pengaturan terbuka

**Acceptance Criteria:**
- Akses dari icon di AppBar home screen
- Berisi: pengaturan tema, info aplikasi (versi), dan link ke backup/restore
- Desain konsisten dengan Material 3

### 4. Foto Attachment

#### Requirement 4.1: Foto Kendaraan
**Given** user menambahkan atau mengedit kendaraan
**When** mereka ingin menambahkan foto
**Then** foto tersimpan dan ditampilkan di profil kendaraan

**Acceptance Criteria:**
- Bisa ambil foto dari kamera atau galeri
- Foto disimpan di app storage lokal (bukan database)
- Path foto disimpan di database
- Maksimal 1 foto utama per kendaraan
- Foto ditampilkan di vehicle card dan vehicle detail
- Jika tidak ada foto, tampilkan icon default berdasarkan tipe kendaraan
- Foto di-resize ke max 800px width untuk hemat storage

#### Requirement 4.2: Foto Bukti Service
**Given** user mencatat maintenance yang selesai
**When** mereka ingin melampirkan bukti
**Then** foto bukti tersimpan bersama record maintenance

**Acceptance Criteria:**
- Bisa attach 1-3 foto per record maintenance
- Foto dari kamera atau galeri
- Foto disimpan di app storage, path di database
- Bisa lihat foto di detail riwayat maintenance
- Bisa zoom foto (pinch-to-zoom atau tap-to-fullscreen)
- Foto di-resize ke max 1024px width
- Foto ikut terhapus jika record maintenance dihapus

#### Requirement 4.3: Foto di Backup/Restore
**Given** user melakukan backup data
**When** backup dijalankan
**Then** informasi foto termasuk dalam backup

**Acceptance Criteria:**
- Path foto disertakan dalam backup JSON
- Saat restore, foto yang masih ada di device akan ter-link kembali
- Foto yang hilang ditampilkan sebagai placeholder "Foto tidak tersedia"
- Ukuran backup tetap manageable (foto tidak di-embed di JSON, hanya path)
