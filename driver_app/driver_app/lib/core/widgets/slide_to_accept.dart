import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An intentional full-width gesture. Network completion is owned by the caller.
class SlideToAccept extends StatefulWidget {
  const SlideToAccept({
    required this.onAccept,
    this.enabled = true,
    this.label = 'Slide to accept',
    super.key,
  });
  final Future<void> Function() onAccept;
  final bool enabled;
  final String label;
  @override
  State<SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<SlideToAccept> {
  double _progress = 0;
  bool _submitting = false;
  Future<void> _accept() async {
    if (!widget.enabled || _submitting) return;
    setState(() {
      _submitting = true;
      _progress = 1;
    });
    HapticFeedback.mediumImpact();
    try {
      await widget.onAccept();
    } finally {
      if (mounted)
        setState(() {
          _submitting = false;
          _progress = 0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !_submitting;
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: widget.label,
      hint: 'Drag the handle all the way to accept this delivery',
      button: true,
      enabled: active,
      // Assistive technology has an explicit activation action.
      onTap: active ? _accept : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = (constraints.maxWidth - 64).clamp(
            1.0,
            double.infinity,
          );
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return Container(
            height: 64,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.16 : 0.06),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Text(
                    _submitting ? 'Accepting…' : widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                PositionedDirectional(
                  start: _progress * travel,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragUpdate: active
                        ? (details) => setState(() {
                            _progress =
                                (_progress +
                                        details.delta.dx *
                                            (rtl ? -1 : 1) /
                                            travel)
                                    .clamp(0.0, 1.0);
                          })
                        : null,
                    onHorizontalDragEnd: active
                        ? (_) {
                            if (_progress >= 0.94) {
                              _accept();
                            } else {
                              setState(() => _progress = 0);
                            }
                          }
                        : null,
                    onHorizontalDragCancel: () => setState(() => _progress = 0),
                    child: Container(
                      width: 54,
                      decoration: BoxDecoration(
                        color: active ? color : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: _submitting
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              rtl
                                  ? Icons.keyboard_double_arrow_left
                                  : Icons.keyboard_double_arrow_right,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
