import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/ai_service.dart';
import '../blocs/theme/theme_cubit.dart';
import 'about_screen.dart';
import 'ai_settings_screen.dart';
import 'backup_restore_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Tampilan'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Column(
                children: [
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('Terang'),
                    subtitle: const Text('Selalu gunakan tema terang'),
                    value: ThemeMode.light,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (mode) =>
                        context.read<ThemeCubit>().setTheme(mode!),
                    secondary: const Icon(Icons.light_mode),
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('Gelap'),
                    subtitle: const Text('Selalu gunakan tema gelap'),
                    value: ThemeMode.dark,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (mode) =>
                        context.read<ThemeCubit>().setTheme(mode!),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('Ikuti Sistem'),
                    subtitle: const Text('Sesuaikan dengan pengaturan perangkat'),
                    value: ThemeMode.system,
                    // ignore: deprecated_member_use
                    groupValue: themeMode,
                    // ignore: deprecated_member_use
                    onChanged: (mode) =>
                        context.read<ThemeCubit>().setTheme(mode!),
                    secondary: const Icon(Icons.settings_brightness),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Cadangkan atau pulihkan data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BackupRestoreScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'Kecerdasan Buatan'),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Assistant'),
            subtitle: const Text('Pengaturan Google Gemini AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final aiService = AiService();
              aiService.initialize().then((_) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiSettingsScreen(aiService: aiService),
                    ),
                  );
                }
              });
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Tentang'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            subtitle: const Text('Informasi dan fitur OtoBuzz'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AboutScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan Privasi'),
            subtitle: const Text('Informasi penggunaan data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.verified_outlined),
            title: Text('Versi'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
