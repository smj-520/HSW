import 'categories.dart';

const String _hostelFees =
    '<svg viewBox="0 0 24 24"><path d="M12 3L21 11V21H3V11Z" fill="#fff"/><rect x="10" y="14" width="4" height="7" rx="1" fill="{{C}}"/><rect x="5.5" y="12" width="2.5" height="2.5" rx=".6" fill="{{C}}"/><rect x="16" y="12" width="2.5" height="2.5" rx=".6" fill="{{C}}"/></svg>';

const String _messFood =
    '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="7" fill="#fff"/><circle cx="12" cy="12" r="4" fill="none" stroke="{{C}}" stroke-width="1.6"/><path d="M3 4v16M20.8 4v16" stroke="#fff" stroke-width="2" stroke-linecap="round"/></svg>';

const String _laundry =
    '<svg viewBox="0 0 24 24"><rect x="4" y="3" width="16" height="18" rx="3" fill="#fff"/><circle cx="12" cy="13.5" r="5" fill="{{C}}"/><path d="M9.5 13.5q1.2-1.5 2.5 0t2.5 0" stroke="#fff" stroke-width="1.3" fill="none" stroke-linecap="round"/><circle cx="7.5" cy="6.5" r="1" fill="{{C}}"/><circle cx="10.5" cy="6.5" r="1" fill="{{C}}"/></svg>';

const String _transport =
    '<svg viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="14" rx="3" fill="#fff"/><rect x="6.5" y="6.5" width="11" height="5" rx="1.2" fill="{{C}}"/><circle cx="8" cy="15" r="1.2" fill="{{C}}"/><circle cx="16" cy="15" r="1.2" fill="{{C}}"/><rect x="6" y="18" width="3" height="3" rx="1" fill="#fff"/><rect x="15" y="18" width="3" height="3" rx="1" fill="#fff"/></svg>';

const String _study =
    '<svg viewBox="0 0 24 24"><path d="M3 6Q8 4 12 7V20Q8 17 3 19Z" fill="#fff"/><path d="M21 6Q16 4 12 7V20Q16 17 21 19Z" fill="#fff" fill-opacity=".72"/><path d="M12 7V20" stroke="{{C}}" stroke-width="1.2"/><path d="M5.5 9.5q2 0 4 1M5.5 12.5q2 0 4 1" stroke="{{C}}" stroke-width="1" stroke-linecap="round" fill="none"/></svg>';

const String _mobile =
    '<svg viewBox="0 0 24 24"><rect x="7" y="2.5" width="10" height="19" rx="2.8" fill="#fff"/><rect x="9" y="5" width="6" height="11" rx="1" fill="{{C}}"/><circle cx="12" cy="19" r=".9" fill="{{C}}"/><path d="M10.2 10.5a2.6 2.6 0 0 1 3.6 0M11 12.6a1.4 1.4 0 0 1 2 0" stroke="#fff" stroke-width="1" fill="none" stroke-linecap="round"/></svg>';

const String _health =
    '<svg viewBox="0 0 24 24"><rect x="9" y="3" width="6" height="18" rx="2" fill="#fff"/><rect x="3" y="9" width="18" height="6" rx="2" fill="#fff"/><circle cx="12" cy="12" r="1.8" fill="{{C}}"/></svg>';

const String _personalCare =
    '<svg viewBox="0 0 24 24"><path d="M12 3C12 3 5 11 5 15a7 7 0 0 0 14 0C19 11 12 3 12 3Z" fill="#fff"/><path d="M9 15a3 3 0 0 0 3 3" stroke="{{C}}" stroke-width="1.6" fill="none" stroke-linecap="round"/><circle cx="19.5" cy="5" r="1.5" fill="#fff" fill-opacity=".75"/><circle cx="4.5" cy="6.5" r="1" fill="#fff" fill-opacity=".75"/></svg>';

const String _entertainment =
    '<svg viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="11" rx="5.5" fill="#fff"/><path d="M7 10.5v4M5 12.5h4" stroke="{{C}}" stroke-width="1.8" stroke-linecap="round"/><circle cx="16" cy="11.5" r="1.3" fill="{{C}}"/><circle cx="18.5" cy="14" r="1.3" fill="{{C}}"/></svg>';

const String _giftsFamily =
    '<svg viewBox="0 0 24 24"><rect x="4" y="10" width="16" height="11" rx="2" fill="#fff"/><rect x="3" y="7" width="18" height="4" rx="1.5" fill="#fff" fill-opacity=".72"/><rect x="11" y="7" width="2" height="14" fill="{{C}}"/><path d="M12 7C9 2.5 6 4.5 8 7ZM12 7C15 2.5 18 4.5 16 7Z" fill="#fff"/></svg>';

const String _groceries =
    '<svg viewBox="0 0 24 24"><path d="M8 10L12 4L16 10" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M3.5 10H20.5L18.5 20H5.5Z" fill="#fff"/><path d="M9 13v4M12 13v4M15 13v4" stroke="{{C}}" stroke-width="1.5" stroke-linecap="round"/></svg>';

const String _emergency =
    '<svg viewBox="0 0 24 24"><path d="M6 18V12a6 6 0 0 1 12 0V18Z" fill="#fff"/><rect x="4" y="18" width="16" height="3" rx="1.2" fill="#fff"/><path d="M9.5 12a2.5 2.5 0 0 1 2.5-2.5" stroke="{{C}}" stroke-width="1.6" fill="none" stroke-linecap="round"/><path d="M12 2v2M4.5 5l1.5 1.5M19.5 5L18 6.5" stroke="#fff" stroke-width="1.6" stroke-linecap="round"/></svg>';

const Map<String, String> kCategoryIconSvgs = {
  'hostel_fees': _hostelFees,
  'mess_food': _messFood,
  'laundry': _laundry,
  'transport': _transport,
  'study': _study,
  'mobile': _mobile,
  'health': _health,
  'personal_care': _personalCare,
  'entertainment': _entertainment,
  'gifts_family': _giftsFamily,
  'groceries': _groceries,
  'emergency': _emergency,
};

String categoryIconKey(String categoryId) {
  final key = normalizeExpenseCategoryId(categoryId);
  assert(
    kCategoryIconSvgs.containsKey(key),
    'No icon for category id: $categoryId (key: $key)',
  );
  return key;
}

String categoryIconSvg(String categoryId) {
  final key = categoryIconKey(categoryId);
  final svg = kCategoryIconSvgs[key];
  assert(svg != null, 'No icon for category id: $categoryId (key: $key)');
  if (svg == null) {
    throw StateError('No icon for category id: $categoryId');
  }
  return svg;
}
