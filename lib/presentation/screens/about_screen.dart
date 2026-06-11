import 'package:flutter/material.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // App Icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.directions_car,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // App Name
            Text(
              'OtoBuzz',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Kelola Perawatan Armada Anda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            // Feature list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitur Utama',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const _FeatureItem(
                      icon: Icons.add_road,
                      text: 'Input kilometer harian',
                    ),
                    const _FeatureItem(
                      icon: Icons.build,
                      text: 'Jadwal perawatan otomatis',
                    ),
                    const _FeatureItem(
                      icon: Icons.notifications_active,
                      text: 'Pengingat servis kendaraan',
                    ),
                    const _FeatureItem(
                      icon: Icons.local_gas_station,
                      text: 'Pencatatan bahan bakar',
                    ),
                    const _FeatureItem(
                      icon: Icons.receipt_long,
                      text: 'Laporan biaya perawatan',
                    ),
                    const _FeatureItem(
                      icon: Icons.analytics,
                      text: 'Analitik armada',
                    ),
                    const _FeatureItem(
                      icon: Icons.backup,
                      text: 'Backup & restore data',
                    ),
                    const _FeatureItem(
                      icon: Icons.picture_as_pdf,
                      text: 'Export laporan PDF',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Privacy Policy link
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Kebijakan Privasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Made with love
            const Text(
              'Dibuat dengan ❤️ di Indonesia',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Kontak: otobuzz.app@gmail.com',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
