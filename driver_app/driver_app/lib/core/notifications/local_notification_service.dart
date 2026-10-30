import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  Future<void>? _initializing;
  void Function(String? payload)? _onTap;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    if (onTap != null) _onTap = onTap;
    if (_initialized) return;
    final pending = _initializing;
    if (pending != null) {
      await pending;
      return;
    }
    final initialization = _initializePlugin();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializePlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _onTap?.call(response.payload);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showDriverAlert({
    required String id,
    required String title,
    required String body,
    String? payload,
    bool deliveryOffer = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const standardAndroid = AndroidNotificationDetails(
      'driver_delivery_alerts',
      'Driver delivery alerts',
      channelDescription: 'Delivery assignments and driver status updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
    );
    const offerAndroid = AndroidNotificationDetails(
      'driver_offer_chime_v3',
      'New delivery offers',
      channelDescription: 'Admin-style chime when a delivery is assigned',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('driver_offer'),
      enableVibration: false,
      category: AndroidNotificationCategory.message,
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: deliveryOffer ? 'driver_offer.wav' : null,
    );

    await _plugin.show(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: deliveryOffer ? offerAndroid : standardAndroid,
        iOS: ios,
      ),
      payload: payload,
    );
  }
}
