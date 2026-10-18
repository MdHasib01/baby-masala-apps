import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Redeem catalog (RewardsTab.tsx "showRedeemCatalog").
class RedeemCatalog extends ConsumerWidget {
  const RedeemCatalog({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        Row(children: [
          TextButton.icon(onPressed: onBack, icon: const Icon(LucideIcons.chevronLeft, size: 18), label: const Text('রিওয়ার্ডসে ফিরে যান')),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('উপলব্ধ ব্যালেন্স', style: ts(10, color: AppColors.grey500)),
            Text('${toBnDigits(d.availablePoints)} পয়েন্ট', style: ts(14, weight: bold, color: AppColors.maroon)),
          ]),
        ]),
        const SizedBox(height: 8),
        Text('রিডিম ক্যাটালগ', style: ts(17, weight: bold, color: AppColors.maroon)),
        Text('আপনার অর্জিত পয়েন্ট দিয়ে পছন্দের প্রিমিয়াম হার্বস ও গিফট রিডিম করুন', style: ts(12, color: AppColors.grey600)),
        const SizedBox(height: 14),
        for (final g in d.gifts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  NetImage(g.image, width: 88, height: 88, radius: 12),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Tag('${toBnDigits(g.pointsCost)} পয়েন্ট', bg: AppColors.gold, fg: AppColors.maroon),
                  ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.name, style: ts(13, weight: bold)),
                    const SizedBox(height: 3),
                    Text(g.description, style: ts(11.5, color: AppColors.grey600, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: Text(g.stock > 0 ? 'স্টক: ${toBnDigits(g.stock)}টি উপলব্ধ' : 'স্টক আউট',
                            style: ts(10.5, weight: semi, color: g.stock > 0 ? AppColors.green700 : AppColors.red600)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: ts(11.5, weight: bold)),
                        onPressed: d.availablePoints >= g.pointsCost && g.stock > 0
                            ? () => showAppSheet<void>(context, title: 'রিডিম: ${g.name}', builder: (_) => _RedeemFlow(gift: g))
                            : null,
                        child: const Text('রিডিম করুন'),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
      ]);
  }
}

/// details → address → success (same steps as the web modal).
class _RedeemFlow extends ConsumerStatefulWidget {
  const _RedeemFlow({required this.gift});
  final GiftItem gift;

  @override
  ConsumerState<_RedeemFlow> createState() => _RedeemFlowState();
}

class _RedeemFlowState extends ConsumerState<_RedeemFlow> {
  static const _deliveryCharge = 50;
  String _step = 'details';
  late final _address = TextEditingController(
    text: ref.read(dataProvider).user.defaultAddress?.details ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final g = widget.gift;
    final d = ref.read(dataProvider);
    if (d.availablePoints < g.pointsCost) {
      setState(() => _error = 'আপনার পর্যাপ্ত পয়েন্ট নেই!');
      return;
    }
    if (g.stock <= 0) {
      setState(() => _error = 'এই গিফটটি বর্তমানে স্টকআউট রয়েছে।');
      return;
    }
    setState(() => _error = null);
    try {
      // The server re-checks balance and stock atomically before deducting.
      final r = await ref.read(apiProvider).redeemGift(g.id, _address.text.trim());
      ref.read(appDataProvider.notifier).giftRedeemed(r.redemption, r.rewardTx, r.gift);
      setState(() => _step = 'success');
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gift;
    switch (_step) {
      case 'details':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            NetImage(g.image, width: 72, height: 72, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name, style: ts(14, weight: bold)),
                Text(g.description, style: ts(11.5, color: AppColors.grey600)),
                const SizedBox(height: 4),
                Text('প্রয়োজনীয় পয়েন্ট: ${toBnDigits(g.pointsCost)}', style: ts(12, weight: bold, color: AppColors.maroon)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          InfoBox('ডেলিভারি চার্জ: ৳ ${toBnDigits(_deliveryCharge)}\nপয়েন্ট দিয়ে গিফট অর্ডারের ক্ষেত্রে হোম ডেলিভারি চার্জ প্রযোজ্য, যা ডেলিভারির সময় পরিশোধ করতে হবে।'),
          const SizedBox(height: 14),
          BusyButton(label: 'ঠিকানা নিশ্চিত করুন', onPressed: () async => setState(() => _step = 'address')),
        ]);
      case 'address':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const FieldLabel('ডেলিভারি ঠিকানা'),
          TextField(controller: _address, minLines: 3, maxLines: 4),
          if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = 'details'), child: const Text('পেছনে'))),
            const SizedBox(width: 10),
            Expanded(child: BusyButton(label: 'রিডিম কনফার্ম করুন', busyLabel: 'অপেক্ষা করুন...', onPressed: _redeem)),
          ]),
        ]);
      default:
        return Column(children: [
          const Icon(LucideIcons.circleCheck, color: AppColors.green700, size: 56),
          const SizedBox(height: 10),
          Text('রিডেম্পশন সফল হয়েছে!', style: ts(16, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 6),
          Text('অভিনন্দন! ${g.name} সফলভাবে রিডিম করা হয়েছে।', textAlign: TextAlign.center, style: ts(12.5, color: AppColors.grey600)),
          const SizedBox(height: 16),
          BusyButton(label: 'ঠিক আছে', onPressed: () async => Navigator.pop(context)),
        ]);
    }
  }
}
