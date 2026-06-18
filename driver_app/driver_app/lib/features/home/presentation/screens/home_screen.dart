import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:driver_app/config/router/navigation_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/home/data/repositories/map_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final MapRepository _mapRepository = MapRepository();
  LatLng _currentPosition = const LatLng(8.9806, 38.7578); // Default to Addis Ababa
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStream;
  RealtimeChannel? _ridesChannel;

  Map<String, dynamic>? _activeRide;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition, 16.0);
  }

  void _toggleOnlineStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final userId = authState.user.id;
    final supabase = Supabase.instance.client;

    setState(() {
      _isOnline = !_isOnline;
      if (!_isOnline) {
        _activeRide = null;
        _routePoints = [];
      }
    });

    if (_isOnline) {
      // Start streaming location
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        await supabase.from('driver_locations').upsert({
          'id': userId,
          'lat': position.latitude,
          'lng': position.longitude,
          'status': _activeRide != null ? 'busy' : 'online',
          'updated_at': DateTime.now().toIso8601String(),
        });
      });

      // Listen to new ride requests
      _ridesChannel = supabase
          .channel('public:rides:pending')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'rides',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'status',
              value: 'pending',
            ),
            callback: (payload) {
              if (mounted && _activeRide == null) {
                setState(() {
                  _activeRide = payload.newRecord;
                });
                _fetchRouteToPickup();
              }
            },
          )
          .subscribe();

    } else {
      // Stop streaming and set status offline
      _positionStream?.cancel();
      _ridesChannel?.unsubscribe();
      await supabase.from('driver_locations').upsert({
        'id': userId,
        'lat': _currentPosition.latitude,
        'lng': _currentPosition.longitude,
        'status': 'offline',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _fetchRouteToPickup() async {
    if (_activeRide == null) return;
    
    final pickupLat = _activeRide!['pickup_lat'] as double;
    final pickupLng = _activeRide!['pickup_lng'] as double;
    final pickupLocation = LatLng(pickupLat, pickupLng);

    final route = await _mapRepository.getRoute(_currentPosition, pickupLocation);
    if (mounted && route.isNotEmpty) {
      setState(() {
        _routePoints = route;
      });
      final bounds = LatLngBounds.fromPoints([_currentPosition, pickupLocation]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }

  Future<void> _acceptRide() async {
    if (_activeRide == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    
    final userId = authState.user.id;
    final rideId = _activeRide!['id'];
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('rides')
          .update({
            'driver_id': userId,
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rideId)
          .eq('status', 'pending') // Ensure it wasn't accepted by someone else
          .select()
          .single();

      setState(() {
        _activeRide = response;
      });
      
      // Update driver status to busy
      await supabase.from('driver_locations').update({'status': 'busy'}).eq('id', userId);

      AppToast.show(context: context, message: 'Ride Accepted!', type: AppToastType.success);
    } catch (e) {
      setState(() {
        _activeRide = null;
        _routePoints = [];
      });
      AppToast.show(context: context, message: 'Ride no longer available.', type: AppToastType.error);
    }
  }

  void _declineRide() {
    setState(() {
      _activeRide = null;
      _routePoints = [];
    });
    _mapController.move(_currentPosition, 16.0);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _ridesChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 16.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.delivery.driver',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Driver Location Marker
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ),
                  // Pickup Location Marker
                  if (_activeRide != null)
                    Marker(
                      point: LatLng(
                        _activeRide!['pickup_lat'] as double,
                        _activeRide!['pickup_lng'] as double,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.success, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                      onPressed: () => context.navigator.pushProfileScreen(),
                    ),
                  ),
                  
                  // Online/Offline Toggle
                  GestureDetector(
                    onTap: _toggleOnlineStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: _isOnline ? AppColors.success : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.white : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppText(
                            _isOnline ? 'ONLINE' : 'OFFLINE',
                            variant: AppTextVariant.labelLarge,
                            color: _isOnline ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),
          ),

          // 3. Bottom Action Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      if (!_isOnline) ...[
                        const Icon(Icons.power_settings_new_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.md),
                        const AppText('You are offline', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                        const SizedBox(height: AppSpacing.xs),
                        const AppText('Go online to start receiving ride requests', variant: AppTextVariant.bodyMedium, color: AppColors.textSecondary),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.primary(label: 'GO ONLINE', fullWidth: true, onPressed: _toggleOnlineStatus),
                      ] else if (_activeRide == null) ...[
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: AppSpacing.lg),
                        const AppText('Finding requests...', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                        const SizedBox(height: AppSpacing.xs),
                        const AppText('Stay in high demand areas to get more rides', variant: AppTextVariant.bodyMedium, color: AppColors.textSecondary),
                      ] else if (_activeRide!['status'] == 'pending') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText('New Ride Request!', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                            AppText('${_activeRide!['price']} ETB', variant: AppTextVariant.heading2, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ],
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                          title: const AppText('Pickup', variant: AppTextVariant.labelLarge),
                          subtitle: AppText(_activeRide!['pickup_address'] ?? 'Current Location', variant: AppTextVariant.bodyMedium, maxLines: 1),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.flag_rounded, color: AppColors.primary),
                          title: const AppText('Dropoff', variant: AppTextVariant.labelLarge),
                          subtitle: AppText(_activeRide!['dropoff_address'] ?? 'Destination', variant: AppTextVariant.bodyMedium, maxLines: 1),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.outlinedSecondary(label: 'DECLINE', onPressed: _declineRide),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppButton.primary(label: 'ACCEPT', onPressed: _acceptRide),
                            ),
                          ],
                        ),
                      ] else if (_activeRide!['status'] == 'accepted') ...[
                        const AppText('Head to Pickup', variant: AppTextVariant.heading2, fontWeight: FontWeight.bold),
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 40),
                          title: const AppText('Client', variant: AppTextVariant.labelLarge),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.message_rounded, color: AppColors.primary), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.call_rounded, color: AppColors.success), onPressed: () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.primary(
                          label: 'ARRIVED',
                          fullWidth: true,
                          onPressed: () {
                            // Proceed to in_progress state
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 300), // Above bottom sheet
        child: FloatingActionButton(
          backgroundColor: AppColors.background,
          onPressed: _getCurrentLocation,
          child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
        ),
      ),
    );
  }
}
