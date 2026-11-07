import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/categories.dart';
import '../constants/category_icons.dart';
import 'category_icon.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.size,
    this.percent,
    this.badgeColor,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  final ExpenseCategory category;
  final double size;
  final int? percent;
  final Color? badgeColor;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.33;
    final glyph = size * 0.62;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final svg = categoryIconSvg(category.id).replaceAll(
      '{{C}}',
      colorToHex(category.color),
    );

    Widget tile = AnimatedScale(
      scale: selected ? 1.12 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: glyph,
          height: glyph,
          child: SvgPicture.string(svg, fit: BoxFit.contain),
        ),
      ),
    );

    if (percent != null) {
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor ?? category.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: category.label(context),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size + 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              const SizedBox(height: 4),
              Text(
                category.shortLabel(context),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: muted,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
