import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/profile_repository.dart';
import '../../l10n/app_localizations.dart';
import 'sign_up_data.dart';
import 'sign_up_step_scaffold.dart';

/// Step 5 (final): username. Rules/copy carried over from the original app.
/// This is where the account is actually created: sign up (email + password
/// collected earlier), then insert the profile with the collected fields.
class SignUpUsernameScreen extends StatefulWidget {
  const SignUpUsernameScreen({super.key, required this.data});

  final SignUpData data;

  @override
  State<SignUpUsernameScreen> createState() => _SignUpUsernameScreenState();
}

class _SignUpUsernameScreenState extends State<SignUpUsernameScreen> {
  // Lowercase only (a-z, 0-9, . _), 2-30 chars, no leading/trailing or repeated
  // punctuation. Uppercase is auto-lowercased by the input formatter below, so a
  // username is always stored lowercase (no "John" vs "john" collisions).
  static final _usernameRegex =
      RegExp(r"^[a-z0-9](?!.*\.\.)(?!.*__)[a-z0-9._]{0,28}[a-z0-9]$");

  final _controller = TextEditingController();
  final _repo = ProfileRepository();
  bool _valid = false;
  bool _loading = false;
  bool _signedUp = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) =>
      setState(() => _valid = _usernameRegex.hasMatch(v));

  Future<void> _finish() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Supabase.instance.client.auth;
    try {
      // Create the auth account once (email + password from earlier steps).
      if (!_signedUp) {
        final res = await auth.signUp(
          email: widget.data.email,
          password: widget.data.password,
        );
        if (res.session == null) {
          setState(() => _error = l.signUpConfirmEmailNotice);
          return;
        }
        _signedUp = true;
      }
      await _repo.createMyProfile(
        username: _controller.text,
        gender: widget.data.gender,
        birthDate: widget.data.birthDate,
      );
      // Arm the one-time "tap + to post" coach mark on the home map (new
      // sign-ups only). Cleared once the map shows it.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_post_guide', true);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on UsernameTakenException {
      if (mounted) setState(() => _error = l.signUpUsernameTaken);
    } on SessionInvalidException {
      await auth.signOut();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.commonSomethingWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SignUpStepScaffold(
      question: l.signUpUsernameQuestion,
      requirements: l.signUpUsernameRequirements,
      errorText: _error,
      canNext: _valid,
      loading: _loading,
      onNext: _finish,
      field: TextField(
        controller: _controller,
        onChanged: _onChanged,
        autocorrect: false,
        // Force everything to lowercase as it's typed / pasted.
        inputFormatters: [
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                newValue.copyWith(text: newValue.text.toLowerCase()),
          ),
        ],
        style: const TextStyle(color: Colors.black),
        decoration: signUpInputDecoration(),
      ),
    );
  }
}
