import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'sign_up_data.dart';
import 'sign_up_step_scaffold.dart';
import 'sign_up_username_screen.dart';

/// Step 4: gender. (Options and copy carried over from the original app.)
class SignUpGenderScreen extends StatefulWidget {
  const SignUpGenderScreen({super.key, required this.data});

  final SignUpData data;

  @override
  State<SignUpGenderScreen> createState() => _SignUpGenderScreenState();
}

class _SignUpGenderScreenState extends State<SignUpGenderScreen> {
  // Canonical values stored to the profile. These stay English regardless of
  // the UI language so the database holds a stable, language-independent value;
  // only the displayed label is localized (see _genderLabel).
  static const _options = <String>[
    'Male',
    'Female',
    'Non-binary',
    'Other',
    'Prefer not to say',
  ];

  String? _selected;

  String _genderLabel(AppLocalizations l, String value) => switch (value) {
    'Male' => l.genderMale,
    'Female' => l.genderFemale,
    'Non-binary' => l.genderNonBinary,
    'Other' => l.genderOther,
    'Prefer not to say' => l.genderPreferNotToSay,
    _ => value,
  };

  void _next() {
    widget.data.gender = _selected;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpUsernameScreen(data: widget.data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignUpStepScaffold(
      question: l.signUpGenderQuestion,
      canNext: _selected != null,
      onNext: _next,
      field: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selected,
            isExpanded: true,
            hint: Text(
              l.signUpGenderSelect,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            items: _options
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(
                      _genderLabel(l, g),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
        ),
      ),
    );
  }
}
