import 'package:flutter/material.dart';

abstract final class AdminHomeColors {
  static const Color user = Color(0xFF2E9E5B);
  static const Color biller = Color(0xFF1E9E8F);
  static const Color report = Color(0xFF6AB82E);
  static const Color feedback = Color(0xFF12805C);
}

const Map<String, String> kAdminHomeGlyphs = {
  'user':
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4.2" fill="#fff"/><path d="M4 21a8 8 0 0 1 16 0Z" fill="#fff"/></svg>',
  'biller':
      '<svg viewBox="0 0 24 24"><path d="M6 3H18V21L15 19L12 21L9 19L6 21Z" fill="#fff"/><path d="M9 8h6M9 11.5h6M9 15h3" stroke="{{C}}" stroke-width="1.5" stroke-linecap="round"/></svg>',
  'report':
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="#fff" fill-opacity=".55"/><path d="M12 12V3A9 9 0 0 1 21 12Z" fill="#fff"/><path d="M12 12V21" stroke="{{C}}" stroke-width="1.2" opacity=".6"/></svg>',
  'feedback':
      '<svg viewBox="0 0 24 24"><path d="M5 4H19A2 2 0 0 1 21 6V15A2 2 0 0 1 19 17H11L6 21V17H5A2 2 0 0 1 3 15V6A2 2 0 0 1 5 4Z" fill="#fff"/><path d="M12 7.2l1.1 2.3 2.5.3-1.8 1.7.5 2.5L12 12.8l-2.3 1.2.5-2.5-1.8-1.7 2.5-.3Z" fill="{{C}}"/></svg>',
};

String adminHomeGlyphSvg(String key, Color color) {
  final svg = kAdminHomeGlyphs[key];
  assert(svg != null, 'No admin home glyph for key: $key');
  if (svg == null) {
    throw StateError('No admin home glyph for key: $key');
  }
  final hex =
      '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
  return svg.replaceAll('{{C}}', hex);
}
