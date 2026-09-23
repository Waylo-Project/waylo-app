import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A locale-aware date label that includes the year, e.g. "2026년 6월 30일"
/// (ko) or "Jun 30, 2026" (en).
///
/// We deliberately use [DateFormat.yMMMd] rather than a hardcoded pattern: the
/// field order and separators follow the active locale, so each country gets
/// its natural format. (The old `formatMediumDate` dropped the year in every
/// locale, which read oddly — "6월 30일" with no year.)
String formatPhotoDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date);
}
