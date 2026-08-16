import 'dart:async';

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

enum _EarningsPeriod { day, week, month }

class _DateWindow {
  const _DateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

extension _EarningsPeriodDetails on _EarningsPeriod {
  String get label {
    switch (this) {
      case _EarningsPeriod.day:
        return 'Day';
      case _EarningsPeriod.week:
        return 'Week';
      case _EarningsPeriod.month:
        return 'Month';
    }
  }

  String get summaryTitle {
    switch (this) {
      case _EarningsPeriod.day:
        return "Today's Earnings";
      case _EarningsPeriod.week:
        return "This Week's Earnings";
      case _EarningsPeriod.month:
        return "This Month's Earnings";
    }
  }

  String get statValue {
    switch (this) {
      case _EarningsPeriod.day:
        return 'Today';
      case _EarningsPeriod.week:
        return 'Week';
      case _EarningsPeriod.month:
        return 'Month';
    }
  }

  String get emptyTitle {
    switch (this) {
      case _EarningsPeriod.day:
        return 'No earnings today';
      case _EarningsPeriod.week:
        return 'No earnings this week';
      case _EarningsPeriod.month:
        return 'No earnings this month';
    }
  }

  String get emptyMessage {
    switch (this) {
      case _EarningsPeriod.day:
        return 'Completed deliveries from today will appear here.';
      case _EarningsPeriod.week:
        return 'Completed deliveries from this week will appear here.';
      case _EarningsPeriod.month:
        return 'Completed deliveries from this month will appear here.';
    }
  }

  _DateWindow window(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _EarningsPeriod.day:
        return _DateWindow(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _EarningsPeriod.week:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return _DateWindow(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
      case _EarningsPeriod.month:
        final monthStart = DateTime(now.year, now.month);
        return _DateWindow(
          start: monthStart,
          end: DateTime(now.year, now.month + 1),
        );
    }
  }
}

class _EarningsScreenState extends State<EarningsScreen> {
  final DriverProfileRepository _repository = DriverProfileRepository();

  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  bool _isFilterLoading = false;
  bool _hasMoreDeliveries = false;
  double _totalEarnings = 0;
  int _totalDeliveries = 0;
  String? _errorMessage;
  _EarningsPeriod _period = _EarningsPeriod.day;
  RealtimeChannel? _earningsChannel;
  String? _subscribedDriverId;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchEarnings());
  }

  Future<void> _fetchEarnings({bool showLoader = false}) async {
    final period = _period;
    if (showLoader && mounted) {
      setState(() {
        _isFilterLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      final window = period.window(DateTime.now());
      final snapshot = await _repository.loadEarnings(
        user,
        startAt: window.start,
        endAt: window.end,
      );

      if (!mounted || period != _period) return;
      setState(() {
        _deliveries = snapshot.deliveries;
        _totalEarnings = snapshot.totalEarnings;
        _totalDeliveries = snapshot.totalDeliveries;
        _hasMoreDeliveries = snapshot.hasMoreDeliveries;
        _errorMessage = snapshot.errorMessage;
        _isLoading = false;
        _isFilterLoading = false;
      });
      _subscribeToEarnings(snapshot.driverId);
    } catch (_) {
      if (!mounted || period != _period) return;
      setState(() {
        _deliveries = const [];
        _totalEarnings = 0;
        _totalDeliveries = 0;
        _hasMoreDeliveries = false;
        _errorMessage = 'Could not load earnings right now.';
        _isLoading = false;
        _isFilterLoading = false;
      });
    }
  }

  void _selectPeriod(_EarningsPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    unawaited(_fetchEarnings(showLoader: true));
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
          callback: (_) => unawaited(_fetchEarnings()),
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
                  expandedHeight: 224,
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
                            AppText(
                              _period.summaryTitle,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_totalEarnings.toStringAsFixed(0)} ETB',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
                                _buildStatBadge(_period.statValue, 'Filter'),
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
                      onPressed: () =>
                          unawaited(_fetchEarnings(showLoader: true)),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildPeriodFilter(),
                      if (_isFilterLoading)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(),
                  )
                else if (_deliveries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else ...[
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
                  if (_hasMoreDeliveries)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          MediaQuery.viewPaddingOf(context).bottom +
                              AppSpacing.lg,
                        ),
                        child: AppText(
                          'Showing latest ${_deliveries.length} of '
                          '$_totalDeliveries completed deliveries.',
                          variant: AppTextVariant.bodySmall,
                          color: context.appTextSecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildPeriodFilter() {
    const periods = _EarningsPeriod.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          for (final period in periods) ...[
            Expanded(
              child: _EarningsPeriodButton(
                label: period.label,
                selected: _period == period,
                onTap: () => _selectPeriod(period),
              ),
            ),
            if (period != periods.last) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final errorMessage = _errorMessage ?? 'Could not load earnings right now.';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 72, color: context.appBorder),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            errorMessage,
            variant: AppTextVariant.heading3,
            color: context.appTextSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => unawaited(_fetchEarnings(showLoader: true)),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 80, color: context.appBorder),
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

class _EarningsPeriodButton extends StatelessWidget {
  const _EarningsPeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
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
      ),
    );
  }
}
