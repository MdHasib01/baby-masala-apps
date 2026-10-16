import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../core/utils/image_data_url.dart';
import '../../data/models/contest.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Contest submission modal (RewardsTab.tsx "selectedContest").
Future<void> showContestEntrySheet(BuildContext context, Contest c) =>
    showAppSheet<void>(context, title: c.title, builder: (_) => _ContestEntry(contest: c));

class _ContestEntry extends ConsumerStatefulWidget {
  const _ContestEntry({required this.contest});
  final Contest contest;

  @override
  ConsumerState<_ContestEntry> createState() => _ContestEntryState();
}

class _ContestEntryState extends ConsumerState<_ContestEntry> {
  final _desc = TextEditingController();
  String? _media;
  String? _orderId;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = widget.contest;
    final delivered = ref.read(dataProvider).orders.where((o) => o.status == 'delivered');
    if (c.needsDeliveredOrder && delivered.isEmpty && _orderId == null) {
      setState(() => _error = 'এই কনটেস্টে অংশগ্রহণের জন্য ডেলিভারি সম্পন্ন হওয়া অর্ডার নির্বাচন করা আবশ্যক।');
      return;
    }
    if (_desc.text.trim().isEmpty) {
      setState(() => _error = 'দয়া করে বিবরণ লিখুন।');
      return;
    }
    setState(() => _error = null);
    try {
      // Eligibility and contest points are checked by the server.
      final r = await ref.read(apiProvider).submitContestEntry(c.id, description: _desc.text.trim(), mediaUrl: _media, orderId: _orderId);
      ref.read(appDataProvider.notifier).addSubmission(r.submission, r.rewardTx);
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contest;
    final delivered = ref.watch(dataProvider.select((d) => d.orders.where((o) => o.status == 'delivered').toList()));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (c.needsDeliveredOrder) ...[
        const FieldLabel('ডেলিভারি সম্পন্ন অর্ডার নির্বাচন করুন'),
        DropdownButtonFormField<String>(
          initialValue: _orderId,
          hint: Text('-- অর্ডার সিলেক্ট করুন --', style: ts(12.5)),
          items: [
            for (final o in delivered)
              DropdownMenuItem(value: o.id, child: Text('অর্ডার #${o.id} (${taka(o.totalAmount)})', style: ts(12.5))),
          ],
          onChanged: (v) => setState(() => _orderId = v),
        ),
        if (delivered.isEmpty) ...[
          const SizedBox(height: 6),
          Text('আপনার কোনো ডেলিভারি সম্পন্ন অর্ডার নেই।', style: ts(11, weight: semi, color: AppColors.red600)),
        ],
        const SizedBox(height: 10),
      ],
      const FieldLabel('ভিডিও বা ছবি'),
      if (_media != null)
        Stack(children: [
          NetImage(_media, height: 160, width: double.infinity, radius: 12),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => setState(() => _media = null),
              icon: const Icon(LucideIcons.x, size: 16, color: Colors.white),
            ),
          ),
        ])
      else
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final url = await pickImageAsDataUrl(context);
              if (url != null) setState(() => _media = url);
            } catch (e) {
              if (context.mounted) toastError(context, e);
            }
          },
          icon: const Icon(LucideIcons.image, size: 16),
          label: const Text('ছবি যোগ করুন'),
        ),
      const SizedBox(height: 10),
      const FieldLabel('আপনার রেসিপি বা রিভিউ বিবরণ'),
      TextField(
        controller: _desc,
        minLines: 4,
        maxLines: 8,
        maxLength: 2000,
        decoration: const InputDecoration(hintText: 'বিস্তারিত লিখুন...', counterText: ''),
      ),
      if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
      if (_success) ...[
        const SizedBox(height: 10),
        InfoBox('সাবমিশন সফল হয়েছে (+${toBnDigits(c.reward)} পয়েন্ট)!',
            icon: LucideIcons.circleCheck, bg: AppColors.green50, fg: AppColors.green700),
      ],
      const SizedBox(height: 14),
      BusyButton(label: 'সাবমিট করুন', onPressed: _success ? null : _submit),
    ]);
  }
}
