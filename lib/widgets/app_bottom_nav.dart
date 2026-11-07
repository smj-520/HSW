import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/nav_colors.dart';
import '../constants/nav_icons.dart';
import '../services/app_i18n.dart';

class NavBarItem {
  const NavBarItem({
    required this.iconKey,
    required this.color,
    required this.label,
    this.big = false,
  });

  final String iconKey;
  final Color color;
  final String label;
  final bool big;
}

class NavTile extends StatelessWidget {
  const NavTile({
    super.key,
    required this.iconKey,
    required this.color,
    required this.label,
    required this.selected,
    this.big = false,
    this.onTap,
  });

  final String iconKey;
  final Color color;
  final String label;
  final bool selected;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final size = big ? (tablet ? 56.0 : 50.0) : (tablet ? 44.0 : 38.0);
    final radius = big ? 18.0 : 13.0;
    final labelColor = selected ? color : scheme.onSurfaceVariant;
    final surface = scheme.surface;

    Widget tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.all(size * 0.20),
      child: SvgPicture.string(
        navIconSvg(iconKey, color),
        fit: BoxFit.contain,
      ),
    );

    if (selected) {
      tile = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius + 4),
          border: Border.all(color: color, width: 2),
        ),
        child: tile,
      );
    }

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: selected ? 1 : 0.92,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: tile,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: tablet ? 12 : 11,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: labelColor,
            height: 1.1,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: big ? const Offset(0, -16) : Offset.zero,
        child: body,
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<NavBarItem> items;

  factory AppBottomNav.admin({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onSelected,
  }) {
    return AppBottomNav(
      currentIndex: currentIndex,
      onSelected: onSelected,
      items: [
        NavBarItem(
          iconKey: 'home',
          color: NavColors.home,
          label: AppI18n.t(context, en: 'Home', ar: 'الرئيسية'),
        ),
        NavBarItem(
          iconKey: 'user',
          color: NavColors.user,
          label: AppI18n.t(context, en: 'User', ar: 'المستخدم'),
        ),
        NavBarItem(
          iconKey: 'biller',
          color: NavColors.biller,
          label: AppI18n.t(context, en: 'Biller', ar: 'الجهة'),
        ),
        NavBarItem(
          iconKey: 'report',
          color: NavColors.report,
          label: AppI18n.t(context, en: 'Report', ar: 'التقرير'),
        ),
        NavBarItem(
          iconKey: 'feedback',
          color: NavColors.feedback,
          label: AppI18n.t(context, en: 'Feedback', ar: 'الملاحظات'),
        ),
      ],
    );
  }

  factory AppBottomNav.student({
    required BuildContext context,
    required int currentIndex,
    required ValueChanged<int> onSelected,
  }) {
    return AppBottomNav(
      currentIndex: currentIndex,
      onSelected: onSelected,
      items: [
        NavBarItem(
          iconKey: 'home',
          color: NavColors.home,
          label: AppI18n.t(context, en: 'Home', ar: 'الرئيسية'),
        ),
        NavBarItem(
          iconKey: 'transactions',
          color: NavColors.transactions,
          label: AppI18n.t(context, en: 'Transactions', ar: 'المعاملات'),
        ),
        NavBarItem(
          iconKey: 'add',
          color: NavColors.add,
          label: AppI18n.t(context, en: 'Add', ar: 'إضافة'),
          big: true,
        ),
        NavBarItem(
          iconKey: 'report',
          color: NavColors.report,
          label: AppI18n.t(context, en: 'Report', ar: 'التقرير'),
        ),
        NavBarItem(
          iconKey: 'settings',
          color: NavColors.settings,
          label: AppI18n.t(context, en: 'Setting', ar: 'الإعدادات'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final hasBig = items.any((item) => item.big);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tablet ? 20 : 12,
            hasBig ? 18 : 8,
            tablet ? 20 : 12,
            4,
          ),
          child: Container(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.55),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: NavTile(
                      iconKey: items[i].iconKey,
                      color: items[i].color,
                      label: items[i].label,
                      selected: currentIndex == i,
                      big: items[i].big,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
