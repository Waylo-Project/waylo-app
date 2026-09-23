import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Shared chrome for every sign-up step, matching the original design:
/// sky-blue background, "Create account" app bar, a bold white question, the
/// step's input, optional requirements text, and a white "Next" button that is
/// enabled only when the step is valid.
class SignUpStepScaffold extends StatelessWidget {
  const SignUpStepScaffold({
    super.key,
    required this.question,
    required this.field,
    required this.canNext,
    required this.onNext,
    this.requirements,
    this.errorText,
    this.loading = false,
    this.buttonText,
  });

  final String question;
  final Widget field;
  final String? requirements;
  final String? errorText;
  final bool canNext;
  final bool loading;
  final VoidCallback onNext;

  /// Defaults to the localized "Next" label when null.
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.signUpCreateAccount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            field,
            if (requirements != null) ...[
              const SizedBox(height: 5),
              Text(
                requirements!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: (canNext && !loading) ? onNext : null,
                  style: AuthButtonStyles.form(isEnabled: canNext),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF757575)),
                        )
                      : Text(buttonText ?? l.commonNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white filled rounded input used across the sign-up steps.
InputDecoration signUpInputDecoration({String? hint, Widget? suffixIcon}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    suffixIcon: suffixIcon,
    contentPadding:
        const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
