# 🚀 Checklist Rilis OtoBuzz ke Google Play Store

Panduan langkah demi langkah untuk menerbitkan OtoBuzz di Google Play Store.

---

## Persiapan Aset

- [ ] **Ganti app icon placeholder dengan desain proper**
  - Siapkan ikon aplikasi dalam format PNG, ukuran 1024x1024 piksel
  - Simpan di `assets/icon/app_icon.png`
  - Untuk adaptive icon, siapkan juga `assets/icon/app_icon_foreground.png`

- [ ] **Generate app icons**
  ```bash
  dart run flutter_launcher_icons
  ```

---

## Persiapan Signing

- [ ] **Pastikan `android/key.properties` ada dan berisi konfigurasi yang benar**
  ```properties
  storePassword=<password>
  keyPassword=<password>
  keyAlias=otobuzz
  storeFile=../keystore/otobuzz-release.jks
  ```

- [ ] **Pastikan file keystore ada** di `android/keystore/otobuzz-release.jks`

> ⚠️ **PENTING:** Simpan file keystore dan password di tempat yang aman!
> Jika keystore hilang, Anda tidak bisa update aplikasi di Play Store.

---

## Build Release

- [ ] **Build App Bundle untuk rilis**
  ```bash
  flutter build appbundle --release
  ```

- [ ] **Verifikasi output file** ada di:
  ```
  build/app/outputs/bundle/release/app-release.aab
  ```

---

## Google Play Console

- [ ] **Buat akun Google Play Developer**
  - Daftar di [Google Play Console](https://play.google.com/console)
  - Biaya pendaftaran: $25 (sekali bayar)
  - Verifikasi identitas diperlukan

- [ ] **Buat aplikasi baru** di Play Console
  - Nama aplikasi: OtoBuzz
  - Bahasa default: Indonesia
  - Tipe: Aplikasi
  - Gratis/Berbayar: Gratis

---

## Upload & Listing

- [ ] **Upload AAB file**
  - Buka menu Production > Create new release
  - Upload file dari `build/app/outputs/bundle/release/app-release.aab`

- [ ] **Isi Store Listing**
  - Gunakan materi dari folder `store_listing/` (jika ada)
  - Judul: OtoBuzz - Pencatat Perawatan Kendaraan
  - Deskripsi singkat (80 karakter max)
  - Deskripsi lengkap (4000 karakter max)
  - Kategori: Auto & Vehicles

- [ ] **Host Privacy Policy**
  - File ada di `docs/privacy-policy.html`
  - Opsi hosting:
    - **GitHub Pages** — Push ke repository, aktifkan Pages
    - **Google Sites** — Copy konten ke halaman Google Sites
  - Masukkan URL privacy policy di Play Console

---

## Screenshots & Grafis

- [ ] **Ambil 4-8 screenshots dari emulator**
  - Minimal 4 screenshot (wajib)
  - Ukuran yang disarankan: 1080x1920 (portrait)
  - Tampilkan fitur utama: dashboard, daftar kendaraan, detail perawatan, pengingat

- [ ] **Siapkan Feature Graphic**
  - Ukuran: 1024x500 piksel
  - Format: PNG atau JPEG

---

## Review & Submit

- [ ] **Isi Content Rating questionnaire**
  - Jawab pertanyaan tentang konten aplikasi
  - OtoBuzz seharusnya mendapat rating "Everyone"

- [ ] **Isi Data Safety form**
  - Tidak mengumpulkan data pengguna
  - Semua data disimpan lokal
  - Tidak ada sharing data dengan pihak ketiga

- [ ] **Pilih negara distribusi**
  - Minimal: Indonesia
  - Opsional: Semua negara

- [ ] **Submit untuk review**
  - Review biasanya memakan waktu 1-7 hari kerja
  - Pantau status di Play Console

---

## Post-Release

- [ ] Pantau crash reports di Play Console
- [ ] Respon review pengguna
- [ ] Siapkan update berikutnya

---

> 💡 **Tips:**
> - Pastikan `flutter analyze` bersih sebelum build release
> - Test APK di beberapa perangkat berbeda sebelum submit
> - Simpan backup keystore di cloud storage yang aman (Google Drive, dsb.)
