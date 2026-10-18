import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/links.dart';
import '../../data/static/legal_texts.dart';
import '../../shared/widgets/common.dart';

/// Privacy policy / terms. Reachable signed in (Settings) and signed out (sign-up).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});
  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        InfoBox('সর্বশেষ হালনাগাদ: ${doc.updated}', icon: LucideIcons.calendar, bg: AppColors.blue50, fg: AppColors.blue600),
        const SizedBox(height: 12),
        for (final s in doc.sections) ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionTitle(s.title),
              const SizedBox(height: 8),
              for (final p in s.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(p, style: ts(12.5, color: AppColors.ink, height: 1.6)),
                ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: () => openUrl(context, doc.webUrl),
          icon: const Icon(LucideIcons.externalLink, size: 16),
          label: const Text('ওয়েবসাইটে দেখুন'),
        ),
      ]),
    );
  }
}
