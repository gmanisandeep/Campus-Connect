import 'package:campus_connect/core/theme/purple_universe/cc_radius.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:flutter/material.dart';

@immutable
class CcNavigationItem {
  const CcNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class CcNavigationBar extends StatelessWidget {
  const CcNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<CcNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(
      CcSpacing.sm,
      CcSpacing.xxs,
      CcSpacing.sm,
      CcSpacing.sm,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.ccTheme.glassSurface,
        borderRadius: BorderRadius.circular(CcRadius.prominent),
        border: Border.all(
          color: Color.alphaBlend(
            context.ccTheme.glowCyan.withValues(alpha: 0.18),
            context.ccTheme.borderSubtle,
          ),
        ),
        boxShadow: context.ccTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CcRadius.prominent),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.transparent,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: item.label,
              ),
          ],
        ),
      ),
    ),
  );
}

class CcNavigationRail extends StatelessWidget {
  const CcNavigationRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.leading,
    this.trailing,
    this.extended = false,
    super.key,
  });

  final List<CcNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? leading;
  final Widget? trailing;
  final bool extended;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(CcSpacing.sm),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.ccTheme.glassSurface,
        borderRadius: BorderRadius.circular(CcRadius.prominent),
        border: Border.all(color: context.ccTheme.borderSubtle),
        boxShadow: context.ccTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CcRadius.prominent),
        child: NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          extended: extended,
          minWidth: 76,
          minExtendedWidth: 232,
          groupAlignment: -0.72,
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.selected,
          backgroundColor: Colors.transparent,
          leading: leading == null
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CcSpacing.sm,
                    CcSpacing.md,
                    CcSpacing.sm,
                    CcSpacing.xl,
                  ),
                  child: leading,
                ),
          trailing: trailing,
          destinations: [
            for (final item in items)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ),
          ],
        ),
      ),
    ),
  );
}
