import 'package:flutter/material.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  double _totalEarnings = 0;
  int _totalRides = 0;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('rides')
          .select()
          .eq('driver_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(50);

      final rides = List<Map<String, dynamic>>.from(data);
      final total = rides.fold<double>(0, (sum, r) => sum + ((r['price'] as num?)?.toDouble() ?? 0));

      if (mounted) {
        setState(() {
          _rides = rides;
          _totalEarnings = total;
          _totalRides = rides.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatBadge('$_totalRides', 'Trips'),
                                Container(width: 1, height: 24, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
                                _buildStatBadge('5.0 ★', 'Rating'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                if (_rides.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payments_outlined, size: 80, color: AppColors.border),
                          const SizedBox(height: AppSpacing.lg),
                          const AppText('No completed rides yet', variant: AppTextVariant.heading3, color: AppColors.textSecondary),
                          const AppText('Go online to start earning!', variant: AppTextVariant.bodyMedium, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ride = _rides[index];
                          final price = (ride['price'] as num?)?.toStringAsFixed(0) ?? '--';
                          final createdAt = ride['created_at'] != null
                              ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(ride['created_at']).toLocal())
                              : '';
                          final dropoff = ride['dropoff_address'] as String? ?? 'Destination';

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                              ),
                              title: AppText(
                                dropoff.split(',').first,
                                variant: AppTextVariant.bodyMedium,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: AppText(createdAt, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
                              trailing: AppText(
                                '$price ETB',
                                variant: AppTextVariant.heading3,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        childCount: _rides.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
