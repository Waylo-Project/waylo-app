import 'package:flutter/material.dart';

/// Brand colors, carried over from the original waylo design.
class AppColors {
  static const Color primary = Color(0xFF97DCF1); // sky blue

  // Ink scale (Hanken redesign). Sky-blue is reserved for action & selection
  // only; everything textual sits on this neutral scale over white.
  static const Color ink = Color(0xFF15303B); // primary text / headings
  static const Color inkMuted = Color(0xFF55626A); // secondary text
  static const Color inkFaint = Color(0xFF8A949B); // meta / captions
  static const Color hairline = Color(0xFFEAEEF0); // 1px dividers, card borders

  // Semantic surface/accent tokens (added for the Settings screen handoff).
  static const Color pageBackground = Color(0xFFF4F6F7); // settings page bg
  static const Color fill = Color(0xFFF1F4F6); // chips / pills / icon chips
  static const Color chevron = Color(0xFFC2CACF); // trailing chevrons
  static const Color caption = Color(0xFFB6BEC3); // faint captions
  static const Color checkAccent = Color(0xFF2BA8D4); // selected check mark
  static const Color danger = Color(0xFFD64545); // destructive actions
  static const Color warning = Color(0xFFC58A2E); // preview / caution notes
}

/// The app typeface. Bundled static Hanken Grotesk (assets/fonts) — replaces
/// Flutter's default Roboto everywhere via the global theme.
const String kFontFamily = 'HankenGrotesk';

/// Semantic, theme-aware color tokens. Widgets read these via `context.c.<x>`
/// instead of the fixed [AppColors] constants, so the same screen renders in
/// light or dark depending on the active theme. Brand hues (sky-blue primary,
/// danger red) stay recognizable across modes; only the neutral ink/surface
/// scale flips.
@immutable
class WayloColors extends ThemeExtension<WayloColors> {
  const WayloColors({
    required this.surface,
    required this.pageBackground,
    required this.fill,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.hairline,
    required this.chevron,
    required this.caption,
    required this.primary,
    required this.onPrimary,
    required this.checkAccent,
    required this.danger,
    required this.warning,
    required this.scrim,
  });

  /// Cards, sheets, app bars, dialogs — the raised "paper" surface (white in
  /// light).
  final Color surface;

  /// The page behind the cards (settings/list backgrounds).
  final Color pageBackground;

  /// Chips, pills, icon chips, comment bubbles, filled inputs.
  final Color fill;

  final Color ink; // primary text / headings
  final Color inkMuted; // secondary text
  final Color inkFaint; // meta / captions
  final Color hairline; // 1px dividers, card borders
  final Color chevron; // trailing chevrons
  final Color caption; // faint captions

  final Color primary; // sky-blue action & selection
  final Color onPrimary; // text/icon sitting on [primary]
  final Color checkAccent; // selected check mark
  final Color danger; // destructive actions
  final Color warning; // preview / caution notes
  final Color scrim; // modal barrier behind sheets/dialogs

  /// Light palette — the original waylo look, sourced from [AppColors].
  static const WayloColors light = WayloColors(
    surface: Colors.white,
    pageBackground: AppColors.pageBackground,
    fill: AppColors.fill,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    inkFaint: AppColors.inkFaint,
    hairline: AppColors.hairline,
    chevron: AppColors.chevron,
    caption: AppColors.caption,
    primary: AppColors.primary,
    onPrimary: AppColors.ink,
    checkAccent: AppColors.checkAccent,
    danger: AppColors.danger,
    warning: AppColors.warning,
    scrim: Color(0x6B15303B),
  );

  /// Dark palette — a deep teal-tinted neutral scale under the same brand blue.
  static const WayloColors dark = WayloColors(
    surface: Color(0xFF171D20),
    pageBackground: Color(0xFF0F1416),
    fill: Color(0xFF232A2E),
    ink: Color(0xFFEAF1F3),
    inkMuted: Color(0xFFAAB8BE),
    inkFaint: Color(0xFF7E8B92),
    hairline: Color(0xFF283237),
    chevron: Color(0xFF4A555B),
    caption: Color(0xFF6B767C),
    primary: AppColors.primary, // brand blue reads well on dark
    onPrimary: Color(0xFF102128), // dark ink on the light-blue pill
    checkAccent: Color(0xFF54C4E8),
    danger: Color(0xFFE5675F),
    warning: Color(0xFFD6A24A),
    scrim: Color(0x99000000),
  );

  @override
  WayloColors copyWith({
    Color? surface,
    Color? pageBackground,
    Color? fill,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? hairline,
    Color? chevron,
    Color? caption,
    Color? primary,
    Color? onPrimary,
    Color? checkAccent,
    Color? danger,
    Color? warning,
    Color? scrim,
  }) {
    return WayloColors(
      surface: surface ?? this.surface,
      pageBackground: pageBackground ?? this.pageBackground,
      fill: fill ?? this.fill,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      hairline: hairline ?? this.hairline,
      chevron: chevron ?? this.chevron,
      caption: caption ?? this.caption,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      checkAccent: checkAccent ?? this.checkAccent,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  WayloColors lerp(covariant ThemeExtension<WayloColors>? other, double t) {
    if (other is! WayloColors) return this;
    return WayloColors(
      surface: Color.lerp(surface, other.surface, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      chevron: Color.lerp(chevron, other.chevron, t)!,
      caption: Color.lerp(caption, other.caption, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      checkAccent: Color.lerp(checkAccent, other.checkAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// `context.c.ink` — the active [WayloColors] for the current theme.
extension WayloColorsX on BuildContext {
  WayloColors get c => Theme.of(this).extension<WayloColors>()!;
}

/// App theme. The auth screens use the sky-blue background with white pill
/// buttons / white filled inputs, matching the original look.
class AppTheme {
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: kFontFamily,
    useMaterial3: true,
    extensions: const [WayloColors.light],
  );

  static ThemeData get dark => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: WayloColors.dark.pageBackground,
    fontFamily: kFontFamily,
    useMaterial3: true,
    extensions: const [WayloColors.dark],
  );
}

/// Shared button styles for the auth flow.
class AuthButtonStyles {
  /// Large white pill button used on the sky-blue welcome screen.
  static ButtonStyle pill(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      shadowColor: Colors.transparent,
      fixedSize: Size(MediaQuery.of(context).size.width * 0.85, 52),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// The original "Next" form button: 100x50 rounded pill, white when enabled
  /// and grey when disabled, grey label.
  static ButtonStyle form({required bool isEnabled}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isEnabled ? Colors.white : const Color(0xFF9E9E9E),
      foregroundColor: const Color(0xFF757575),
      disabledBackgroundColor: const Color(0xFF9E9E9E),
      disabledForegroundColor: const Color(0xFF757575),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 0,
      shadowColor: Colors.transparent,
      fixedSize: const Size(100, 50),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

/// White filled rounded input, used on the sky-blue auth screens.
InputDecoration authInputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );
}
