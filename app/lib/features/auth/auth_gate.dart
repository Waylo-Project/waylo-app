import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/profile_repository.dart';
import '../../l10n/app_localizations.dart';
import '../map/map_home_page.dart';
import 'welcome_screen.dart';

/// Top-level router based on auth + profile state:
///   no session            -> WelcomeScreen (sign in / sign up)
///   session, has profile   -> MapHomePage
/// A signed-in user always has a profile (it is created at the end of sign-up),
/// so a persistent "session but no profile" means a stale/broken session and we
/// sign out.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const WelcomeScreen();
    }
    return _ProfileGate(key: ValueKey(session.user.id));
  }
}

/// Loads the signed-in user's profile and routes to the map. Because the
/// profile is created during sign-up, a freshly signed-up user may briefly read
/// null before the insert is visible, so we retry a few times before giving up.
class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  final _repo = ProfileRepository();
  late Future<Profile?> _future = _load();

  Future<Profile?> _load() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final profile = await _repo.getMyProfile();
      if (profile != null) return profile;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final l = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.profileLoadError),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: Text(l.commonRetry)),
                ],
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          // Stale/broken session: sign out so AuthGate returns to Welcome.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Supabase.instance.client.auth.signOut();
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return MapHomePage(profile: profile);
      },
    );
  }
}
