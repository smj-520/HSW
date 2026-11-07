import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/categories.dart';
import '../constants/category_icons.dart';

String colorToHex(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

Color categoryTileColor(String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) {
    return const Color(0xFF27AE60);
  }
  final cat = expenseCategoryById(categoryIconKey(categoryId));
  assert(cat != null, 'No tile color for category id: $categoryId');
  return cat?.color ?? const Color(0xFFF2672D);
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(
    this.categoryId,
    this.color,
    this.size, {
    super.key,
    this.badgePercent,
    this.selected = false,
  });

  final String categoryId;
  final Color color;
  final double size;
  final int? badgePercent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final svg = categoryIconSvg(categoryId);
    final filled = svg.replaceAll('{{C}}', colorToHex(color));
    final radius = size * 0.31;
    final glyphPad = size * 0.22;
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(glyphPad),
        child: SvgPicture.string(
          filled,
          fit: BoxFit.contain,
          allowDrawingOutsideViewBox: true,
        ),
      ),
    );

    Widget body = tile;
    if (badgePercent != null) {
      final badgeSize = (size * 0.38).clamp(16.0, 22.0);
      body = SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 0, bottom: 0, child: tile),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(minWidth: badgeSize),
                height: badgeSize,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  '$badgePercent%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badgeSize * 0.42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Transform.scale(
      scale: selected ? 1.15 : 1,
      child: body,
    );
  }
}
