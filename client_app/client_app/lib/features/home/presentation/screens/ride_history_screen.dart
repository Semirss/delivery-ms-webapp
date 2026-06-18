import 'package:flutter/material.dart';
import 'package:client_ui/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('rides')
          .select()
          .eq('client_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _rides = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      case 'in_progress': return AppColors.info;
      case 'accepted': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'in_progress': return Icons.directions_bike_rounded;
      case 'accepted': return Icons.motorcycle_rounded;
      default: return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const AppText('My Rides', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.motorcycle_rounded, size: 80, color: AppColors.border),
                      const SizedBox(height: AppSpacing.lg),
                      const AppText('No rides yet', variant: AppTextVariant.heading3, color: AppColors.textSecondary),
                      const AppText('Book your first ride!', variant: AppTextVariant.bodyMedium, color: AppColors.textSecondary),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchRides,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _rides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      final status = ride['status'] as String? ?? 'unknown';
                      final price = (ride['price'] as num?)?.toStringAsFixed(0) ?? '--';
                      final createdAt = ride['created_at'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(ride['created_at']).toLocal())
                          : '';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
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
                                      Icon(_statusIcon(status), color: _statusColor(status), size: 18),
                                      const SizedBox(width: 6),
                                      AppText(
                                        status.replaceAll('_', ' ').toUpperCase(),
                                        variant: AppTextVariant.labelLarge,
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                  AppText('$price ETB', variant: AppTextVariant.heading3, fontWeight: FontWeight.bold),
                                ],
                              ),
                              const Divider(height: AppSpacing.lg),
                              _buildLocationRow(
                                icon: Icons.my_location_rounded,
                                color: AppColors.primary,
                                label: ride['pickup_address'] as String? ?? 'Pickup Location',
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _buildLocationRow(
                                icon: Icons.location_on_rounded,
                                color: AppColors.textPrimary,
                                label: ride['dropoff_address'] as String? ?? 'Dropoff Location',
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppText(createdAt, variant: AppTextVariant.bodySmall, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildLocationRow({required IconData icon, required Color color, required String label}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppText(label, variant: AppTextVariant.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
