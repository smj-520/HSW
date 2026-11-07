import 'package:flutter/material.dart';

import 'category_icons.dart';
import 'nav_icons.dart';

Map<String, String> get kAppIconSvgs => {
      ...kCategoryIconSvgs,
      'nav_home': kNavIconSvgs['home']!,
      'nav_transactions': kNavIconSvgs['transactions']!,
      'nav_add': kNavIconSvgs['add']!,
      'nav_report': kNavIconSvgs['report']!,
      'nav_settings': kNavIconSvgs['settings']!,
    };

String appIconSvg(String id, Color color) {
  final svg = kAppIconSvgs[id] ?? kCategoryIconSvgs[id];
  assert(svg != null, 'No icon for id: $id');
  if (svg == null) {
    throw StateError('No icon for id: $id');
  }
  final hex =
      '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
  return svg.replaceAll('{{C}}', hex);
}
