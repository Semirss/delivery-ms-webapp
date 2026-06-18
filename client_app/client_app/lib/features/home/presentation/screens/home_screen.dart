import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:client_ui/app_ui.dart';
import 'package:client_app/config/router/navigation_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'package:client_app/features/search/presentation/screens/search_destination_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(8.9806, 38.7578); // Addis Ababa, Ethiopia
  List<Marker> _driverMarkers = [];
  RealtimeChannel? _driverChannel;
  RealtimeChannel? _rideChannel;

  final MapRepository _mapRepository = MapRepository();
  MapPlace? _destination;
  List<LatLng> _routePoints = [];
  bool _isRequestingRide = false;
  String? _currentRideId;
  String _rideStatus = 'none'; // none, pending, accepted

  @override
  void initState() {
    super.initState();
    _listenToDrivers();
  }

  void _listenToDrivers() {
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch initial online drivers
      supabase
          .from('driver_locations')
          .select()
          .eq('status', 'online')
          .then((data) {
        if (mounted) {
          setState(() {
            _driverMarkers = (data as List<dynamic>).map((driver) {
              return _buildDriverMarker(
                driver['id'] as String,
                LatLng(driver['lat'] as double, driver['lng'] as double),
              );
            }).toList();
          });
        }
      });

      // Listen to real-time updates
      _driverChannel = supabase
          .channel('public:driver_locations')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'driver_locations',
            callback: (payload) {
              _handleDriverUpdate(payload);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up Supabase Realtime: $e');
    }
  }

  void _handleDriverUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    
    final data = payload.newRecord;
    if (data.isEmpty) {
      final oldData = payload.oldRecord;
      setState(() {
        _driverMarkers.removeWhere((m) => m.key == ValueKey(oldData['id']));
      });
      return;
    }

    final id = data['id'] as String;
    final status = data['status'] as String;
    final lat = data['lat'] as double;
    final lng = data['lng'] as double;

    setState(() {
      _driverMarkers.removeWhere((m) => m.key == ValueKey(id));
      if (status == 'online') {
        _driverMarkers.add(_buildDriverMarker(id, LatLng(lat, lng)));
      }
    });
  }

  Marker _buildDriverMarker(String id, LatLng position) {
    return Marker(
      key: ValueKey(id),
      point: position,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.motorcycle_rounded,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Future<void> _handleSearchDestination() async {
    final MapPlace? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchDestinationScreen()),
    );

    if (result != null) {
      setState(() {
        _destination = result;
        _isRequestingRide = true;
      });

      // Fetch Route
      final route = await _mapRepository.getRoute(_initialCenter, result.location);
      if (mounted && route.isNotEmpty) {
        setState(() {
          _routePoints = route;
        });
        
        // Zoom to fit route
        final bounds = LatLngBounds.fromPoints([_initialCenter, result.location]);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      }
    }
  }

  Future<void> _requestRide() async {
    if (_destination == null) return;
    
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _rideStatus = 'pending';
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('rides').insert({
        'client_id': authState.user.id,
        'pickup_lat': _initialCenter.latitude,
        'pickup_lng': _initialCenter.longitude,
        'pickup_address': 'Current Location',
        'dropoff_lat': _destination!.location.latitude,
        'dropoff_lng': _destination!.location.longitude,
        'dropoff_address': _destination!.displayName,
        'status': 'pending',
        'price': 150.0, // Mock price
      }).select().single();

      _currentRideId = response['id'];

      // Listen for driver acceptance
      _rideChannel = supabase
          .channel('public:rides:$_currentRideId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'rides',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: _currentRideId!,
            ),
            callback: (payload) {
              if (mounted) {
                setState(() {
                  _rideStatus = payload.newRecord['status'];
                });
                if (_rideStatus == 'accepted') {
                  AppToast.show(context: context, message: 'Driver is on the way!', type: AppToastType.success);
                }
              }
            },
          )
          .subscribe();

    } catch (e) {
      debugPrint('Error requesting ride: $e');
      setState(() {
        _rideStatus = 'none';
        _isRequestingRide = false;
      });
      AppToast.show(context: context, message: 'Failed to request ride.', type: AppToastType.error);
    }
  }

  void _cancelRideRequest() {
    setState(() {
      _isRequestingRide = false;
      _destination = null;
      _routePoints = [];
      _rideStatus = 'none';
    });
    _rideChannel?.unsubscribe();
    // In a real app, you would update the DB status to 'cancelled' here.
    _mapController.move(_initialCenter, 14.0);
  }

  @override
  void dispose() {
    _driverChannel?.unsubscribe();
    _rideChannel?.unsubscribe();
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
              initialCenter: _initialCenter,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.delivery.client',
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
              MarkerLayer(markers: _driverMarkers),
              MarkerLayer(
                markers: [
                  // User location marker
                  Marker(
                    point: _initialCenter,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Destination marker
                  if (_destination != null)
                    Marker(
                      point: _destination!.location,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Header (Menu & Branding)
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                      onPressed: () => context.navigator.pushProfileScreen(),
                    ),
                  ),
                  const Text(
                    'MOTORIDE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 3. Bottom Sheet Layer
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
                      
                      if (!_isRequestingRide) ...[
                        // Default State
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTransportOption('Ride', Icons.motorcycle_rounded, true),
                              const SizedBox(width: AppSpacing.sm),
                              _buildTransportOption('Delivery', Icons.local_shipping_rounded, false),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GestureDetector(
                          onTap: _handleSearchDestination,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                                const SizedBox(width: AppSpacing.sm),
                                const AppText('Where to?', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRecentPlace('Work', 'Bole, Addis Ababa', '12 min'),
                        const Divider(),
                        _buildRecentPlace('Home', 'CMC, Addis Ababa', '40 min'),
                      ] else if (_rideStatus == 'none') ...[
                        // Request State
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: _cancelRideRequest,
                            ),
                            Expanded(
                              child: AppText(
                                _destination!.displayName.split(',').first,
                                variant: AppTextVariant.heading3,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.motorcycle_rounded, color: AppColors.primary, size: 32),
                          title: const AppText('Motorbike Ride', variant: AppTextVariant.bodyMedium, fontWeight: FontWeight.bold),
                          subtitle: const AppText('2 mins away', variant: AppTextVariant.bodySmall),
                          trailing: const AppText('150 ETB', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton.primary(
                          label: 'REQUEST RIDE',
                          fullWidth: true,
                          onPressed: _requestRide,
                        ),
                      ] else if (_rideStatus == 'pending') ...[
                        // Waiting State
                        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        const SizedBox(height: AppSpacing.lg),
                        const Center(
                          child: AppText(
                            'Finding your driver...',
                            variant: AppTextVariant.heading3,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.outlinedSecondary(
                          label: 'CANCEL REQUEST',
                          fullWidth: true,
                          onPressed: _cancelRideRequest,
                        ),
                      ] else if (_rideStatus == 'accepted') ...[
                        // Accepted State
                        const Center(
                          child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Center(
                          child: AppText(
                            'Driver is on the way!',
                            variant: AppTextVariant.heading2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.primary(
                          label: 'VIEW DRIVER DETAILS',
                          fullWidth: true,
                          onPressed: () {},
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
    );
  }

  Widget _buildTransportOption(String title, IconData icon, bool isSelected) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceAlt : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
          const SizedBox(height: AppSpacing.xs),
          AppText(title, variant: AppTextVariant.bodySmall, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ],
      ),
    );
  }

  Widget _buildRecentPlace(String title, String subtitle, String eta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, variant: AppTextVariant.labelLarge, fontWeight: FontWeight.bold),
                AppText(subtitle, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
              ],
            ),
          ),
          AppText(eta, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
