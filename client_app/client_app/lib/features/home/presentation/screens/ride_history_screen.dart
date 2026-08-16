import 'package:client_app/config/router/app_routes.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _DeliveryHistoryPeriod { day, week, month }

class _DeliveryHistoryWindow {
  const _DeliveryHistoryWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

extension _DeliveryHistoryPeriodDetails on _DeliveryHistoryPeriod {
  String get label {
    switch (this) {
      case _DeliveryHistoryPeriod.day:
        return 'Day';
      case _DeliveryHistoryPeriod.week:
        return 'Week';
      case _DeliveryHistoryPeriod.month:
        return 'Month';
    }
  }

  String get emptyTitle {
    switch (this) {
      case _DeliveryHistoryPeriod.day:
        return 'No deliveries today';
      case _DeliveryHistoryPeriod.week:
        return 'No deliveries this week';
      case _DeliveryHistoryPeriod.month:
        return 'No deliveries this month';
    }
  }

  String get emptyMessage {
    switch (this) {
      case _DeliveryHistoryPeriod.day:
        return 'Delivery requests from today will appear here.';
      case _DeliveryHistoryPeriod.week:
        return 'Delivery requests from this week will appear here.';
      case _DeliveryHistoryPeriod.month:
        return 'Delivery requests from this month will appear here.';
    }
  }

  _DeliveryHistoryWindow window(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _DeliveryHistoryPeriod.day:
        return _DeliveryHistoryWindow(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _DeliveryHistoryPeriod.week:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return _DeliveryHistoryWindow(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
      case _DeliveryHistoryPeriod.month:
        final monthStart = DateTime(now.year, now.month);
        return _DeliveryHistoryWindow(
          start: monthStart,
          end: DateTime(now.year, now.month + 1),
        );
    }
  }
}

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  static const double _bottomNavClearance = 132;
  static const int _deliveryListLimit = 75;

  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  bool _isFilterLoading = false;
  bool _hasMoreDeliveries = false;
  _DeliveryHistoryPeriod _period = _DeliveryHistoryPeriod.day;
  RealtimeChannel? _deliveriesChannel;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries({bool showLoader = false}) async {
    final period = _period;
    if (showLoader && mounted) {
      setState(() => _isFilterLoading = true);
    }

    try {
      final supabase = Supabase.instance.client;
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final clientId = user?.id;
      final userPhone = user?.phone?.trim();
      final phone = (userPhone?.isNotEmpty ?? false)
          ? userPhone!
          : user?.email.trim() ?? '';

      if ((clientId == null || clientId.isEmpty) && phone.isEmpty) {
        if (mounted) {
          setState(() {
            _deliveries = const [];
            _hasMoreDeliveries = false;
            _isLoading = false;
            _isFilterLoading = false;
          });
        }
        return;
      }

      const select =
          'id, status, delivery_fee, created_at, '
          'pickup_location, dropoff_location';
      final window = period.window(DateTime.now());
      final start = window.start.toUtc().toIso8601String();
      final end = window.end.toUtc().toIso8601String();
      final responses = <List<dynamic>>[];

      if (clientId != null && clientId.isNotEmpty) {
        final data = await supabase
            .from('deliveries')
            .select(select)
            .eq('client_id', clientId)
            .gte('created_at', start)
            .lt('created_at', end)
            .order('created_at', ascending: false)
            .limit(_deliveryListLimit);
        responses.add(data);
      }

      if (phone.isNotEmpty) {
        final data = await supabase
            .from('deliveries')
            .select(select)
            .eq('customer_phone', phone)
            .gte('created_at', start)
            .lt('created_at', end)
            .order('created_at', ascending: false)
            .limit(_deliveryListLimit);
        responses.add(data);
      }

      final byId = <String, Map<String, dynamic>>{};
      for (final response in responses) {
        for (final delivery in List<Map<String, dynamic>>.from(response)) {
          final id = delivery['id']?.toString();
          if (id == null || id.isEmpty) continue;
          byId[id] = delivery;
        }
      }

      final deliveries = byId.values.toList()
        ..sort((a, b) {
          final aDate =
              DateTime.tryParse(a['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime(0);
          final bDate =
              DateTime.tryParse(b['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime(0);
          return bDate.compareTo(aDate);
        });
      final visibleDeliveries = deliveries.length > _deliveryListLimit
          ? deliveries.take(_deliveryListLimit).toList(growable: false)
          : deliveries;

      if (!mounted || period != _period) return;
      if (mounted) {
        setState(() {
          _deliveries = visibleDeliveries;
          _hasMoreDeliveries = deliveries.length >= _deliveryListLimit;
          _isLoading = false;
          _isFilterLoading = false;
        });
        _subscribeToDeliveryHistory(clientId: clientId, phone: phone);
      }
    } catch (e) {
      if (!mounted || period != _period) return;
      setState(() {
        _deliveries = const [];
        _hasMoreDeliveries = false;
        _isLoading = false;
        _isFilterLoading = false;
      });
    }
  }

  void _selectPeriod(_DeliveryHistoryPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _fetchDeliveries(showLoader: true);
  }

  void _subscribeToDeliveryHistory({required String phone, String? clientId}) {
    final hasClientId = clientId?.isNotEmpty ?? false;
    final filterColumn = hasClientId ? 'client_id' : 'customer_phone';
    final filterValue = hasClientId ? clientId! : phone;
    if (filterValue.isEmpty) return;

    _deliveriesChannel?.unsubscribe();
    _deliveriesChannel = Supabase.instance.client
        .channel('public:deliveries:$filterColumn:$filterValue')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filterColumn,
            value: filterValue,
          ),
          callback: (_) => _fetchDeliveries(),
        )
        .subscribe();
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
        return Icons.pending_rounded;
    }
  }

  @override
  void dispose() {
    _deliveriesChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        title: const AppText(
          'My Deliveries',
          variant: AppTextVariant.heading3,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appTextPrimary),
          onPressed: NavigationService().triggerHomeAction,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchDeliveries,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  _bottomNavClearance,
                ),
                children: [
                  _buildPeriodFilter(),
                  if (_isFilterLoading) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.primary,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (_deliveries.isEmpty)
                    _buildEmptyState()
                  else ...[
                    for (final delivery in _deliveries) ...[
                      _buildDeliveryCard(delivery),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_hasMoreDeliveries)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: AppText(
                          'Showing latest $_deliveryListLimit deliveries '
                          'for this period.',
                          variant: AppTextVariant.bodySmall,
                          color: context.appTextSecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodFilter() {
    const periods = _DeliveryHistoryPeriod.values;
    return Row(
      children: [
        for (final period in periods) ...[
          Expanded(
            child: _PeriodButton(
              label: period.label,
              selected: _period == period,
              onTap: () => _selectPeriod(period),
            ),
          ),
          if (period != periods.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 80, color: context.appBorder),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            _period.emptyTitle,
            variant: AppTextVariant.heading3,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
          AppText(
            _period.emptyMessage,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final deliveryId = delivery['id']?.toString();
    final status = delivery['status']?.toString() ?? 'Pending';
    final fee = _feeLabel(delivery['delivery_fee']);
    final createdAt = delivery['created_at'] != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(DateTime.parse(delivery['created_at'].toString()).toLocal())
        : '';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: deliveryId == null
          ? null
          : () => context.pushNamed(
              AppRoutes.tracking.name,
              queryParameters: {'deliveryId': deliveryId},
            ),
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _statusIcon(status),
                        color: _statusColor(status),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      AppText(
                        status.toUpperCase(),
                        variant: AppTextVariant.labelLarge,
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        fee,
                        variant: AppTextVariant.heading3,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appTextSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              _buildLocationRow(
                icon: Icons.my_location_rounded,
                color: AppColors.primary,
                label:
                    delivery['pickup_location']?.toString() ??
                    'Pickup location',
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildLocationRow(
                icon: Icons.location_on_rounded,
                color: context.appTextPrimary,
                label:
                    delivery['dropoff_location']?.toString() ??
                    'Dropoff location',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      createdAt,
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                    ),
                  ),
                  const AppText(
                    'View details',
                    variant: AppTextVariant.labelSmall,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _feeLabel(Object? value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (amount == null) return '-- ETB';
    return '${amount.toStringAsFixed(0)} ETB';
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppText(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : context.appSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : context.appBorder,
            ),
          ),
          child: AppText(
            label,
            color: selected ? Colors.white : context.appTextPrimary,
            fontWeight: FontWeight.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
