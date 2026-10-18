import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';
import '../../state/session_controller.dart';

const _confirmWord = 'মুছে ফেলুন';

/// Permanent account deletion (Google Play account-deletion requirement).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool get _typed => _confirm.text.trim() == _confirmWord;

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      'অ্যাকাউন্টটি স্থায়ীভাবে মুছে ফেলবেন?\nএটি আর ফেরত আনা যাবে না।',
      confirm: _confirmWord,
      danger: true,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionProvider.notifier).deleteAccount();
      messenger.showSnackBar(const SnackBar(content: Text('আপনার অ্যাকাউন্ট ও তথ্য মুছে ফেলা হয়েছে।')));
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(dataProvider.select((d) => d.user.contact));

    Widget point(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(LucideIcons.x, size: 14, color: AppColors.red600),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: ts(12.5, height: 1.5))),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাকাউন্ট মুছে ফেলুন')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        InfoBox(
          'অ্যাকাউন্ট ($email) মুছে ফেললে তা আর ফেরত আনা যাবে না।',
          icon: LucideIcons.triangleAlert,
          bg: AppColors.red50,
          fg: AppColors.red600,
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('যা স্থায়ীভাবে মুছে যাবে', icon: LucideIcons.trash2),
            const SizedBox(height: 10),
            point('আপনার প্রোফাইল, ছবি ও ঠিকানা'),
            point('শিশুর তথ্য ও ছবি'),
            point('আপনার পোস্ট, কমেন্ট, রিঅ্যাকশন ও সেভ করা কনটেন্ট'),
            point('পয়েন্ট, গিফট রিডেম্পশন ও কনটেস্ট এন্ট্রি'),
            point('অভিযোগ, নোটিফিকেশন ও সেটিংস'),
            const SizedBox(height: 6),
            Text(
              'হিসাবের প্রয়োজনে অর্ডারের রেকর্ড (প্রোডাক্ট, পরিমাণ, মূল্য ও তারিখ) রাখা হবে, তবে আপনার নাম, ঠিকানা ও ফোন নম্বর সরিয়ে ফেলা হবে।',
              style: ts(11.5, color: AppColors.grey600, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        FieldLabel('নিশ্চিত করতে নিচে "$_confirmWord" লিখুন'),
        TextField(
          controller: _confirm,
          decoration: const InputDecoration(hintText: _confirmWord),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
        const SizedBox(height: 16),
        BusyButton(
          label: 'অ্যাকাউন্ট স্থায়ীভাবে মুছে ফেলুন',
          busyLabel: 'মুছে ফেলা হচ্ছে...',
          icon: LucideIcons.trash2,
          color: AppColors.red600,
          onPressed: _typed ? _delete : null,
        ),
      ]),
    );
  }
}
