import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'legal_content.dart';

/// A read-only, scrollable view of a legal document (Terms of Service or
/// Privacy Policy). Shown in-app (we don't host the documents on the web), so
/// the rows in Settings push this instead of opening an external link.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.pageBackground,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        foregroundColor: context.c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          document.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: context.c.hairline),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
        children: [
          Text(
            document.lastUpdated,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.c.inkFaint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            document.intro,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: context.c.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final section in document.sections) _Section(section),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.section);

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          section.heading,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.c.ink,
          ),
        ),
        const SizedBox(height: 8),
        for (final paragraph in section.paragraphs) ...[
          Text(
            paragraph,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: context.c.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
