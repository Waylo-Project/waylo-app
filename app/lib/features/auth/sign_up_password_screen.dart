import 'package:flutter/material.dart';

import '../../core/validators.dart';
import '../../l10n/app_localizations.dart';
import 'sign_up_birth_date_screen.dart';
import 'sign_up_data.dart';
import 'sign_up_step_scaffold.dart';

/// Step 2: password. At least 10 characters and must include both letters and
/// numbers; other characters (symbols) are allowed.
class SignUpPasswordScreen extends StatefulWidget {
  const SignUpPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<SignUpPasswordScreen> createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPasswordScreen> {
  final _controller = TextEditingController();
  bool _valid = false;
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) =>
      setState(() => _valid = isValidPassword(v));

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpBirthDateScreen(
          data: SignUpData(email: widget.email, password: _controller.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignUpStepScaffold(
      question: l.signUpPasswordQuestion,
      requirements: l.signUpPasswordRequirements,
      canNext: _valid,
      onNext: _next,
      field: TextField(
        controller: _controller,
        onChanged: _onChanged,
        obscureText: _obscure,
        style: const TextStyle(color: Colors.black),
        decoration: signUpInputDecoration(
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}
