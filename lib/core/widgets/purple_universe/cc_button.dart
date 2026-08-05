import 'package:campus_connect/core/theme/purple_universe/cc_motion.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

class CcPrimaryButton extends StatelessWidget {
  const CcPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: '$label in progress',
                liveRegion: true,
                child: const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: CcSpacing.sm),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(width: CcSpacing.xs),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    return _CcPressable(
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      ),
    );
  }
}

class CcSecondaryButton extends StatelessWidget {
  const CcSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) => _CcPressable(
    enabled: onPressed != null,
    subtle: true,
    child: SizedBox(
      width: expand ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    ),
  );
}

class _CcPressable extends StatefulWidget {
  const _CcPressable({
    required this.child,
    required this.enabled,
    this.subtle = false,
  });

  final Widget child;
  final bool enabled;
  final bool subtle;

  @override
  State<_CcPressable> createState() => _CcPressableState();
}

class _CcPressableState extends State<_CcPressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final active = widget.enabled && (_hovered || _pressed);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onPointerUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onPointerCancel: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: reduceMotion
              ? 1
              : _pressed
              ? 0.985
              : _hovered && widget.enabled
              ? 1.008
              : 1,
          duration: reduceMotion ? Duration.zero : CcMotionDurations.quick,
          curve: CcMotionCurves.soft,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : CcMotionDurations.quick,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: !active || widget.subtle
                  ? const <BoxShadow>[]
                  : [
                      BoxShadow(
                        color: context.ccTheme.glowPrimary.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 20,
                        spreadRadius: -6,
                      ),
                    ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
