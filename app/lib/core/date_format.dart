import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// A locale-aware date label that includes the year, e.g. "2026년 6월 30일"
/// (ko) or "Jun 30, 2026" (en). [DateFormat.yMMMd] rather than a fixed pattern,
/// so field order and separators follow the active locale.
String formatPhotoDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date);
}

/// A short relative age ("now", "5m", "3h", "2d", "1w") for comments and the
/// recent-post cards.
String formatAgo(AppLocalizations l, DateTime time, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(time);
  if (d.inMinutes < 1) return l.timeNow;
  if (d.inMinutes < 60) return l.timeMinutesShort(d.inMinutes);
  if (d.inHours < 24) return l.timeHoursShort(d.inHours);
  if (d.inDays < 7) return l.timeDaysShort(d.inDays);
  return l.timeWeeksShort(d.inDays ~/ 7);
}
