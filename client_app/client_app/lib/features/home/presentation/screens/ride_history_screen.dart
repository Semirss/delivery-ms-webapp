import 'package:client_ui/app_ui.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  RealtimeChannel? _deliveriesChannel;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    try {
      final supabase = Supabase.instance.client;
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final clientId = user?.id;
      final phone = user?.phone?.trim().isNotEmpty == true
          ? user!.phone!.trim()
          : user?.email.trim() ?? '';

      if ((clientId == null || clientId.isEmpty) && phone.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      const select =
          '*, driver:drivers(id, name, phone, vehicle_type, current_lat, current_lng)';
      List<Map<String, dynamic>> deliveries = [];

      if (clientId != null && clientId.isNotEmpty) {
        final data = await supabase
            .from('deliveries')
            .select(select)
            .eq('client_id', clientId)
            .order('created_at', ascending: false)
            .limit(50);
        deliveries = List<Map<String, dynamic>>.from(data);
      }

      if (deliveries.isEmpty && phone.isNotEmpty) {
        final data = await supabase
            .from('deliveries')
            .select(select)
            .eq('customer_phone', phone)
            .order('created_at', ascending: false)
            .limit(50);
        deliveries = List<Map<String, dynamic>>.from(data);
      }

      if (mounted) {
        setState(() {
          _deliveries = deliveries;
          _isLoading = false;
        });
        _subscribeToDeliveryHistory(clientId: clientId, phone: phone);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToDeliveryHistory({String? clientId, required String phone}) {
    final filterColumn = clientId?.isNotEmpty == true
        ? 'client_id'
        : 'customer_phone';
    final filterValue = clientId?.isNotEmpty == true ? clientId! : phone;
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
          : _deliveries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 80,
                    color: context.appBorder,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppText(
                    'No deliveries yet',
                    variant: AppTextVariant.heading3,
                    color: context.appTextSecondary,
                  ),
                  AppText(
                    'Create your first delivery request.',
                    variant: AppTextVariant.bodyMedium,
                    color: context.appTextSecondary,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchDeliveries,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _deliveries.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final delivery = _deliveries[index];
                  final status = delivery['status']?.toString() ?? 'Pending';
                  final fee = _feeLabel(delivery['delivery_fee']);
                  final createdAt = delivery['created_at'] != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(
                          DateTime.parse(
                            delivery['created_at'].toString(),
                          ).toLocal(),
                        )
                      : '';

                  return Container(
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
                              AppText(
                                fee,
                                variant: AppTextVariant.heading3,
                                fontWeight: FontWeight.bold,
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
                          AppText(
                            createdAt,
                            variant: AppTextVariant.bodySmall,
                            color: context.appTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
          child: AppText(
            label,
            variant: AppTextVariant.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
