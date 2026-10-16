import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../data/models/contest.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../timeline/user_timeline_screen.dart';
import 'contest_entry_sheet.dart';
import 'redeem_catalog.dart';

/// Rewards tab — port of frontend/src/tabs/RewardsTab.tsx.
class RewardsTab extends ConsumerStatefulWidget {
  const RewardsTab({super.key});

  @override
  ConsumerState<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends ConsumerState<RewardsTab> {
  String _tab = 'rewards'; // rewards | contests
  String _contestTab = 'active'; // active | my | winners
  bool _catalog = false;

  @override
  Widget build(BuildContext context) {
    if (_catalog) return RedeemCatalog(onBack: () => setState(() => _catalog = false));

    return RefreshIndicator(
      color: AppColors.maroon,
      onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 32), children: [
        _Segmented(
          value: _tab,
          options: const {'rewards': 'আমার রিওয়ার্ডস', 'contests': 'কনটেস্ট'},
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 14),
        if (_tab == 'rewards') ..._rewards() else ..._contests(),
      ]),
    );
  }

  // ------------------------------------------------------------ rewards --
  List<Widget> _rewards() {
    final d = ref.watch(dataProvider);
    final lb = [
      for (final e in d.leaderboard)
        e.isMe
            ? LeaderboardEntry(rank: e.rank, userId: e.userId, name: d.user.name, avatar: d.user.avatar, earned: d.earnedPoints, isMe: true)
            : e,
    ]..sort((a, b) => b.earned - a.earned);

    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('উপলব্ধ পয়েন্ট ব্যালেন্স', style: ts(11, color: AppColors.sand)),
                const SizedBox(height: 2),
                Text('${toBnDigits(d.availablePoints)} পয়েন্ট', style: ts(26, weight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.maroon),
              onPressed: () => setState(() => _catalog = true),
              icon: const Icon(LucideIcons.gift, size: 16),
              label: const Text('রিডিম করুন'),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _stat('মোট অর্জিত', '+${toBnDigits(d.earnedPoints)} পয়েন্ট'),
            const SizedBox(width: 10),
            _stat('ব্যয়িত (গিফট)', '-${toBnDigits(d.spentPoints)} পয়েন্ট'),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('পয়েন্ট পাবেন যেভাবে', icon: LucideIcons.sparkles),
          const SizedBox(height: 10),
          for (final (l, v) in const [
            ('টেক্সট বা ছবি পোস্ট', '+৫ পয়েন্ট'),
            ('ভিডিও পোস্ট', '+১০ পয়েন্ট'),
            ('পোস্ট রিঅ্যাকশন (লাইক)', '+২ পয়েন্ট'),
            ('কমেন্ট', '+২ পয়েন্ট'),
            ('শপ পার্চেস', 'প্রোডাক্ট অনুযায়ী নির্দিষ্ট'),
            ('কনটেস্ট অংশগ্রহণ', 'কনটেস্ট অনুযায়ী নির্দিষ্ট'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Text(l, style: ts(12))),
                Text(v, style: ts(12, weight: bold, color: AppColors.olive)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('পয়েন্ট লিডারবোর্ড (সর্বমোট অর্জিত)', icon: LucideIcons.award),
          const SizedBox(height: 10),
          if (lb.isEmpty) Text('লিডারবোর্ড লোড হচ্ছে...', style: ts(12, color: AppColors.grey500)),
          for (var i = 0; i < lb.length; i++) _leaderRow(lb[i], i, lb.length),
        ]),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
        onPressed: () => showAppSheet<void>(context, title: 'রিডেম্পশন ও ট্রানজ্যাকশন ইতিহাস', builder: (_) => const _History()),
        icon: const Icon(LucideIcons.history, size: 16),
        label: const Text('রিডেম্পশন ও ট্রানজ্যাকশন ইতিহাস'),
      ),
    ];
  }

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: ts(10, color: AppColors.sand)),
            Text(value, style: ts(13, weight: bold, color: Colors.white)),
          ]),
        ),
      );

  Widget _leaderRow(LeaderboardEntry m, int index, int total) {
    // Outside the top list, the server-computed rank is the real one.
    final trailingMe = m.isMe && index == total - 1 && m.rank > index + 1;
    final rank = trailingMe ? m.rank : index + 1;
    final (bg, border) = m.isMe
        ? (AppColors.maroon.withValues(alpha: 0.08), AppColors.maroon)
        : rank == 1
            ? (const Color(0xFFFEF3C7), const Color(0xFFFCD34D))
            : rank <= 3
                ? (AppColors.amber50, const Color(0xFFFDE68A))
                : (AppColors.cream, AppColors.sandA(0.5));
    final medal = switch (rank) { 1 => AppColors.gold, 2 => const Color(0xFFB0B7C3), 3 => const Color(0xFFCD7F32), _ => AppColors.sand };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(
            Routes.timeline,
            extra: m.isMe ? const TimelineTarget.me() : TimelineTarget.other(authorName: m.name, authorId: m.userId),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: medal,
                child: Text(toBnDigits(rank), style: ts(11, weight: bold, color: rank <= 3 ? Colors.white : AppColors.maroon)),
              ),
              const SizedBox(width: 10),
              AppAvatar(m.avatar, size: 34, ring: false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${m.name}${m.isMe ? ' (আপনি)' : ''}', style: ts(12.5, weight: m.isMe ? bold : semi), overflow: TextOverflow.ellipsis),
                  Text('র‍্যাংক #${toBnDigits(rank)}', style: ts(10, color: AppColors.grey500)),
                ]),
              ),
              Text('${toBnDigits(m.earned)} পয়েন্ট', style: ts(12, weight: bold, color: AppColors.maroon)),
            ]),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- contests --
  List<Widget> _contests() {
    final d = ref.watch(dataProvider);
    return [
      SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final (id, label) in const [('active', 'চলমান কনটেস্ট'), ('my', 'আমার অংশগ্রহণ'), ('winners', 'বিজয়ীগণ')])
            PillChip(label: label, selected: _contestTab == id, onTap: () => setState(() => _contestTab = id)),
        ]),
      ),
      const SizedBox(height: 14),
      if (_contestTab == 'active') ...[
        Text('চলমান কনটেস্টসমূহ', style: ts(15, weight: bold, color: AppColors.maroon)),
        Text('রেসিপি ও ভিডিও রিভিউ শেয়ার করে জিতে নিন আকর্ষণীয় পুরস্কার', style: ts(11.5, color: AppColors.grey600)),
        const SizedBox(height: 12),
        if (d.contests.isEmpty) const EmptyState(icon: LucideIcons.trophy, title: 'এখন কোনো কনটেস্ট নেই'),
        for (final c in d.contests) _contestCard(c, d.submissions.any((s) => s.contestId == c.id)),
      ],
      if (_contestTab == 'my') ...[
        Text('আমার কনটেস্ট সাবমিশন', style: ts(15, weight: bold, color: AppColors.maroon)),
        const SizedBox(height: 12),
        if (d.submissions.isEmpty)
          Text('আপনার কোনো সাবমিশন নেই।', style: ts(12, color: AppColors.grey500))
        else
          for (final s in d.submissions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (s.mediaUrl.isNotEmpty) ...[NetImage(s.mediaUrl, width: 54, height: 54, radius: 10), const SizedBox(width: 10)],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('সাবমিশন আইডি: #${s.id}', style: ts(11, weight: bold)),
                      const SizedBox(height: 2),
                      Text(s.description, style: ts(12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(s.createdAt, style: ts(10, color: AppColors.grey500)),
                    ]),
                  ),
                  _submissionStatus(s.status),
                ]),
              ),
            ),
      ],
      if (_contestTab == 'winners') ..._winners(d.contests),
    ];
  }

  Widget _submissionStatus(String status) => switch (status) {
        'approved' => const Tag('অনুমোদিত', bg: AppColors.green50, fg: AppColors.green700),
        'rejected' => const Tag('প্রত্যাখ্যাত', bg: AppColors.red50, fg: AppColors.red600),
        _ => const Tag('মডারেশন পেন্ডিং', bg: AppColors.amber50, fg: AppColors.amber800),
      };

  Widget _contestCard(Contest c, bool alreadySubmitted) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Tag(c.status == 'active' ? 'চলমান' : 'সমাপ্ত',
                  bg: c.status == 'active' ? AppColors.green50 : AppColors.grey100,
                  fg: c.status == 'active' ? AppColors.green700 : AppColors.grey600),
              const Spacer(),
              Text('${c.endDate} পর্যন্ত', style: ts(10.5, color: AppColors.grey500)),
            ]),
            const SizedBox(height: 8),
            Text(c.title, style: ts(14, weight: bold, color: AppColors.maroon)),
            const SizedBox(height: 4),
            Text(c.description, style: ts(12, color: AppColors.grey600, height: 1.5)),
            const SizedBox(height: 8),
            Text('পুরস্কার: ${c.prize}', style: ts(12, weight: bold, color: AppColors.olive)),
            const SizedBox(height: 4),
            Text('যোগ্যতা: ${c.needsDeliveredOrder ? 'ডেলিভারি সম্পন্ন অর্ডার প্রয়োজন' : 'সকলের জন্য উন্মুক্ত'}',
                style: ts(11, color: AppColors.grey600)),
            const SizedBox(height: 12),
            BusyButton(
              label: alreadySubmitted ? 'ইতিমধ্যে অংশগ্রহণ করেছেন' : 'অংশগ্রহণ করুন (+${toBnDigits(c.reward)} পয়েন্ট)',
              onPressed: c.status != 'active' || alreadySubmitted ? null : () => showContestEntrySheet(context, c),
            ),
          ]),
        ),
      );

  /// Uses `contest.winners` from the API; falls back to the same hard-coded
  /// winners the web shows when no contest has winners yet.
  List<Widget> _winners(List<Contest> contests) {
    final real = [
      for (final c in contests)
        for (final w in c.winners) (c.title, w.name, w.prize),
    ];
    final rows = real.isNotEmpty
        ? real
        : const [
            ('সেরা বেবি রেসিপি কনটেস্ট (অক্টোবর)', 'সুমাইয়া শারমিন (ধানমন্ডি, ঢাকা)', '১ম স্থান'),
            ('স্বাস্থ্যকর পুষ্টি টিপস কনটেস্ট (সেপ্টেম্বর)', 'ফারহানা সুলতানা (উত্তরা, ঢাকা)', '১ম স্থান'),
          ];
    return [
      Text('গত কনটেস্টের বিজয়ীবৃন্দ', style: ts(15, weight: bold, color: AppColors.maroon)),
      const SizedBox(height: 12),
      for (final (title, name, prize) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(LucideIcons.trophy, color: AppColors.gold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: ts(12.5, weight: bold)),
                  Text('বিজয়ী: $name', style: ts(11.5, color: AppColors.grey600)),
                ]),
              ),
              Tag(prize, bg: const Color(0xFFFEF3C7), fg: AppColors.amber800),
            ]),
          ),
        ),
    ];
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('আমার গিফট রিডেম্পশন', style: ts(13, weight: bold, color: AppColors.maroon)),
      const SizedBox(height: 8),
      if (d.giftRedemptions.isEmpty)
        Text('কোনো গিফট রিডিম করা হয়নি।', style: ts(12, color: AppColors.grey500))
      else
        for (final r in d.giftRedemptions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(r.giftName, style: ts(12.5, weight: bold)),
            subtitle: Text('খরচ: ${toBnDigits(r.pointsCost)} পয়েন্ট · ${r.createdAt}', style: ts(11, color: AppColors.grey500)),
            trailing: Tag(_redemptionLabel(r.status), bg: AppColors.blue50, fg: AppColors.blue600),
          ),
      const SizedBox(height: 16),
      Text('পয়েন্ট লেজার', style: ts(13, weight: bold, color: AppColors.maroon)),
      const SizedBox(height: 8),
      for (final tx in d.rewardTx)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(tx.description, style: ts(12.5)),
          subtitle: Text(tx.date, style: ts(10.5, color: AppColors.grey500)),
          trailing: Text(
            tx.points > 0 ? '+${toBnDigits(tx.points)}' : toBnDigits(tx.points),
            style: ts(13, weight: bold, color: tx.points > 0 ? AppColors.green700 : AppColors.red600),
          ),
        ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন')),
      ),
    ]);
  }

  String _redemptionLabel(String s) => switch (s) {
        'pending' => 'অনুরোধ করা হয়েছে',
        'processing' => 'প্রসেসিং',
        'shipped' => 'পাঠানো হয়েছে',
        'delivered' => 'ডেলিভারি সম্পন্ন',
        _ => s,
      };
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.sand)),
        child: Row(children: [
          for (final e in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: value == e.key ? AppColors.maroon : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(e.value, style: ts(12.5, weight: bold, color: value == e.key ? Colors.white : AppColors.grey600)),
                ),
              ),
            ),
        ]),
      );
}
