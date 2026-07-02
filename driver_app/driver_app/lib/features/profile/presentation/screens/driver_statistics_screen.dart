import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DriverStatisticsScreen extends StatefulWidget {
  const DriverStatisticsScreen({super.key});

  @override
  State<DriverStatisticsScreen> createState() => _DriverStatisticsScreenState();
}

class _DriverStatisticsScreenState extends State<DriverStatisticsScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();

  DriverProfileSnapshot? _snapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final snapshot = await _repository.load(user);
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: const AppAppBar(titleText: 'Statistics'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildTopStats(snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _buildWeeklyChart(snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatusBreakdown(snapshot),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentDeliveries(snapshot),
                ],
              ),
            ),
    );
  }

  Widget _buildTopStats(DriverProfileSnapshot? snapshot) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        _statTile(
          Icons.delivery_dining_rounded,
          '${snapshot?.completedDeliveries ?? 0}',
          'Completed',
          AppColors.success,
        ),
        _statTile(
          Icons.payments_rounded,
          '${snapshot?.weekEarnings.toStringAsFixed(0) ?? '0'} ETB',
          'Last 7 days',
          AppColors.primary,
        ),
        _statTile(
          Icons.today_rounded,
          '${snapshot?.todayDeliveries ?? 0}',
          'Today',
          AppColors.info,
        ),
        _statTile(
          Icons.star_rounded,
          snapshot?.rating.label ?? 'New',
          'Rating',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                value,
                variant: AppTextVariant.heading3,
                color: context.appTextPrimary,
                fontWeight: FontWeight.w900,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppText(
                label,
                variant: AppTextVariant.bodySmall,
                color: context.appTextSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(DriverProfileSnapshot? snapshot) {
    final days = _lastSevenDays(snapshot);
    final maxValue = days.fold<double>(
      0,
      (max, day) => day.earnings > max ? day.earnings : max,
    );

    return _panel(
      title: 'Weekly earnings',
      child: Column(
        children: [
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: AppText(
                      DateFormat('EEE').format(day.date),
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextSecondary,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final fraction = maxValue == 0
                            ? 0.06
                            : (day.earnings / maxValue).clamp(0.06, 1.0);
                        return Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: context.appSurfaceAlt,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              height: 12,
                              width: constraints.maxWidth * fraction,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 74,
                    child: AppText(
                      '${day.earnings.toStringAsFixed(0)} ETB',
                      variant: AppTextVariant.bodySmall,
                      color: context.appTextPrimary,
                      textAlign: TextAlign.end,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(DriverProfileSnapshot? snapshot) {
    final total = snapshot?.deliveries.length ?? 0;
    final completed = snapshot?.completedDeliveries ?? 0;
    final active = snapshot?.activeDeliveries ?? 0;
    final cancelled = snapshot?.cancelledDeliveries ?? 0;

    return _panel(
      title: 'Delivery status',
      child: Column(
        children: [
          _statusRow('Completed', completed, total, AppColors.success),
          const SizedBox(height: AppSpacing.md),
          _statusRow('Active', active, total, AppColors.info),
          const SizedBox(height: AppSpacing.md),
          _statusRow('Cancelled', cancelled, total, AppColors.error),
        ],
      ),
    );
  }

  Widget _statusRow(String label, int value, int total, Color color) {
    final fraction = total == 0 ? 0.0 : value / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                label,
                variant: AppTextVariant.bodySmall,
                color: context.appTextSecondary,
              ),
            ),
            AppText(
              '$value',
              variant: AppTextVariant.bodySmall,
              color: context.appTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: fraction,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadius.full),
          color: color,
          backgroundColor: context.appSurfaceAlt,
        ),
      ],
    );
  }

  Widget _buildRecentDeliveries(DriverProfileSnapshot? snapshot) {
    final deliveries = snapshot?.deliveries.take(8).toList() ?? const [];

    return _panel(
      title: 'Recent deliveries',
      child: deliveries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: AppText(
                  'No deliveries yet',
                  variant: AppTextVariant.bodyMedium,
                  color: context.appTextSecondary,
                ),
              ),
            )
          : Column(
              children: [
                for (final delivery in deliveries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _statusColor(
                            delivery['status'],
                          ).withValues(alpha: 0.12),
                          child: Icon(
                            _statusIcon(delivery['status']),
                            color: _statusColor(delivery['status']),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                valueText(
                                  delivery['dropoff_location'],
                                  fallback: 'Destination',
                                ).split(',').first,
                                variant: AppTextVariant.bodyMedium,
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                _dateLabel(delivery['created_at']),
                                variant: AppTextVariant.bodySmall,
                                color: context.appTextSecondary,
                              ),
                            ],
                          ),
                        ),
                        AppText(
                          moneyText(delivery['delivery_fee']),
                          variant: AppTextVariant.bodySmall,
                          color: context.appTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            variant: AppTextVariant.heading3,
            color: context.appTextPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  List<_DailyEarnings> _lastSevenDays(DriverProfileSnapshot? snapshot) {
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index));
      return _DailyEarnings(date: date);
    });

    for (final delivery in snapshot?.deliveries ?? const []) {
      if (delivery['status'] != 'Delivered') continue;
      final createdAt = asDate(delivery['created_at']);
      if (createdAt == null) continue;

      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      _DailyEarnings? match;
      for (final item in days) {
        if (item.date == day) {
          match = item;
          break;
        }
      }
      if (match != null) {
        match.earnings += asMoney(delivery['delivery_fee']);
      }
    }

    return days;
  }

  Color _statusColor(Object? status) {
    switch (status?.toString()) {
      case 'Delivered':
        return AppColors.success;
      case 'Assigned':
      case 'Picked Up':
        return AppColors.info;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(Object? status) {
    switch (status?.toString()) {
      case 'Delivered':
        return Icons.check_rounded;
      case 'Assigned':
      case 'Picked Up':
        return Icons.route_rounded;
      case 'Cancelled':
        return Icons.close_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _dateLabel(Object? value) {
    final date = asDate(value);
    if (date == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(date);
  }
}

class _DailyEarnings {
  _DailyEarnings({required this.date});

  final DateTime date;
  double earnings = 0;
}
