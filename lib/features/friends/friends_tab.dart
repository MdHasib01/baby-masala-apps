import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/social.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../timeline/user_timeline_screen.dart';

/// Friends — port of components/social/FriendsScreen.tsx. On mobile it is a
/// full screen opened from "আরও" (web shows it as the 3rd top tab).
/// Friend status changes go through `setFriends` → `PUT /sync/friends`.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  String _tab = 'friends'; // friends | requests | search
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(dataProvider.select((d) => d.friends.where((f) => f.isBlocked != true).toList()));
    final mine = friends.where((f) => f.friendshipStatus == 'friends').toList();
    final requests = friends.where((f) => f.friendshipStatus == 'request_received').toList();
    final q = _query.toLowerCase();
    final search = friends.where((f) => f.name.toLowerCase().contains(q) || f.location.toLowerCase().contains(q)).toList();
    final list = switch (_tab) { 'requests' => requests, 'search' => search, _ => mine };

    return Scaffold(
      appBar: AppBar(title: const Text('মায়েদের কমিউনিটি ও ফ্রেন্ডস')),
      body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandA(0.6)),
          ),
          child: Row(children: [
            _subTab('friends', 'আমার ফ্রেন্ডস (${toBnDigits(mine.length)})'),
            _subTab('requests', 'রিকোয়েস্ট (${toBnDigits(requests.length)})'),
            _subTab('search', 'মায়েদের খুঁজুন'),
          ]),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          color: AppColors.maroon,
          onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_tab == 'search') ...[
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.search, size: 18),
                  hintText: 'নাম বা এলাকা দিয়ে মায়েরা খুঁজুন...',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (list.isEmpty)
              EmptyState(
                icon: LucideIcons.users,
                title: switch (_tab) {
                  'requests' => 'কোনো নতুন ফ্রেন্ড রিকোয়েস্ট নেই',
                  'search' => 'কাউকে পাওয়া যায়নি',
                  _ => 'এখনো কোনো ফ্রেন্ড নেই',
                },
              ),
            for (final f in list) _FriendRow(friend: f),
          ]),
        ),
      ),
    ]),
    );
  }

  Widget _subTab(String id, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _tab == id ? AppColors.maroon : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(label,
                textAlign: TextAlign.center,
                style: ts(11.5, weight: bold, color: _tab == id ? Colors.white : AppColors.grey600)),
          ),
        ),
      );
}

/// Shared friendship actions (also used by the User Timeline).
extension FriendOps on WidgetRef {
  void setFriendStatus(String id, String status) {
    final list = read(dataProvider).friends;
    read(appDataProvider.notifier).setFriends([for (final f in list) f.id == id ? f.withStatus(status) : f]);
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.friend});
  final FriendUser friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = friend;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push(Routes.timeline, extra: TimelineTarget.other(friend: f)),
              child: Row(children: [
                AppAvatar(f.avatar, size: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.name, style: ts(13, weight: bold), overflow: TextOverflow.ellipsis),
                    if (f.location.isNotEmpty)
                      Row(children: [
                        const Icon(LucideIcons.mapPin, size: 11, color: AppColors.grey400),
                        const SizedBox(width: 3),
                        Flexible(child: Text(f.location, style: ts(11, color: AppColors.grey500), overflow: TextOverflow.ellipsis)),
                      ]),
                    Text('${toBnDigits(f.mutualFriendsCount)} মিউচুয়াল ফ্রেন্ড', style: ts(10.5, color: AppColors.olive)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          FriendshipButtons(friend: f),
        ]),
      ),
    );
  }
}

class FriendshipButtons extends ConsumerWidget {
  const FriendshipButtons({super.key, required this.friend, this.showMessage = true});
  final FriendUser friend;
  final bool showMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = friend;
    final small = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: ts(11, weight: bold),
      minimumSize: Size.zero,
    );
    final smallOutline = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      textStyle: ts(11, weight: bold),
      minimumSize: Size.zero,
    );
    switch (f.friendshipStatus) {
      case 'friends':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          if (showMessage)
            IconButton.filledTonal(
              tooltip: 'মেসেজ',
              onPressed: () => context.push(Routes.messenger, extra: f),
              icon: const Icon(LucideIcons.messageSquare, size: 16, color: AppColors.maroon),
            ),
          IconButton(
            tooltip: 'আনফ্রেন্ড',
            onPressed: () async {
              if (await confirmDialog(context, 'আপনি কি নিশ্চিতভাবে ${f.name}-কে আনফ্রেন্ড করতে চান?', danger: true)) {
                ref.setFriendStatus(f.id, 'none');
              }
            },
            icon: const Icon(LucideIcons.userX, size: 16, color: AppColors.red600),
          ),
        ]);
      case 'request_received':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(style: small, onPressed: () => ref.setFriendStatus(f.id, 'friends'), child: const Text('গ্রহণ করুন')),
          const SizedBox(width: 6),
          OutlinedButton(style: smallOutline, onPressed: () => ref.setFriendStatus(f.id, 'none'), child: const Text('বাতিল')),
        ]);
      case 'request_sent':
        return OutlinedButton(
          style: smallOutline,
          onPressed: () => ref.setFriendStatus(f.id, 'none'),
          child: const Text('রিকোয়েস্ট পাঠানো হয়েছে'),
        );
      default:
        return ElevatedButton.icon(
          style: small,
          onPressed: () => ref.setFriendStatus(f.id, 'request_sent'),
          icon: const Icon(LucideIcons.userPlus, size: 14),
          label: const Text('রিকোয়েস্ট পাঠান'),
        );
    }
  }
}
