import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/gas_station_service.dart';
import '../../domain/models/gas_station.dart';

class GasStationMapScreen extends StatefulWidget {
  const GasStationMapScreen({super.key});

  @override
  State<GasStationMapScreen> createState() => _GasStationMapScreenState();
}

class _GasStationMapScreenState extends State<GasStationMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<GasStation> _stations = [];
  List<GasStation> _filteredStations = [];
  bool _isLoading = true;
  String? _errorMessage;
  GasStationBrand? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Aktifkan layanan lokasi untuk menemukan SPBU terdekat';
          _isLoading = false;
        });
        return;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Aktifkan akses lokasi untuk menemukan SPBU terdekat';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Akses lokasi ditolak permanen. Aktifkan di pengaturan.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _currentPosition = position;
      });

      await _loadStations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStations() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stations = await GasStationService.getNearbyStations(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _stations = stations;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Butuh koneksi internet untuk memuat peta';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredStations = List.from(_stations);
    } else {
      _filteredStations =
          _stations.where((s) => s.brand == _selectedFilter).toList();
    }
  }

  void _onFilterChanged(GasStationBrand? brand) {
    setState(() {
      _selectedFilter = brand;
      _applyFilter();
    });
  }

  void _recenterMap() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    }
  }

  double _calculateDistance(GasStation station) {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      station.latitude,
      station.longitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m dari Anda';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km dari Anda';
  }

  Color _getBrandColor(GasStationBrand brand) {
    switch (brand) {
      case GasStationBrand.pertamina:
        return Colors.red;
      case GasStationBrand.bp:
        return Colors.green;
      case GasStationBrand.vivo:
        return Colors.amber.shade700;
      case GasStationBrand.shell:
        return Colors.orange;
      case GasStationBrand.other:
        return Colors.grey;
    }
  }

  void _showStationBottomSheet(GasStation station) {
    final distance = _calculateDistance(station);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StationBottomSheet(
        station: station,
        distance: _formatDistance(distance),
        brandColor: _getBrandColor(station.brand),
        onNavigate: () => _openGoogleMapsNavigation(station),
        onFuelUp: () => _navigateToFuelForm(station),
      ),
    );
  }

  Future<void> _openGoogleMapsNavigation(GasStation station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToFuelForm(GasStation station) {
    Navigator.of(context).pop(); // Close bottom sheet
    // Navigate back with station name for fuel form
    Navigator.of(context).pop(station.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPBU Terdekat'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Map or error/loading state
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _currentPosition != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(_mapController.camera.center, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: _recenterMap,
                  child: const Icon(Icons.my_location),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              isSelected: _selectedFilter == null,
              onTap: () => _onFilterChanged(null),
            ),
            _FilterChip(
              label: 'Pertamina',
              isSelected: _selectedFilter == GasStationBrand.pertamina,
              color: Colors.red,
              onTap: () => _onFilterChanged(GasStationBrand.pertamina),
            ),
            _FilterChip(
              label: 'BP',
              isSelected: _selectedFilter == GasStationBrand.bp,
              color: Colors.green,
              onTap: () => _onFilterChanged(GasStationBrand.bp),
            ),
            _FilterChip(
              label: 'Vivo',
              isSelected: _selectedFilter == GasStationBrand.vivo,
              color: Colors.amber.shade700,
              onTap: () => _onFilterChanged(GasStationBrand.vivo),
            ),
            _FilterChip(
              label: 'Shell',
              isSelected: _selectedFilter == GasStationBrand.shell,
              color: Colors.orange,
              onTap: () => _onFilterChanged(GasStationBrand.shell),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari SPBU...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _initLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return const Center(child: Text('Lokasi tidak tersedia'));
    }

    return _buildMap();
  }

  Widget _buildMap() {
    final userLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 15.0,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.otobuzz.app',
            ),
            // User location marker
            MarkerLayer(
              markers: [
                Marker(
                  point: userLatLng,
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Gas station markers
            MarkerLayer(
              markers: _filteredStations.map((station) {
                return Marker(
                  point: LatLng(station.latitude, station.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showStationBottomSheet(station),
                    child: _StationMarker(
                      color: _getBrandColor(station.brand),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        // OSM attribution
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        ),
        // Station count indicator
        if (_filteredStations.isEmpty && !_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_gas_station,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada SPBU ditemukan dalam radius 3 km',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coba geser peta atau perluas area pencarian',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// HELPER WIDGETS
// ============================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppTheme.primaryColor)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null && !isSelected) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationMarker extends StatelessWidget {
  final Color color;

  const _StationMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pin shadow
        Positioned(
          bottom: 0,
          child: Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        // Pin body
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_gas_station,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StationBottomSheet extends StatelessWidget {
  final GasStation station;
  final String distance;
  final Color brandColor;
  final VoidCallback onNavigate;
  final VoidCallback onFuelUp;

  const _StationBottomSheet({
    required this.station,
    required this.distance,
    required this.brandColor,
    required this.onNavigate,
    required this.onFuelUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Station info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: brandColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: brandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            station.brandDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: brandColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (station.address != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    station.address!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Navigasi'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onFuelUp,
                  icon: const Icon(Icons.local_gas_station, size: 18),
                  label: const Text('Isi BBM di Sini'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
