import 'dart:async';
import 'dart:math' as math;

import 'package:client_app/config/router/navigation_helper.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:client_app/core/utils/functions/base_functions/ethiopian_phone.dart';
import 'package:client_app/features/auth/domain/entities/user_entity.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/home/data/repositories/map_repository.dart';
import 'package:client_app/features/search/presentation/screens/search_destination_screen.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/router/app_routes.dart';
import '../../../../core/preferences/app_preferences.dart';

enum _PickupChoice { currentLocation, neighborhood, pinOnMap }

enum _DeliveryDestinationChoice { currentLocation, neighborhood, pinOnMap }

class _DeliveryPricing {
  const _DeliveryPricing({
    required this.title,
    required this.subtitle,
    required this.baseFare,
    required this.perKm,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final int baseFare;
  final int perKm;
  final IconData icon;
}

class _HomeDeal {
  const _HomeDeal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cardType,
    required this.accentColor,
    required this.textColor,
    required this.overlayOpacity,
    required this.sortOrder,
    required this.isActive,
    this.body = '',
    this.imageUrl = '',
    this.fallbackAsset,
    this.badgeText = '',
    this.ctaLabel = '',
    this.ctaUrl = '',
    this.startsAt,
    this.endsAt,
  });

  factory _HomeDeal.fromMap(Map<String, dynamic> map) {
    return _HomeDeal(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString().trim() ?? '',
      subtitle: map['subtitle']?.toString().trim() ?? '',
      body: map['body']?.toString().trim() ?? '',
      imageUrl: map['image_url']?.toString().trim() ?? '',
      cardType: map['card_type']?.toString() == 'hero' ? 'hero' : 'grid',
      accentColor: _dealColor(map['accent_color'], AppColors.primary),
      textColor: _dealColor(map['text_color'], Colors.white),
      overlayOpacity: _dealOpacity(map['overlay_opacity']),
      badgeText: map['badge_text']?.toString().trim() ?? '',
      ctaLabel: map['cta_label']?.toString().trim() ?? '',
      ctaUrl: map['cta_url']?.toString().trim() ?? '',
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
      isActive: map['is_active'] != false,
      startsAt: _dealDate(map['starts_at']),
      endsAt: _dealDate(map['ends_at']),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String imageUrl;
  final String cardType;
  final Color accentColor;
  final Color textColor;
  final double overlayOpacity;
  final String? fallbackAsset;
  final String badgeText;
  final String ctaLabel;
  final String ctaUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isHero => cardType == 'hero';
  bool get hasAction => ctaUrl.trim().isNotEmpty;

  bool get isVisibleNow {
    if (!isActive) return false;
    final now = DateTime.now();
    return (startsAt == null || !startsAt!.isAfter(now)) &&
        (endsAt == null || !endsAt!.isBefore(now));
  }
}

const Map<String, _DeliveryPricing> _deliveryPricing = {
  'Bike': _DeliveryPricing(
    title: 'Bicycle',
    subtitle: '40/km ETB',
    baseFare: 30,
    perKm: 40,
    icon: Icons.directions_bike_rounded,
  ),
  'Motor': _DeliveryPricing(
    title: 'Motorbike',
    subtitle: '50/km ETB',
    baseFare: 40,
    perKm: 50,
    icon: Icons.motorcycle_rounded,
  ),
};

const List<String> _packageTypes = [
  'Documents',
  'Small Box',
  'Food/Groceries',
  'Electronics',
  'Other',
];

const List<_HomeDeal> _fallbackDeals = [
  _HomeDeal(
    id: 'fallback-hero',
    title: 'Deals are coming',
    subtitle:
        'MotoBike is launching soon with exciting deals and offers for our first users. Stay tuned!',
    body: 'Upcoming offers for delivery customers.',
    imageUrl: '',
    fallbackAsset: ImageConstants.upcomingMotobikeDealsBackground,
    cardType: 'hero',
    accentColor: AppColors.primary,
    textColor: Colors.white,
    overlayOpacity: 0.56,
    sortOrder: 10,
    isActive: true,
  ),
  _HomeDeal(
    id: 'fallback-launch',
    title: 'Launch deals',
    subtitle: 'Save on first deliveries',
    body: 'Introductory delivery offers.',
    imageUrl: '',
    fallbackAsset: ImageConstants.promoLaunchDeals,
    cardType: 'grid',
    accentColor: AppColors.primary,
    textColor: Colors.white,
    overlayOpacity: 0.46,
    sortOrder: 20,
    isActive: true,
  ),
  _HomeDeal(
    id: 'fallback-partners',
    title: 'Partner perks',
    subtitle: 'Offers from local shops',
    body: 'Local partner discounts and perks.',
    imageUrl: '',
    fallbackAsset: ImageConstants.promoPartnerPerks,
    cardType: 'grid',
    accentColor: AppColors.secondary,
    textColor: Colors.white,
    overlayOpacity: 0.46,
    sortOrder: 30,
    isActive: true,
  ),
];

Color _dealColor(Object? value, Color fallback) {
  final raw = value?.toString().trim() ?? '';
  final hex = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hex.length != 6) return fallback;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}

double _dealOpacity(Object? value) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0.55;
  if (parsed < 0) return 0;
  if (parsed > 0.95) return 0.95;
  return parsed;
}

DateTime? _dealDate(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

class HomeDrawerVisibilityNotification extends Notification {
  const HomeDrawerVisibilityNotification({required this.visible});

  final bool visible;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key})
    : deliveryPage = false,
      initialVehicleCategory = 'Bike',
      initialService = 'parcel',
      autoSearchDestination = false;

  const HomeScreen.delivery({
    super.key,
    this.initialVehicleCategory = 'Motor',
    this.initialService = 'parcel',
    this.autoSearchDestination = false,
  }) : deliveryPage = true;

  final bool deliveryPage;
  final String initialVehicleCategory;
  final String initialService;
  final bool autoSearchDestination;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _bottomNavClearance = 132;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final MapRepository _mapRepository = MapRepository();
  final TextEditingController _otherItemController = TextEditingController();
  final LatLng _fallbackCenter = const LatLng(8.9806, 38.7578);

  List<Marker> _driverMarkers = [];
  List<LatLng> _routePoints = [];
  List<_HomeDeal> _deals = _fallbackDeals;
  RealtimeChannel? _driverChannel;
  RealtimeChannel? _deliveryChannel;
  RealtimeChannel? _dealsChannel;

  MapPlace? _pickupPlace;
  MapPlace? _destination;
  Map<String, dynamic>? _currentDelivery;
  LatLng? _currentLocation;
  LatLng? _deliveryPickup;
  String? _currentDeliveryId;
  String _deliveryStatus = 'none';
  String _selectedService = 'parcel';
  String _selectedVehicleCategory = 'Bike';
  String? _lastPulsedVehicleCategory;
  String _selectedPackageType = 'Documents';
  int _vehicleSelectionPulse = 0;
  double? _distanceKm;
  bool _hasLoadedActiveDelivery = false;
  bool _isLoadingActiveDelivery = false;
  bool _showMap = false;
  bool _isPreparingDelivery = false;
  bool _isRequestingAnotherDelivery = false;
  bool _isSubmitting = false;
  bool _isResolvingPickup = false;
  bool _hasAutoOpenedDestinationSearch = false;
  Future<bool>? _locationReadyFuture;
  final Set<String> _ratingPromptedDeliveries = <String>{};
  late final VoidCallback _homeAction;
  late final VoidCallback _primaryDeliveryAction;

  @override
  void initState() {
    super.initState();
    _selectedVehicleCategory = _normalizedVehicleCategory(
      widget.initialVehicleCategory,
    );
    _selectedService = widget.initialService.trim().isEmpty
        ? 'parcel'
        : widget.initialService.trim();
    _showMap = widget.deliveryPage;
    _homeAction = _returnToHomeFromNav;
    _primaryDeliveryAction = () =>
        _openDeliveryRoute(vehicleCategory: 'Motor', service: _selectedService);
    if (!widget.deliveryPage) {
      NavigationService().setHomeAction(_homeAction);
      NavigationService().setPrimaryDeliveryAction(_primaryDeliveryAction);
    }
    _listenToDrivers();
    _listenToDeals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadCurrentLocation());
      _maybeAutoOpenDestinationSearch();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.deliveryPage) return;

    final nextVehicle = _normalizedVehicleCategory(
      widget.initialVehicleCategory,
    );
    final nextService = widget.initialService.trim().isEmpty
        ? 'parcel'
        : widget.initialService.trim();

    if (oldWidget.autoSearchDestination != widget.autoSearchDestination ||
        oldWidget.initialVehicleCategory != widget.initialVehicleCategory ||
        oldWidget.initialService != widget.initialService) {
      _hasAutoOpenedDestinationSearch = false;
    }

    if (nextVehicle != _selectedVehicleCategory ||
        nextService != _selectedService ||
        !_showMap) {
      setState(() {
        _selectedVehicleCategory = nextVehicle;
        _lastPulsedVehicleCategory = nextVehicle;
        _vehicleSelectionPulse++;
        _selectedService = nextService;
        _showMap = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAutoOpenDestinationSearch();
    });
  }

  LatLng get _mapCenter =>
      _deliveryPickup ?? _currentLocation ?? _fallbackCenter;

  Future<bool> _loadCurrentLocation() async {
    try {
      final canReadLocation = await _ensureLocationReady();
      if (!canReadLocation) return false;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return false;

      final location = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = location);
      if (!_showMap) return true;
      _mapController.move(location, 14);
      return true;
    } catch (e) {
      debugPrint('Error loading current location: $e');
      if (!mounted) return false;
      await _showLocationRequiredDialog(
        title: 'GPS required',
        message:
            'We could not read your current GPS position. Keep GPS on and check again so pickup stays accurate.',
        primaryLabel: 'Open GPS settings',
        onPrimaryPressed: Geolocator.openLocationSettings,
      );
      return false;
    }
  }

  Future<bool> _ensureLocationReady() {
    final inFlight = _locationReadyFuture;
    if (inFlight != null) return inFlight;

    late final Future<bool> nextCheck;
    nextCheck = _ensureLocationReadyLoop().whenComplete(() {
      if (identical(_locationReadyFuture, nextCheck)) {
        _locationReadyFuture = null;
      }
    });
    _locationReadyFuture = nextCheck;
    return nextCheck;
  }

  Future<bool> _ensureLocationReadyLoop() async {
    while (mounted) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return false;
      if (!serviceEnabled) {
        await _showLocationRequiredDialog(
          title: 'Turn on GPS',
          message:
              'MotoBike needs GPS to set your pickup point, calculate distance, and track the delivery. Turn on GPS, then tap Check again.',
          primaryLabel: 'Open GPS settings',
          onPrimaryPressed: Geolocator.openLocationSettings,
        );
        continue;
      }

      var permission = await Geolocator.checkPermission();
      if (!mounted) return false;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return false;
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationRequiredDialog(
          title: 'Allow location',
          message:
              'Location permission is blocked. Open app settings, allow location, then tap Check again.',
          primaryLabel: 'Open app settings',
          onPrimaryPressed: Geolocator.openAppSettings,
        );
        continue;
      }

      if (permission == LocationPermission.denied) {
        await _showLocationRequiredDialog(
          title: 'Allow location',
          message:
              'Location permission is required before you can request a delivery. Allow it, then tap Check again.',
          primaryLabel: 'Open app settings',
          onPrimaryPressed: Geolocator.openAppSettings,
        );
        continue;
      }

      return true;
    }

    return false;
  }

  Future<bool> _isLocationReadySilently() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _showLocationRequiredDialog({
    required String title,
    required String message,
    required String primaryLabel,
    required Future<bool> Function() onPrimaryPressed,
  }) async {
    if (!mounted) return;

    Timer? autoCloseTimer;
    var autoCheckingLocation = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var waitingForSettings = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            autoCloseTimer ??= Timer.periodic(
              const Duration(milliseconds: 800),
              (_) {
                if (autoCheckingLocation) return;
                autoCheckingLocation = true;
                unawaited(() async {
                  try {
                    final ready = await _isLocationReadySilently();
                    if (mounted && dialogContext.mounted && ready) {
                      autoCloseTimer?.cancel();
                      Navigator.of(dialogContext).pop();
                    }
                  } finally {
                    autoCheckingLocation = false;
                  }
                }());
              },
            );

            Future<void> openSettingsAndWait() async {
              if (waitingForSettings) return;
              setDialogState(() => waitingForSettings = true);
              await onPrimaryPressed();

              for (var i = 0; i < 45; i++) {
                await Future<void>.delayed(const Duration(milliseconds: 800));
                if (!mounted || !dialogContext.mounted) return;
                if (await _isLocationReadySilently()) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  return;
                }
              }

              if (dialogContext.mounted) {
                setDialogState(() => waitingForSettings = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      title,
                      variant: AppTextVariant.heading3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              content: AppText(
                waitingForSettings
                    ? 'Waiting for GPS to turn on. MotoBike will continue '
                          'automatically.'
                    : message,
                variant: AppTextVariant.bodyMedium,
                color: dialogContext.appTextSecondary,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const AppText(
                    'Check again',
                    variant: AppTextVariant.button,
                  ),
                ),
                FilledButton.icon(
                  onPressed: waitingForSettings
                      ? null
                      : () => unawaited(openSettingsAndWait()),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: Text(
                    waitingForSettings ? 'Waiting for GPS...' : primaryLabel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    autoCloseTimer?.cancel();
  }

  Future<void> _listenToDrivers() async {
    try {
      await _loadOnlineDrivers();
      _driverChannel = Supabase.instance.client
          .channel('public:drivers')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'drivers',
            callback: _handleDriverUpdate,
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up driver realtime: $e');
    }
  }

  Future<void> _listenToDeals() async {
    try {
      await _loadDeals();
      _dealsChannel = Supabase.instance.client
          .channel('public:app_deals:home')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_deals',
            callback: (_) => unawaited(_loadDeals()),
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up deals realtime: $e');
    }
  }

  Future<void> _loadDeals() async {
    try {
      final data = await Supabase.instance.client
          .from('app_deals')
          .select(
            'id,title,subtitle,body,image_url,card_type,accent_color,text_color,overlay_opacity,badge_text,cta_label,cta_url,sort_order,is_active,starts_at,ends_at,created_at',
          )
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      final deals = List<Map<String, dynamic>>.from(data)
          .map(_HomeDeal.fromMap)
          .where((deal) => deal.title.isNotEmpty && deal.isVisibleNow)
          .toList();

      if (!mounted) return;
      setState(() => _deals = deals.isEmpty ? _fallbackDeals : deals);
    } catch (e) {
      debugPrint('Deals fallback: $e');
      if (!mounted) return;
      setState(() => _deals = _fallbackDeals);
    }
  }

  Future<void> _openDealAction(_HomeDeal deal) async {
    final uri = Uri.tryParse(deal.ctaUrl.trim());
    if (uri == null || !uri.hasScheme) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'Could not open deal.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _loadOnlineDrivers() async {
    final data = await Supabase.instance.client
        .from('drivers')
        .select(
          'id, status, approval_status, is_active, current_lat, current_lng, vehicle_type',
        )
        .eq('status', 'Online')
        .eq('approval_status', 'Approved');

    if (!mounted) return;
    setState(() {
      _driverMarkers = List<Map<String, dynamic>>.from(data)
          .where(_isVisibleDriver)
          .map(
            (driver) => _buildDriverMarker(
              driver['id'].toString(),
              LatLng(
                _asDouble(driver['current_lat']),
                _asDouble(driver['current_lng']),
              ),
              driver['vehicle_type']?.toString() ?? 'Motorbike',
            ),
          )
          .toList();
    });
  }

  bool _isVisibleDriver(Map<String, dynamic> driver) {
    return driver['status'] == 'Online' &&
        driver['approval_status'] == 'Approved' &&
        driver['is_active'] != false &&
        driver['current_lat'] != null &&
        driver['current_lng'] != null;
  }

  void _handleDriverUpdate(PostgresChangePayload payload) {
    if (!mounted) return;

    final oldId = payload.oldRecord['id']?.toString();
    final data = Map<String, dynamic>.from(payload.newRecord);
    final id = data['id']?.toString() ?? oldId;
    if (id == null) return;

    setState(() {
      _driverMarkers.removeWhere((marker) => marker.key == ValueKey(id));
      if (data.isNotEmpty && _isVisibleDriver(data)) {
        _driverMarkers.add(
          _buildDriverMarker(
            id,
            LatLng(
              _asDouble(data['current_lat']),
              _asDouble(data['current_lng']),
            ),
            data['vehicle_type']?.toString() ?? 'Motorbike',
          ),
        );
      }
      if (_assignedDriverId == id) {
        final currentDriver = _currentDelivery?['driver'] is Map
            ? Map<String, dynamic>.from(_currentDelivery!['driver'] as Map)
            : <String, dynamic>{};
        _currentDelivery = {
          ...?_currentDelivery,
          'driver': {...currentDriver, ...data},
        };
      }
    });
  }

  String? get _assignedDriverId {
    final driver = _currentDelivery?['driver'];
    if (driver is! Map) return null;
    return driver['id']?.toString();
  }

  Marker _buildDriverMarker(String id, LatLng position, String vehicleType) {
    final icon = _vehicleIconFor(vehicleType);
    final markerColor = _isBicycle(vehicleType)
        ? AppColors.secondary
        : AppColors.primary;

    return Marker(
      key: ValueKey(id),
      point: position,
      width: 46,
      height: 46,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: markerColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: markerColor, size: 25),
      ),
    );
  }

  bool _isBicycle(Object? vehicleType) {
    final type = vehicleType?.toString().toLowerCase() ?? '';
    if (type.contains('motor')) return false;
    return type.contains('bike') ||
        type.contains('bicycle') ||
        type.contains('cycle');
  }

  IconData _vehicleIconFor(Object? vehicleType) {
    final type = vehicleType?.toString().toLowerCase() ?? '';
    if (_isBicycle(type)) return Icons.directions_bike_rounded;
    if (type.contains('truck')) return Icons.local_shipping_rounded;
    return Icons.motorcycle_rounded;
  }

  _DeliveryPricing get _selectedPricing =>
      _deliveryPricing[_selectedVehicleCategory]!;

  int? get _estimatedPrice {
    final distanceKm = _distanceKm;
    if (distanceKm == null) return null;
    return _calculateEstimatedPrice(distanceKm, _selectedPricing);
  }

  String _normalizedVehicleCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('motor')) return 'Motor';
    if (normalized.contains('bike') || normalized.contains('bicycle')) {
      return 'Bike';
    }
    return 'Bike';
  }

  void _selectVehicleCategory(String value) {
    final vehicleCategory = _normalizedVehicleCategory(value);
    setState(() {
      _selectedVehicleCategory = vehicleCategory;
      _lastPulsedVehicleCategory = vehicleCategory;
      _vehicleSelectionPulse++;
    });
  }

  void _maybeAutoOpenDestinationSearch() {
    if (!widget.deliveryPage ||
        !widget.autoSearchDestination ||
        _hasAutoOpenedDestinationSearch ||
        _destination != null ||
        _isPreparingDelivery) {
      return;
    }

    _hasAutoOpenedDestinationSearch = true;
    _isRequestingAnotherDelivery = _hasActiveDelivery;
    unawaited(_startDeliveryFlow(service: _selectedService));
  }

  void _openDeliveryRoute({
    String? vehicleCategory,
    String? service,
    bool openSearchDestination = true,
  }) {
    final selectedVehicle = _normalizedVehicleCategory(
      vehicleCategory ?? _selectedVehicleCategory,
    );
    final selectedService = (service ?? _selectedService).trim().isEmpty
        ? 'parcel'
        : (service ?? _selectedService).trim();

    context.goNamed(
      AppRoutes.delivery.name,
      queryParameters: {
        'vehicle': selectedVehicle,
        'service': selectedService,
        'search': openSearchDestination ? '1' : '0',
      },
    );
  }

  int _calculateEstimatedPrice(double distanceKm, _DeliveryPricing pricing) {
    final raw = pricing.baseFare + (distanceKm * pricing.perKm);
    return (raw / 10).round() * 10;
  }

  String _distanceLabel() {
    final distanceKm = _distanceKm;
    if (distanceKm == null) return 'Select a destination for exact km';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String _pickupTitle() {
    final displayName = _pickupPlace?.displayName;
    if (displayName == null || displayName.trim().isEmpty) {
      return 'Choose pickup';
    }
    return displayName.split(',').first.trim();
  }

  String _pickupSubtitle() {
    final displayName = _pickupPlace?.displayName;
    if (displayName == null || displayName.trim().isEmpty) {
      return 'Use GPS, choose a neighborhood, or pin the map.';
    }
    return displayName;
  }

  bool get _hasPickup => _deliveryPickup != null && _pickupPlace != null;

  Future<bool> _ensurePickupSelected({bool prompt = true}) async {
    if (_hasPickup) return true;
    if (!prompt) return false;

    final choice = await _showPickupChoiceSheet();
    if (!mounted || choice == null) return _hasPickup;

    switch (choice) {
      case _PickupChoice.currentLocation:
        await _useCurrentLocationForPickup();
      case _PickupChoice.neighborhood:
        await _choosePickupNeighborhood();
      case _PickupChoice.pinOnMap:
        await _pinPickupOnMap();
    }

    return _hasPickup;
  }

  Future<_PickupChoice?> _showPickupChoiceSheet() {
    return showModalBottomSheet<_PickupChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (sheetContext) {
        return _LocationChoiceSheet<_PickupChoice>(
          accentColor: AppColors.success,
          heroIcon: Icons.trip_origin_rounded,
          title: 'Pickup',
          subtitle: 'Set collection point',
          options: const [
            _LocationChoiceOption(
              value: _PickupChoice.currentLocation,
              icon: Icons.my_location_rounded,
              title: 'GPS',
              caption: 'Here',
            ),
            _LocationChoiceOption(
              value: _PickupChoice.neighborhood,
              icon: Icons.travel_explore_rounded,
              title: 'Area',
              caption: 'Search',
            ),
            _LocationChoiceOption(
              value: _PickupChoice.pinOnMap,
              icon: Icons.add_location_alt_rounded,
              title: 'Pin',
              caption: 'Map',
            ),
          ],
        );
      },
    );
  }

  Future<void> _useCurrentLocationForPickup() async {
    final hasLocation = await _loadCurrentLocation();
    if (!hasLocation || !mounted) return;

    final location = _currentLocation;
    if (location == null) return;
    await _setPickupFromPoint(location, fallbackName: 'Current GPS pickup');
  }

  Future<void> _choosePickupNeighborhood() async {
    final result = await Navigator.push<MapPlace>(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchDestinationScreen(
          title: 'Where is pickup?',
          subtitle:
              'Choose the pickup neighborhood or search the closest known area.',
          emptyTitle: 'No pickup area found',
          emptyMessagePrefix: 'Try another spelling for',
          defaultSectionTitle: 'Major pickup areas',
          defaultSectionSubtitle:
              'Tap the closest area to use it as the pickup point.',
        ),
      ),
    );

    if (!mounted || result == null) return;
    await _setPickupPlace(result);
  }

  Future<void> _pinPickupOnMap() async {
    final initialCenter =
        _deliveryPickup ?? _currentLocation ?? _destination?.location;
    final point = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => _PinLocationScreen(
          initialCenter: initialCenter ?? _fallbackCenter,
          title: 'Pin pickup',
          subtitle: 'Move the map until the pin is on the collection point.',
          buttonLabel: 'USE PINNED PICKUP',
          pinColor: AppColors.success,
        ),
      ),
    );

    if (!mounted || point == null) return;
    await _setPickupFromPoint(point, fallbackName: 'Pinned pickup');
  }

  Future<void> _setPickupPlace(MapPlace place) async {
    if (!mounted) return;
    setState(() {
      _pickupPlace = place;
      _deliveryPickup = place.location;
    });
    await _refreshRouteEstimate();
  }

  Future<void> _setPickupFromPoint(
    LatLng point, {
    required String fallbackName,
  }) async {
    if (!mounted) return;
    setState(() => _isResolvingPickup = true);

    final place = await _mapRepository.describeLocation(
      point,
      fallbackName: fallbackName,
      exactPinLabel: fallbackName.toLowerCase().startsWith('pinned'),
    );
    if (!mounted) return;

    setState(() {
      _pickupPlace = place;
      _deliveryPickup = point;
      _isResolvingPickup = false;
    });
    await _refreshRouteEstimate();
  }

  Future<void> _refreshRouteEstimate() async {
    final pickup = _deliveryPickup;
    final destination = _destination;
    if (pickup == null || destination == null) {
      if (!mounted) return;
      setState(() {
        _routePoints = [];
        _distanceKm = null;
      });
      return;
    }

    final route = await _mapRepository.getRoute(pickup, destination.location);
    if (!mounted) return;

    setState(() {
      _routePoints = route.points.isNotEmpty
          ? route.points
          : [pickup, destination.location];
      _distanceKm = route.distanceKm > 0
          ? route.distanceKm
          : _mapRepository.straightLineDistanceKm(pickup, destination.location);
    });
    _fitRoute(pickup, destination.location);
  }

  void _fitRoute(LatLng pickup, LatLng dropoff) {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints([pickup, dropoff]),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  String? _resolvedPackageType() {
    if (_selectedPackageType != 'Other') return _selectedPackageType;

    final other = _otherItemController.text.trim();
    if (other.isEmpty) return null;
    return 'Other: $other';
  }

  Future<void> _startDeliveryFlow({String service = 'parcel'}) async {
    setState(() {
      _selectedService = service;
      _showMap = true;
      _isRequestingAnotherDelivery =
          _isRequestingAnotherDelivery || _hasActiveDelivery;
    });

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _chooseDeliveryDestination();
  }

  Future<void> _chooseDeliveryDestination() async {
    final choice = await _showDestinationChoiceSheet();
    if (!mounted) return;

    if (choice == null) {
      _handleDestinationSelectionCancelled();
      return;
    }

    switch (choice) {
      case _DeliveryDestinationChoice.currentLocation:
        await _useCurrentLocationForDestination();
      case _DeliveryDestinationChoice.neighborhood:
        await _chooseDestinationNeighborhood();
      case _DeliveryDestinationChoice.pinOnMap:
        await _pinDestinationOnMap();
    }
  }

  Future<_DeliveryDestinationChoice?> _showDestinationChoiceSheet() {
    return showModalBottomSheet<_DeliveryDestinationChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (sheetContext) {
        return _LocationChoiceSheet<_DeliveryDestinationChoice>(
          accentColor: AppColors.primary,
          heroIcon: Icons.flag_rounded,
          title: 'Drop-off',
          subtitle: 'Set delivery point',
          options: const [
            _LocationChoiceOption(
              value: _DeliveryDestinationChoice.currentLocation,
              icon: Icons.my_location_rounded,
              title: 'GPS',
              caption: 'Here',
            ),
            _LocationChoiceOption(
              value: _DeliveryDestinationChoice.neighborhood,
              icon: Icons.travel_explore_rounded,
              title: 'Area',
              caption: 'Search',
            ),
            _LocationChoiceOption(
              value: _DeliveryDestinationChoice.pinOnMap,
              icon: Icons.add_location_alt_rounded,
              title: 'Pin',
              caption: 'Map',
            ),
          ],
        );
      },
    );
  }

  Future<void> _chooseDestinationNeighborhood() async {
    final result = await Navigator.push<MapPlace>(
      context,
      MaterialPageRoute(builder: (context) => const SearchDestinationScreen()),
    );
    if (!mounted) return;

    if (result == null) {
      _handleDestinationSelectionCancelled();
      return;
    }

    await _setDeliveryDestination(result);
  }

  Future<void> _useCurrentLocationForDestination() async {
    final hasLocation = await _loadCurrentLocation();
    if (!hasLocation || !mounted) return;

    final location = _currentLocation;
    if (location == null) return;
    final place = await _mapRepository.describeLocation(
      location,
      fallbackName: 'Current GPS delivery destination',
    );
    if (!mounted) return;
    await _setDeliveryDestination(place);
  }

  Future<void> _pinDestinationOnMap() async {
    final initialCenter =
        _destination?.location ?? _currentLocation ?? _deliveryPickup;
    final point = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => _PinLocationScreen(
          initialCenter: initialCenter ?? _fallbackCenter,
          title: 'Pin drop-off',
          subtitle: 'Move the map until the pin is on the delivery point.',
          buttonLabel: 'USE PINNED DROP-OFF',
          pinColor: AppColors.primary,
        ),
      ),
    );
    if (!mounted || point == null) return;

    final place = await _mapRepository.describeLocation(
      point,
      fallbackName: 'Pinned delivery destination',
      exactPinLabel: true,
    );
    if (!mounted) return;
    await _setDeliveryDestination(place);
  }

  void _handleDestinationSelectionCancelled() {
    if (widget.deliveryPage &&
        widget.autoSearchDestination &&
        _destination == null &&
        !_hasActiveDelivery) {
      NavigationService().triggerHomeAction();
      return;
    }
    if (!_isPreparingDelivery && !_hasActiveDelivery) {
      setState(() => _showMap = false);
    }
  }

  Future<void> _setDeliveryDestination(MapPlace result) async {
    final isAnotherDelivery =
        _isRequestingAnotherDelivery || _hasActiveDelivery;
    setState(() {
      _destination = result;
      _isPreparingDelivery = true;
      _isRequestingAnotherDelivery = isAnotherDelivery;
      if (!isAnotherDelivery) {
        _deliveryStatus = 'none';
      }
      _routePoints = [];
      _distanceKm = null;
    });

    if (_hasPickup) {
      await _refreshRouteEstimate();
    } else {
      await _ensurePickupSelected();
    }
  }

  Future<void> _requestDelivery() async {
    if (_destination == null || _isSubmitting) return;
    final previousDelivery = _currentDelivery == null
        ? null
        : Map<String, dynamic>.from(_currentDelivery!);
    final previousDeliveryId = _currentDeliveryId;
    final previousDeliveryStatus = _deliveryStatus;
    final hasPickup = await _ensurePickupSelected();
    if (!hasPickup) {
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Choose pickup location first.',
        type: AppToastType.warning,
      );
      return;
    }
    if (!mounted) return;
    final pickup = _deliveryPickup;
    if (pickup == null) {
      return;
    }

    final packageType = _resolvedPackageType();
    if (packageType == null) {
      AppToast.show(
        context: context,
        message: 'Tell us what the item is for Other.',
        type: AppToastType.error,
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      AppToast.show(
        context: context,
        message: 'Please sign in to request delivery.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _deliveryStatus = 'Pending';
    });

    try {
      final user = authState.user;
      final customerName = [user.firstName, user.lastName]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join(' ')
          .trim();
      final distanceKm =
          _distanceKm ??
          _mapRepository.straightLineDistanceKm(pickup, _destination!.location);
      if (_distanceKm == null) {
        await _refreshRouteEstimate();
      }
      final pickupLabel = _pickupPlace?.displayName.trim().isNotEmpty == true
          ? _pickupPlace!.displayName.trim()
          : 'Pinned pickup, Addis Ababa, Ethiopia';
      final deliveryFee = _calculateEstimatedPrice(
        _distanceKm ?? distanceKm,
        _selectedPricing,
      );

      final response = await Supabase.instance.client
          .from('deliveries')
          .insert({
            'customer_name': customerName.isEmpty ? user.email : customerName,
            'customer_phone': user.phone?.trim().isNotEmpty == true
                ? normalizeEthiopianPhone(user.phone!)
                : user.email,
            'client_id': user.id,
            'pickup_location': pickupLabel,
            'dropoff_location': _destination!.displayName,
            'package_type': packageType,
            'service_type': _selectedService,
            'vehicle_category': _selectedVehicleCategory,
            'delivery_fee': deliveryFee,
            'status': 'Pending',
            'pickup_lat': pickup.latitude,
            'pickup_lng': pickup.longitude,
            'dropoff_lat': _destination!.location.latitude,
            'dropoff_lng': _destination!.location.longitude,
          })
          .select(
            '*, driver:drivers(id, name, phone, vehicle_type, current_lat, current_lng)',
          )
          .single();

      _currentDeliveryId = response['id']?.toString();
      _subscribeToDelivery();

      if (!mounted) return;
      setState(() {
        _currentDelivery = Map<String, dynamic>.from(response);
        _deliveryStatus = response['status']?.toString() ?? 'Pending';
        _isRequestingAnotherDelivery = false;
      });
      AppToast.show(
        context: context,
        message: 'Delivery request sent.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Error requesting delivery: $e');
      if (!mounted) return;
      setState(() {
        _currentDelivery = previousDelivery;
        _currentDeliveryId = previousDeliveryId;
        _deliveryStatus = previousDeliveryId == null
            ? 'none'
            : previousDeliveryStatus;
      });
      AppToast.show(
        context: context,
        message: 'Failed to request delivery.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _subscribeToDelivery() {
    final deliveryId = _currentDeliveryId;
    if (deliveryId == null) return;

    _deliveryChannel?.unsubscribe();
    _deliveryChannel = Supabase.instance.client
        .channel('public:deliveries:$deliveryId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: deliveryId,
          ),
          callback: (_) => _fetchDelivery(deliveryId),
        )
        .subscribe();
  }

  Future<void> _fetchDelivery(String id) async {
    try {
      final data = await Supabase.instance.client
          .from('deliveries')
          .select(
            '*, driver:drivers(id, name, phone, vehicle_type, current_lat, current_lng)',
          )
          .eq('id', id)
          .single();

      if (!mounted) return;
      final nextStatus = data['status']?.toString() ?? _deliveryStatus;
      setState(() {
        _currentDelivery = Map<String, dynamic>.from(data);
        _deliveryStatus = nextStatus;
      });

      if (nextStatus == 'Assigned') {
        AppToast.show(
          context: context,
          message: 'Courier assigned.',
          type: AppToastType.success,
        );
      } else if (nextStatus == 'Delivered') {
        AppToast.show(
          context: context,
          message: 'Delivery completed.',
          type: AppToastType.success,
        );
        final deliveredDelivery = Map<String, dynamic>.from(data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showClientRatingPrompt(deliveredDelivery);
        });
      } else if (nextStatus == 'Cancelled') {
        AppToast.show(
          context: context,
          message: 'Delivery cancelled.',
          type: AppToastType.warning,
        );
      }
    } catch (e) {
      debugPrint('Error fetching delivery: $e');
    }
  }

  Future<void> _showClientRatingPrompt(
    Map<String, dynamic> delivery, {
    bool force = false,
  }) async {
    final deliveryId = delivery['id']?.toString();
    final driver = delivery['driver'] is Map
        ? Map<String, dynamic>.from(delivery['driver'] as Map)
        : null;
    final driverId =
        delivery['driver_id']?.toString() ?? driver?['id']?.toString();
    final authState = context.read<AuthBloc>().state;

    if (deliveryId == null ||
        driverId == null ||
        authState is! AuthAuthenticated) {
      return;
    }
    if (!force && !_ratingPromptedDeliveries.add(deliveryId)) return;

    try {
      final existing = await Supabase.instance.client
          .from('delivery_ratings')
          .select('rating')
          .eq('delivery_id', deliveryId)
          .eq('rater_type', 'client')
          .eq('rater_id', authState.user.id)
          .eq('ratee_type', 'driver')
          .eq('ratee_id', driverId)
          .maybeSingle();

      if (existing != null && !force) return;
      if (!mounted) return;

      final initialRating = existing == null
          ? 5
          : int.tryParse(existing['rating']?.toString() ?? '') ?? 5;
      final rating = await _showRatingSheet(
        title: 'Rate your driver',
        subtitle: driver?['name']?.toString() ?? 'How was this delivery?',
        initialRating: initialRating,
      );
      if (rating == null) return;

      await Supabase.instance.client.from('delivery_ratings').upsert({
        'delivery_id': deliveryId,
        'rater_type': 'client',
        'rater_id': authState.user.id,
        'ratee_type': 'driver',
        'ratee_id': driverId,
        'rating': rating,
      }, onConflict: 'delivery_id,rater_type,rater_id,ratee_type,ratee_id');

      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Rating saved.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Error saving driver rating: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Ratings are not ready. Run supabase/schema_v5_ratings.sql.',
        type: AppToastType.error,
      );
    }
  }

  Future<int?> _showRatingSheet({
    required String title,
    required String subtitle,
    required int initialRating,
  }) {
    var selectedRating = initialRating.clamp(1, 5).toInt();

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.appBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppText(
                      title,
                      variant: AppTextVariant.heading3,
                      fontWeight: FontWeight.w900,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      subtitle,
                      variant: AppTextVariant.bodyMedium,
                      color: context.appTextSecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          tooltip: '$value star',
                          onPressed: () {
                            setSheetState(() => selectedRating = value);
                          },
                          icon: Icon(
                            value <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 38,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: 'SUBMIT RATING',
                      fullWidth: true,
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(selectedRating),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: AppText(
                        'Skip',
                        variant: AppTextVariant.button,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _ensureActiveDeliveryLoaded(AuthState authState) {
    if (_hasLoadedActiveDelivery || _isLoadingActiveDelivery) return;
    if (authState is! AuthAuthenticated) return;

    _hasLoadedActiveDelivery = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadActiveDeliveryForCurrentUser(authState.user);
    });
  }

  Future<void> _loadActiveDeliveryForCurrentUser(UserEntity user) async {
    if (_isLoadingActiveDelivery) return;

    setState(() => _isLoadingActiveDelivery = true);
    try {
      final supabase = Supabase.instance.client;
      final select =
          '*, driver:drivers(id, name, phone, vehicle_type, current_lat, current_lng)';

      final byClient = await supabase
          .from('deliveries')
          .select(select)
          .eq('client_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      var delivery = _firstActiveDelivery(byClient);
      final customerLookup = user.phone?.trim().isNotEmpty == true
          ? normalizeEthiopianPhone(user.phone!)
          : user.email;

      if (delivery == null && customerLookup.trim().isNotEmpty) {
        final byPhone = await supabase
            .from('deliveries')
            .select(select)
            .eq('customer_phone', customerLookup)
            .order('created_at', ascending: false)
            .limit(10);
        delivery = _firstActiveDelivery(byPhone);
      }

      if (!mounted || delivery == null) return;
      await _adoptDelivery(delivery, showMap: false);
    } catch (e) {
      debugPrint('Error loading active delivery: $e');
    } finally {
      if (mounted) setState(() => _isLoadingActiveDelivery = false);
    }
  }

  Map<String, dynamic>? _firstActiveDelivery(Object? value) {
    if (value is! List) return null;

    for (final item in value) {
      final delivery = Map<String, dynamic>.from(item as Map);
      if (_isActiveDeliveryStatus(delivery['status']?.toString())) {
        return delivery;
      }
    }
    return null;
  }

  bool _isActiveDeliveryStatus(String? status) {
    return status == 'Pending' || status == 'Assigned' || status == 'Picked Up';
  }

  bool get _hasActiveDelivery =>
      _currentDeliveryId != null && _isActiveDeliveryStatus(_deliveryStatus);

  Future<void> _adoptDelivery(
    Map<String, dynamic> delivery, {
    required bool showMap,
  }) async {
    final pickup = _latLngFromFields(
      delivery['pickup_lat'],
      delivery['pickup_lng'],
    );
    final dropoff = _latLngFromFields(
      delivery['dropoff_lat'],
      delivery['dropoff_lng'],
    );
    final vehicleCategory = delivery['vehicle_category']?.toString();
    final packageType = delivery['package_type']?.toString();

    setState(() {
      _currentDelivery = delivery;
      _currentDeliveryId = delivery['id']?.toString();
      _deliveryStatus = delivery['status']?.toString() ?? 'Pending';
      _deliveryPickup = pickup;
      _showMap = showMap;
      _isPreparingDelivery = true;
      _isRequestingAnotherDelivery = false;
      if (vehicleCategory == 'Bike' || vehicleCategory == 'Motor') {
        _selectedVehicleCategory = vehicleCategory!;
      }
      _applyPackageType(packageType);
      if (pickup != null) {
        _pickupPlace = MapPlace(
          displayName: delivery['pickup_location']?.toString() ?? 'Pickup',
          location: pickup,
        );
      }
      if (dropoff != null) {
        _destination = MapPlace(
          displayName: delivery['dropoff_location']?.toString() ?? 'Dropoff',
          location: dropoff,
        );
      }
    });

    _subscribeToDelivery();

    if (pickup != null && dropoff != null) {
      final route = await _mapRepository.getRoute(pickup, dropoff);
      if (!mounted) return;
      setState(() {
        _routePoints = route.points.isNotEmpty
            ? route.points
            : [pickup, dropoff];
        _distanceKm = route.distanceKm > 0
            ? route.distanceKm
            : _mapRepository.straightLineDistanceKm(pickup, dropoff);
      });
      if (showMap) _fitActiveDelivery();
    }
  }

  void _applyPackageType(String? packageType) {
    if (packageType == null || packageType.trim().isEmpty) return;
    if (packageType.startsWith('Other:')) {
      _selectedPackageType = 'Other';
      _otherItemController.text = packageType.replaceFirst('Other:', '').trim();
    } else if (_packageTypes.contains(packageType)) {
      _selectedPackageType = packageType;
      _otherItemController.clear();
    }
  }

  LatLng? _latLngFromFields(Object? lat, Object? lng) {
    final latitude = _asNullableDouble(lat);
    final longitude = _asNullableDouble(lng);
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  bool get _canCancelCurrentDelivery =>
      _currentDeliveryId != null &&
      (_deliveryStatus == 'Pending' || _deliveryStatus == 'Assigned');

  Future<void> _confirmCancelCurrentDelivery() async {
    if (!_canCancelCurrentDelivery) return;

    final confirmed = await AppModal.confirm(
      context: context,
      title: 'Cancel delivery?',
      contentText: 'This delivery will be cancelled before pickup.',
      confirmLabel: 'Cancel delivery',
      cancelLabel: 'Keep delivery',
      icon: Icons.cancel_outlined,
      heightPercentage: 0.46,
    );
    if (confirmed != true || !mounted) return;

    await _cancelDeliveryRequest();
    if (!mounted) return;
    AppToast.show(
      context: context,
      message: 'Delivery cancelled.',
      type: AppToastType.success,
    );
  }

  Future<void> _startAnotherDeliveryRequest() async {
    setState(() {
      _isRequestingAnotherDelivery = true;
      _isPreparingDelivery = false;
      _showMap = true;
      _destination = null;
      _routePoints = [];
      _distanceKm = null;
      _selectedPackageType = 'Documents';
      _otherItemController.clear();
    });
    await _startDeliveryFlow(service: _selectedService);
  }

  void _discardDraftDelivery() {
    setState(() {
      _isRequestingAnotherDelivery = false;
      _isPreparingDelivery = false;
      _destination = null;
      _routePoints = [];
      _distanceKm = null;
      if (!_hasActiveDelivery) {
        _showMap = false;
        _pickupPlace = null;
        _deliveryPickup = null;
        _deliveryStatus = 'none';
      }
    });
  }

  Future<void> _cancelDeliveryRequest() async {
    final deliveryId = _currentDeliveryId;
    if (deliveryId != null &&
        ['Pending', 'Assigned'].contains(_deliveryStatus)) {
      try {
        await Supabase.instance.client
            .from('deliveries')
            .update({
              'status': 'Cancelled',
              'driver_id': null,
              'assigned_at': null,
              'cancelled_by': 'customer',
              'cancellation_reason': 'Cancelled from client app',
            })
            .eq('id', deliveryId)
            .inFilter('status', const ['Pending', 'Assigned']);
      } catch (e) {
        debugPrint('Error cancelling delivery: $e');
      }
    }
    _resetDeliveryState();
  }

  Future<void> _callAssignedDriver() async {
    final phone = _currentDriver?['phone']?.toString().trim() ?? '';
    if (phone.isEmpty) {
      AppToast.show(
        context: context,
        message: 'Driver phone is not available yet.',
        type: AppToastType.warning,
      );
      return;
    }

    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'Could not start the call.',
        type: AppToastType.error,
      );
    }
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  void _trackCurrentDelivery() {
    final deliveryId = _currentDeliveryId;
    context.goNamed(
      AppRoutes.tracking.name,
      queryParameters: {if (deliveryId != null) 'deliveryId': deliveryId},
    );
  }

  void _fitActiveDelivery() {
    final points = <LatLng>[
      if (_deliveryPickup != null) _deliveryPickup!,
      if (_destination != null) _destination!.location,
      if (_currentDriverPosition != null) _currentDriverPosition!,
    ];

    if (points.length >= 2) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(70),
        ),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 15);
    }
  }

  Map<String, dynamic>? get _currentDriver {
    final driver = _currentDelivery?['driver'];
    if (driver is! Map) return null;
    return Map<String, dynamic>.from(driver);
  }

  LatLng? get _currentDriverPosition {
    final driver = _currentDriver;
    if (driver == null) return null;
    return _latLngFromFields(driver['current_lat'], driver['current_lng']);
  }

  Marker? _buildAssignedDriverMarker(Map<String, dynamic>? driver) {
    final position = _currentDriverPosition;
    if (driver == null || position == null) return null;

    return Marker(
      point: position,
      width: 58,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _vehicleIconFor(driver['vehicle_type']),
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _closeMapView() {
    if (_isRequestingAnotherDelivery) {
      _discardDraftDelivery();
      return;
    }

    if (widget.deliveryPage) {
      NavigationService().triggerHomeAction();
      return;
    }

    if (_hasActiveDelivery) {
      setState(() => _showMap = false);
      return;
    }
    _resetDeliveryState();
  }

  void _returnToHomeFromNav() {
    if (!mounted || !_showMap) return;
    _closeMapView();
  }

  void _resetDeliveryState() {
    setState(() {
      _showMap = false;
      _isPreparingDelivery = false;
      _isRequestingAnotherDelivery = false;
      _pickupPlace = null;
      _destination = null;
      _routePoints = [];
      _distanceKm = null;
      _deliveryPickup = null;
      _deliveryStatus = 'none';
      _currentDeliveryId = null;
      _currentDelivery = null;
      _isResolvingPickup = false;
    });
    _deliveryChannel?.unsubscribe();
    _mapController.move(_mapCenter, 14);
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  void dispose() {
    NavigationService().clearHomeAction(_homeAction);
    NavigationService().clearPrimaryDeliveryAction(_primaryDeliveryAction);
    _driverChannel?.unsubscribe();
    _deliveryChannel?.unsubscribe();
    _dealsChannel?.unsubscribe();
    _otherItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureActiveDeliveryLoaded(context.watch<AuthBloc>().state);
    final driver = _currentDelivery?['driver'] is Map
        ? Map<String, dynamic>.from(_currentDelivery!['driver'] as Map)
        : null;

    return widget.deliveryPage || _showMap
        ? _buildMapExperience(driver)
        : _buildStartExperience();
  }

  Widget _buildStartExperience() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.appBackground,
      endDrawer: _buildHomeDrawer(),
      onEndDrawerChanged: (isOpened) {
        HomeDrawerVisibilityNotification(visible: isOpened).dispatch(context);
      },
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            _bottomNavClearance,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          ImageConstants.appLogo,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'MotoBike',
                            variant: AppTextVariant.heading2,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                          const SizedBox(height: 0),
                          Row(
                            children: [
                              const SizedBox(width: AppSpacing.xs),
                              const AppText(
                                'Your delivery companion',
                                color: AppColors.textSecondary,
                                variant: AppTextVariant.bodySmall,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Menu',
                    icon: Icon(
                      Icons.menu_rounded,
                      color: context.appTextPrimary,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_currentDeliveryId != null &&
                _isActiveDeliveryStatus(_deliveryStatus)) ...[
              _buildActiveDeliveryCard(),
              const SizedBox(height: AppSpacing.lg),
            ],
            // const AppText('', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
            const SizedBox(height: AppSpacing.sm),
            _buildVehicleSelector(compact: false),
            const SizedBox(height: AppSpacing.lg),
            _buildFoodDeliveryEntrySection(),
            const SizedBox(height: AppSpacing.lg),
            _buildPromoCard(),
            const SizedBox(height: AppSpacing.xxl),
            _buildUpcomingAdsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapExperience(Map<String, dynamic>? driver) {
    final assignedDriverMarker = _buildAssignedDriverMarker(driver);
    final pickupMarkerPoint = _deliveryPickup ?? _currentLocation;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motobikedeliveryservice.client',
                maxNativeZoom: 19,
                keepBuffer: 5,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.success,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: _driverMarkers),
              if (assignedDriverMarker != null)
                MarkerLayer(markers: [assignedDriverMarker]),
              MarkerLayer(
                markers: [
                  if (pickupMarkerPoint != null)
                    Marker(
                      point: pickupMarkerPoint,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.18),
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
                  if (_destination != null)
                    Marker(
                      point: _destination!.location,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundMapButton(Icons.arrow_back_rounded, _closeMapView),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: AppText(
                      'Delivery map',
                      variant: AppTextVariant.labelLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _roundMapButton(
                    Icons.search_rounded,
                    () => unawaited(_chooseDeliveryDestination()),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              key: ValueKey(
                'delivery-sheet-$_isPreparingDelivery-'
                '$_isRequestingAnotherDelivery-$_deliveryStatus',
              ),
              initialChildSize: _initialMapSheetSize,
              minChildSize: 0.24,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.32, 0.62, 0.88],
              builder: (context, scrollController) {
                return _buildBottomSheet(driver, scrollController);
              },
            ),
          ),
        ],
      ),
    );
  }

  double get _initialMapSheetSize {
    if (!_isPreparingDelivery) return 0.32;
    if (_deliveryStatus == 'none' || _isRequestingAnotherDelivery) {
      return 0.62;
    }
    if (_deliveryStatus == 'Pending') return 0.32;
    return 0.62;
  }

  void _showSettingsSheet() {
    final preferences = AppPreferencesScope.of(context);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: preferences,
          builder: (context, _) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppText(
                      'Settings',
                      variant: AppTextVariant.heading2,
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSettingsTile(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      subtitle: 'Light, dark, or system',
                      trailing: DropdownButton<ThemeMode>(
                        value: preferences.themeMode,
                        dropdownColor: context.appSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        style: TextStyle(color: context.appTextPrimary),
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) preferences.setThemeMode(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext tileContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: tileContext.appSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tileContext.appBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(
          title,
          variant: AppTextVariant.bodyMedium,
          fontWeight: FontWeight.bold,
        ),
        subtitle: AppText(
          subtitle,
          variant: AppTextVariant.bodySmall,
          color: tileContext.appTextSecondary,
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildHomeDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsetsDirectional.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
            end: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadiusDirectional.horizontal(
              start: Radius.circular(30),
            ),
            border: Border.all(color: context.appBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(-10, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.95),
                            AppColors.secondary.withValues(alpha: 0.78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          ImageConstants.appLogo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: AppText(
                        'MotoBike',
                        variant: AppTextVariant.heading3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: context.appBorder),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    _drawerTile(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () =>
                          _closeDrawerThen(context.navigator.navigateToHomeTab),
                    ),
                    _drawerTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'My Orders',
                      onTap: () => _closeDrawerThen(() {
                        NavigationService().navigateToTab(1);
                      }),
                    ),
                    _drawerTile(
                      icon: Icons.route_rounded,
                      title: 'Live Tracking',
                      onTap: () => _closeDrawerThen(_trackCurrentDelivery),
                    ),
                    _drawerTile(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      onTap: () => _closeDrawerThen(() {
                        context.pushNamed(AppRoutes.notification.name);
                      }),
                    ),
                    _drawerTile(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      onTap: () => _closeDrawerThen(
                        context.navigator.navigateToProfileTab,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Divider(color: context.appBorder),
                    ),
                    _drawerTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => _closeDrawerThen(_showSettingsSheet),
                    ),
                  ],
                ),
              ),
              _buildDrawerSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSignOutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.pop(context);
            context.read<AuthBloc>().add(const LogoutEvent());
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    'SIGN OUT',
                    variant: AppTextVariant.button,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 23),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppText(
                    title,
                    variant: AppTextVariant.bodyMedium,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.appSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: context.appTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDeliveryCard() {
    final driver = _currentDriver;
    final packageType =
        _currentDelivery?['package_type']?.toString() ?? 'Package';
    final destination =
        _currentDelivery?['dropoff_location']?.toString() ?? 'Dropoff';
    final fee = _currentDelivery?['delivery_fee'];
    final driverHasGps = _currentDriverPosition != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  'Current live package delivery',
                  variant: AppTextVariant.heading3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppText(
                _deliveryStatus,
                variant: AppTextVariant.bodySmall,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(packageType, variant: AppTextVariant.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            destination,
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (fee != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '${_asDouble(fee).toStringAsFixed(0)} ETB',
              variant: AppTextVariant.bodySmall,
              fontWeight: FontWeight.bold,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppText(
            driver == null
                ? 'Waiting for dispatch. You can request another delivery below.'
                : driverHasGps
                ? 'Driver GPS is live.'
                : 'Driver assigned. Waiting for GPS update.',
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  label: 'TRACK',
                  icon: Icons.route_rounded,
                  onPressed: _trackCurrentDelivery,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.outlinedSecondary(
                  label: 'CALL',
                  icon: Icons.call_rounded,
                  onPressed: driver == null ? null : _callAssignedDriver,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outlinedSecondary(
            label: 'REQUEST ANOTHER',
            icon: Icons.add_road_rounded,
            fullWidth: true,
            onPressed: () => unawaited(_startAnotherDeliveryRequest()),
          ),
          if (_canCancelCurrentDelivery) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.outlinedDanger(
              label: 'CANCEL DELIVERY',
              icon: Icons.cancel_outlined,
              fullWidth: true,
              onPressed: () => unawaited(_confirmCancelCurrentDelivery()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
    Map<String, dynamic>? driver,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            _bottomNavClearance,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_isPreparingDelivery &&
                  widget.deliveryPage &&
                  widget.autoSearchDestination) ...[
                _buildWhereToCard(),
              ] else if (!_isPreparingDelivery) ...[
                _buildWhereToCard(),
              ] else if (_deliveryStatus == 'none' ||
                  _isRequestingAnotherDelivery) ...[
                _buildPackageTypeSelector(),
                const SizedBox(height: AppSpacing.md),
                _buildVehicleSelector(compact: true),
                const SizedBox(height: AppSpacing.md),
                _buildPickupSelector(),
                const SizedBox(height: AppSpacing.md),
                _buildDeliverySummary(),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: _isRequestingAnotherDelivery
                      ? 'REQUEST ANOTHER DELIVERY'
                      : 'REQUEST DELIVERY',
                  fullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _requestDelivery,
                ),
              ] else if (_deliveryStatus == 'Pending') ...[
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AppText(
                  'Waiting for dispatch',
                  variant: AppTextVariant.heading3,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppText(
                  'We are looking for a courier. You can send another request while this one is waiting.',
                  variant: AppTextVariant.bodySmall,
                  color: context.appTextSecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'REQUEST ANOTHER',
                  icon: Icons.add_road_rounded,
                  fullWidth: true,
                  onPressed: () => unawaited(_startAnotherDeliveryRequest()),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.outlinedSecondary(
                  label: 'CANCEL REQUEST',
                  fullWidth: true,
                  onPressed: _cancelDeliveryRequest,
                ),
              ] else if ([
                'Assigned',
                'Picked Up',
              ].contains(_deliveryStatus)) ...[
                Icon(
                  _deliveryStatus == 'Assigned'
                      ? Icons.assignment_turned_in_rounded
                      : Icons.delivery_dining_rounded,
                  color: AppColors.success,
                  size: 56,
                ),
                const SizedBox(height: AppSpacing.md),
                AppText(
                  _deliveryStatus == 'Assigned'
                      ? 'Courier assigned'
                      : 'Package on the way',
                  variant: AppTextVariant.heading2,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                if (driver != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoTile(
                    icon: _vehicleIconFor(driver['vehicle_type']),
                    title: driver['name']?.toString() ?? 'Courier',
                    subtitle:
                        '${driver['vehicle_type'] ?? 'Motorbike'} - ${driver['phone'] ?? 'phone unavailable'}',
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        label: 'TRACK',
                        icon: Icons.route_rounded,
                        onPressed: _trackCurrentDelivery,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton.outlinedSecondary(
                        label: 'CALL',
                        icon: Icons.call_rounded,
                        onPressed: driver == null ? null : _callAssignedDriver,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.outlinedSecondary(
                  label: 'REFRESH STATUS',
                  fullWidth: true,
                  onPressed: () {
                    final id = _currentDeliveryId;
                    if (id != null) _fetchDelivery(id);
                  },
                ),
              ] else ...[
                Icon(
                  _deliveryStatus == 'Delivered'
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: _deliveryStatus == 'Delivered'
                      ? AppColors.success
                      : AppColors.warning,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.md),
                AppText(
                  _deliveryStatus == 'Delivered'
                      ? 'Delivered'
                      : _deliveryStatus,
                  variant: AppTextVariant.heading2,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_deliveryStatus == 'Delivered' && driver != null) ...[
                  AppButton.outlinedSecondary(
                    label: 'RATE DRIVER',
                    icon: Icons.star_rounded,
                    fullWidth: true,
                    onPressed: () {
                      final delivery = _currentDelivery;
                      if (delivery != null) {
                        _showClientRatingPrompt(delivery, force: true);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton.primary(
                  label: 'DONE',
                  fullWidth: true,
                  onPressed: _resetDeliveryState,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'What are you sending?',
          variant: AppTextVariant.bodyMedium,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedPackageType,
          dropdownColor: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          style: TextStyle(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.appSurfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: context.appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: context.appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _packageTypes
              .map(
                (type) =>
                    DropdownMenuItem<String>(value: type, child: Text(type)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedPackageType = value;
              if (value != 'Other') _otherItemController.clear();
            });
          },
        ),
        if (_selectedPackageType == 'Other') ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _otherItemController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.appTextPrimary),
            decoration: InputDecoration(
              hintText: 'Type what the item is',
              hintStyle: TextStyle(color: context.appTextSecondary),
              filled: true,
              fillColor: context.appSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: context.appBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: context.appBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _roundMapButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: context.appTextPrimary),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildWhereToCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: widget.deliveryPage
          ? () => _startDeliveryFlow(service: _selectedService)
          : () => _openDeliveryRoute(service: _selectedService),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.place_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: AppText(
                'Where should we deliver?',
                variant: AppTextVariant.heading3,
                fontWeight: FontWeight.bold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: context.appTextPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector({required bool compact}) {
    if (!compact) {
      return SizedBox(
        height: 154,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildVehicleShowcaseChoice('Bike')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildVehicleShowcaseChoice('Motor')),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: _buildVehicleChoice('Bike', compact: compact)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildVehicleChoice('Motor', compact: compact)),
      ],
    );
  }

  Widget _buildFoodDeliveryEntrySection() {
    return SizedBox(
      height: 306,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: _buildFoodDeliveryShowcaseCard(),
          ),
          PositionedDirectional(
            top: 210,
            start: 0,
            end: 0,
            child: _buildWhereToCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDeliveryShowcaseCard() {
    return Semantics(
      button: true,
      label: 'Food delivery',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            _selectedPackageType = 'Food/Groceries';
            _selectedService = 'food';
          });
          NavigationService().navigateToTab(2);
        },
        child: Container(
          height: 188,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage(ImageConstants.foodDeliveryReferenceBanner),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textWidth = constraints.maxWidth * 0.44;

              return Stack(
                children: [
                  PositionedDirectional(
                    top: 16,
                    start: 16,
                    width: textWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delivery_dining_rounded,
                                color: AppColors.primary,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              AppText(
                                'Fast & reliable',
                                variant: AppTextVariant.labelSmall,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w800,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const AppText(
                          'Food delivery',
                          variant: AppTextVariant.heading3,
                          color: Color(0xFF08233F),
                          fontWeight: FontWeight.w900,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const AppText(
                          'Your favorite meals,\ndelivered to your door.',
                          variant: AppTextVariant.bodySmall,
                          color: Color(0xFF667085),
                          fontWeight: FontWeight.w700,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    start: 16,
                    bottom: 16,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        end: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            'Order Food',
                            variant: AppTextVariant.button,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          SizedBox(width: 14),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleShowcaseChoice(String category) {
    final pricing = _deliveryPricing[category]!;
    final selected = _selectedVehicleCategory == category;
    final isMotor = category == 'Motor';
    final accent = isMotor ? AppColors.secondary : AppColors.primary;
    final backgroundPath = category == 'Bike'
        ? ImageConstants.vehicleBicycleCardBackground
        : ImageConstants.vehicleMotorbikeCardBackground;
    const titleColor = Color(0xFF08233F);
    const motorCover = Color(0xFFEAF8FF);
    const motorBorder = Color(0xFFAEE4FA);
    final borderColor = selected
        ? accent
        : (isMotor ? motorBorder : const Color(0xFFFFB6AA));

    return _buildVehicleTapPulse(
      category,
      Semantics(
        button: true,
        selected: selected,
        label: '${pricing.title} courier',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.deliveryPage) {
              _selectVehicleCategory(category);
            } else {
              _openDeliveryRoute(vehicleCategory: category);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isMotor ? motorCover : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(backgroundPath),
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: selected || isMotor ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: selected ? 0.18 : 0.09,
                          ),
                          blurRadius: selected ? 22 : 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          Colors.white.withValues(alpha: isMotor ? 0.18 : 0.30),
                          Colors.white.withValues(alpha: isMotor ? 0.04 : 0),
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 15,
                  start: 14,
                  end: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        pricing.title,
                        variant: AppTextVariant.bodyLarge,
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      _buildVehiclePriceLine(pricing, amountColor: accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehiclePriceLine(
    _DeliveryPricing pricing, {
    Color amountColor = AppColors.primary,
  }) {
    final parts = pricing.subtitle.split('/');
    final amount = parts.first;
    final suffix = parts.length > 1 ? '/${parts.sublist(1).join('/')}' : '';

    return AppText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: ' $suffix',
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      variant: AppTextVariant.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildVehicleChoice(String category, {required bool compact}) {
    final pricing = _deliveryPricing[category]!;
    final selected = _selectedVehicleCategory == category;
    final isMotor = category == 'Motor';
    const motorCover = Color(0xFFEAF8FF);
    const motorSelectedCover = Color(0xFFDDF4FF);
    const motorBorder = Color(0xFFAFE4FA);
    const motorForeground = Color(0xFF12324A);
    const motorSubtitle = Color(0xFF536C7C);
    final accent = isMotor ? AppColors.secondary : AppColors.primary;
    final foreground = isMotor
        ? motorForeground
        : selected
        ? Colors.white
        : context.appTextPrimary;
    final subtitleColor = isMotor
        ? motorSubtitle
        : selected
        ? Colors.white.withValues(alpha: 0.82)
        : context.appTextSecondary;

    return _buildVehicleTapPulse(
      category,
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectVehicleCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? (isMotor ? motorSelectedCover : accent)
                : (isMotor ? motorCover : context.appSurfaceAlt),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent
                  : (isMotor ? motorBorder : context.appBorder),
              width: isMotor ? 1.4 : 1,
            ),
            boxShadow: [
              if (selected || isMotor)
                BoxShadow(
                  color: accent.withValues(alpha: selected ? 0.18 : 0.08),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(pricing.icon, color: foreground, size: compact ? 22 : 30),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      pricing.title,
                      variant: AppTextVariant.bodyMedium,
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      pricing.subtitle,
                      variant: AppTextVariant.bodySmall,
                      color: subtitleColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTapPulse(String category, Widget child) {
    final pulseKey = _lastPulsedVehicleCategory == category
        ? _vehicleSelectionPulse
        : 0;

    return _SubtleVehicleCardMotion(
      category: category,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('vehicle-pulse-$category-$pulseKey'),
        tween: Tween<double>(begin: pulseKey == 0 ? 1 : 1.035, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: child,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPromoCard() {
    return _AnimatedDeliveryMapCard(
      onTap: widget.deliveryPage
          ? () => _startDeliveryFlow(service: _selectedService)
          : () => _openDeliveryRoute(service: _selectedService),
    );
  }

  Widget _buildUpcomingAdsSection() {
    final deals = _deals.isEmpty ? _fallbackDeals : _deals;
    final heroDeal = deals.firstWhere(
      (deal) => deal.isHero,
      orElse: () => deals.first,
    );
    final gridDeals = deals
        .where((deal) => deal.id != heroDeal.id)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Upcoming',
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HeroDealCard(deal: heroDeal, onTap: _openDealAction),
        if (gridDeals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.18,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            children: gridDeals
                .map(
                  (deal) => _DealGridAdCard(deal: deal, onTap: _openDealAction),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPickupSelector() {
    final hasPickup = _hasPickup;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasPickup
              ? AppColors.success.withValues(alpha: 0.35)
              : context.appBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trip_origin_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Pickup',
                      variant: AppTextVariant.labelLarge,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      _pickupSubtitle(),
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isResolvingPickup)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  hasPickup
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: hasPickup ? AppColors.success : AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            _pickupTitle(),
            variant: AppTextVariant.bodyMedium,
            fontWeight: FontWeight.w900,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PickupActionChip(
                icon: Icons.my_location_rounded,
                label: 'GPS',
                onTap: _isResolvingPickup
                    ? null
                    : () => unawaited(_useCurrentLocationForPickup()),
              ),
              _PickupActionChip(
                icon: Icons.travel_explore_rounded,
                label: 'Neighborhood',
                onTap: _isResolvingPickup
                    ? null
                    : () => unawaited(_choosePickupNeighborhood()),
              ),
              _PickupActionChip(
                icon: Icons.add_location_alt_rounded,
                label: 'Pin map',
                onTap: _isResolvingPickup
                    ? null
                    : () => unawaited(_pinPickupOnMap()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySummary() {
    final pricing = _selectedPricing;
    final price = _estimatedPrice;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.appTextPrimary),
              onPressed: _isRequestingAnotherDelivery
                  ? _discardDraftDelivery
                  : _cancelDeliveryRequest,
            ),
            Expanded(
              child: AppText(
                _destination?.displayName.split(',').first ?? 'Destination',
                variant: AppTextVariant.heading3,
                fontWeight: FontWeight.bold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Divider(color: context.appBorder),
        ListTile(
          leading: Icon(
            pricing.icon,
            color: _selectedVehicleCategory == 'Bike'
                ? AppColors.secondary
                : AppColors.primary,
            size: 32,
          ),
          title: AppText(
            '${pricing.title} delivery',
            variant: AppTextVariant.bodyMedium,
            fontWeight: FontWeight.bold,
          ),
          subtitle: AppText(
            '${_distanceLabel()} - ${pricing.baseFare} base + ${pricing.perKm} Birr/km',
            variant: AppTextVariant.bodySmall,
            color: context.appTextSecondary,
          ),
          trailing: AppText(
            price == null ? 'Estimating' : '$price ETB',
            variant: AppTextVariant.heading3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: AppText(
          title,
          variant: AppTextVariant.bodyMedium,
          fontWeight: FontWeight.bold,
        ),
        subtitle: AppText(
          subtitle,
          variant: AppTextVariant.bodySmall,
          color: context.appTextSecondary,
        ),
      ),
    );
  }
}

class _SubtleVehicleCardMotion extends StatefulWidget {
  const _SubtleVehicleCardMotion({required this.category, required this.child});

  final String category;
  final Widget child;

  @override
  State<_SubtleVehicleCardMotion> createState() =>
      _SubtleVehicleCardMotionState();
}

class _SubtleVehicleCardMotionState extends State<_SubtleVehicleCardMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _SubtleVehicleCardMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _controller
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: TickerMode.of(context),
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final accent = widget.category == 'Bike'
              ? AppColors.primary
              : AppColors.secondary;
          final phaseShift = widget.category == 'Bike' ? 0.0 : 0.48;
          final phase = (_controller.value + phaseShift) % 1.0;
          final activePhase = phase <= 0.42 ? phase / 0.42 : 1.0;
          final pulse = phase <= 0.42 ? math.sin(activePhase * math.pi) : 0.0;
          final scale = 1 + (pulse * 0.026);
          final lift = -5 * pulse;
          final glow = 0.07 + (pulse * 0.12);
          final sweepOffset = phase <= 0.42 ? (activePhase * 250) - 125 : 125.0;

          return Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: scale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: glow),
                      blurRadius: 20 + (pulse * 10),
                      spreadRadius: pulse * 0.8,
                      offset: Offset(0, 9 + (pulse * 4)),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    child!,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Opacity(
                            opacity: 0.05 + (pulse * 0.13),
                            child: Transform.translate(
                              offset: Offset(sweepOffset, 0),
                              child: Transform.rotate(
                                angle: -0.45,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.34),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewRouteOverlayPainter extends CustomPainter {
  const _PreviewRouteOverlayPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _deliveryPreviewOverlayPath(size);

    final routeShadow = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;
    final routeGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2387FF), Color(0xFF805BFF), Color(0xFFFF5B4D)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas
      ..drawPath(path, routeShadow)
      ..drawPath(path, routeGradient)
      ..drawPath(path, highlight);

    _paintPin(
      canvas,
      _deliveryPreviewOverlayPoint(size, 0),
      const Color(0xFF2387FF),
    );
    _paintPin(canvas, _deliveryPreviewOverlayPoint(size, 1), AppColors.primary);
  }

  void _paintPin(Canvas canvas, Offset center, Color color) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final shell = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(center + const Offset(0, 3), 30, shadow)
      ..drawCircle(center, 10, shell)
      ..drawCircle(center, 5, fill);
  }

  @override
  bool shouldRepaint(covariant _PreviewRouteOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HeroDealCard extends StatelessWidget {
  const _HeroDealCard({required this.deal, required this.onTap});

  final _HomeDeal deal;
  final ValueChanged<_HomeDeal> onTap;

  @override
  Widget build(BuildContext context) {
    final overlay = deal.overlayOpacity;
    return GestureDetector(
      onTap: deal.hasAction ? () => onTap(deal) : null,
      child: Container(
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: deal.accentColor.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _DealImage(
                deal: deal,
                fallbackAsset: ImageConstants.upcomingMotobikeDealsBackground,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Colors.black.withValues(
                        alpha: math.min(0.98, overlay + 0.14),
                      ),
                      Colors.black.withValues(alpha: overlay),
                      Colors.black.withValues(
                        alpha: math.max(0.10, overlay - 0.32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (deal.badgeText.isNotEmpty)
              PositionedDirectional(
                top: AppSpacing.md,
                end: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: deal.accentColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: AppText(
                    deal.badgeText,
                    variant: AppTextVariant.labelSmall,
                    color: deal.textColor,
                    fontWeight: FontWeight.w900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            PositionedDirectional(
              start: AppSpacing.lg,
              top: AppSpacing.lg,
              end: 118,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    deal.title,
                    variant: AppTextVariant.heading3,
                    color: deal.textColor,
                    fontWeight: FontWeight.w900,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    deal.subtitle.isNotEmpty ? deal.subtitle : deal.body,
                    variant: AppTextVariant.bodySmall,
                    color: deal.textColor.withValues(alpha: 0.86),
                    maxLines: deal.ctaLabel.isEmpty ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deal.ctaLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: deal.accentColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: AppText(
                        deal.ctaLabel,
                        variant: AppTextVariant.labelSmall,
                        color: deal.textColor,
                        fontWeight: FontWeight.w900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealGridAdCard extends StatelessWidget {
  const _DealGridAdCard({required this.deal, required this.onTap});

  final _HomeDeal deal;
  final ValueChanged<_HomeDeal> onTap;

  @override
  Widget build(BuildContext context) {
    final overlay = deal.overlayOpacity;
    return GestureDetector(
      onTap: deal.hasAction ? () => onTap(deal) : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: deal.accentColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _DealImage(
                deal: deal,
                fallbackAsset:
                    deal.fallbackAsset ?? ImageConstants.promoLaunchDeals,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: math.max(0.04, overlay - 0.40),
                      ),
                      Colors.black.withValues(alpha: math.max(0.24, overlay)),
                      Colors.black.withValues(
                        alpha: math.min(0.90, overlay + 0.26),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Container(
                width: 26,
                height: 4,
                decoration: BoxDecoration(
                  color: deal.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.sm,
              end: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    deal.title,
                    variant: AppTextVariant.bodyMedium,
                    color: deal.textColor,
                    fontWeight: FontWeight.w900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    deal.subtitle.isNotEmpty ? deal.subtitle : deal.body,
                    variant: AppTextVariant.bodySmall,
                    color: deal.textColor.withValues(alpha: 0.84),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealImage extends StatelessWidget {
  const _DealImage({required this.deal, required this.fallbackAsset});

  final _HomeDeal deal;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final imageUrl = deal.imageUrl.trim();
    final asset = deal.fallbackAsset ?? fallbackAsset;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(asset, fit: BoxFit.cover),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(asset, fit: BoxFit.cover),
      );
    }
    return Image.asset(asset, fit: BoxFit.cover);
  }
}

class _OfflineDeliveryPreviewMap extends StatelessWidget {
  const _OfflineDeliveryPreviewMap();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImageConstants.fastCityDeliveryMapBackground,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _OfflineDeliveryPreviewMapFallback(),
    );
  }
}

class _OfflineDeliveryPreviewMapFallback extends StatelessWidget {
  const _OfflineDeliveryPreviewMapFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF172635),
      child: CustomPaint(
        painter: _OfflineDeliveryPreviewMapPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _OfflineDeliveryPreviewMapPainter extends CustomPainter {
  const _OfflineDeliveryPreviewMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF203143), Color(0xFF121D29)],
        ).createShader(rect),
    );

    final blockPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final parkPaint = Paint()
      ..color = const Color(0xFF3CBF89).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final minorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;
    final roadEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    final roadPaint = Paint()
      ..color = const Color(0xFF8090A0).withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    final arterialEdgePaint = Paint()
      ..color = const Color(0xFFFFC46A).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15;
    final arterialPaint = Paint()
      ..color = const Color(0xFFECA84C).withValues(alpha: 0.64)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    _drawPolygon(canvas, size, parkPaint, const [
      Offset(0.05, 0.05),
      Offset(0.29, 0.02),
      Offset(0.35, 0.21),
      Offset(0.14, 0.26),
    ]);
    _drawPolygon(canvas, size, parkPaint, const [
      Offset(0.71, 0.62),
      Offset(0.98, 0.58),
      Offset(0.98, 0.92),
      Offset(0.76, 0.88),
    ]);

    for (final block in const [
      Rect.fromLTWH(0.07, 0.35, 0.18, 0.18),
      Rect.fromLTWH(0.30, 0.29, 0.14, 0.16),
      Rect.fromLTWH(0.51, 0.16, 0.18, 0.18),
      Rect.fromLTWH(0.75, 0.14, 0.16, 0.23),
      Rect.fromLTWH(0.10, 0.65, 0.22, 0.20),
      Rect.fromLTWH(0.42, 0.67, 0.17, 0.18),
      Rect.fromLTWH(0.61, 0.38, 0.14, 0.14),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            block.left * size.width,
            block.top * size.height,
            block.width * size.width,
            block.height * size.height,
          ),
          const Radius.circular(12),
        ),
        blockPaint,
      );
    }

    for (final y in const [0.18, 0.33, 0.48, 0.63, 0.78]) {
      _drawLine(
        canvas,
        size,
        Offset(-0.05, y),
        Offset(1.05, y + 0.08),
        minorRoadPaint,
      );
    }
    for (final x in const [0.16, 0.34, 0.56, 0.81]) {
      _drawLine(
        canvas,
        size,
        Offset(x, -0.05),
        Offset(x - 0.08, 1.05),
        minorRoadPaint,
      );
    }

    final arterial = Path()
      ..moveTo(-size.width * 0.05, size.height * 0.58)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.45,
        size.height * 0.45,
        size.width * 0.63,
        size.height * 0.53,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.59,
        size.width * 0.91,
        size.height * 0.57,
        size.width * 1.05,
        size.height * 0.44,
      );
    canvas
      ..drawPath(arterial, arterialEdgePaint)
      ..drawPath(arterial, arterialPaint);

    final ringRoad = Path()
      ..moveTo(size.width * 0.07, size.height * 0.86)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.64,
        size.width * 0.34,
        size.height * 0.54,
        size.width * 0.50,
        size.height * 0.49,
      )
      ..cubicTo(
        size.width * 0.67,
        size.height * 0.44,
        size.width * 0.83,
        size.height * 0.30,
        size.width * 0.95,
        size.height * 0.08,
      );
    canvas
      ..drawPath(ringRoad, roadEdgePaint)
      ..drawPath(ringRoad, roadPaint);

    _drawLine(
      canvas,
      size,
      const Offset(0.02, 0.12),
      const Offset(0.92, 0.92),
      roadPaint..strokeWidth = 4.5,
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    canvas.drawLine(
      Offset(start.dx * size.width, start.dy * size.height),
      Offset(end.dx * size.width, end.dy * size.height),
      paint,
    );
  }

  void _drawPolygon(
    Canvas canvas,
    Size size,
    Paint paint,
    List<Offset> points,
  ) {
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double _clampUnit(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

Path _deliveryPreviewOverlayPath(Size size) {
  return Path()
    ..moveTo(size.width * 0.34, size.height * 0.78)
    ..cubicTo(
      size.width * 0.46,
      size.height * 0.56,
      size.width * 0.58,
      size.height * 0.48,
      size.width * 0.70,
      size.height * 0.56,
    )
    ..cubicTo(
      size.width * 0.76,
      size.height * 0.60,
      size.width * 0.81,
      size.height * 0.62,
      size.width * 0.87,
      size.height * 0.56,
    );
}

Offset _deliveryPreviewOverlayPoint(Size size, double progress) {
  final metric = _deliveryPreviewOverlayPath(size).computeMetrics().first;
  final tangent = metric.getTangentForOffset(
    metric.length * _clampUnit(progress),
  );

  return tangent?.position ?? Offset(size.width * 0.34, size.height * 0.78);
}

class _AnimatedDeliveryMapCard extends StatefulWidget {
  const _AnimatedDeliveryMapCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AnimatedDeliveryMapCard> createState() =>
      _AnimatedDeliveryMapCardState();
}

class _AnimatedDeliveryMapCardState extends State<_AnimatedDeliveryMapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Animated delivery map preview',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 234,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF182431),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            child: const _OfflineDeliveryPreviewMap(),
            builder: (context, staticMap) {
              final sweepProgress = _controller.value <= 0.5
                  ? _controller.value * 2
                  : (1 - _controller.value) * 2;
              final progress = Curves.easeInOutCubic.transform(sweepProgress);
              final movingForward = _controller.value <= 0.5;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final bikeOffset = _deliveryPreviewOverlayPoint(
                    size,
                    progress,
                  );

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: staticMap ?? const SizedBox.shrink(),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.42),
                                Colors.black.withValues(alpha: 0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0B2341,
                            ).withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PreviewRouteOverlayPainter(
                              progress: progress,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: bikeOffset.dx - 39,
                        top: bikeOffset.dy - 31,
                        child: _buildPreviewBikeMarker(
                          movingForward: movingForward,
                        ),
                      ),
                      PositionedDirectional(
                        start: AppSpacing.xl,
                        top: 30,
                        end: AppSpacing.xl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Fast city ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'delivery',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                ],
                              ),
                              variant: AppTextVariant.heading3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            AppText(
                              'A live route preview from pickup\nto drop-off.',
                              variant: AppTextVariant.bodyMedium,
                              color: Colors.white.withValues(alpha: 0.84),
                              fontWeight: FontWeight.w700,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 42,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        end: AppSpacing.xl,
                        bottom: AppSpacing.xl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                'Request now',
                                variant: AppTextVariant.bodyMedium,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBikeMarker({required bool movingForward}) {
    return SizedBox(
      width: 78,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scaleX: movingForward ? 1 : -1,
            child: Image.asset(
              ImageConstants.bikeCourier,
              width: 76,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationChoiceOption<T> {
  const _LocationChoiceOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.caption,
  });

  final T value;
  final IconData icon;
  final String title;
  final String caption;
}

class _LocationChoiceSheet<T> extends StatelessWidget {
  const _LocationChoiceSheet({
    required this.accentColor,
    required this.heroIcon,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final Color accentColor;
  final IconData heroIcon;
  final String title;
  final String subtitle;
  final List<_LocationChoiceOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(heroIcon, color: accentColor, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        variant: AppTextVariant.heading3,
                        fontWeight: FontWeight.w900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        subtitle,
                        variant: AppTextVariant.bodySmall,
                        color: context.appTextSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                for (int index = 0; index < options.length; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _LocationChoiceTile<T>(
                      option: options[index],
                      accentColor: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChoiceTile<T> extends StatelessWidget {
  const _LocationChoiceTile({required this.option, required this.accentColor});

  final _LocationChoiceOption<T> option;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.alphaBlend(
        accentColor.withValues(alpha: context.isAppDark ? 0.18 : 0.08),
        context.appSurfaceAlt,
      ),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(option.value),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(option.icon, color: Colors.white, size: 21),
              ),
              const SizedBox(height: 6),
              AppText(
                option.title,
                variant: AppTextVariant.bodyMedium,
                fontWeight: FontWeight.w900,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              AppText(
                option.caption,
                variant: AppTextVariant.labelSmall,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupActionChip extends StatelessWidget {
  const _PickupActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: enabled ? AppColors.primary : context.appTextSecondary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: enabled ? context.appTextPrimary : context.appTextSecondary,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: context.appSurfaceAlt,
      side: BorderSide(color: context.appBorder),
      onPressed: onTap,
    );
  }
}

class _PinLocationScreen extends StatefulWidget {
  const _PinLocationScreen({
    required this.initialCenter,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.pinColor,
  });

  final LatLng initialCenter;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color pinColor;

  @override
  State<_PinLocationScreen> createState() => _PinLocationScreenState();
}

class _PinLocationScreenState extends State<_PinLocationScreen> {
  final MapController _controller = MapController();
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, _) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motobikedeliveryservice.client',
                maxNativeZoom: 19,
                keepBuffer: 5,
              ),
            ],
          ),
          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -26),
                child: Icon(
                  Icons.location_on_rounded,
                  color: widget.pinColor,
                  size: 52,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: context.appSurface,
                  shape: const CircleBorder(),
                  elevation: 8,
                  child: IconButton(
                    tooltip: 'Back',
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: context.appTextPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      widget.title,
                      variant: AppTextVariant.heading3,
                      fontWeight: FontWeight.w900,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      widget.subtitle,
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.primary(
                      label: widget.buttonLabel,
                      fullWidth: true,
                      icon: Icons.add_location_alt_rounded,
                      onPressed: () => Navigator.pop(context, _center),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
