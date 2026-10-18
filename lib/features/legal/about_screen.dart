import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/links.dart';
import '../../data/static/legal_texts.dart';
import '../../shared/widgets/common.dart';

/// App name, version, publisher, support contact, legal pages and licenses.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value ?? '';

    Widget tile(IconData icon, String title, String? subtitle, VoidCallback onTap, {Color color = AppColors.maroon}) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: ts(13, weight: semi)),
          subtitle: subtitle == null ? null : Text(subtitle, style: ts(11, color: AppColors.grey500)),
          trailing: const Icon(LucideIcons.chevronRight, size: 18),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাপ সম্পর্কে')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          child: Column(children: [
            const AppLogo(size: 72),
            const SizedBox(height: 10),
            Text('Baby Care by Baby Masala', style: ts(16, weight: bold, color: AppColors.maroon)),
            if (version.isNotEmpty) Text('সংস্করণ $version', style: ts(12, color: AppColors.grey500)),
            const SizedBox(height: 8),
            Text('বাংলাদেশের মায়েদের জন্য শিশুর পুষ্টি, পরিচর্যা ও কমিউনিটি অ্যাপ।',
                textAlign: TextAlign.center, style: ts(12.5, color: AppColors.grey600, height: 1.5)),
            const SizedBox(height: 6),
            Text('ডেভেলপার: ${Env.publisher}', style: ts(12, weight: semi, color: AppColors.olive)),
          ]),
        ),
        const SizedBox(height: 12),
        const InfoBox(medicalDisclaimer, icon: LucideIcons.stethoscope),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            tile(LucideIcons.mail, 'যোগাযোগ করুন', Env.supportEmail, () => emailSupport(context)),
            tile(LucideIcons.globe, 'ওয়েবসাইট', Env.liveWeb.replaceFirst('https://', ''), () => openUrl(context, Env.liveWeb)),
            tile(LucideIcons.shieldCheck, 'গোপনীয়তা নীতি', null, () => context.push(Routes.privacy)),
            tile(LucideIcons.fileText, 'ব্যবহারের শর্তাবলী', null, () => context.push(Routes.terms)),
            tile(LucideIcons.scrollText, 'ওপেন সোর্স লাইসেন্স', null, () {
              showLicensePage(
                context: context,
                applicationName: 'Baby Care by Baby Masala',
                applicationVersion: version,
                applicationLegalese: '© ${DateTime.now().year} ${Env.publisher}',
              );
            }),
          ]),
        ),
      ]),
    );
  }
}
