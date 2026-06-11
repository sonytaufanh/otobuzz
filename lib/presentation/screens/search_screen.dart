import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../domain/models/vehicle.dart';
import '../../core/utils/page_transitions.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_state.dart';
import 'vehicle_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _searchRepo = SearchRepository();
  List<SearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final results = await _searchRepo.search(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  void _navigateToResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.vehicle:
        _navigateToVehicle(result.id);
        break;
      case SearchResultType.maintenance:
      case SearchResultType.workshop:
        if (result.parentId != null) {
          _navigateToVehicle(result.parentId!);
        }
        break;
    }
  }

  void _navigateToVehicle(String vehicleId) {
    final vehicleState = context.read<VehicleBloc>().state;
    if (vehicleState is VehicleLoaded) {
      final vehicle = vehicleState.vehicles.cast<Vehicle?>().firstWhere(
            (v) => v!.id == vehicleId,
            orElse: () => null,
          );
      if (vehicle != null) {
        Navigator.push(
          context,
          SlidePageRoute(
            page: VehicleDetailScreen(
              vehicle: vehicle,
              customIntervalRepository:
                  context.read<CustomIntervalRepository>(),
              driverRepository: context.read<DriverRepository>(),
              driverAssignmentRepository:
                  context.read<DriverAssignmentRepository>(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari kendaraan, perawatan, bengkel...',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Ketik untuk mencari',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Group results by type
    final vehicles = _results
        .where((r) => r.type == SearchResultType.vehicle)
        .toList();
    final maintenance = _results
        .where((r) => r.type == SearchResultType.maintenance)
        .toList();
    final workshops = _results
        .where((r) => r.type == SearchResultType.workshop)
        .toList();

    return ListView(
      children: [
        if (vehicles.isNotEmpty) ...[
          _SectionHeader(title: 'Kendaraan', count: vehicles.length),
          ...vehicles.map((r) => _ResultTile(
                result: r,
                icon: Icons.directions_car,
                onTap: () => _navigateToResult(r),
              )),
        ],
        if (maintenance.isNotEmpty) ...[
          _SectionHeader(title: 'Perawatan', count: maintenance.length),
          ...maintenance.map((r) => _ResultTile(
                result: r,
                icon: Icons.build,
                onTap: () => _navigateToResult(r),
              )),
        ],
        if (workshops.isNotEmpty) ...[
          _SectionHeader(title: 'Bengkel', count: workshops.length),
          ...workshops.map((r) => _ResultTile(
                result: r,
                icon: Icons.store,
                onTap: () => _navigateToResult(r),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final IconData icon;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon, size: 20)),
      title: Text(result.title),
      subtitle: Text(result.subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
