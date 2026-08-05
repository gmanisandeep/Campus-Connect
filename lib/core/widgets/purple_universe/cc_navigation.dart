import 'package:campus_connect/core/theme/purple_universe/cc_elevation.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_gradients.dart';
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ccTheme.raisedSurface,
      boxShadow: context.ccTheme.cardShadow,
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.transparent,
          destinations: [
            for (var index = 0; index < items.length; index++)
              NavigationDestination(
                icon: _NavigationIcon(
                  icon: items[index].icon,
                  orbit: items.length == 5 && index == 2,
                ),
                selectedIcon: _NavigationIcon(
                  icon: items[index].selectedIcon ?? items[index].icon,
                  orbit: items.length == 5 && index == 2,
                  selected: true,
                ),
                label: items[index].label,
              ),
          ],
        ),
      ),
    ),
  );
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({
    required this.icon,
    required this.orbit,
    this.selected = false,
  });

  final IconData icon;
  final bool orbit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!orbit) return Icon(icon);
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: CcGradients.orbitBlue,
        border: Border.all(color: context.ccTheme.raisedSurface, width: 3),
        boxShadow: CcElevation.orbit,
      ),
      child: Container(
        width: selected ? 30 : 27,
        height: selected ? 30 : 27,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.72),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.ccTheme.canvas,
      border: Border(right: BorderSide(color: context.ccTheme.borderSubtle)),
    ),
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
  );
}
