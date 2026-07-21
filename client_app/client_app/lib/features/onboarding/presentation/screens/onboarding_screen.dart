import 'dart:math' as math;

import 'package:client_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/app_routes.dart';
import '../../../../core/storage/storage_adapter.dart';
import '../../../../core/storage/storage_key_constants.dart';
import '../../../../core/utils/enums/onboarding_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFEAF6FA);
  static const _coral = Color(0xFFFF6B55);
  static const _titleColor = Color(0xFF4C5155);
  static const _bodyColor = Color(0xFF8BA0AA);

  final PageController _pageController = PageController();
  final IStorageService _storageService = GetIt.instance<IStorageService>();
  int _currentPage = 0;
  late final AnimationController _motionController;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'Send Anything Fast',
      subtitle:
          'Set pickup and drop-off. A motorbike courier handles the rest.',
    ),
    _OnboardingData(
      title: 'Watch Every Move',
      subtitle: 'Track your delivery live from pickup to arrival.',
    ),
    _OnboardingData(
      title: 'Food And Parcels',
      subtitle: 'Order meals or request city delivery from one place.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPage = index);

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await _storageService.saveData(
      StorageKeys.onboardingState,
      OnboardingState.completed.toJson(),
    );
    if (mounted) context.goNamed(AppRoutes.login.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          const _DecorativeBackground(color: _coral),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: _titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPage(
                          data: _pages[index],
                          motion: _motionController,
                        );
                      },
                    ),
                  ),
                  _PageIndicator(
                    count: _pages.length,
                    currentIndex: _currentPage,
                    color: _coral,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _NextButton(
                    isLast: _currentPage == _pages.length - 1,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 72,
          right: -118,
          child: _Circle(size: 260, color: color),
        ),
        Positioned(top: 136, left: 54, child: _Circle(size: 14, color: color)),
        Positioned(top: 420, right: 56, child: _Circle(size: 10, color: color)),
        Positioned(
          bottom: 96,
          left: -32,
          child: _Circle(size: 74, color: color),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.motion});

  final _OnboardingData data;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        final heroSize = math.min(
          constraints.maxWidth,
          constraints.maxHeight * (compact ? 0.50 : 0.56),
        );
        final heroHeight = constraints.maxHeight * (compact ? 0.48 : 0.52);

        return Column(
          children: [
            SizedBox(
              height: heroHeight,
              child: Center(
                child: _MotorbikeHero(motion: motion, size: heroSize),
              ),
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
            Text(
              data.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _OnboardingScreenState._titleColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _OnboardingScreenState._bodyColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}

class _MotorbikeHero extends StatelessWidget {
  const _MotorbikeHero({required this.motion, required this.size});

  static const _motorAsset = 'assets/images/generated/onboarding_motorbike.png';

  final Animation<double> motion;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        final cycle = motion.value * math.pi * 2;
        final bob = math.sin(cycle) * 2;
        final tilt = math.sin(cycle * 0.9) * 0.06;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: size * 0.06,
                child: CustomPaint(
                  size: Size.square(size * 0.78),
                  painter: _ArcPainter(progress: motion.value),
                ),
              ),
              Positioned(
                top: size * 0.12 + bob,
                child: Transform.rotate(
                  angle: tilt,
                  child: Image.asset(
                    _motorAsset,
                    width: size * 0.68,
                    height: size * 0.72,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..color = const Color(0xFFDCE8EC)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    final activePaint = Paint()
      ..color = _OnboardingScreenState._coral
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas
      ..drawArc(rect, -math.pi * 0.10, math.pi * 1.25, false, basePaint)
      ..drawArc(
        rect,
        -math.pi * 1.05 + progress * math.pi * 2,
        math.pi * 0.48,
        false,
        activePaint,
      );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentIndex,
    required this.color,
  });

  final int count;
  final int currentIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 22 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFD4E0E5),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.isLast, required this.onPressed});

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _OnboardingScreenState._coral,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: _OnboardingScreenState._coral.withValues(alpha: 0.38),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Icon(
          isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
          size: 28,
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
