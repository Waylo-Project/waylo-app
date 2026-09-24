import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows a minimal error dialog with a single confirm button — the app's one
/// way to surface a failure, so it can't be missed. Successes stay silent; the
/// screen itself reflects the result.
Future<void> showErrorDialog(BuildContext context, String message) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.commonGotIt),
        ),
      ],
    ),
  );
}
