import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'sign_in_screen.dart';
import 'sign_up_email_screen.dart';

/// The first screen for signed-out users. Sky-blue background, logo, tagline,
/// and the entry buttons. (Social sign-in will be added here before launch.)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned(
            top: size.height * 0.2,
            left: 0,
            right: 0,
            child: Image.asset('assets/logos/logo2.png', width: 150, height: 150),
          ),
          Positioned(
            top: size.height * 0.45,
            left: 0,
            right: 0,
            child: Text(
              l.welcomeTagline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: AuthButtonStyles.pill(context),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignUpEmailScreen(),
                    ),
                  ),
                  child: Text(l.welcomeSignUp),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: Text(
                    l.authLogIn,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
