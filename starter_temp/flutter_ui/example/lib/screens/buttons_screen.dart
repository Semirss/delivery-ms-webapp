import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class ButtonsScreen extends StatefulWidget {
  const ButtonsScreen({super.key});

  @override
  State<ButtonsScreen> createState() => _ButtonsScreenState();
}

class _ButtonsScreenState extends State<ButtonsScreen> {
  bool _isLoading = false;

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
          titleText: 'Buttons',
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
              title: 'Button Variants',
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: AppButton.primary(
                    label: 'Primary Button',
                    onPressed: () =>
                        _showSnackBar(context, 'Primary button pressed'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: AppButton.secondary(
                    label: 'Secondary Button',
                    onPressed: () =>
                        _showSnackBar(context, 'Secondary button pressed'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: AppButton.tertiary(
                    label: 'Tertiary Button',
                    onPressed: () =>
                        _showSnackBar(context, 'Tertiary button pressed'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: AppButton.ghost(
                    label: 'Ghost Button',
                    onPressed: () =>
                        _showSnackBar(context, 'Ghost button pressed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Button Variants',
              children: [
                AppButton.primary(
                  label: 'Primary Button',
                  onPressed: () =>
                      _showSnackBar(context, 'Primary button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.tertiary(
                  label: 'Tertiary Button',
                  onPressed: () =>
                      _showSnackBar(context, 'Tertiary button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.ghost(
                  label: 'Ghost Button',
                  onPressed: () =>
                      _showSnackBar(context, 'Ghost button pressed'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Button Sizes',
              children: [
                AppButton.primary(
                  label: 'Small Button',
                  size: AppButtonSize.small,
                  onPressed: () =>
                      _showSnackBar(context, 'Small button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Medium Button',
                  size: AppButtonSize.medium,
                  onPressed: () =>
                      _showSnackBar(context, 'Medium button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Large Button',
                  size: AppButtonSize.large,
                  onPressed: () =>
                      _showSnackBar(context, 'Large button pressed'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Button States',
              children: [
                AppButton.primary(
                  label: 'Enabled Button',
                  onPressed: () => _showSnackBar(context, 'Button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(label: 'Disabled Button', onPressed: null),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Loading Button',
                  isLoading: _isLoading,
                  onPressed: () {
                    setState(() => _isLoading = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        _showSnackBar(context, 'Loading complete');
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Buttons with Icons',
              children: [
                AppButton.primary(
                  label: 'Button with Icon',
                  icon: Icons.add,
                  onPressed: () =>
                      _showSnackBar(context, 'Icon button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Download',
                  icon: Icons.download,
                  onPressed: () =>
                      _showSnackBar(context, 'Download button pressed'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Icon Buttons',
              children: [
                Row(
                  children: [
                    AppIconButton.primary(
                      icon: Icons.favorite,
                      onPressed: () =>
                          _showSnackBar(context, 'Favorite pressed'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppIconButton.secondary(
                      icon: Icons.share,
                      onPressed: () => _showSnackBar(context, 'Share pressed'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppIconButton.tertiary(
                      icon: Icons.settings,
                      onPressed: () =>
                          _showSnackBar(context, 'Settings pressed'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppIconButton.ghost(
                      icon: Icons.more_vert,
                      onPressed: () => _showSnackBar(context, 'More pressed'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Custom Colors',
              children: [
                AppButton.custom(
                  label: 'Custom Success',
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showSnackBar(context, 'Custom button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Custom Warning',
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showSnackBar(context, 'Custom button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Custom Error',
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showSnackBar(context, 'Custom button pressed'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Custom Info',
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showSnackBar(context, 'Custom button pressed'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Button Combinations',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Cancel',
                        onPressed: () => _showSnackBar(context, 'Cancelled'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Confirm',
                        onPressed: () => _showSnackBar(context, 'Confirmed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.ghost(
                        label: 'Back',
                        icon: Icons.arrow_back,
                        onPressed: () => _showSnackBar(context, 'Back pressed'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        label: 'Continue',
                        icon: Icons.arrow_forward,
                        onPressed: () =>
                            _showSnackBar(context, 'Continue pressed'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              title: 'Real-World Examples',
              children: [
                AppButton.primary(
                  label: 'Add to Cart',
                  icon: Icons.shopping_cart,
                  size: AppButtonSize.large,
                  onPressed: () => _showSnackBar(context, 'Added to cart'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Buy Now',
                  icon: Icons.payment,
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  size: AppButtonSize.large,
                  onPressed: () =>
                      _showSnackBar(context, 'Proceeding to checkout'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Save Draft',
                        icon: Icons.save,
                        onPressed: () => _showSnackBar(context, 'Draft saved'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton.primary(
                        label: 'Publish',
                        icon: Icons.publish,
                        onPressed: () => _showSnackBar(context, 'Published'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.custom(
                  label: 'Delete Account',
                  icon: Icons.delete_forever,
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _showSnackBar(context, 'Account deletion requested'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AppIconButton.ghost(
                      icon: Icons.thumb_up,
                      onPressed: () => _showSnackBar(context, 'Liked'),
                    ),
                    AppIconButton.ghost(
                      icon: Icons.comment,
                      onPressed: () => _showSnackBar(context, 'Comment'),
                    ),
                    AppIconButton.ghost(
                      icon: Icons.share,
                      onPressed: () => _showSnackBar(context, 'Share'),
                    ),
                    AppIconButton.ghost(
                      icon: Icons.bookmark_border,
                      onPressed: () => _showSnackBar(context, 'Bookmarked'),
                    ),
                  ],
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
