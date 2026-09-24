import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/date_format.dart';
import 'package:waylo/l10n/app_localizations.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);
  String ago(AppLocalizations l, Duration d) =>
      formatAgo(l, now.subtract(d), now: now);

  test('formatAgo picks the largest whole unit', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(ago(en, const Duration(seconds: 30)), 'now');
    expect(ago(en, const Duration(minutes: 5)), '5m');
    expect(ago(en, const Duration(minutes: 59)), '59m');
    expect(ago(en, const Duration(hours: 3)), '3h');
    expect(ago(en, const Duration(hours: 23, minutes: 59)), '23h');
    expect(ago(en, const Duration(days: 2)), '2d');
    expect(ago(en, const Duration(days: 6)), '6d');
    expect(ago(en, const Duration(days: 7)), '1w');
    expect(ago(en, const Duration(days: 20)), '2w');
  });

  test('formatAgo is localized', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    expect(ago(ko, const Duration(hours: 3)), '3시간');
  });
}
