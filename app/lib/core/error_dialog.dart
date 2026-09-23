import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows a minimal error dialog with a single confirm button.
///
/// Replaces the old error snackbars: a failure now surfaces as an explicit,
/// dismissible message the user has to acknowledge, instead of a transient
/// toast that can be missed. Success/confirmation messages are intentionally
/// silent — the screen itself already reflects the result.
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
