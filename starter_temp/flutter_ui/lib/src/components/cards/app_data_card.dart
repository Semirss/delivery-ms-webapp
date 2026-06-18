import 'package:flutter/material.dart';
import '../common/app_icon.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/constants/app_shadows.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the visual variants of AppDataCard
enum AppDataCardVariant { metric, compact, withIcon, gradient, clickable }

/// Enum defining image placement options for AppDataCard
enum AppDataCardImagePlacement {
  /// Image placed at the top of the card
  top,

  /// Image placed at the bottom of the card
  bottom,

  /// Image placed on the left side of the card
  left,

  /// Image placed on the right side of the card
  right,

  /// Image used as background with overlay content
  background,
}

/// A customizable data card component for displaying metrics and information.
///
/// AppDataCard provides a consistent card interface with support for
/// different visual styles (variants), change indicators, icons, gradients,
/// images with various placements, overlay options with height percentage control,
/// and clickable interactions.
///
/// Example usage:
/// ```dart
/// AppDataCard.metric(
///   title: 'Total Revenue',
///   value: '\$45,231',
///   change: '+12.5%',
///   isPositive: true,
///   image: NetworkImage('https://example.com/image.jpg'),
///   imagePlacement: AppDataCardImagePlacement.top,
///   overlayColor: Colors.black,
///   overlayOpacity: 0.5,
///   overlayHeightPercent: 0.6, // Overlay covers 60% of image height
/// )
/// ```
class AppDataCard extends StatelessWidget {
  /// The title text displayed on the card
  final String title;

  /// The main value displayed on the card
  final String value;

  /// Optional change indicator text (e.g., '+12.5%')
  final String? change;

  /// Whether the change is positive (true) or negative (false)
  final bool? isPositive;

  /// Optional icon to display on the card (IconData, SVG path, Image path, or Widget)
  final dynamic icon;

  /// Custom color for the icon
  final Color? iconColor;

  /// Gradient colors for gradient variant
  final List<Color>? gradientColors;

  /// Callback invoked when the card is tapped (for clickable variant)
  final VoidCallback? onTap;

  /// Optional trailing widget
  final Widget? trailing;

  /// Optional image to display on the card
  final ImageProvider? image;

  /// Placement of the image on the card
  final AppDataCardImagePlacement? imagePlacement;

  /// Height of the image when placed at top or bottom
  final double? imageHeight;

  /// Width of the image when placed at left or right
  final double? imageWidth;

  /// Box fit for the image
  /// Options: contain (fit entire image), cover (fill while maintaining aspect), fill (stretch to fill)
  final BoxFit imageFit;

  /// Whether to show shimmer loading effect
  final bool showImageShimmer;

  /// Shimmer base color
  final Color? shimmerBaseColor;

  /// Shimmer highlight color
  final Color? shimmerHighlightColor;

  /// Overlay color for the image (applies to background and other placements)
  final Color? overlayColor;

  /// Overlay opacity (0.0 to 1.0)
  final double overlayOpacity;

  /// Percentage of image height to apply overlay (0.0 to 1.0)
  /// When 1.0, overlay covers full image height
  /// When less than 1.0, overlay covers that percentage from bottom
  final double overlayHeightPercent;

  /// The visual variant of the card
  final AppDataCardVariant variant;

  const AppDataCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    this.isPositive,
    this.icon,
    this.iconColor,
    this.gradientColors,
    this.onTap,
    this.trailing,
    this.image,
    this.imagePlacement,
    this.imageHeight,
    this.imageWidth,
    this.imageFit = BoxFit.cover,
    this.showImageShimmer = true,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.overlayColor,
    this.overlayOpacity = 0.4,
    this.overlayHeightPercent = 1.0,
    this.variant = AppDataCardVariant.metric,
  });

  /// Creates a metric card with change indicator
  factory AppDataCard.metric({
    Key? key,
    required String title,
    required String value,
    String? change,
    bool? isPositive,
    ImageProvider? image,
    AppDataCardImagePlacement? imagePlacement,
    double? imageHeight,
    double? imageWidth,
    BoxFit imageFit = BoxFit.cover,
    bool showImageShimmer = true,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? overlayColor,
    double overlayOpacity = 0.4,
    double overlayHeightPercent = 1.0,
  }) {
    return AppDataCard(
      key: key,
      title: title,
      value: value,
      change: change,
      isPositive: isPositive,
      image: image,
      imagePlacement: imagePlacement,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      imageFit: imageFit,
      showImageShimmer: showImageShimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      overlayHeightPercent: overlayHeightPercent,
      variant: AppDataCardVariant.metric,
    );
  }

  /// Creates a compact card with minimal spacing
  factory AppDataCard.compact({
    Key? key,
    required String title,
    required String value,
    Widget? trailing,
    ImageProvider? image,
    AppDataCardImagePlacement? imagePlacement,
    double? imageHeight,
    double? imageWidth,
    BoxFit imageFit = BoxFit.cover,
    bool showImageShimmer = true,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? overlayColor,
    double overlayOpacity = 0.4,
    double overlayHeightPercent = 1.0,
  }) {
    return AppDataCard(
      key: key,
      title: title,
      value: value,
      trailing: trailing,
      image: image,
      imagePlacement: imagePlacement,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      imageFit: imageFit,
      showImageShimmer: showImageShimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      overlayHeightPercent: overlayHeightPercent,
      variant: AppDataCardVariant.compact,
    );
  }

  /// Creates a card with an icon
  factory AppDataCard.withIcon({
    Key? key,
    required String title,
    required String value,
    required dynamic icon,
    Color? iconColor,
    String? change,
    bool? isPositive,
    ImageProvider? image,
    AppDataCardImagePlacement? imagePlacement,
    double? imageHeight,
    double? imageWidth,
    BoxFit imageFit = BoxFit.cover,
    bool showImageShimmer = true,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? overlayColor,
    double overlayOpacity = 0.4,
    double overlayHeightPercent = 1.0,
  }) {
    return AppDataCard(
      key: key,
      title: title,
      value: value,
      icon: icon,
      iconColor: iconColor,
      change: change,
      isPositive: isPositive,
      image: image,
      imagePlacement: imagePlacement,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      imageFit: imageFit,
      showImageShimmer: showImageShimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      overlayHeightPercent: overlayHeightPercent,
      variant: AppDataCardVariant.withIcon,
    );
  }

  /// Creates a card with gradient background
  factory AppDataCard.gradient({
    Key? key,
    required String title,
    required String value,
    required List<Color> gradientColors,
    dynamic icon,
    ImageProvider? image,
    AppDataCardImagePlacement? imagePlacement,
    double? imageHeight,
    double? imageWidth,
    BoxFit imageFit = BoxFit.cover,
    bool showImageShimmer = true,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? overlayColor,
    double overlayOpacity = 0.4,
    double overlayHeightPercent = 1.0,
  }) {
    return AppDataCard(
      key: key,
      title: title,
      value: value,
      gradientColors: gradientColors,
      icon: icon,
      image: image,
      imagePlacement: imagePlacement,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      imageFit: imageFit,
      showImageShimmer: showImageShimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      overlayHeightPercent: overlayHeightPercent,
      variant: AppDataCardVariant.gradient,
    );
  }

  /// Creates a clickable card with tap feedback
  factory AppDataCard.clickable({
    Key? key,
    required String title,
    required String value,
    required VoidCallback onTap,
    dynamic icon,
    String? change,
    bool? isPositive,
    ImageProvider? image,
    AppDataCardImagePlacement? imagePlacement,
    double? imageHeight,
    double? imageWidth,
    BoxFit imageFit = BoxFit.cover,
    bool showImageShimmer = true,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? overlayColor,
    double overlayOpacity = 0.4,
    double overlayHeightPercent = 1.0,
  }) {
    return AppDataCard(
      key: key,
      title: title,
      value: value,
      onTap: onTap,
      icon: icon,
      change: change,
      isPositive: isPositive,
      image: image,
      imagePlacement: imagePlacement,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      imageFit: imageFit,
      showImageShimmer: showImageShimmer,
      shimmerBaseColor: shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor,
      overlayColor: overlayColor,
      overlayOpacity: overlayOpacity,
      overlayHeightPercent: overlayHeightPercent,
      variant: AppDataCardVariant.clickable,
    );
  }

  /// Returns the padding based on variant
  EdgeInsets get _padding {
    switch (variant) {
      case AppDataCardVariant.compact:
        return const EdgeInsets.all(AppSpacing.md);
      case AppDataCardVariant.metric:
      case AppDataCardVariant.withIcon:
      case AppDataCardVariant.gradient:
      case AppDataCardVariant.clickable:
        return const EdgeInsets.all(AppSpacing.lg);
    }
  }

  /// Returns the change indicator color based on isPositive
  Color get _changeColor {
    if (isPositive == null) return AppColors.textSecondary;
    return isPositive! ? AppColors.success : AppColors.error;
  }

  /// Returns the background color based on variant
  Color? get _backgroundColor {
    if (variant == AppDataCardVariant.gradient) {
      return null; // Gradient will be applied via decoration
    }
    return AppColors.surface;
  }

  /// Returns the text color for gradient variant
  Color get _textColor {
    return variant == AppDataCardVariant.gradient
        ? Colors.white
        : AppColors.textPrimary;
  }

  /// Returns the secondary text color for gradient variant
  Color get _secondaryTextColor {
    return variant == AppDataCardVariant.gradient
        ? Colors.white.withOpacity(0.9)
        : AppColors.textSecondary;
  }

  /// Builds a shimmer loading widget
  Widget _buildShimmer({required double width, required double height}) {
    if (!showImageShimmer) {
      return Container(
        width: width,
        height: height,
        color: shimmerBaseColor ?? AppColors.surfaceAlt,
      );
    }

    return _ShimmerWidget(
      width: width,
      height: height,
      baseColor: shimmerBaseColor ?? AppColors.surfaceAlt,
      highlightColor: shimmerHighlightColor ?? AppColors.surface,
    );
  }

  /// Builds a cached image widget with shimmer support
  Widget _buildCachedImage({
    required ImageProvider imageProvider,
    required double? width,
    required double? height,
    required BoxFit fit,
  }) {
    return Image(
      image: imageProvider,
      fit: fit,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _buildShimmer(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: AppColors.surfaceAlt,
          child: Icon(
            Icons.broken_image,
            color: AppColors.textSecondary,
            size: 40,
          ),
        );
      },
    );
  }

  /// Builds the overlay widget based on image placement and height percentage
  Widget? _buildOverlay({
    required double imageHeight,
    required double imageWidth,
  }) {
    if (overlayColor == null || image == null) return null;

    final placement = imagePlacement ?? AppDataCardImagePlacement.top;
    final heightPercent = overlayHeightPercent.clamp(0.0, 1.0);
    final overlayHeight = imageHeight * heightPercent;

    final overlay = Container(
      color: overlayColor!.withValues(alpha: overlayOpacity),
    );

    // For background placement, overlay covers percentage from bottom
    if (placement == AppDataCardImagePlacement.background) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: overlayHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          child: overlay,
        ),
      );
    }

    // For top placement, overlay covers percentage from bottom of image
    if (placement == AppDataCardImagePlacement.top) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: overlayHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          child: overlay,
        ),
      );
    }

    // For bottom placement, overlay covers percentage from top of image
    if (placement == AppDataCardImagePlacement.bottom) {
      return Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: overlayHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
          child: overlay,
        ),
      );
    }

    // For left/right placements, overlay covers percentage from the inner edge
    if (placement == AppDataCardImagePlacement.left) {
      final overlayWidth = imageWidth * heightPercent;
      return Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        width: overlayWidth,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          child: overlay,
        ),
      );
    }

    if (placement == AppDataCardImagePlacement.right) {
      final overlayWidth = imageWidth * heightPercent;
      return Positioned(
        top: 0,
        bottom: 0,
        left: 0,
        width: overlayWidth,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(AppRadius.lg),
          ),
          child: overlay,
        ),
      );
    }

    return null;
  }

  /// Builds the image widget based on placement
  Widget? _buildImage() {
    if (image == null) return null;

    // Default to top placement if image is provided but placement is not specified
    final placement = imagePlacement ?? AppDataCardImagePlacement.top;

    final imageWidget = _buildCachedImage(
      imageProvider: image!,
      width: imageWidth,
      height: imageHeight,
      fit: imageFit,
    );

    switch (placement) {
      case AppDataCardImagePlacement.top:
        final height = imageHeight ?? 120;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              children: [
                imageWidget,
                if (_buildOverlay(
                      imageHeight: height,
                      imageWidth: double.infinity,
                    ) !=
                    null)
                  _buildOverlay(
                    imageHeight: height,
                    imageWidth: double.infinity,
                  )!,
              ],
            ),
          ),
        );
      case AppDataCardImagePlacement.bottom:
        final height = imageHeight ?? 120;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Stack(
              children: [
                imageWidget,
                if (_buildOverlay(
                      imageHeight: height,
                      imageWidth: double.infinity,
                    ) !=
                    null)
                  _buildOverlay(
                    imageHeight: height,
                    imageWidth: double.infinity,
                  )!,
              ],
            ),
          ),
        );
      case AppDataCardImagePlacement.left:
        final width = imageWidth ?? 120;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Stack(
              children: [
                imageWidget,
                if (_buildOverlay(
                      imageHeight: double.infinity,
                      imageWidth: width,
                    ) !=
                    null)
                  _buildOverlay(
                    imageHeight: double.infinity,
                    imageWidth: width,
                  )!,
              ],
            ),
          ),
        );
      case AppDataCardImagePlacement.right:
        final width = imageWidth ?? 120;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Stack(
              children: [
                imageWidget,
                if (_buildOverlay(
                      imageHeight: double.infinity,
                      imageWidth: width,
                    ) !=
                    null)
                  _buildOverlay(
                    imageHeight: double.infinity,
                    imageWidth: width,
                  )!,
              ],
            ),
          ),
        );
      case AppDataCardImagePlacement.background:
        return Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Stack(
                  children: [
                    imageWidget,
                    if (_buildOverlay(
                          imageHeight: constraints.maxHeight,
                          imageWidth: constraints.maxWidth,
                        ) !=
                        null)
                      _buildOverlay(
                        imageHeight: constraints.maxHeight,
                        imageWidth: constraints.maxWidth,
                      )!,
                  ],
                ),
              );
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final placement = imagePlacement ?? AppDataCardImagePlacement.top;
    final isBackground = placement == AppDataCardImagePlacement.background;

    final cardContent = Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: isBackground ? null : _backgroundColor,
        gradient: gradientColors != null && gradientColors!.length >= 2
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: variant == AppDataCardVariant.clickable
            ? AppShadows.sm
            : null,
      ),
      child: isBackground
          ? Stack(
              children: [
                _buildImage()!,
                // Only add default overlay if no custom overlay is specified
                if (overlayColor == null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                _buildCardContent(),
              ],
            )
          : _buildCardContent(),
    );

    // Build the card with image placement
    Widget finalCard;
    if (image != null) {
      final placement = imagePlacement ?? AppDataCardImagePlacement.top;
      switch (placement) {
        case AppDataCardImagePlacement.top:
          finalCard = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildImage()!, cardContent],
          );
          break;
        case AppDataCardImagePlacement.bottom:
          finalCard = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cardContent, _buildImage()!],
          );
          break;
        case AppDataCardImagePlacement.left:
          finalCard = IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage()!,
                Expanded(child: cardContent),
              ],
            ),
          );
          break;
        case AppDataCardImagePlacement.right:
          finalCard = IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cardContent),
                _buildImage()!,
              ],
            ),
          );
          break;
        case AppDataCardImagePlacement.background:
          finalCard = cardContent;
          break;
      }
    } else {
      finalCard = cardContent;
    }

    // Wrap in Material and InkWell for clickable variant
    if (variant == AppDataCardVariant.clickable && onTap != null) {
      return Semantics(
        button: true,
        enabled: true,
        label: '$title card',
        hint: 'Tap to view details',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              child: finalCard,
            ),
          ),
        ),
      );
    }

    return Semantics(label: '$title: $value', readOnly: true, child: finalCard);
  }

  /// Builds the card content based on variant
  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with title and optional icon/trailing
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText(
                title,
                variant: AppTextVariant.heading3,
                color: _secondaryTextColor,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: variant == AppDataCardVariant.gradient
                      ? Colors.white.withOpacity(0.2)
                      : (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: variant == AppDataCardVariant.gradient
                      ? Colors.white
                      : (iconColor ?? AppColors.primary),
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Value row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: AppText(
                value,
                variant: AppTextVariant.bodyMedium,
                color: _textColor,
              ),
            ),
            if (change != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: variant == AppDataCardVariant.gradient
                      ? Colors.white.withOpacity(0.2)
                      : _changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: AppText(
                  change!,
                  variant: AppTextVariant.labelSmall,
                  color: variant == AppDataCardVariant.gradient
                      ? Colors.white
                      : _changeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Shimmer loading widget for image placeholders
class _ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerWidget({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
