import 'dart:async';

import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/core/map/addis_ababa_base_map.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.deliveryId});

  final String? deliveryId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const double _bottomNavClearance = 132;
  static const String _deliverySelect =
      '*, driver:drivers(id, name, phone, vehicle_type, current_lat, current_lng)';

  Map<String, dynamic>? _trackedDelivery;
  Map<String, dynamic>? _lastDelivery;
  RealtimeChannel? _deliveryChannel;
  RealtimeChannel? _driverChannel;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTracking());
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryId != widget.deliveryId) {
      unawaited(_loadTracking());
    }
  }

  @override
  void dispose() {
    _deliveryChannel?.unsubscribe();
    _driverChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedId = widget.deliveryId?.trim();
      Map<String, dynamic>? selectedDelivery;

      if (selectedId != null && selectedId.isNotEmpty) {
        selectedDelivery = await _fetchDeliveryById(selectedId);
      }

      final deliveries = await _fetchUserDeliveries();
      final activeDelivery = _firstActiveDelivery(deliveries);
      final lastDelivery = deliveries.isNotEmpty ? deliveries.first : null;
      final tracked = selectedDelivery ?? activeDelivery;

      if (!mounted) return;
      setState(() {
        _trackedDelivery = tracked;
        _lastDelivery = selectedDelivery ?? lastDelivery;
        _isLoading = false;
      });
      _subscribeToTrackedDelivery(tracked?['id']?.toString());
      final trackedDriver = tracked == null ? null : _driverFor(tracked);
      _subscribeToAssignedDriver(trackedDriver?['id']);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load delivery tracking.';
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchDeliveryById(String id) async {
    final data = await Supabase.instance.client
        .from('deliveries')
        .select(_deliverySelect)
        .eq('id', id)
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(data);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> _fetchUserDeliveries() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final clientId = user?.id;
    final phone = user?.phone?.trim().isNotEmpty == true
        ? user!.phone!.trim()
        : user?.email.trim() ?? '';

    if ((clientId == null || clientId.isEmpty) && phone.isEmpty) {
      return const [];
    }

    final supabase = Supabase.instance.client;
    if (clientId != null && clientId.isNotEmpty) {
      final data = await supabase
          .from('deliveries')
          .select(_deliverySelect)
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(25);
      final rows = List<Map<String, dynamic>>.from(data);
      if (rows.isNotEmpty) return rows;
    }

    if (phone.isEmpty) return const [];

    final data = await supabase
        .from('deliveries')
        .select(_deliverySelect)
        .eq('customer_phone', phone)
        .order('created_at', ascending: false)
        .limit(25);
    return List<Map<String, dynamic>>.from(data);
  }

  void _subscribeToTrackedDelivery(String? deliveryId) {
    _deliveryChannel?.unsubscribe();
    if (deliveryId == null || deliveryId.isEmpty) return;

    _deliveryChannel = Supabase.instance.client
        .channel('public:deliveries:tracking:$deliveryId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: deliveryId,
          ),
          callback: (_) => _refreshTrackedDelivery(deliveryId),
        )
        .subscribe();
  }

  Future<void> _refreshTrackedDelivery(String deliveryId) async {
    final delivery = await _fetchDeliveryById(deliveryId);
    if (!mounted || delivery == null) return;
    setState(() {
      _trackedDelivery = delivery;
      _lastDelivery = delivery;
    });
    _subscribeToAssignedDriver(_driverFor(delivery)?['id']);
  }

  void _subscribeToAssignedDriver(Object? driverIdValue) {
    _driverChannel?.unsubscribe();
    final driverId = driverIdValue?.toString();
    if (driverId == null || driverId.isEmpty) return;

    _driverChannel = Supabase.instance.client
        .channel('public:drivers:tracking:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'drivers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: driverId,
          ),
          callback: _handleDriverUpdate,
        )
        .subscribe();
  }

  void _handleDriverUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    final tracked = _trackedDelivery;
    if (tracked == null) return;

    final currentDriver = _driverFor(tracked);
    final nextDriverId =
        payload.newRecord['id']?.toString() ?? currentDriver?['id']?.toString();
    if (nextDriverId == null ||
        currentDriver?['id']?.toString() != nextDriverId) {
      return;
    }

    final updatedDelivery = {
      ...tracked,
      'driver': {...?currentDriver, ...payload.newRecord},
    };

    setState(() {
      _trackedDelivery = updatedDelivery;
      _lastDelivery = updatedDelivery;
    });
  }

  Map<String, dynamic>? _firstActiveDelivery(
    List<Map<String, dynamic>> deliveries,
  ) {
    for (final delivery in deliveries) {
      if (_isActiveStatus(delivery['status']?.toString())) return delivery;
    }
    return null;
  }

  bool _isActiveStatus(String? status) {
    return status == 'Pending' || status == 'Assigned' || status == 'Picked Up';
  }

  bool _canCancelDelivery(Map<String, dynamic> delivery) {
    final status = delivery['status']?.toString();
    return status == 'Pending' || status == 'Assigned';
  }

  Future<void> _cancelTrackedDelivery(Map<String, dynamic> delivery) async {
    final deliveryId = delivery['id']?.toString();
    if (deliveryId == null ||
        deliveryId.isEmpty ||
        !_canCancelDelivery(delivery)) {
      return;
    }

    final confirmed = await AppModal.confirm(
      context: context,
      title: 'Cancel delivery?',
      contentText: 'This order will be cancelled before pickup.',
      confirmLabel: 'Cancel delivery',
      cancelLabel: 'Keep order',
      icon: Icons.cancel_outlined,
    );
    if (confirmed != true || !mounted) return;

    try {
      final data = await Supabase.instance.client
          .from('deliveries')
          .update({
            'status': 'Cancelled',
            'driver_id': null,
            'assigned_at': null,
            'cancelled_by': 'customer',
            'cancellation_reason': 'Cancelled from client app',
          })
          .eq('id', deliveryId)
          .inFilter('status', const ['Pending', 'Assigned'])
          .select(_deliverySelect);

      final rows = List<Map<String, dynamic>>.from(data);
      if (!mounted) return;
      if (rows.isEmpty) {
        await _refreshTrackedDelivery(deliveryId);
        if (!mounted) return;
        AppToast.show(
          context: context,
          message: 'This delivery can no longer be cancelled.',
          type: AppToastType.error,
        );
        return;
      }

      setState(() {
        _trackedDelivery = rows.first;
        _lastDelivery = rows.first;
      });
      _subscribeToAssignedDriver(null);
      AppToast.show(
        context: context,
        message: 'Delivery cancelled.',
        type: AppToastType.success,
      );
    } catch (e) {
      debugPrint('Cancel tracked delivery error: $e');
      if (!mounted) return;
      AppToast.show(
        context: context,
        message: 'Could not cancel this delivery.',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackedDelivery = _trackedDelivery;
    final lastDelivery = _lastDelivery;
    final hasCurrent =
        trackedDelivery != null &&
        _isActiveStatus(trackedDelivery['status']?.toString());
    final displayDelivery = trackedDelivery ?? lastDelivery;
    final mapHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(390.0, 560.0)
        .toDouble();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        centerTitle: true,
        title: const AppText(
          'Live Tracking',
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appTextPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              NavigationService().navigateToTab(1);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadTracking,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  _bottomNavClearance,
                ),
                children: [
                  if (_errorMessage != null) ...[
                    _buildNoticeCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Tracking unavailable',
                      message: _errorMessage!,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (!hasCurrent)
                    _buildNoticeCard(
                      icon: Icons.route_rounded,
                      title: 'No current delivery right now',
                      message: displayDelivery == null
                          ? 'When you request a delivery, live tracking will appear here.'
                          : 'There is no active delivery. Your latest delivery is shown below.',
                      color: AppColors.info,
                    ),
                  if (!hasCurrent) const SizedBox(height: AppSpacing.md),
                  if (displayDelivery == null)
                    const SizedBox(height: 420)
                  else ...[
                    _buildMapCard(displayDelivery, height: mapHeight),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatusCard(displayDelivery, hasCurrent: hasCurrent),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTimelineCard(displayDelivery),
                    const SizedBox(height: AppSpacing.md),
                    _buildDetailsCard(displayDelivery),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNoticeCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.bodyMedium,
                  fontWeight: FontWeight.w900,
                  color: context.appTextPrimary,
                ),
                const SizedBox(height: 3),
                AppText(
                  message,
                  variant: AppTextVariant.bodySmall,
                  color: context.appTextSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    Map<String, dynamic> delivery, {
    required bool hasCurrent,
  }) {
    final status = delivery['status']?.toString() ?? 'Pending';
    final statusColor = _statusColor(status);
    final title = hasCurrent ? _currentStatusTitle(status) : 'Last tracked';
    final subtitle = hasCurrent
        ? _currentStatusSubtitle(status, delivery)
        : _statusSubtitle(status);
    final dropoff = delivery['dropoff_location']?.toString() ?? 'Not set';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(status), color: statusColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w900,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppText(
                  status,
                  variant: AppTextVariant.labelSmall,
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatusMeta(
                  icon: Icons.schedule_rounded,
                  label: 'Updated',
                  value: _dateTimeLabel(_lastTrackingTime(delivery)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatusMeta(
                  icon: Icons.location_on_rounded,
                  label: 'Drop-off',
                  value: dropoff,
                ),
              ),
            ],
          ),
          if (_canCancelDelivery(delivery)) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton.outlinedDanger(
              label: 'CANCEL DELIVERY',
              icon: Icons.cancel_outlined,
              fullWidth: true,
              onPressed: () => unawaited(_cancelTrackedDelivery(delivery)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCard(
    Map<String, dynamic> delivery, {
    required double height,
  }) {
    final status = delivery['status']?.toString() ?? 'Pending';
    final pickup = _latLngFromFields(
      delivery['pickup_lat'],
      delivery['pickup_lng'],
    );
    final dropoff = _latLngFromFields(
      delivery['dropoff_lat'],
      delivery['dropoff_lng'],
    );
    final driver = _driverFor(delivery);
    final driverPoint = _latLngFromFields(
      driver?['current_lat'],
      driver?['current_lng'],
    );
    final routePoints = _trackingRoutePoints(
      status: status,
      pickup: pickup,
      dropoff: dropoff,
      driverPoint: driverPoint,
    );
    final center = routePoints.length >= 2
        ? _centerOf(routePoints)
        : driverPoint ?? pickup ?? dropoff ?? const LatLng(8.9806, 38.7578);
    final markers = <Marker>[
      if (pickup != null)
        _buildMapMarker(
          point: pickup,
          icon: Icons.my_location_rounded,
          color: AppColors.primary,
        ),
      if (dropoff != null)
        _buildMapMarker(
          point: dropoff,
          icon: Icons.location_on_rounded,
          color: AppColors.error,
        ),
      if (driverPoint != null)
        _buildMapMarker(
          point: driverPoint,
          icon: _vehicleIconFor(driver?['vehicle_type']),
          color: AppColors.success,
        ),
    ];

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: routePoints.length >= 2 ? 12.2 : 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              ...addisAbabaBaseMapLayers(
                userAgentPackageName: 'com.motobikedeliveryservice.client',
              ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.white.withValues(alpha: 0.92),
                      strokeWidth: 9,
                    ),
                    Polyline(
                      points: routePoints,
                      color: AppColors.success,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          if (markers.isEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.appSurfaceAlt),
                child: Center(
                  child: AppText(
                    'Map location is not available for this delivery.',
                    variant: AppTextVariant.bodyMedium,
                    color: context.appTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            start: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.appSurface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AppText(
                status,
                variant: AppTextVariant.labelSmall,
                color: _statusColor(status),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.appSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appBorder),
              ),
              child: AppText(
                driverPoint == null ? 'Driver GPS pending' : 'Driver GPS live',
                variant: AppTextVariant.labelSmall,
                color: driverPoint == null
                    ? context.appTextSecondary
                    : AppColors.success,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> _trackingRoutePoints({
    required String status,
    required LatLng? pickup,
    required LatLng? dropoff,
    required LatLng? driverPoint,
  }) {
    if (status == 'Picked Up' && driverPoint != null && dropoff != null) {
      return [driverPoint, dropoff];
    }
    if (status == 'Assigned' && driverPoint != null && pickup != null) {
      return [driverPoint, pickup];
    }
    if (pickup != null && dropoff != null) return [pickup, dropoff];
    if (driverPoint != null && dropoff != null) return [driverPoint, dropoff];
    if (driverPoint != null && pickup != null) return [driverPoint, pickup];
    return const [];
  }

  LatLng _centerOf(List<LatLng> points) {
    final total = points.fold(
      const LatLng(0, 0),
      (sum, point) => LatLng(
        sum.latitude + point.latitude,
        sum.longitude + point.longitude,
      ),
    );
    return LatLng(
      total.latitude / points.length,
      total.longitude / points.length,
    );
  }

  Marker _buildMapMarker({
    required LatLng point,
    required IconData icon,
    required Color color,
  }) {
    return Marker(
      point: point,
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> delivery) {
    final status = delivery['status']?.toString() ?? 'Pending';
    const steps = ['Pending', 'Assigned', 'Picked Up', 'Delivered'];
    final currentIndex = steps.indexOf(status);
    final isCancelled = status == 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
      ),
      child: isCancelled
          ? const Row(
              children: [
                Icon(Icons.cancel_rounded, color: AppColors.error, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    'Cancelled',
                    variant: AppTextVariant.bodyMedium,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            )
          : Row(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;
                return Expanded(
                  child: _buildTimelineStep(
                    title: title,
                    complete: currentIndex >= index,
                    active: currentIndex == index,
                    color: _statusColor(title),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required bool complete,
    required bool active,
    required Color color,
  }) {
    final stepColor = complete ? color : context.appBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: complete ? stepColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 2),
          ),
          child: complete
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
              : null,
        ),
        const SizedBox(height: 6),
        AppText(
          title,
          variant: AppTextVariant.labelSmall,
          fontWeight: active ? FontWeight.w900 : FontWeight.w700,
          color: active ? color : context.appTextSecondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Map<String, dynamic> delivery) {
    final driver = _driverFor(delivery);
    final fee = _feeLabel(delivery['delivery_fee']);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Delivery details',
            variant: AppTextVariant.heading3,
            fontWeight: FontWeight.w900,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            icon: Icons.inventory_2_rounded,
            label: 'Package',
            value: delivery['package_type']?.toString() ?? 'Package',
          ),
          _buildDetailRow(
            icon: Icons.two_wheeler_rounded,
            label: 'Vehicle',
            value:
                delivery['vehicle_category']?.toString() ??
                driver?['vehicle_type']?.toString() ??
                'Not selected',
          ),
          _buildDetailRow(
            icon: Icons.payments_rounded,
            label: 'Estimate',
            value: fee,
          ),
          _buildDetailRow(
            icon: Icons.my_location_rounded,
            label: 'Pickup',
            value: delivery['pickup_location']?.toString() ?? 'Pickup',
          ),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: 'Drop-off',
            value: delivery['dropoff_location']?.toString() ?? 'Dropoff',
          ),
          _buildDetailRow(
            icon: Icons.person_rounded,
            label: 'Courier',
            value: driver?['name']?.toString() ?? 'Not assigned yet',
          ),
          _buildDetailRow(
            icon: Icons.phone_rounded,
            label: 'Courier phone',
            value: driver?['phone']?.toString() ?? 'Unavailable',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMeta({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.appTextSecondary, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  label,
                  variant: AppTextVariant.labelSmall,
                  color: context.appTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  value,
                  variant: AppTextVariant.labelSmall,
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w800,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  variant: AppTextVariant.labelSmall,
                  color: context.appTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 2),
                AppText(
                  value,
                  variant: AppTextVariant.bodyMedium,
                  fontWeight: FontWeight.w700,
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

  Map<String, dynamic>? _driverFor(Map<String, dynamic> delivery) {
    final driver = delivery['driver'];
    if (driver is! Map) return null;
    return Map<String, dynamic>.from(driver);
  }

  LatLng? _latLngFromFields(Object? lat, Object? lng) {
    final latitude = _asNullableDouble(lat);
    final longitude = _asNullableDouble(lng);
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  double? _asNullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _feeLabel(Object? value) {
    final amount = _asNullableDouble(value);
    if (amount == null) return '-- ETB';
    return '${amount.toStringAsFixed(0)} ETB';
  }

  DateTime? _lastTrackingTime(Map<String, dynamic> delivery) {
    const keys = [
      'last_tracked_at',
      'last_tracked',
      'driver_location_updated_at',
      'updated_at',
      'picked_up_at',
      'assigned_at',
      'created_at',
    ];
    for (final key in keys) {
      final parsed = _parseDateTime(delivery[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _dateTimeLabel(DateTime? value) {
    if (value == null) return 'Not available';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  String _currentStatusTitle(String status) {
    switch (status) {
      case 'Pending':
        return 'Waiting for dispatch';
      case 'Assigned':
        return 'Courier assigned';
      case 'Picked Up':
        return 'Delivery in progress';
      default:
        return status;
    }
  }

  String _currentStatusSubtitle(String status, Map<String, dynamic> delivery) {
    final driver = _driverFor(delivery);
    switch (status) {
      case 'Pending':
        return 'Your request is waiting for admin dispatch.';
      case 'Assigned':
        return driver == null
            ? 'A courier has been assigned.'
            : '${driver['name'] ?? 'Courier'} is preparing to pick up.';
      case 'Picked Up':
        return 'Your package is on the way to the drop-off location.';
      default:
        return _statusSubtitle(status);
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'Pending':
        return 'Request received and waiting for dispatch.';
      case 'Assigned':
        return 'Courier assigned and pickup is next.';
      case 'Picked Up':
        return 'Package picked up and moving to destination.';
      case 'Delivered':
        return 'Delivery completed.';
      case 'Cancelled':
        return 'Delivery cancelled.';
      default:
        return 'Status updated.';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      case 'Picked Up':
        return AppColors.info;
      case 'Assigned':
        return AppColors.warning;
      case 'Pending':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      case 'Picked Up':
        return Icons.delivery_dining_rounded;
      case 'Assigned':
        return Icons.motorcycle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  IconData _vehicleIconFor(Object? vehicleType) {
    final type = vehicleType?.toString().toLowerCase() ?? '';
    if (type.contains('bike') || type.contains('bicycle')) {
      return Icons.directions_bike_rounded;
    }
    return Icons.motorcycle_rounded;
  }
}
