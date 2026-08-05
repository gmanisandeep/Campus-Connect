import 'dart:async';

import 'package:campus_connect/core/theme/purple_universe/cc_motion.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

/// A performance-bounded, Flutter-native interpretation of a spotlight card.
///
/// The light only follows an active pointer. It never runs an idle animation,
/// uses no backdrop filter, and becomes an ordinary static surface when the
/// platform requests reduced motion.
class CcSpotlightSurface extends StatefulWidget {
  const CcSpotlightSurface({
    required this.child,
    this.padding = const EdgeInsets.all(CcSpacing.lg),
    this.onTap,
    this.semanticLabel,
    this.prominent = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool prominent;

  @override
  State<CcSpotlightSurface> createState() => _CcSpotlightSurfaceState();
}

class _CcSpotlightSurfaceState extends State<CcSpotlightSurface> {
  Offset? _pointer;
  double _width = 1;

  void _updatePointer(Offset position) {
    setState(() => _pointer = position);
  }

  void _clearPointer() {
    if (_pointer != null) setState(() => _pointer = null);
  }

  @override
  Widget build(BuildContext context) {
    final ccTheme = context.ccTheme;
    final radius = BorderRadius.circular(
      widget.prominent ? CcRadius.prominent : CcRadius.card,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final activePointer = reduceMotion ? null : _pointer;
    final alignment = activePointer == null
        ? const Alignment(-0.85, -0.9)
        : Alignment(
            ((activePointer.dx / _width) * 2 - 1).clamp(-1.0, 1.0),
            -0.72,
          );

    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1;
        return RepaintBoundary(
          child: MouseRegion(
            onHover: (event) => _updatePointer(event.localPosition),
            onExit: (_) => _clearPointer(),
            child: Listener(
              onPointerDown: (event) => _updatePointer(event.localPosition),
              onPointerUp: (_) => _clearPointer(),
              onPointerCancel: (_) => _clearPointer(),
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : CcMotionDurations.standard,
                curve: CcMotionCurves.soft,
                decoration: BoxDecoration(
                  color: ccTheme.surface,
                  borderRadius: radius,
                  border: Border.all(
                    color: activePointer == null
                        ? ccTheme.borderSubtle
                        : Color.alphaBlend(
                            ccTheme.glowCyan.withValues(alpha: 0.34),
                            ccTheme.borderActive,
                          ),
                  ),
                  boxShadow: activePointer == null
                      ? const <BoxShadow>[]
                      : [
                          BoxShadow(
                            color: ccTheme.glowPrimary.withValues(alpha: 0.12),
                            blurRadius: 24,
                            spreadRadius: -8,
                          ),
                        ],
                  gradient: RadialGradient(
                    center: alignment,
                    radius: activePointer == null ? 1.35 : 0.95,
                    colors: [
                      Color.alphaBlend(
                        ccTheme.glowCyan.withValues(
                          alpha: activePointer == null ? 0.08 : 0.16,
                        ),
                        ccTheme.surface,
                      ),
                      Color.alphaBlend(
                        ccTheme.glowPrimary.withValues(alpha: 0.045),
                        ccTheme.surface,
                      ),
                      ccTheme.surface,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Padding(
                        padding: widget.padding,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.semanticLabel != null) {
      result = Semantics(
        container: true,
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: result,
      );
    }
    return result;
  }
}

/// Reveals content once when it enters the tree. Reduced-motion users receive
/// the same content immediately.
class CcReveal extends StatefulWidget {
  const CcReveal({
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.035),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<CcReveal> createState() => _CcRevealState();
}

class _CcRevealState extends State<CcReveal>
    with SingleTickerProviderStateMixin {
  bool _scheduled = false;
  Timer? _timer;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CcMotionDurations.comfortable,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: CcMotionCurves.decelerate,
  );
  late final Animation<Offset> _position = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: CcMotionCurves.soft));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_scheduled && !_controller.isCompleted) {
      _scheduled = true;
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        _timer = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _position, child: widget.child),
  );
}
