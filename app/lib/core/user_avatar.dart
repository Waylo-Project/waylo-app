import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A round user avatar: the profile photo when there is one, else the first
/// letter of [name] on a pale sky-blue disc.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.url,
    required this.radius,
    this.fontSize,
  });

  final String name;
  final String? url;
  final double radius;

  /// Initial letter size; defaults to 0.8 × [radius].
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.c.primary.withValues(alpha: 0.25),
      foregroundImage: url != null ? NetworkImage(url) : null,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: fontSize ?? radius * 0.8,
          fontWeight: FontWeight.w700,
          color: context.c.ink,
        ),
      ),
    );
  }
}
