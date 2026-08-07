import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();

  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  double _totalEarnings = 0;
  int _totalDeliveries = 0;
  RealtimeChannel? _earningsChannel;
  String? _subscribedDriverId;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final snapshot = await _repository.load(user);
      final deliveries = snapshot.deliveries
          .where((delivery) => delivery['status'] == 'Delivered')
          .take(50)
          .toList();
      final total = deliveries.fold<double>(
        0,
        (sum, delivery) => sum + asMoney(delivery['delivery_fee']),
      );

      if (mounted) {
        setState(() {
          _deliveries = deliveries;
          _totalEarnings = total;
          _totalDeliveries = deliveries.length;
          _isLoading = false;
        });
        _subscribeToEarnings(snapshot.driverId);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToEarnings(String? driverId) {
    if (driverId == null || driverId.isEmpty) return;
    if (_subscribedDriverId == driverId) return;
    _subscribedDriverId = driverId;
    _earningsChannel?.unsubscribe();
    _earningsChannel = Supabase.instance.client
        .channel('public:deliveries:earnings:$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (_) => _fetchEarnings(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _earningsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  backgroundColor: AppColors.primary,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            const AppText(
                              'Total Earnings',
                              variant: AppTextVariant.bodyMedium,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${_totalEarnings.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatBadge(
                                  '$_totalDeliveries',
                                  'Deliveries',
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white30,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                ),
                                _buildStatBadge('5.0', 'Rating'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  leading: widget.showBackButton
                      ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _fetchEarnings,
                    ),
                  ],
                ),
                if (_deliveries.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 80,
                            color: context.appBorder,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppText(
                            'No completed deliveries yet',
                            variant: AppTextVariant.heading3,
                            color: context.appTextSecondary,
                          ),
                          const AppText(
                            'Go online to start earning.',
                            variant: AppTextVariant.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      MediaQuery.viewPaddingOf(context).bottom + AppSpacing.xl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final delivery = _deliveries[index];
                        final fee = asMoney(
                          delivery['delivery_fee'],
                        ).toStringAsFixed(0);
                        final createdAt = delivery['created_at'] != null
                            ? DateFormat('dd MMM, hh:mm a').format(
                                DateTime.parse(
                                  delivery['created_at'].toString(),
                                ).toLocal(),
                              )
                            : '';
                        final dropoff =
                            delivery['dropoff_location']?.toString() ??
                            'Destination';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            title: AppText(
                              dropoff.split(',').first,
                              variant: AppTextVariant.bodyMedium,
                              fontWeight: FontWeight.bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: AppText(
                              createdAt,
                              variant: AppTextVariant.bodySmall,
                              color: context.appTextSecondary,
                            ),
                            trailing: AppText(
                              '$fee ETB',
                              variant: AppTextVariant.heading3,
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }, childCount: _deliveries.length),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
