import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/theme/theme_cubit.dart';
import 'backup_restore_screen.dart';

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
                  RadioListTile<ThemeMode>(
                    title: const Text('Terang'),
                    subtitle: const Text('Selalu gunakan tema terang'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (mode) =>
                        context.read<ThemeCubit>().setTheme(mode!),
                    secondary: const Icon(Icons.light_mode),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Gelap'),
                    subtitle: const Text('Selalu gunakan tema gelap'),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (mode) =>
                        context.read<ThemeCubit>().setTheme(mode!),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Ikuti Sistem'),
                    subtitle: const Text('Sesuaikan dengan pengaturan perangkat'),
                    value: ThemeMode.system,
                    groupValue: themeMode,
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
          const _SectionHeader(title: 'Tentang'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('OtoBuzz'),
            subtitle: Text('Versi 1.0.0\nFleet Maintenance Tracker'),
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
