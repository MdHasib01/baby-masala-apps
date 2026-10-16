import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

/// Port of components/auth/MembershipActivationScreen.tsx.
class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  final _coupon = TextEditingController();
  String? _error;
  late bool _success = ref.read(dataProvider).user.isMember;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_coupon.text.trim().isEmpty) {
      setState(() => _error = 'দয়া করে কুপন কোড লিখুন।');
      return;
    }
    try {
      final user = await ref.read(apiProvider).activateMembership(_coupon.text.trim());
      ref.read(appDataProvider.notifier).setUserFromServer(user);
      setState(() {
        _success = true;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  Future<void> _demoPurchase() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const _DemoCheckoutDialog());
    if (ok == true && mounted) setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
              child: const Icon(LucideIcons.sparkles, color: AppColors.gold, size: 30),
            ),
          ),
          const SizedBox(height: 14),
          Text('প্রিমিয়াম মেম্বারশিপ অ্যাক্টিভেশন',
              textAlign: TextAlign.center, style: ts(20, weight: FontWeight.w800, color: AppColors.maroon)),
          const SizedBox(height: 6),
          Text('বেবি কেয়ারের সকল প্রিমিয়াম ফিচার ও এক্সক্লুসিভ গাইডলাইন আনলক করুন।',
              textAlign: TextAlign.center, style: ts(13, color: AppColors.grey600, height: 1.5)),
          const SizedBox(height: 24),
          if (_success) _successCard() else _activationCard(),
        ]),
      ),
    );
  }

  Widget _successCard() => AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(LucideIcons.circleCheck, color: AppColors.green700, size: 56),
          const SizedBox(height: 12),
          Text('মেম্বারশিপ সফলভাবে সক্রিয় হয়েছে!', textAlign: TextAlign.center, style: ts(16, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 6),
          Text('আপনার অ্যাকাউন্টটি এখন প্রিমিয়াম অ্যাক্সেস সহ প্রস্তুত।',
              textAlign: TextAlign.center, style: ts(12, color: AppColors.grey600)),
          const SizedBox(height: 18),
          BusyButton(
            label: 'শুরু করুন',
            icon: LucideIcons.arrowRight,
            onPressed: () async => ref.read(sessionProvider.notifier).finishMembership(),
          ),
        ]),
      );

  Widget _activationCard() => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('নিয়মিত মূল্য:', style: ts(12, color: AppColors.grey600))),
                Text('৳ ৮,০০০',
                    style: ts(13, weight: bold, color: AppColors.grey500).copyWith(decoration: TextDecoration.lineThrough)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text('কুপন দিয়ে ফ্রি অ্যাক্টিভেশন:', style: ts(12, weight: semi))),
                Text('৳ ০ (BABYCARE)', style: ts(13, weight: bold, color: AppColors.olive)),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          const FieldLabel('কুপন কোড লিখুন'),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _coupon,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'BABYCARE'),
                onSubmitted: (_) => _activate(),
              ),
            ),
            const SizedBox(width: 8),
            BusyButton(label: 'অ্যাক্টিভ করুন', expand: false, onPressed: _activate),
          ]),
          if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Text('কুপন না থাকলে সরাসরি মেম্বারশিপ নিতে পারেন:', textAlign: TextAlign.center, style: ts(12, color: AppColors.grey600)),
          const SizedBox(height: 10),
          BusyButton(label: 'মেম্বারশিপ কিনুন (৳ ৮,০০০ - ডেমো)', color: AppColors.olive, onPressed: _demoPurchase),
        ]),
      );
}

class _DemoCheckoutDialog extends ConsumerStatefulWidget {
  const _DemoCheckoutDialog();

  @override
  ConsumerState<_DemoCheckoutDialog> createState() => _DemoCheckoutDialogState();
}

class _DemoCheckoutDialogState extends ConsumerState<_DemoCheckoutDialog> {
  bool _paid = false;

  Future<void> _pay() async {
    try {
      final user = await ref.read(apiProvider).demoPurchaseMembership();
      ref.read(appDataProvider.notifier).setUserFromServer(user);
      setState(() => _paid = true);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, false);
      toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ডেমো মেম্বারশিপ চেকআউট', style: ts(16, weight: bold, color: AppColors.maroon)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text.rich(TextSpan(style: ts(13, height: 1.5), children: [
          const TextSpan(text: 'মূল্য: '),
          TextSpan(text: '৳ ৮,০০০', style: ts(13, weight: bold)),
          const TextSpan(text: ' (এটি একটি সম্পূর্ণ সিমুলেটেড ডেমো পেমেন্ট, কোনো আসল টাকা কাটা হবে না)।'),
        ])),
        if (_paid) ...[
          const SizedBox(height: 10),
          Text('সফল পেমেন্ট! মেম্বারশিপ সক্রিয় হচ্ছে...', style: ts(12, weight: bold, color: AppColors.green700)),
        ],
      ]),
      actions: [
        TextButton(onPressed: _paid ? null : () => Navigator.pop(context, false), child: const Text('বাতিল')),
        BusyButton(label: 'পেমেন্ট কনফার্ম করুন', expand: false, onPressed: _paid ? null : _pay),
      ],
    );
  }
}
