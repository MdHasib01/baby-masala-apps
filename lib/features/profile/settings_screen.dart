import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';
import '../../state/session_controller.dart';

/// Port of components/profile/SettingsModal.tsx — unreachable on web, opened
/// from the drawer on mobile. Saves via `PATCH /me` (debounced setUser).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _user = ref.read(dataProvider).user;
  late bool _push = _user.notificationPrefs.push;
  late bool _community = _user.notificationPrefs.communityAlerts;
  late bool _sms = _user.notificationPrefs.sms;
  late bool _email = _user.notificationPrefs.email;
  late bool _hideChildInfo = !_user.privacySettings.showChildrenInfo;
  late bool _shareProfile = _user.privacySettings.shareProfile;
  bool _saved = false;

  void _save() {
    final u = ref.read(dataProvider).user;
    ref.read(appDataProvider.notifier).setUser(u.copyWith(
          notificationPrefs: u.notificationPrefs.copyWith(push: _push, communityAlerts: _community, sms: _sms, email: _email),
          privacySettings: u.privacySettings.copyWith(showChildrenInfo: !_hideChildInfo, shareProfile: _shareProfile),
        ));
    setState(() => _saved = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস ও প্রাইভেসি')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            _header('নোটিফিকেশন পছন্দ', LucideIcons.bell),
            _switch('পুশ নোটিফিকেশন ও অ্যালার্ট', _push, (v) => setState(() => _push = v)),
            _switch('কমিউনিটি কমেন্ট ও কনটেস্ট আপডেট', _community, (v) => setState(() => _community = v)),
            _switch('এসএমএস আপডেট', _sms, (v) => setState(() => _sms = v)),
            _switch('ইমেইল আপডেট', _email, (v) => setState(() => _email = v)),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            _header('প্রাইভেসি ও গোপনীয়তা', LucideIcons.lock),
            _switch('শিশুর জন্মতারিখ ও এলার্জি গোপনীয় রাখা', _hideChildInfo, (v) => setState(() => _hideChildInfo = v),
                subtitle: 'বাইরে প্রদর্শিত হবে না (ডিফল্টভাবে সুরক্ষিত)'),
            _switch('প্রোফাইল কমিউনিটিতে দৃশ্যমান', _shareProfile, (v) => setState(() => _shareProfile = v)),
          ]),
        ),
        if (_saved) ...[
          const SizedBox(height: 12),
          const InfoBox('সেটিংস সফলভাবে সংরক্ষিত হয়েছে!', icon: LucideIcons.check, bg: AppColors.green50, fg: AppColors.green700),
        ],
        const SizedBox(height: 16),
        BusyButton(label: 'পরিবর্তন সেভ করুন', onPressed: () async => _save()),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.red600, backgroundColor: Colors.white),
          onPressed: () async {
            if (await confirmDialog(context, 'লগআউট করবেন?\nআবার লগইন করে আপনার অ্যাকাউন্টে ফিরতে পারবেন।', confirm: 'লগআউট', danger: true)) {
              await ref.read(sessionProvider.notifier).logout();
            }
          },
          icon: const Icon(LucideIcons.logOut, size: 16),
          label: const Text('লগ আউট / অ্যাকাউন্ট পরিবর্তন'),
        ),
      ]),
    );
  }

  Widget _header(String text, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: SectionTitle(text, icon: icon),
      );

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.maroon,
        title: Text(title, style: ts(13, weight: semi)),
        subtitle: subtitle == null ? null : Text(subtitle, style: ts(11, color: AppColors.grey500)),
      );
}
