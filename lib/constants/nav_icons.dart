import 'package:flutter/material.dart';

const Map<String, String> kNavIconSvgs = {
  'home':
      '<svg viewBox="0 0 24 24"><path d="M12 3L21 11V21H3V11Z" fill="#fff"/><rect x="10" y="14" width="4" height="7" rx="1" fill="{{C}}"/><rect x="16" y="4" width="2.5" height="5" rx=".8" fill="#fff"/></svg>',
  'user':
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4.2" fill="#fff"/><path d="M4 21a8 8 0 0 1 16 0Z" fill="#fff"/></svg>',
  'biller':
      '<svg viewBox="0 0 24 24"><path d="M6 3H18V21L15 19L12 21L9 19L6 21Z" fill="#fff"/><path d="M9 8h6M9 11.5h6M9 15h3" stroke="{{C}}" stroke-width="1.5" stroke-linecap="round"/></svg>',
  'report':
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="#fff" fill-opacity=".55"/><path d="M12 12V3A9 9 0 0 1 21 12Z" fill="#fff"/><path d="M12 12V21" stroke="{{C}}" stroke-width="1.2" opacity=".6"/></svg>',
  'feedback':
      '<svg viewBox="0 0 24 24"><path d="M5 4H19A2 2 0 0 1 21 6V15A2 2 0 0 1 19 17H11L6 21V17H5A2 2 0 0 1 3 15V6A2 2 0 0 1 5 4Z" fill="#fff"/><path d="M12 7.2l1.1 2.3 2.5.3-1.8 1.7.5 2.5L12 12.8l-2.3 1.2.5-2.5-1.8-1.7 2.5-.3Z" fill="{{C}}"/></svg>',
  'transactions':
      '<svg viewBox="0 0 24 24"><path d="M16 20V7M11.5 11.5L16 7l4.5 4.5" stroke="#fff" stroke-width="2.3" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 4v13M3.5 12.5L8 17l4.5-4.5" stroke="#fff" stroke-width="2.3" fill="none" stroke-linecap="round" stroke-linejoin="round" opacity=".7"/></svg>',
  'add':
      '<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" stroke="#fff" stroke-width="3" stroke-linecap="round"/></svg>',
  'settings':
      '<svg viewBox="0 0 24 24"><g fill="#fff"><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(45 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(90 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(135 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(180 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(225 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(270 12 12)"/><rect x="10.4" y="2.5" width="3.2" height="4.5" rx="1" transform="rotate(315 12 12)"/><circle cx="12" cy="12" r="6.6"/></g><circle cx="12" cy="12" r="2.7" fill="{{C}}"/></svg>',
};

String navIconSvg(String key, Color color) {
  final svg = kNavIconSvgs[key];
  assert(svg != null, 'No nav icon for key: $key');
  if (svg == null) {
    throw StateError('No nav icon for key: $key');
  }
  final hex = '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
  return svg.replaceAll('{{C}}', hex);
}
