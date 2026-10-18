import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Post actions shared by the Community feed and the User Timeline.
/// Logic is the same as the handlers in frontend/src/tabs/CommunityTab.tsx.
class PostActions {
  PostActions(this.ref, this.context);
  final WidgetRef ref;
  final BuildContext context;

  AppDataController get _data => ref.read(appDataProvider.notifier);

  /// Facebook-style: same [type] again removes it, another type switches.
  Future<void> react(Post original, [String type = 'like']) async {
    // Optimistic; the server's answer (and any points) replaces it.
    _data.upsertPost(original.withReaction(type));
    try {
      final r = await ref.read(apiProvider).reactToPost(original.id, type: type);
      _data.upsertPost(r.post);
      _data.addRewardTx(r.rewardTx);
    } catch (e) {
      _data.upsertPost(original);
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> toggleSave(Post p) async {
    try {
      final updated = await ref.read(apiProvider).toggleSavePost(p.id);
      _data.upsertPost(updated);
      if (context.mounted) toast(context, updated.savedByMe ? 'পোস্টটি সেভ করা হয়েছে।' : 'সেভ সরিয়ে নেওয়া হয়েছে।');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  void hide(Post p) {
    _data.removePost(p.id);
    ref.read(apiProvider).hidePost(p.id).catchError((Object e) => debugPrint('[hide post] $e'));
  }

  /// Blocks the author: their posts and comments disappear for this user.
  Future<void> blockAuthor(Post p) async {
    final authorId = p.authorId;
    if (authorId == null) return hide(p);
    final ok = await confirmDialog(
      context,
      '${p.authorName}-কে ব্লক করবেন?\nতার কোনো পোস্ট বা কমেন্ট আপনি আর দেখবেন না।',
      confirm: 'ব্লক করুন',
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(apiProvider).blockUser(authorId);
      _data.removePostsBy(authorId);
      if (context.mounted) toast(context, '${p.authorName}-কে ব্লক করা হয়েছে।');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> report(Post p) async {
    try {
      await ref.read(apiProvider).reportPost(p.id);
      if (context.mounted) await alertDialog(context, 'পোস্টটি সফলভাবে রিপোর্ট করা হয়েছে। আমাদের টিম এটি পর্যালোচনা করবে।');
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> delete(Post p) async {
    if (!await confirmDialog(context, 'আপনি কি নিশ্চিতভাবে এই পোস্টটি মুছে ফেলতে চান?', confirm: 'ডিলিট করুন', danger: true)) {
      return;
    }
    try {
      await ref.read(apiProvider).deletePost(p.id);
      _data.removePost(p.id);
    } catch (e) {
      if (context.mounted) toastError(context, e);
    }
  }

  Future<void> share(Post p) => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _ShareSheet(post: p),
      );
}

String postLink(String postId) => '${Env.webOrigin}/community/post/$postId';

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.post});
  final Post post;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('পোস্ট শেয়ার করুন', style: ts(16, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 6),
          Text('${p.authorName}-এর পোস্টটি আপনার কমিউনিটিতে শেয়ার করুন বা লিংক কপি করুন।',
              style: ts(12, color: AppColors.grey600, height: 1.5)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.share2, size: 16),
            label: const Text('অন্য অ্যাপে শেয়ার করুন'),
            onPressed: () {
              final text = p.content.length > 200 ? '${p.content.substring(0, 200)}...' : p.content;
              SharePlus.instance.share(ShareParams(text: '$text\n\n${postLink(p.id)}'));
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 16),
            label: Text(_copied ? 'লিংক কপি হয়েছে!' : 'পোস্টের লিংক কপি করুন'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: postLink(p.id)));
              setState(() => _copied = true);
            },
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
        ]),
      ),
    );
  }
}
