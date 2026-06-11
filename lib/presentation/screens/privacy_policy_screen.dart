import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kebijakan Privasi OtoBuzz',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Terakhir diperbarui: Juni 2026',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            _SectionTitle('1. Data yang Dikumpulkan'),
            SizedBox(height: 8),
            Text(
              'OtoBuzz hanya mengumpulkan dan menyimpan data secara lokal di perangkat Anda. '
              'Data yang disimpan meliputi:\n'
              '• Informasi kendaraan (nama, plat nomor, tahun, jenis)\n'
              '• Catatan kilometer harian\n'
              '• Jadwal dan riwayat perawatan kendaraan\n'
              '• Catatan bahan bakar\n'
              '• Data pengemudi (jika digunakan)\n'
              '• Dokumen kendaraan (STNK, pajak)\n\n'
              'Semua data ini disimpan secara lokal di database perangkat Anda dan '
              'TIDAK dikirim ke server manapun.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('2. Penyimpanan Data'),
            SizedBox(height: 8),
            Text(
              'Seluruh data aplikasi disimpan di perangkat pengguna menggunakan '
              'database lokal (SQLite). Kami tidak memiliki server atau layanan cloud '
              'yang menyimpan data Anda. Data sepenuhnya berada di bawah kendali Anda.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('3. Backup Data'),
            SizedBox(height: 8),
            Text(
              'Fitur backup tersedia agar pengguna dapat mencadangkan data secara manual. '
              'File backup disimpan di lokasi yang dipilih pengguna di perangkat mereka. '
              'Proses backup dan restore sepenuhnya dilakukan oleh pengguna secara lokal. '
              'Kami tidak memiliki akses terhadap file backup Anda.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('4. Tracking & Analytics'),
            SizedBox(height: 8),
            Text(
              'OtoBuzz TIDAK menggunakan layanan tracking atau analytics pihak ketiga. '
              'Kami tidak mengumpulkan data penggunaan, tidak melacak perilaku pengguna, '
              'dan tidak mengirim data apapun ke pihak ketiga. Aplikasi ini bekerja '
              'sepenuhnya secara offline.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('5. Izin Aplikasi'),
            SizedBox(height: 8),
            Text(
              'Aplikasi meminta izin berikut:\n'
              '• Notifikasi: Untuk mengirim pengingat perawatan kendaraan\n'
              '• Penyimpanan: Untuk fitur backup dan restore data\n\n'
              'Izin-izin ini hanya digunakan untuk fungsionalitas aplikasi dan tidak '
              'untuk mengumpulkan data pribadi.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('6. Keamanan Data'),
            SizedBox(height: 8),
            Text(
              'Karena semua data disimpan secara lokal di perangkat Anda, keamanan data '
              'bergantung pada keamanan perangkat Anda sendiri. Kami menyarankan untuk:\n'
              '• Menggunakan kunci layar pada perangkat Anda\n'
              '• Melakukan backup data secara berkala\n'
              '• Tidak memberikan akses perangkat kepada pihak yang tidak dipercaya',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('7. Perubahan Kebijakan'),
            SizedBox(height: 8),
            Text(
              'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. '
              'Perubahan akan diumumkan melalui pembaruan aplikasi. Kami menyarankan '
              'Anda untuk meninjau halaman ini secara berkala.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 20),
            _SectionTitle('8. Hubungi Kami'),
            SizedBox(height: 8),
            Text(
              'Jika Anda memiliki pertanyaan mengenai Kebijakan Privasi ini, '
              'silakan hubungi kami melalui:\n\n'
              'Email: otobuzz.app@gmail.com',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
