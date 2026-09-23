import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'sign_up_data.dart';
import 'sign_up_gender_screen.dart';
import 'sign_up_step_scaffold.dart';

/// Step 3: date of birth. (Copy carried over from the original app.)
class SignUpBirthDateScreen extends StatefulWidget {
  const SignUpBirthDateScreen({super.key, required this.data});

  final SignUpData data;

  @override
  State<SignUpBirthDateScreen> createState() => _SignUpBirthDateScreenState();
}

class _SignUpBirthDateScreenState extends State<SignUpBirthDateScreen> {
  // Minimum age to sign up (GDPR default). Under this, sign-up is blocked.
  static const int _minAge = 16;

  final _controller = TextEditingController();
  DateTime? _date;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Full years old today for a birth date [d].
  int _ageOn(DateTime d) {
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(DateTime.now().year - _minAge),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      final tooYoung = _ageOn(picked) < _minAge;
      setState(() {
        _date = picked;
        _controller.text = '${picked.year}-$m-$d';
        _error = tooYoung
            ? AppLocalizations.of(context).signUpAgeRestriction(_minAge)
            : null;
      });
    }
  }

  void _next() {
    widget.data.birthDate = _date;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SignUpGenderScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignUpStepScaffold(
      question: l.signUpBirthDateQuestion,
      errorText: _error,
      canNext: _date != null && _error == null,
      onNext: _next,
      field: TextField(
        controller: _controller,
        readOnly: true,
        onTap: _selectDate,
        style: const TextStyle(color: Colors.black),
        decoration: signUpInputDecoration(hint: l.signUpBirthDateHint),
      ),
    );
  }
}
