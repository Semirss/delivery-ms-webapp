import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          titleText: 'Cards',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildSection(
              context,
              title: 'Cards with Images - Top Position',
              children: [
                AppCard.elevated(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          'https://picsum.photos/400/200?random=1',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 64),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mountain Landscape',
                              style: AppTypography.heading3,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Beautiful mountain scenery with clear blue skies and lush greenery.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Swiss Alps',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard.outlined(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          'https://picsum.photos/400/200?random=2',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 64),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ocean View',
                                  style: AppTypography.heading3,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    'Featured',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Stunning coastal views with crystal clear waters.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Cards with Images - Left Position',
              children: [
                AppCard.elevated(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          'https://picsum.photos/150/150?random=3',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 48),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'City Lights',
                                style: AppTypography.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Urban nightscape with vibrant city lights.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    '4.8',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard.filled(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          'https://picsum.photos/150/150?random=4',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 100,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 40),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forest Trail',
                                style: AppTypography.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Peaceful hiking path through dense forest.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.md),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Cards with Images - Right Position',
              children: [
                AppCard.outlined(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desert Sunset',
                                style: AppTypography.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Golden hour in the vast desert landscape.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '\$299',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(AppRadius.lg),
                        ),
                        child: Image.network(
                          'https://picsum.photos/150/150?random=5',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 48),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Cards with Background Images',
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Image.network(
                        'https://picsum.photos/400/250?random=6',
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: AppColors.surfaceAlt,
                          child: const Icon(Icons.image, size: 64),
                        ),
                      ),
                    ),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Northern Lights',
                              style: AppTypography.heading3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Experience the magical aurora borealis in Iceland',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton.custom(
                              label: 'Book Now',
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              size: AppButtonSize.small,
                              onPressed: () => _showSnackBar(
                                context,
                                'Booking Northern Lights tour',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard.elevated(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.network(
                          'https://picsum.photos/400/200?random=7',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: AppColors.surfaceAlt,
                                child: const Icon(Icons.image, size: 64),
                              ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '50% OFF',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tropical Paradise',
                                    style: AppTypography.labelLarge,
                                  ),
                                  Text(
                                    'Limited time offer',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              AppIconButton(
                                icon: Icons.favorite_border,
                                onPressed: () => _showSnackBar(
                                  context,
                                  'Added to favorites',
                                ),
                                variant: AppIconButtonVariant.ghost,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Metric Cards',
              children: [
                AppDataCard.metric(
                  title: 'Total Revenue',
                  value: '\$45,231',
                  change: '+20.1%',
                  isPositive: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.metric(
                  title: 'Active Users',
                  value: '2,345',
                  change: '+12.5%',
                  isPositive: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.metric(
                  title: 'Bounce Rate',
                  value: '42.3%',
                  change: '-5.2%',
                  isPositive: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Compact Cards',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppDataCard.compact(
                        title: 'Orders',
                        value: '1,234',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppDataCard.compact(
                        title: 'Sales',
                        value: '\$12.5K',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppDataCard.compact(
                        title: 'Visitors',
                        value: '8,234',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppDataCard.compact(
                        title: 'Conversion',
                        value: '3.2%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Cards with Icons',
              children: [
                AppDataCard.withIcon(
                  title: 'Total Sales',
                  value: '\$54,239',
                  icon: Icons.shopping_cart,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.withIcon(
                  title: 'New Customers',
                  value: '234',
                  icon: Icons.people,
                  iconColor: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.withIcon(
                  title: 'Pending Orders',
                  value: '45',
                  icon: Icons.pending,
                  iconColor: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Gradient Cards',
              children: [
                AppDataCard.gradient(
                  title: 'Premium Users',
                  value: '1,234',
                  gradientColors: const [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.gradient(
                  title: 'Total Downloads',
                  value: '45.2K',
                  gradientColors: const [
                    AppColors.secondary,
                    AppColors.secondaryDark,
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.gradient(
                  title: 'Active Sessions',
                  value: '892',
                  gradientColors: const [AppColors.accent1, AppColors.accent2],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Clickable Cards',
              children: [
                AppDataCard.clickable(
                  title: 'View Analytics',
                  value: 'Click to explore',
                  onTap: () => _showSnackBar(context, 'Analytics card tapped'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.clickable(
                  title: 'Generate Report',
                  value: 'Click to generate',
                  icon: Icons.assessment,
                  onTap: () => _showSnackBar(context, 'Report card tapped'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Dashboard Example',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppDataCard.metric(
                        title: 'Revenue',
                        value: '\$12.5K',
                        change: '+8.2%',
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppDataCard.metric(
                        title: 'Expenses',
                        value: '\$8.3K',
                        change: '+3.1%',
                        isPositive: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppDataCard.withIcon(
                  title: 'Net Profit',
                  value: '\$4.2K',
                  icon: Icons.trending_up,
                  iconColor: AppColors.success,
                  change: '+12.5%',
                  isPositive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading3.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackBar.show(
      context: context,
      message: message,
      duration: const Duration(seconds: 1),
    );
  }
}
