import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error_dialog.dart';
import '../../core/locale_controller.dart';
import '../../core/theme_controller.dart';
import '../../core/validators.dart';
import '../../data/profile_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../legal/legal_content.dart';
import '../legal/legal_screen.dart';
import 'avatar_picker_screen.dart';

/// The Settings screen — one scrolling page grouped into sections, per
/// `docs/SETTINGS.md` and the design handoff. Colors read from the theme-aware
/// [WayloColors] tokens (`context.c`), so the whole screen adapts to light/dark.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.profile});

  /// The signed-in user's profile (null in the unconfigured/dev path).
  final Profile? profile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileRepository _repo = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  // Mutable copy so edits reflect immediately.
  late Profile? _profile = widget.profile;

  // "1.0.0 (1)" — the built app's version + build number (from pubspec);
  // null until read.
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  String get _username => _profile?.username ?? 'you';

  /// The display label for the current language selection: an explicit choice,
  /// or "System default" when following the device locale.
  String _languageLabel(AppLocalizations l) {
    switch (LocaleController.instance.value?.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      case 'es':
        return 'Español';
      default:
        return l.settingsLanguageSystem;
    }
  }

  /// The display label for the current light/dark selection.
  String _themeLabel(AppLocalizations l) {
    switch (ThemeController.instance.value) {
      case ThemeMode.light:
        return l.settingsThemeLight;
      case ThemeMode.dark:
        return l.settingsThemeDark;
      case ThemeMode.system:
        return l.settingsThemeSystem;
    }
  }

  String get _email =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.c;
    return Scaffold(
      backgroundColor: c.pageBackground,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l.settingsTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: c.hairline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 44),
        children: [
          _ProfileHero(
            displayName: _profile?.displayName ?? _username,
            username: _username,
            avatarUrl: _profile?.avatarUrl,
            onEdit: _openProfilePhotoSheet,
          ),
          const SizedBox(height: 22),

          _SectionLabel(l.settingsSectionProfile),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.alternate_email,
              label: l.settingsUsername,
              value: '@$_username',
              onTap: _editUsername,
            ),
            _SettingsRow(
              icon: Icons.badge_outlined,
              label: l.settingsDisplayName,
              value: _profile?.displayName ?? '—',
              onTap: _editDisplayName,
            ),
          ]),
          const SizedBox(height: 18),

          _SectionLabel(l.settingsSectionAccount),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.mail_outline,
              label: l.settingsEmail,
              value: _email.isEmpty ? '—' : _email,
              onTap: _editEmail,
            ),
            _SettingsRow(
              icon: Icons.lock_outline,
              label: l.settingsPassword,
              value: l.settingsChange,
              onTap: _editPassword,
            ),
          ]),
          const SizedBox(height: 18),

          _SectionLabel(l.settingsSectionPreferences),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.language,
              label: l.settingsLanguage,
              value: _languageLabel(l),
              onTap: _openLanguageSheet,
            ),
            _SettingsRow(
              icon: Icons.brightness_6_outlined,
              label: l.settingsAppearance,
              value: _themeLabel(l),
              onTap: _openThemeSheet,
            ),
            _SettingsRow(
              icon: Icons.group_outlined,
              label: l.settingsPhotoVisibility,
              value: l.settingsFriendsOnly,
              valuePrefix: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.lock, size: 15, color: c.inkFaint),
              ),
              onTap: _openVisibilitySheet,
            ),
          ]),
          const SizedBox(height: 18),

          _SectionLabel(l.settingsSectionAbout),
          _SettingsCard(children: [
            _SettingsRow(
              icon: Icons.info_outline,
              label: l.settingsVersion,
              value: _version,
              trailing: _Trailing.none,
            ),
            _SettingsRow(
              icon: Icons.description_outlined,
              label: l.settingsTermsOfService,
              onTap: () => _openLegal(termsOfService),
            ),
            _SettingsRow(
              icon: Icons.shield_outlined,
              label: l.settingsPrivacyPolicy,
              onTap: () => _openLegal(privacyPolicy),
            ),
          ]),
          const SizedBox(height: 22),

          _DeleteCard(onTap: _openDeleteDialog),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l.settingsSignedInAs(_username),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Interactions -------------------------------------------------------

  /// Push an in-app legal document (Terms / Privacy), resolved to the active
  /// locale. [build] is `termsOfService` or `privacyPolicy` from legal_content.
  void _openLegal(LegalDocument Function(Locale) build) {
    final doc = build(Localizations.localeOf(context));
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LegalScreen(document: doc),
    ));
  }

  /// Profile photo action sheet: take / choose / remove, then a Cancel card.
  Future<void> _openProfilePhotoSheet() async {
    final l = AppLocalizations.of(context);
    final c = context.c;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FloatingCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        l.settingsProfilePhoto,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.inkFaint,
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: c.hairline),
                    _SheetAction(
                      icon: Icons.photo_camera,
                      label: l.settingsTakePhoto,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndCrop(ImageSource.camera);
                      },
                    ),
                    Divider(height: 1, thickness: 1, indent: 56, color: c.hairline),
                    _SheetAction(
                      icon: Icons.photo_library,
                      label: l.settingsChooseFromGallery,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndCrop(ImageSource.gallery);
                      },
                    ),
                    if ((_profile?.avatarPath) != null) ...[
                      Divider(height: 1, thickness: 1, indent: 56, color: c.hairline),
                      _SheetAction(
                        icon: Icons.delete_outline,
                        label: l.settingsRemovePhoto,
                        danger: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          _removeAvatar();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _FloatingCard(
                child: _SheetAction(
                  label: l.commonCancel,
                  bold: true,
                  center: true,
                  onTap: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App language picker.
  Future<void> _openLanguageSheet() async {
    final l = AppLocalizations.of(context);
    final c = context.c;
    final current = LocaleController.instance.value?.languageCode;
    // The sheet returns null on dismissal, a Locale for an explicit language,
    // or the [_systemDefault] sentinel for "follow the device locale" — so a
    // tap-outside (null) is not confused with choosing System default.
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: _FloatingCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.settingsAppLanguage,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
                _LanguageOption(
                  label: l.settingsLanguageSystem,
                  selected: current == null,
                  onTap: () => Navigator.pop(ctx, _systemDefault),
                ),
                const _LanguageDivider(),
                // Language names are shown as endonyms (each in its own script),
                // a localization convention, so they are not translated.
                _LanguageOption(
                  label: 'English',
                  selected: current == 'en',
                  onTap: () => Navigator.pop(ctx, const Locale('en')),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: '한국어',
                  selected: current == 'ko',
                  onTap: () => Navigator.pop(ctx, const Locale('ko')),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: '日本語',
                  selected: current == 'ja',
                  onTap: () => Navigator.pop(ctx, const Locale('ja')),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: '中文',
                  selected: current == 'zh',
                  onTap: () => Navigator.pop(ctx, const Locale('zh')),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: 'Español',
                  selected: current == 'es',
                  onTap: () => Navigator.pop(ctx, const Locale('es')),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Text(
                    l.settingsLanguageNote,
                    style: TextStyle(fontSize: 13, color: c.inkFaint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return; // dismissed without choosing
    final locale = picked is Locale ? picked : null; // _systemDefault -> null
    await LocaleController.instance.setLocale(locale);
    if (mounted) setState(() {});
  }

  /// Light/dark appearance picker.
  Future<void> _openThemeSheet() async {
    final l = AppLocalizations.of(context);
    final c = context.c;
    final current = ThemeController.instance.value;
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: _FloatingCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.settingsAppearance,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                ),
                _LanguageOption(
                  label: l.settingsThemeSystem,
                  selected: current == ThemeMode.system,
                  onTap: () => Navigator.pop(ctx, ThemeMode.system),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: l.settingsThemeLight,
                  selected: current == ThemeMode.light,
                  onTap: () => Navigator.pop(ctx, ThemeMode.light),
                ),
                const _LanguageDivider(),
                _LanguageOption(
                  label: l.settingsThemeDark,
                  selected: current == ThemeMode.dark,
                  onTap: () => Navigator.pop(ctx, ThemeMode.dark),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await ThemeController.instance.setMode(picked);
    if (mounted) setState(() {});
  }

  /// Photo-visibility info (locked mode): explains the fixed "friends only"
  /// rule. A selectable mode exists in the design but needs an RLS model change
  /// (a product decision) before it ships.
  Future<void> _openVisibilitySheet() async {
    final l = AppLocalizations.of(context);
    final c = context.c;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: c.scrim,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: _FloatingCard(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsPhotoVisibility,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.fill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 18, color: c.inkMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.settingsFriendsOnly,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l.settingsVisibilityFriendsDesc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l.settingsVisibilityFixedNote,
                    style: TextStyle(fontSize: 13, color: c.inkFaint),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: _PrimaryButton(
                      label: l.commonGotIt,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Account-deletion confirmation. The actual delete needs a server-side
  /// routine (RPC / Edge Function) — wired in a later phase.
  Future<void> _openDeleteDialog() async {
    final l = AppLocalizations.of(context);
    final c = context.c;
    await showDialog<void>(
      context: context,
      barrierColor: c.scrim,
      builder: (ctx) => Dialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_forever, size: 26, color: c.danger),
                ),
                const SizedBox(height: 14),
                Text(
                  l.settingsDeleteTitle,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsDeleteBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.inkMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: l.commonCancel,
                        background: c.fill,
                        foreground: c.ink,
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogButton(
                        label: l.commonDelete,
                        background: c.danger,
                        foreground: Colors.white,
                        onTap: () {
                          Navigator.pop(ctx);
                          _deleteAccount();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Runs the irreversible delete: block the UI with a spinner, call the
  /// `delete_account` RPC, then sign out — which flips [AuthGate] back to the
  /// Welcome screen and tears this screen down.
  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.c.scrim,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _repo.deleteAccount();
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // spinner
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner
      _snack(l.settingsCouldNotDeleteAccount('$e'));
    }
  }

  // ---- Avatar -------------------------------------------------------------

  /// Open the avatar picker (Instagram-style: square crop preview + library
  /// grid). A camera shot seeds the preview; gallery loads the grid. The
  /// returned square crop is uploaded and set as the avatar.
  Future<void> _pickAndCrop(ImageSource source) async {
    try {
      Uint8List? initial;
      if (source == ImageSource.camera) {
        final shot =
            await _picker.pickImage(source: ImageSource.camera, maxWidth: 2048);
        if (shot == null || !mounted) return;
        initial = await shot.readAsBytes();
        if (!mounted) return;
      }
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => AvatarPickerScreen(initialImage: initial),
        ),
      );
      if (cropped == null || !mounted) return;
      final updated = await _repo.uploadAvatar(cropped);
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (e) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).settingsCouldNotUpdatePhoto('$e'));
    }
  }

  Future<void> _removeAvatar() async {
    try {
      final updated = await _repo.removeAvatar();
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (e) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).settingsCouldNotRemovePhoto('$e'));
    }
  }

  // ---- Profile / account edits --------------------------------------------

  Future<void> _editUsername() async {
    final l = AppLocalizations.of(context);
    await _promptEdit(
      title: l.settingsUsername,
      initial: _profile?.username ?? '',
      hint: l.settingsUsernameHint,
      onSubmit: (raw) async {
        final v = raw.trim();
        // Field-level validation stays in the dialog (inline, not a snackbar).
        if (v.isEmpty) return _EditResult.error(l.settingsEnterUsername);
        if (v == _profile?.username) return _EditResult.dismiss;
        try {
          final updated = await _repo.updateUsername(v);
          if (!mounted) return _EditResult.dismiss;
          setState(() => _profile = updated);
          return _EditResult.ok;
        } on UsernameTakenException {
          return _EditResult.error(l.signUpUsernameTaken);
        } catch (e) {
          // Transient/network failure → snackbar, close the dialog.
          _snack(l.settingsCouldNotUpdateUsername('$e'));
          return _EditResult.dismiss;
        }
      },
    );
  }

  Future<void> _editDisplayName() async {
    final l = AppLocalizations.of(context);
    await _promptEdit(
      title: l.settingsDisplayName,
      initial: _profile?.displayName ?? '',
      hint: l.settingsDisplayNameHint,
      onSubmit: (value) async {
        try {
          final updated = await _repo.updateDisplayName(value);
          if (!mounted) return _EditResult.dismiss;
          setState(() => _profile = updated);
          return _EditResult.ok;
        } catch (e) {
          _snack(l.settingsCouldNotUpdateDisplayName('$e'));
          return _EditResult.dismiss;
        }
      },
    );
  }

  Future<void> _editEmail() async {
    final l = AppLocalizations.of(context);
    await _promptEdit(
      title: l.settingsEmail,
      initial: _email,
      hint: l.settingsEmailHint,
      keyboardType: TextInputType.emailAddress,
      onSubmit: (raw) async {
        final v = raw.trim();
        if (v.isEmpty || v == _email) return _EditResult.dismiss;
        if (!isValidEmail(v)) return _EditResult.error(l.authInvalidEmail);
        try {
          await Supabase.instance.client.auth
              .updateUser(UserAttributes(email: v));
          if (!mounted) return _EditResult.dismiss;
          // The email does NOT change until the user clicks the confirmation
          // link sent to the new address, so we don't optimistically update the
          // displayed value — we tell them to check their inbox instead.
          _snack(l.settingsEmailChangeSent(v));
          return _EditResult.dismiss;
        } catch (e) {
          _snack(l.settingsCouldNotUpdateEmail('$e'));
          return _EditResult.dismiss;
        }
      },
    );
  }

  Future<void> _editPassword() async {
    final l = AppLocalizations.of(context);
    await _promptEdit(
      title: l.settingsNewPassword,
      initial: '',
      hint: l.settingsPasswordHint,
      obscure: true,
      onSubmit: (value) async {
        // Same policy as sign-up (10+ chars, letters + numbers), so a password
        // can't be weakened here below what sign-up requires.
        if (!isValidPassword(value)) {
          return _EditResult.error(l.settingsPasswordTooShort);
        }
        try {
          await Supabase.instance.client.auth
              .updateUser(UserAttributes(password: value));
          return _EditResult.ok;
        } catch (e) {
          _snack(l.settingsCouldNotUpdatePassword('$e'));
          return _EditResult.dismiss;
        }
      },
    );
  }

  /// A single-field editor dialog that validates **in place**: [onSubmit] runs
  /// while the dialog stays open, and a returned [_EditResult.error] is shown
  /// inline (red helper text) instead of as a snackbar, so the user can fix the
  /// value without reopening. Success / no-change / handled-elsewhere close it.
  Future<void> _promptEdit({
    required String title,
    required String initial,
    String? hint,
    TextInputType? keyboardType,
    bool obscure = false,
    required Future<_EditResult> Function(String value) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: context.c.scrim,
      builder: (ctx) => _EditDialog(
        title: title,
        initial: initial,
        hint: hint,
        keyboardType: keyboardType,
        obscure: obscure,
        onSubmit: onSubmit,
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    showErrorDialog(context, msg);
  }
}

// ---------------------------------------------------------------------------
// Inline single-field editor
// ---------------------------------------------------------------------------

enum _EditOutcome { success, inlineError, dismissed }

/// Outcome of an [_EditDialog] save. [error] keeps the dialog open and shows an
/// inline message; [ok]/[dismiss] both close it (dismiss = the caller already
/// handled feedback, e.g. a snackbar, or there was nothing to change).
class _EditResult {
  const _EditResult._(this.outcome, [this.message]);

  final _EditOutcome outcome;
  final String? message;

  static const _EditResult ok = _EditResult._(_EditOutcome.success);
  static const _EditResult dismiss = _EditResult._(_EditOutcome.dismissed);
  factory _EditResult.error(String message) =>
      _EditResult._(_EditOutcome.inlineError, message);
}

/// The editor dialog itself: a text field plus inline error + a Save button
/// that shows a spinner while [onSubmit] runs.
class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.initial,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    required this.onSubmit,
  });

  final String title;
  final String initial;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Future<_EditResult> Function(String value) onSubmit;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    switch (result.outcome) {
      case _EditOutcome.success:
      case _EditOutcome.dismissed:
        Navigator.pop(context);
      case _EditOutcome.inlineError:
        setState(() {
          _saving = false;
          _error = result.message;
        });
    }
  }

  OutlineInputBorder _border({Color? color}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        style: TextStyle(color: c.ink),
        // Clear the inline error as soon as the user starts fixing the value.
        onChanged: _error == null ? null : (_) => setState(() => _error = null),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: c.inkFaint),
          filled: true,
          fillColor: c.fill,
          errorText: _error,
          border: _border(),
          enabledBorder: _border(),
          focusedBorder: _border(),
          errorBorder: _border(color: c.danger),
          focusedErrorBorder: _border(color: c.danger),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonCancel,
              style: TextStyle(color: c.inkMuted)),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.checkAccent,
                  ),
                )
              : Text(AppLocalizations.of(context).commonSave,
                  style: TextStyle(
                      color: c.checkAccent,
                      fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// The profile hero card at the top: avatar (+ camera badge), name, @handle,
/// and an Edit pill — all tapping into the profile-photo sheet.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String displayName;
  final String username;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.hairline),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEdit,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: c.primary.withValues(alpha: 0.24),
                    foregroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.photo_camera,
                          size: 14, color: c.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: c.fill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context).settingsEdit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section header above each card.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.c.inkFaint,
        ),
      ),
    );
  }
}

/// White rounded card grouping rows, with inset hairlines between them.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 60,
          color: c.hairline,
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.hairline),
      ),
      child: Column(children: rows),
    );
  }
}

enum _Trailing { chevron, none }

/// One settings row: icon chip · label · optional value · trailing affordance.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.valuePrefix,
    this.trailing = _Trailing.chevron,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valuePrefix;
  final _Trailing trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.fill,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: c.inkMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                ?valuePrefix,
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.inkFaint,
                    ),
                  ),
                ),
              ],
              if (trailing == _Trailing.chevron) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: c.chevron),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The standalone "Delete account" card (centered, danger-styled).
class _DeleteCard extends StatelessWidget {
  const _DeleteCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.hairline),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 20, color: c.danger),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).settingsDeleteAccount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floating sheet card (rounded, soft shadow) used by the bottom sheets.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// A row inside a bottom-sheet card: optional icon + label.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    this.icon,
    required this.label,
    this.danger = false,
    this.bold = false,
    this.center = false,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final bool danger;
  final bool bold;
  final bool center;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = danger ? c.danger : c.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment:
              center ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sentinel result from the language sheet meaning "follow the device locale",
/// kept distinct from null (sheet dismissed without choosing).
const Object _systemDefault = Object();

/// Inset hairline between options.
class _LanguageDivider extends StatelessWidget {
  const _LanguageDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
      color: context.c.hairline,
    );
  }
}

/// One option row with a trailing check when selected (language or theme).
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check, size: 22, color: c.checkAccent),
          ],
        ),
      ),
    );
  }
}

/// Filled primary (sky-blue) button used inside sheets.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dialog action button (Cancel / Delete).
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
