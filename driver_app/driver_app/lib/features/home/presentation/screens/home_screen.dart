import 'dart:async';
import 'dart:math' as math;

import 'package:driver_app/config/router/navigation_helper.dart';
import 'package:driver_app/core/map/addis_ababa_base_map.dart';
import 'package:driver_app/core/notifications/local_notification_service.dart';
import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:driver_app/core/widgets/slide_to_accept.dart';
import 'package:driver_app/features/profile/presentation/screens/driver_settings_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/wallet_screen.dart';
import 'package:driver_app/core/utils/constants/asset_constants/image_constants.dart';
import 'package:driver_app/features/auth/domain/entities/user_entity.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/home/data/repositories/map_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _locationDisclosureConsentKey =
      'driver_location_prominent_disclosure_consent_v1';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final MapRepository _mapRepository = MapRepository();
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverOperationsApi _operations = DriverOperationsApi();
  Position? _gpsFix;
  Timer? _offerTimer;
  Timer? _refreshTimer;
  String? _expiringDeliveryId;
  bool _refreshingGps = false;

  LatLng _currentPosition = const LatLng(8.9806, 38.7578);
  StreamSubscription<Position>? _positionStream;
  RealtimeChannel? _driverChannel;
  RealtimeChannel? _deliveriesChannel;
  RealtimeChannel? _notificationsChannel;
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  bool _isOnline = false;
  bool _isResolvingDriver = false;
  bool _isUpdating = false;
  Map<String, dynamic>? _driverRecord;
  Map<String, dynamic>? _activeDelivery;
  List<LatLng> _routePoints = [];
  String? _lastNotifiedDeliveryId;
  DateTime? _lastRouteRefreshAt;
  LatLng? _lastRouteStart;
  LatLng? _lastRouteDestination;
  bool _isRefreshingRoute = false;
  final Set<String> _ratingPromptedDeliveries = <String>{};
  final Set<String> _shownSystemNotificationIds = <String>{};
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeDelivery?['status'] != 'Assigned') return;
      setState(() {});
      if (_offerSecondsLeft == 0) unawaited(_expireOffer());
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_isOnline || !mounted) return;
      unawaited(_refreshOnlineState());
    });
    unawaited(
      _localNotifications.initialize(onTap: _handleSystemNotificationTap),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDriverRecord());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isOnline)
      unawaited(_refreshOnlineState());
  }

  Future<void> _refreshOnlineState() async {
    if (_refreshingGps) return;
    _refreshingGps = true;
    try {
      await _getCurrentLocation(updateRemote: true, moveMap: false);
      final id = _driverRecord?['id']?.toString();
      if (id != null && mounted && _isOnline) await _loadAssignedDelivery(id);
    } finally {
      _refreshingGps = false;
    }
  }

  int get _offerSecondsLeft {
    final delivery = _activeDelivery;
    if (delivery == null) return 0;
    final expiry =
        DateTime.tryParse(delivery['offer_expires_at']?.toString() ?? '') ??
        DateTime.tryParse(
          delivery['assigned_at']?.toString() ?? '',
        )?.add(const Duration(minutes: 2));
    if (expiry == null) return 0;
    return math.max(
      0,
      (expiry.difference(DateTime.now()).inMilliseconds / 1000).ceil(),
    );
  }

  Future<void> _expireOffer() async {
    final id = _activeDelivery?['id']?.toString();
    if (id == null || _expiringDeliveryId == id || _isUpdating) return;
    _expiringDeliveryId = id;
    try {
      await _operations.deliveryAction(id, 'expire');
      final driverId = _driverRecord?['id']?.toString();
      if (driverId != null && mounted) await _loadAssignedDelivery(driverId);
    } catch (error) {
      debugPrint('Offer expiry will retry: $error');
    } finally {
      _expiringDeliveryId = null;
    }
  }

  Future<bool> _ensureLocationAccess({bool showMessages = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showMessages && mounted) {
        AppToast.show(
          context: context,
          message: 'Turn on GPS to center the map on your location.',
          type: AppToastType.warning,
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final accepted = await _ensureLocationProminentDisclosure(
        beforePermissionRequest: true,
        showMessages: showMessages,
      );
      if (!accepted) return false;

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (showMessages && mounted) {
          AppToast.show(
            context: context,
            message: 'Location permission is needed for driver GPS.',
            type: AppToastType.warning,
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (showMessages && mounted) {
        AppToast.show(
          context: context,
          message: 'Enable location permission from device settings.',
          type: AppToastType.error,
        );
      }
      return false;
    }

    return _ensureLocationProminentDisclosure(
      beforePermissionRequest: false,
      showMessages: showMessages,
    );
  }

  Future<bool> _ensureLocationProminentDisclosure({
    required bool beforePermissionRequest,
    required bool showMessages,
  }) async {
    if (!beforePermissionRequest) {
      final prefs = await SharedPreferences.getInstance();
      final hasConsent = prefs.getBool(_locationDisclosureConsentKey) ?? false;
      if (hasConsent) return true;
    }

    final accepted = await _showLocationProminentDisclosure();
    if (!accepted) {
      if (showMessages && mounted) {
        AppToast.show(
          context: context,
          message: 'Location consent is needed to use driver GPS features.',
          type: AppToastType.warning,
        );
      }
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationDisclosureConsentKey, true);
    return true;
  }

  Future<bool> _showLocationProminentDisclosure() async {
    if (!mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: dialogContext.appSurface,
            icon: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Location use in MotoBike Driver'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MotoBike Driver collects your precise or approximate '
                    'location while you use the app and while you are Online, '
                    'including in the background or with the screen locked. '
                    'Sharing stops when you go Offline.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'We use this location to show your position on the map, '
                    'send your position to dispatch, assign nearby deliveries, '
                    'update delivery progress for customers and support, and '
                    'help with pickup and drop-off navigation.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Your location may be stored with your driver profile and '
                    'delivery records. Route coordinates may be sent to map or '
                    'routing providers to draw trip routes. We do not sell '
                    'location data or use it for ads.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'If you choose Not now, you can stay offline, but delivery '
                    'assignment and map location features will not work.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop(false);
                },
                child: const Text('Not now'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop(true);
                },
                child: const Text('Agree'),
              ),
            ],
          ),
        );
      },
    );

    return accepted ?? false;
  }

  Future<void> _getCurrentLocation({
    double zoom = 16,
    bool updateRemote = false,
    bool moveMap = true,
  }) async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _applyCurrentPosition(lastKnown, zoom: zoom, moveMap: moveMap);
      }
    } catch (e) {
      debugPrint('Last known GPS skipped: $e');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );
      if (!mounted) return;
      _applyCurrentPosition(position, zoom: zoom, moveMap: moveMap);
      if (updateRemote && _isOnline) {
        final driverId = _driverRecord?['id']?.toString();
        if (driverId != null) {
          await _updateDriverLocation(
            driverId,
            status: _isOnline ? 'Online' : 'Offline',
          );
        }
      }
    } catch (e) {
      debugPrint('GPS refresh skipped: $e');
    }
  }

  Future<void> _focusOnCurrentLocation() async {
    if (!await _ensureLocationAccess(showMessages: true)) return;

    try {
      _moveMapSafely(_currentPosition, 17.5);
      await _getCurrentLocation(zoom: 17.5, updateRemote: true);
    } catch (e) {
      debugPrint('Error focusing current location: $e');
    }
  }

  void _applyCurrentPosition(
    Position position, {
    required double zoom,
    required bool moveMap,
  }) {
    final next = LatLng(position.latitude, position.longitude);
    if (!_isValidMapPoint(next)) return;
    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(seconds: 90) ||
        age < const Duration(seconds: -10) ||
        !position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > 100)
      return;
    if (_gpsFix != null && position.timestamp.isBefore(_gpsFix!.timestamp))
      return;
    setState(() {
      _currentPosition = next;
      _gpsFix = position;
    });
    if (moveMap) _moveMapSafely(next, zoom);
  }

  bool _isValidMapPoint(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  double _safeMapZoom(double zoom, {double fallback = 15}) {
    final value = zoom.isFinite ? zoom : fallback;
    return value.clamp(3.0, 18.0).toDouble();
  }

  void _moveMapSafely(LatLng center, double zoom) {
    if (!mounted || !_isValidMapPoint(center)) return;
    try {
      _mapController.move(center, _safeMapZoom(zoom));
    } catch (e) {
      debugPrint('Driver map move skipped: $e');
    }
  }

  bool _hasUsableMapBounds(List<LatLng> points) {
    if (points.length < 2) return false;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return (maxLat - minLat).abs() > 0.00005 ||
        (maxLng - minLng).abs() > 0.00005;
  }

  void _fitMapSafely(
    List<LatLng> rawPoints, {
    EdgeInsets padding = const EdgeInsets.all(50),
    double fallbackZoom = 15,
  }) {
    if (!mounted) return;
    final points = rawPoints.where(_isValidMapPoint).toList(growable: false);
    if (points.isEmpty) return;
    if (!_hasUsableMapBounds(points)) {
      _moveMapSafely(points.first, fallbackZoom);
      return;
    }

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: padding,
        ),
      );
    } catch (e) {
      debugPrint('Driver map fit skipped: $e');
      _moveMapSafely(points.first, fallbackZoom);
    }
  }

  void _handleSystemNotificationTap(String? payload) {
    if (!mounted) return;
    context.navigator.pushNotificationScreen();
  }

  Future<Map<String, dynamic>?> _loadDriverRecord() async {
    if (_isResolvingDriver) return _driverRecord;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return null;

    setState(() => _isResolvingDriver = true);
    try {
      final record = await _findOrCreateDriver(authState.user);
      if (!mounted) return record;
      setState(() {
        _driverRecord = record;
        _isOnline =
            record?['status'] == 'Online' &&
            record?['is_active'] != false &&
            record?['approval_status'] == 'Approved';
      });
      if (record != null) {
        _subscribeToDriverRecord(record['id'].toString());
        await _loadUnreadNotificationCount();
        _subscribeToNotifications();
      }
      if (_isOnline && record != null) {
        final driverId = record['id'].toString();
        final hasLocationAccess = await _ensureLocationAccess(
          showMessages: true,
        );
        if (!mounted) return record;
        if (!hasLocationAccess) {
          await _setDriverOfflineWithoutLocation(driverId);
          return record;
        }
        await _getCurrentLocation();
        if (!mounted) return record;
        _startLocationStreaming(driverId);
        await _subscribeToAssignments(driverId);
      }
      return record;
    } catch (e) {
      debugPrint('Error loading driver record: $e');
      if (mounted) {
        AppToast.show(
          context: context,
          message: 'Could not load driver profile.',
          type: AppToastType.error,
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isResolvingDriver = false);
    }
  }

  Future<Map<String, dynamic>?> _findOrCreateDriver(UserEntity user) async {
    final byId = await _maybeDriverBy('id', user.id);
    if (byId != null) return byId;

    final phone = _driverPhone(user);
    final byPhone = await _maybeDriverBy('phone', phone);
    if (byPhone != null) return byPhone;

    final name = _driverName(user);
    final byName = await _maybeDriverBy('name', name);
    if (byName != null) return byName;

    throw Exception('Driver profile not found. Please sign in again.');
  }

  Future<Map<String, dynamic>?> _maybeDriverBy(
    String column,
    String value,
  ) async {
    if (value.trim().isEmpty) return null;
    try {
      final data = await _supabase
          .from('drivers')
          .select()
          .eq(column, value)
          .maybeSingle();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  String _driverName(UserEntity user) {
    final name = [
      user.firstName,
      user.lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    return name.isEmpty ? user.email : name;
  }

  String _driverPhone(UserEntity user) {
    final phone = user.phone?.trim() ?? '';
    return phone.isEmpty ? user.email : phone;
  }

  bool _canGoOnline(Map<String, dynamic> driver) {
    if (driver['is_active'] == false) {
      AppToast.show(
        context: context,
        message: 'Your driver account is inactive.',
        type: AppToastType.error,
      );
      return false;
    }
    return true;
  }

  void _subscribeToDriverRecord(String driverId) {
    _driverChannel?.unsubscribe();
    _driverChannel = _supabase
        .channel('public:drivers:home:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: driverId,
          ),
          callback: (payload) {
            final nextRecord = Map<String, dynamic>.from(payload.newRecord);
            if (!mounted) return;
            setState(() {
              _driverRecord = nextRecord;
              _isOnline =
                  nextRecord['status'] == 'Online' &&
                  nextRecord['is_active'] != false;
            });
            if (!_isOnline) unawaited(_positionStream?.cancel());
          },
        )
        .subscribe();
  }

  Future<void> _setDriverOfflineWithoutLocation(String driverId) async {
    await _positionStream?.cancel();
    await _deliveriesChannel?.unsubscribe();

    try {
      await _operations.update({'action': 'offline'});
    } catch (e) {
      debugPrint('Error setting driver offline after location denial: $e');
    }

    if (!mounted) return;
    final driver = _driverRecord;
    setState(() {
      _isOnline = false;
      _activeDelivery = null;
      _routePoints = [];
      if (driver != null) {
        _driverRecord = {...driver, 'status': 'Offline'};
      }
    });
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isUpdating) return;

    final driver = _driverRecord ?? await _loadDriverRecord();
    if (driver == null) return;
    if (!mounted) return;

    if (!_isOnline && !_canGoOnline(driver)) return;
    if (_isOnline && _activeDelivery != null) {
      AppToast.show(
        context: context,
        message: 'Finish the active delivery before going offline.',
        type: AppToastType.warning,
      );
      return;
    }

    if (!_isOnline) {
      final hasLocationAccess = await _ensureLocationAccess(showMessages: true);
      if (!mounted || !hasLocationAccess) return;
    }

    setState(() => _isUpdating = true);
    final driverId = driver['id'].toString();

    try {
      if (_isOnline) {
        await _operations.update({'action': 'offline'});
        await _positionStream?.cancel();
        await _deliveriesChannel?.unsubscribe();

        if (!mounted) return;
        setState(() {
          _isOnline = false;
          _activeDelivery = null;
          _routePoints = [];
          _driverRecord = {...driver, 'status': 'Offline'};
        });
      } else {
        await _getCurrentLocation();
        await _updateDriverLocation(driverId, status: 'Online');
        _startLocationStreaming(driverId);
        await _subscribeToAssignments(driverId);

        if (!mounted) return;
        setState(() {
          _isOnline = true;
          _driverRecord = {...driver, 'status': 'Online'};
        });
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
      if (mounted) {
        AppToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _startLocationStreaming(String driverId) {
    _positionStream?.cancel();
    final LocationSettings settings =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 5),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'MotoBike Driver is online',
              notificationText:
                  'Sharing your GPS with dispatch. Go offline to stop.',
              enableWakeLock: true,
            ),
          )
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            activityType: ActivityType.automotiveNavigation,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
            allowBackgroundLocationUpdates: true,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          );
    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) async {
            if (!mounted) return;
            _applyCurrentPosition(position, zoom: 16, moveMap: false);
            if (_gpsFix != position || !_isOnline) return;
            try {
              await _updateDriverLocation(driverId, status: 'Online');
            } catch (error) {
              debugPrint(
                'GPS upload failed; retaining original fix time: $error',
              );
            }
            if (_activeDelivery != null) {
              unawaited(_refreshActiveRoute());
            }
          },
          onError: (Object error) {
            debugPrint('GPS stream failed: $error');
          },
        );
  }

  Future<void> _updateDriverLocation(
    String driverId, {
    required String status,
  }) async {
    final fix = _gpsFix;
    if (fix == null ||
        DateTime.now().difference(fix.timestamp) >
            const Duration(seconds: 90)) {
      throw Exception(
        'Waiting for a fresh GPS fix. Enable precise location and try again.',
      );
    }
    await _operations.update({
      'action': 'location',
      'status': status,
      'lat': fix.latitude,
      'lng': fix.longitude,
      'accuracy': fix.accuracy,
      'heading': fix.heading,
      'speed': fix.speed,
      'observed_at': fix.timestamp.toUtc().toIso8601String(),
    });
  }

  Future<void> _subscribeToAssignments(String driverId) async {
    await _loadAssignedDelivery(driverId);
    await _deliveriesChannel?.unsubscribe();
    _deliveriesChannel = _supabase
        .channel('public:deliveries:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (_) => _loadAssignedDelivery(driverId),
        )
        .subscribe();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final driver = _driverRecord;
    if (driver == null) return;

    try {
      final data = await _supabase
          .from('app_notifications')
          .select('id, recipient_id, recipient_phone, read_at')
          .eq('app', 'driver')
          .order('created_at', ascending: false)
          .limit(100);

      final count = List<Map<String, dynamic>>.from(data)
          .where(_matchesDriverNotification)
          .where((notification) => notification['read_at'] == null)
          .length;

      if (!mounted) return;
      setState(() => _unreadNotificationCount = count);
    } catch (e) {
      debugPrint('Error loading driver notifications: $e');
    }
  }

  void _subscribeToNotifications() {
    _notificationsChannel?.unsubscribe();
    _notificationsChannel = _supabase
        .channel('public:app_notifications:driver-home')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'app',
            value: 'driver',
          ),
          callback: (payload) {
            _handleNotificationChange(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _handleNotificationChange(Map<String, dynamic> record) {
    final notification = Map<String, dynamic>.from(record);
    if (!_matchesDriverNotification(notification)) {
      unawaited(_loadUnreadNotificationCount());
      return;
    }

    final id = notification['id']?.toString();
    if (_driverRecord?['notifications_enabled'] != false &&
        notification['read_at'] == null &&
        id != null &&
        _shownSystemNotificationIds.add(id)) {
      unawaited(
        _localNotifications.showDriverAlert(
          id: id,
          title: notification['title']?.toString() ?? 'Driver alert',
          body: notification['body']?.toString() ?? '',
          payload: notification['delivery_id']?.toString() ?? id,
        ),
      );
    }

    unawaited(_loadUnreadNotificationCount());
  }

  bool _matchesDriverNotification(Map<String, dynamic> notification) {
    final driver = _driverRecord;
    if (driver == null) return false;

    final recipientId = notification['recipient_id']?.toString();
    final recipientPhone = _cleanRecipient(
      notification['recipient_phone']?.toString(),
    );
    final driverId = driver['id']?.toString();
    final driverPhone = _cleanRecipient(driver['phone']?.toString());

    if (recipientId == null && recipientPhone == null) return true;
    if (driverId != null && recipientId == driverId) return true;
    if (driverPhone != null && recipientPhone == driverPhone) return true;
    return false;
  }

  String? _cleanRecipient(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _loadAssignedDelivery(String driverId) async {
    try {
      final data = await _supabase
          .from('deliveries')
          .select()
          .eq('driver_id', driverId)
          .order('assigned_at', ascending: false)
          .limit(10);

      final deliveries = List<Map<String, dynamic>>.from(data);
      final active = deliveries.cast<Map<String, dynamic>?>().firstWhere(
        (delivery) =>
            delivery != null &&
            ['Assigned', 'Accepted', 'Picked Up'].contains(delivery['status']),
        orElse: () => null,
      );

      if (!mounted) return;
      await _setActiveDelivery(active);
    } catch (e) {
      debugPrint('Error loading assigned delivery: $e');
    }
  }

  Future<void> _setActiveDelivery(Map<String, dynamic>? delivery) async {
    if (delivery == null) {
      setState(() {
        _activeDelivery = null;
        _routePoints = [];
        _lastRouteStart = null;
        _lastRouteDestination = null;
        _lastRouteRefreshAt = null;
      });
      return;
    }

    final destination = _activeDestination(delivery);
    setState(() {
      _activeDelivery = delivery;
      if (destination != null) {
        _routePoints = <LatLng>[_currentPosition, destination];
      } else {
        _routePoints = [];
      }
    });

    final deliveryId = delivery['id']?.toString();
    if (deliveryId != null &&
        deliveryId != _lastNotifiedDeliveryId &&
        delivery['status'] == 'Assigned' &&
        mounted) {
      _lastNotifiedDeliveryId = deliveryId;
      if (_driverRecord?['notifications_enabled'] != false) {
        unawaited(
          _localNotifications.showDriverAlert(
            id: deliveryId,
            title: 'New delivery offer',
            body: 'Review the trip and slide to accept before it expires.',
            payload: deliveryId,
          ),
        );
      }
      AppToast.show(
        context: context,
        message: 'New delivery assigned. Check pickup details.',
        type: AppToastType.info,
      );
    }

    if (destination == null) return;
    unawaited(_refreshActiveRoute(fit: true, force: true));
  }

  LatLng? _activeDestination([Map<String, dynamic>? deliveryOverride]) {
    final delivery = deliveryOverride ?? _activeDelivery;
    if (delivery == null) return null;

    return delivery['status'] == 'Picked Up'
        ? _deliveryPoint(delivery, 'dropoff_lat', 'dropoff_lng')
        : _deliveryPoint(delivery, 'pickup_lat', 'pickup_lng');
  }

  List<LatLng> _visibleRoutePoints(Map<String, dynamic>? delivery) {
    if (_gpsFix == null) return const [];
    final routePoints = _routePoints
        .where(_isValidMapPoint)
        .toList(growable: false);
    if (routePoints.length >= 2) return routePoints;

    final destination = _activeDestination(delivery);
    if (destination == null || !_isValidMapPoint(_currentPosition)) {
      return const [];
    }

    return <LatLng>[_currentPosition, destination];
  }

  LatLng? _deliveryPoint(
    Map<String, dynamic> delivery,
    String latKey,
    String lngKey,
  ) {
    final lat = _asNullableDouble(delivery[latKey]);
    final lng = _asNullableDouble(delivery[lngKey]);
    if (lat == null || lng == null) return null;

    final point = LatLng(lat, lng);
    return _isValidMapPoint(point) ? point : null;
  }

  List<LatLng> _deliveryConnectorPoints(Map<String, dynamic>? delivery) {
    if (delivery == null) return const [];

    final pickup = _deliveryPoint(delivery, 'pickup_lat', 'pickup_lng');
    final dropoff = _deliveryPoint(delivery, 'dropoff_lat', 'dropoff_lng');
    if (pickup == null || dropoff == null) return const [];

    final points = <LatLng>[pickup, dropoff];
    return _hasUsableMapBounds(points) ? points : const [];
  }

  Future<void> _refreshActiveRoute({
    bool fit = false,
    bool force = false,
  }) async {
    if (_isRefreshingRoute || _gpsFix == null) return;

    final destination = _activeDestination();
    if (destination == null) return;

    final now = DateTime.now();
    final previousStart = _lastRouteStart;
    final previousDestination = _lastRouteDestination;
    final movedEnough =
        previousStart == null ||
        const Distance().as(
              LengthUnit.Meter,
              previousStart,
              _currentPosition,
            ) >=
            45;
    final destinationChanged =
        previousDestination == null ||
        const Distance().as(
              LengthUnit.Meter,
              previousDestination,
              destination,
            ) >=
            5;
    final cooledDown =
        _lastRouteRefreshAt == null ||
        now.difference(_lastRouteRefreshAt!) >= const Duration(seconds: 8);

    if (!force && !destinationChanged && (!movedEnough || !cooledDown)) {
      return;
    }

    _isRefreshingRoute = true;
    _lastRouteRefreshAt = now;
    _lastRouteStart = _currentPosition;
    _lastRouteDestination = destination;

    final fallback = <LatLng>[_currentPosition, destination];
    if (mounted && (_routePoints.isEmpty || force)) {
      setState(() => _routePoints = fallback);
    }

    try {
      final route = await _mapRepository.getRoute(
        _currentPosition,
        destination,
      );
      if (!mounted) return;
      setState(() {
        _routePoints = route.isEmpty ? fallback : route;
      });
      if (fit) {
        _fitMapSafely(
          [_currentPosition, destination],
          padding: const EdgeInsets.all(50),
          fallbackZoom: 15,
        );
      }
    } finally {
      _isRefreshingRoute = false;
    }
  }

  Future<void> _rejectDelivery() async {
    if (_isUpdating) return;
    final delivery = _activeDelivery;
    if (delivery == null) return;
    final deliveryId = delivery['id']?.toString();
    if (deliveryId == null) return;

    setState(() => _isUpdating = true);
    try {
      await _operations.deliveryAction(deliveryId, 'reject');

      if (!mounted) return;
      setState(() {
        _activeDelivery = null;
        _routePoints = [];
      });
      AppToast.show(
        context: context,
        message: 'Delivery returned to dispatch.',
        type: AppToastType.info,
      );
    } catch (e) {
      debugPrint('Error rejecting delivery: $e');
      if (mounted) {
        AppToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateDeliveryStatus(String status) async {
    if (_isUpdating) return;
    final delivery = _activeDelivery;
    final driver = _driverRecord;
    if (delivery == null || driver == null) return;
    final deliveryId = delivery['id']?.toString();
    final driverId = driver['id']?.toString();
    if (deliveryId == null || driverId == null) return;

    setState(() => _isUpdating = true);
    try {
      final action = status == 'Accepted'
          ? 'accept'
          : status == 'Picked Up'
          ? 'pickup'
          : 'complete';
      final updated = await _operations.deliveryAction(deliveryId, action);

      if (!mounted) return;
      if (status == 'Delivered') {
        final deliveredDelivery = Map<String, dynamic>.from({
          ...delivery,
          ...Map<String, dynamic>.from(updated),
        });
        setState(() {
          _activeDelivery = null;
          _routePoints = [];
        });
        AppToast.show(
          context: context,
          message: 'Delivery completed.',
          type: AppToastType.success,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDriverRatingPrompt(deliveredDelivery);
        });
      } else {
        await _setActiveDelivery(Map<String, dynamic>.from(updated));
        if (!mounted) return;
        AppToast.show(
          context: context,
          message: 'Status updated.',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      if (mounted) {
        AppToast.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showDriverRatingPrompt(
    Map<String, dynamic> delivery, {
    bool force = false,
  }) async {
    final deliveryId = delivery['id']?.toString();
    final driverId = _driverRecord?['id']?.toString();
    final clientId = delivery['client_id']?.toString();
    final customerPhone = delivery['customer_phone']?.toString();
    final rateeId = clientId?.trim().isNotEmpty == true
        ? clientId!.trim()
        : customerPhone?.trim();

    if (deliveryId == null || driverId == null || rateeId == null) return;
    if (!force && !_ratingPromptedDeliveries.add(deliveryId)) return;

    try {
      final existing = await _supabase
          .from('delivery_ratings')
          .select('rating')
          .eq('delivery_id', deliveryId)
          .eq('rater_type', 'driver')
          .eq('rater_id', driverId)
          .eq('ratee_type', 'client')
          .eq('ratee_id', rateeId)
          .maybeSingle();

      if (existing != null && !force) return;
      if (!mounted) return;

      final initialRating = existing == null
          ? 5
          : int.tryParse(existing['rating']?.toString() ?? '') ?? 5;
      final rating = await _showRatingSheet(
        title: 'Rate this customer',
        subtitle: delivery['customer_name']?.toString() ?? 'How was this trip?',
        initialRating: initialRating,
      );
      if (rating == null) return;

      await _supabase.from('delivery_ratings').upsert({
        'delivery_id': deliveryId,
        'rater_type': 'driver',
        'rater_id': driverId,
        'ratee_type': 'client',
        'ratee_id': rateeId,
        'rating': rating,
      }, onConflict: 'delivery_id,rater_type,rater_id,ratee_type,ratee_id');

      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Rating saved.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Error saving client rating: $e');
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
    var selectedRating = initialRating;
    if (selectedRating < 1) selectedRating = 1;
    if (selectedRating > 5) selectedRating = 5;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg + bottomInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Material(
                      color: dialogContext.appSurface,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppText(
                              title,
                              variant: AppTextVariant.heading3,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              subtitle,
                              variant: AppTextVariant.bodyMedium,
                              color: dialogContext.appTextSecondary,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                              onPressed: () => Navigator.of(
                                dialogContext,
                              ).pop(selectedRating),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: AppText(
                                'Skip',
                                variant: AppTextVariant.button,
                                color: dialogContext.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double? _asNullableDouble(Object? value) {
    if (value == null) return null;
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offerTimer?.cancel();
    _refreshTimer?.cancel();
    _positionStream?.cancel();
    _driverChannel?.unsubscribe();
    _deliveriesChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _activeDelivery;
    final visibleRoutePoints = _visibleRoutePoints(delivery);
    final deliveryConnectorPoints = _deliveryConnectorPoints(delivery);
    final pickupPoint = delivery == null
        ? null
        : _deliveryPoint(delivery, 'pickup_lat', 'pickup_lng');
    final dropoffPoint = delivery == null
        ? null
        : _deliveryPoint(delivery, 'dropoff_lat', 'dropoff_lng');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.appBackground,
      endDrawer: _buildHomeDrawer(),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              ...addisAbabaBaseMapLayers(
                userAgentPackageName: 'com.motobikedeliveryservice.driver',
              ),
              if (deliveryConnectorPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: deliveryConnectorPoints,
                      color: Colors.white.withValues(alpha: 0.92),
                      strokeWidth: 8,
                    ),
                    Polyline(
                      points: deliveryConnectorPoints,
                      color: AppColors.success.withValues(alpha: 0.9),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (visibleRoutePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: visibleRoutePoints,
                      color: Colors.white.withValues(alpha: 0.92),
                      strokeWidth: 10,
                    ),
                    Polyline(
                      points: visibleRoutePoints,
                      color: AppColors.primary,
                      strokeWidth: 6,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_gpsFix != null)
                    Marker(
                      point: _currentPosition,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
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
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.motorcycle_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (pickupPoint != null)
                    Marker(
                      point: pickupPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.success,
                        size: 36,
                      ),
                    ),
                  if (dropoffPoint != null)
                    Marker(
                      point: dropoffPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Menu',
                      icon: Icon(
                        Icons.menu_rounded,
                        color: context.appTextPrimary,
                      ),
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleOnlineStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppColors.success
                            : context.appSurface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: _isOnline
                              ? AppColors.success
                              : context.appBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? Colors.white
                                  : context.appTextSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppText(
                            _isOnline ? 'ONLINE' : 'OFFLINE',
                            variant: AppTextVariant.labelLarge,
                            color: _isOnline
                                ? Colors.white
                                : context.appTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildNotificationBell(),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            top: MediaQuery.viewPaddingOf(context).top + 86,
            child: Material(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(18),
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.20),
              child: InkWell(
                onTap: _focusOnCurrentLocation,
                borderRadius: BorderRadius.circular(18),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: context.appBorder)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.appBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (_isResolvingDriver) ...[
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AppText(
                              'Loading driver profile...',
                              variant: AppTextVariant.heading3,
                              fontWeight: FontWeight.bold,
                            ),
                          ] else if (!_isOnline) ...[
                            Icon(
                              Icons.power_settings_new_rounded,
                              size: 48,
                              color: context.appTextSecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const AppText(
                              'You are offline',
                              variant: AppTextVariant.heading3,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              'Go online to receive admin-assigned deliveries.',
                              variant: AppTextVariant.bodyMedium,
                              color: context.appTextSecondary,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppButton.primary(
                              label: 'GO ONLINE',
                              fullWidth: true,
                              isLoading: _isUpdating,
                              onPressed: _toggleOnlineStatus,
                            ),
                          ] else if (delivery == null) ...[
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const AppText(
                              'Waiting for assignments...',
                              variant: AppTextVariant.heading3,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              'Keep GPS enabled so dispatch can assign nearby deliveries.',
                              variant: AppTextVariant.bodyMedium,
                              color: context.appTextSecondary,
                              textAlign: TextAlign.center,
                            ),
                          ] else if (delivery['status'] == 'Assigned') ...[
                            _buildDeliveryHeader(
                              'New offer · ${_offerSecondsLeft}s',
                              delivery,
                            ),
                            Divider(color: context.appBorder),
                            _buildDeliveryLocation(
                              Icons.storefront_rounded,
                              'Pickup',
                              delivery['pickup_location']?.toString() ??
                                  'Pickup location',
                            ),
                            _buildDeliveryLocation(
                              Icons.flag_rounded,
                              'Dropoff',
                              delivery['dropoff_location']?.toString() ??
                                  'Dropoff location',
                            ),
                            _buildDeliveryDetails(delivery),
                            const SizedBox(height: AppSpacing.lg),
                            SlideToAccept(
                              key: ValueKey(delivery['id']),
                              enabled: !_isUpdating && _offerSecondsLeft > 0,
                              label: _offerSecondsLeft > 0
                                  ? 'Slide to accept'
                                  : 'Offer expired',
                              onAccept: () => _updateDeliveryStatus('Accepted'),
                            ),
                            TextButton(
                              onPressed: _isUpdating ? null : _rejectDelivery,
                              child: const Text('Decline offer'),
                            ),
                          ] else if (delivery['status'] == 'Accepted') ...[
                            _buildDeliveryHeader('Head to pickup', delivery),
                            _buildDeliveryLocation(
                              Icons.storefront_rounded,
                              'Pickup',
                              delivery['pickup_location']?.toString() ??
                                  'Pickup',
                            ),
                            _buildDeliveryDetails(delivery),
                            const SizedBox(height: AppSpacing.lg),
                            AppButton.primary(
                              label: 'CONFIRM PICKUP',
                              fullWidth: true,
                              isLoading: _isUpdating,
                              onPressed: () =>
                                  _updateDeliveryStatus('Picked Up'),
                            ),
                          ] else ...[
                            _buildDeliveryHeader('Deliver Package', delivery),
                            Divider(color: context.appBorder),
                            _buildDeliveryLocation(
                              Icons.flag_rounded,
                              'Dropoff',
                              delivery['dropoff_location']?.toString() ??
                                  'Dropoff location',
                            ),
                            _buildDeliveryDetails(delivery),
                            const SizedBox(height: AppSpacing.xl),
                            AppButton.primary(
                              label: 'MARK DELIVERED',
                              fullWidth: true,
                              isLoading: _isUpdating,
                              onPressed: () =>
                                  _updateDeliveryStatus('Delivered'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  Widget _buildHomeDrawer() {
    final name = _driverRecord?['name']?.toString() ?? 'Driver';
    final status = _driverRecord?['status']?.toString() ?? 'Offline';
    final vehicle = _driverRecord?['vehicle_type']?.toString() ?? 'Driver';

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            name,
                            variant: AppTextVariant.heading3,
                            fontWeight: FontWeight.w900,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            '$vehicle - $status',
                            variant: AppTextVariant.bodySmall,
                            color: status == 'Online'
                                ? AppColors.success
                                : context.appTextSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
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
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      onTap: () => _closeDrawerThen(
                        context.navigator.pushNotificationScreen,
                      ),
                    ),
                    _drawerTile(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      onTap: () =>
                          _closeDrawerThen(context.navigator.pushProfileScreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Divider(color: context.appBorder),
                    ),
                    _drawerTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Wallet',
                      onTap: () => _closeDrawerThen(
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WalletScreen(),
                          ),
                        ),
                      ),
                    ),
                    _drawerTile(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => _closeDrawerThen(
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DriverSettingsScreen(),
                          ),
                        ),
                      ),
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

  Widget _buildNotificationBell() {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(
              Icons.notifications_rounded,
              color: context.appTextPrimary,
            ),
            onPressed: () {
              context.navigator.pushNotificationScreen();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _loadUnreadNotificationCount();
              });
            },
          ),
          if (_unreadNotificationCount > 0)
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: context.appSurface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadNotificationCount > 9
                      ? '9+'
                      : _unreadNotificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
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

  Future<void> _callPhone(String? phone) async {
    final cleaned = phone?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      AppToast.show(
        context: context,
        message: 'No phone number is available for this delivery.',
        type: AppToastType.warning,
      );
      return;
    }

    final opened = await launchUrl(
      Uri(scheme: 'tel', path: cleaned),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      AppToast.show(
        context: context,
        message: 'Could not open the phone dialer.',
        type: AppToastType.error,
      );
    }
  }

  String? _deliveryPhone(Map<String, dynamic> delivery) {
    for (final key in const [
      'customer_phone',
      'recipient_phone',
      'dropoff_phone',
      'pickup_phone',
      'seller_phone',
      'phone',
    ]) {
      final value = delivery[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String _deliveryCustomerName(Map<String, dynamic> delivery) {
    for (final key in const [
      'customer_name',
      'recipient_name',
      'seller_name',
    ]) {
      final value = delivery[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return 'Customer';
  }

  Widget _buildDeliveryHeader(String title, Map<String, dynamic> delivery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: AppText(
            title,
            variant: AppTextVariant.heading3,
            fontWeight: FontWeight.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppText(
          _feeLabel(delivery['driver_earnings'] ?? delivery['delivery_fee']),
          variant: AppTextVariant.heading2,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  Widget _buildDeliveryDetails(Map<String, dynamic> delivery) {
    final phone = _deliveryPhone(delivery);
    final packageType = delivery['package_type']?.toString().trim();
    final vehicle = delivery['vehicle_category']?.toString().trim();
    final pickup = _deliveryPoint(delivery, 'pickup_lat', 'pickup_lng');
    final dropoff = _deliveryPoint(delivery, 'dropoff_lat', 'dropoff_lng');
    final freshGps =
        _gpsFix != null &&
        DateTime.now().difference(_gpsFix!.timestamp) <
            const Duration(seconds: 90);
    final pickupKm = pickup == null || !freshGps
        ? null
        : const Distance().as(LengthUnit.Kilometer, _currentPosition, pickup);
    final tripKm = pickup == null || dropoff == null
        ? null
        : const Distance().as(LengthUnit.Kilometer, pickup, dropoff);
    final radius = _asNullableDouble(_driverRecord?['working_radius_km']) ?? 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          _buildCompactDetailRow(
            Icons.payments_outlined,
            'Your net',
            _feeLabel(delivery['driver_earnings'] ?? delivery['delivery_fee']),
          ),
          _buildCompactDetailRow(
            Icons.receipt_long_outlined,
            'Fare',
            _feeLabel(delivery['delivery_fee']),
          ),
          _buildCompactDetailRow(
            Icons.percent,
            'Owner fee',
            '${delivery['commission_percent'] ?? '--'}% · ${_feeLabel(delivery['owner_commission'])}',
          ),
          _buildCompactDetailRow(
            Icons.account_balance_wallet_outlined,
            'Collect',
            delivery['fee_collection_method'] == 'platform'
                ? 'Business collects · net paid to wallet'
                : 'Collect cash · fee deducted from credit',
          ),
          _buildCompactDetailRow(
            Icons.near_me_outlined,
            'Pickup',
            pickupKm == null
                ? 'Distance unavailable · waiting for GPS'
                : '${pickupKm.toStringAsFixed(1)} km away (straight line)',
          ),
          _buildCompactDetailRow(
            Icons.route_outlined,
            'Trip',
            tripKm == null
                ? 'Distance unavailable'
                : '${tripKm.toStringAsFixed(1)} km (straight-line estimate)',
          ),
          if (pickupKm != null && pickupKm > radius)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Outside your ${radius.toStringAsFixed(0)} km working radius. Review the pickup before accepting.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _buildCompactDetailRow(
            Icons.person_rounded,
            'Customer',
            _deliveryCustomerName(delivery),
          ),
          if (phone != null)
            _buildCompactDetailRow(
              Icons.phone_rounded,
              'Phone',
              phone,
              onTap: () => _callPhone(phone),
              trailing: const Icon(
                Icons.call_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
          if (packageType != null && packageType.isNotEmpty)
            _buildCompactDetailRow(
              Icons.inventory_2_rounded,
              'Package',
              packageType,
            ),
          if (vehicle != null && vehicle.isNotEmpty)
            _buildCompactDetailRow(
              Icons.two_wheeler_rounded,
              'Vehicle',
              vehicle,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: context.appTextSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 72,
            child: AppText(
              label,
              variant: AppTextVariant.labelSmall,
              color: context.appTextSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: AppText(
              value,
              variant: AppTextVariant.bodySmall,
              color: context.appTextPrimary,
              fontWeight: FontWeight.w900,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing,
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: child,
    );
  }

  Widget _buildDeliveryLocation(
    IconData icon,
    String title,
    String subtitle, {
    bool compact = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? AppSpacing.xs : AppSpacing.sm),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : AppSpacing.sm,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: title == 'Pickup' ? AppColors.success : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.labelLarge,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: 2),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodyMedium,
                  color: context.appTextSecondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _feeLabel(Object? value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (amount == null) return '-- ETB';
    return '${amount.toStringAsFixed(2)} ETB';
  }
}
