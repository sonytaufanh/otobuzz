import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/driver_repository.dart';
import '../../domain/models/models.dart';

class DriverListScreen extends StatefulWidget {
  final DriverRepository driverRepository;

  const DriverListScreen({super.key, required this.driverRepository});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<Driver> _drivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _loading = true);
    final drivers = await widget.driverRepository.getAllDrivers();
    setState(() {
      _drivers = drivers;
      _loading = false;
    });
  }

  Future<void> _addOrEditDriver({Driver? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _DriverFormScreen(
          driverRepository: widget.driverRepository,
          existingDriver: existing,
        ),
      ),
    );
    if (result == true) {
      _loadDrivers();
    }
  }

  Future<void> _deleteDriver(Driver driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Driver'),
        content: Text('Yakin ingin menghapus driver "${driver.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.driverRepository.deleteDriver(driver.id);
      _loadDrivers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Driver',
            onPressed: () => _addOrEditDriver(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada driver terdaftar',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _addOrEditDriver(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Driver'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrivers,
                  child: ListView.builder(
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(driver.name),
                        subtitle: Text(driver.phone ?? '-'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _addOrEditDriver(existing: driver);
                            } else if (value == 'delete') {
                              _deleteDriver(driver);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        onTap: () => _addOrEditDriver(existing: driver),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditDriver(),
        tooltip: 'Tambah Driver',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =============================================================================
// Driver Form Screen (Add / Edit)
// =============================================================================

class _DriverFormScreen extends StatefulWidget {
  final DriverRepository driverRepository;
  final Driver? existingDriver;

  const _DriverFormScreen({
    required this.driverRepository,
    this.existingDriver,
  });

  @override
  State<_DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<_DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.existingDriver != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingDriver!.name;
      _phoneController.text = widget.existingDriver!.phone ?? '';
      _licenseController.text = widget.existingDriver!.licenseNumber ?? '';
      _notesController.text = widget.existingDriver!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final driver = Driver(
      id: _isEditing ? widget.existingDriver!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      licenseNumber: _licenseController.text.trim().isNotEmpty
          ? _licenseController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: _isEditing
          ? widget.existingDriver!.createdAt
          : DateTime.now(),
    );

    if (_isEditing) {
      await widget.driverRepository.updateDriver(driver);
    } else {
      await widget.driverRepository.addDriver(driver);
    }

    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Driver' : 'Tambah Driver'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Driver',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama driver wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor HP (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'Nomor SIM (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
