import 'package:flutter/material.dart';

import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'sign_up_password_screen.dart';
import 'sign_up_step_scaffold.dart';

/// Step 1: email. (Rules and copy carried over from the original app.)
class SignUpEmailScreen extends StatefulWidget {
  const SignUpEmailScreen({super.key});

  @override
  State<SignUpEmailScreen> createState() => _SignUpEmailScreenState();
}

class _SignUpEmailScreenState extends State<SignUpEmailScreen> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) => setState(() => _valid = isValidEmail(v.trim()));

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpPasswordScreen(email: _controller.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignUpStepScaffold(
      question: AppLocalizations.of(context).signUpEmailQuestion,
      canNext: _valid,
      onNext: _next,
      field: TextField(
        controller: _controller,
        onChanged: _onChanged,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        style: const TextStyle(color: Colors.black),
        decoration: signUpInputDecoration(),
      ),
    );
  }
}
