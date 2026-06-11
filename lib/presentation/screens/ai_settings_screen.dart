import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/ai_service.dart';

class AiSettingsScreen extends StatefulWidget {
  final AiService aiService;

  const AiSettingsScreen({super.key, required this.aiService});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isEnabled = false;
  bool _isTesting = false;
  bool _obscureKey = true;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.aiService.isEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() => _testResult = 'Masukkan kunci API terlebih dahulu');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Save the key first
    await widget.aiService.setApiKey(_apiKeyController.text.trim());

    final success = await widget.aiService.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = success
            ? '✓ Berhasil terhubung ke Google Gemini!'
            : '✗ Gagal terhubung. Periksa kunci API Anda.';
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    await widget.aiService.setEnabled(value);
    setState(() => _isEnabled = value);
  }

  Future<void> _removeKey() async {
    await widget.aiService.removeApiKey();
    await widget.aiService.setEnabled(false);
    _apiKeyController.clear();
    if (mounted) {
      setState(() {
        _isEnabled = false;
        _testResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunci API berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kecerdasan Buatan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI Assistant (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fitur Tips Cerdas bekerja sepenuhnya offline tanpa AI. '
                    'Aktifkan AI untuk mendapatkan analisis lebih mendalam dan '
                    'kemampuan tanya-jawab tentang armada Anda.',
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Enable/disable toggle
          SwitchListTile(
            title: const Text('Aktifkan fitur AI'),
            subtitle: const Text(
              'Menggunakan Google Gemini untuk analisis lanjutan',
            ),
            value: _isEnabled,
            onChanged: _toggleEnabled,
            secondary: const Icon(Icons.psychology),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // API Key input
          Text(
            'Kunci API Gemini',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: 'Masukkan kunci API Google Gemini',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            obscureText: _obscureKey,
          ),
          const SizedBox(height: 12),

          // Test result
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.startsWith('✓')
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: Text(_isTesting ? 'Menguji...' : 'Tes Koneksi'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _removeKey,
                icon: const Icon(Icons.link_off),
                label: const Text('Putuskan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // How to get API key
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Cara mendapatkan API key',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _InstructionStep(
            number: '1',
            text: 'Buka Google AI Studio (aistudio.google.com)',
          ),
          _InstructionStep(
            number: '2',
            text: 'Login dengan akun Google Anda',
          ),
          _InstructionStep(
            number: '3',
            text: 'Klik "Get API Key" di menu sebelah kiri',
          ),
          _InstructionStep(
            number: '4',
            text: 'Buat API key baru atau gunakan yang sudah ada',
          ),
          _InstructionStep(
            number: '5',
            text: 'Salin dan tempel di kolom di atas',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://aistudio.google.com/apikey');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka Google AI Studio'),
          ),
          const SizedBox(height: 24),

          // Privacy note
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kunci API disimpan lokal di perangkat Anda. '
                      'Data armada yang dikirim ke AI hanya berupa ringkasan (bukan data mentah). '
                      'Anda bisa menonaktifkan fitur ini kapan saja.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Instruction Step Widget
// =============================================================================

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
