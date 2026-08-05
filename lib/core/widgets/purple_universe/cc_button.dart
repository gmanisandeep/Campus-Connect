import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
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

    return SizedBox(
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
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
  Widget build(BuildContext context) => SizedBox(
    width: expand ? double.infinity : null,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
    ),
  );
}
