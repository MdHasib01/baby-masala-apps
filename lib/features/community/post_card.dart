import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../shared/widgets/reactions.dart';
import '../../state/app_data_controller.dart';
import 'comments_sheet.dart';
import 'post_actions.dart';
import 'post_composer.dart';

/// Single post card (CommunityTab.tsx feed item).
class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post, this.onOpenAuthor});

  final Post post;
  final void Function(String authorName, String? authorId)? onOpenAuthor;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final user = ref.watch(dataProvider.select((d) => d.user));
    final comments = ref.watch(dataProvider.select((d) => d.comments.where((c) => c.postId == post.id).toList()));
    final isOwn = (post.authorId != null && post.authorId == user.id) || post.authorName == user.name;
    final isLong = post.content.length > 180;
    final actions = PostActions(ref, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandA(0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ---- header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 6),
          child: Row(children: [
            AppAvatar(post.authorAvatar, size: 40, onTap: () => widget.onOpenAuthor?.call(post.authorName, post.authorId)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                  GestureDetector(
                    onTap: () => widget.onOpenAuthor?.call(post.authorName, post.authorId),
                    child: Text(post.authorName, style: ts(13, weight: bold)),
                  ),
                  if (post.isVerifiedBuyer)
                    const Tag('মেম্বার', icon: LucideIcons.shieldCheck, bg: Color(0xFFFEF3C7), fg: AppColors.amber800),
                  if (post.status != 'approved')
                    Tag(post.status == 'pending' ? 'অপেক্ষমাণ' : 'প্রত্যাখ্যাত', bg: AppColors.red50, fg: AppColors.red600),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text('${post.createdAt} · ${post.topic} · ', style: ts(10.5, color: AppColors.grey500)),
                  const Icon(LucideIcons.globe, size: 11, color: AppColors.grey400),
                ]),
              ]),
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.ellipsisVertical, size: 18, color: AppColors.grey500),
              onSelected: (v) {
                switch (v) {
                  case 'save':
                    actions.toggleSave(post);
                  case 'hide':
                    actions.hide(post);
                  case 'report':
                    actions.report(post);
                  case 'edit':
                    showPostComposer(context, editing: post);
                  case 'delete':
                    actions.delete(post);
                }
              },
              itemBuilder: (_) => [
                _menu('save', LucideIcons.bookmark, post.savedByMe ? 'সেভ সরিয়ে নিন' : 'পোস্ট সেভ করুন'),
                _menu('hide', LucideIcons.eyeOff, 'ফিড থেকে লুকান'),
                _menu('report', LucideIcons.flag, 'রিপোর্ট করুন'),
                if (isOwn) ...[
                  const PopupMenuDivider(),
                  _menu('edit', LucideIcons.pencil, 'এডিট করুন'),
                  _menu('delete', LucideIcons.trash2, 'ডিলিট করুন', danger: true),
                ],
              ],
            ),
          ]),
        ),
        // ---- content
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isLong && !_expanded ? '${post.content.substring(0, 160)}...' : post.content,
                style: ts(13, height: 1.6)),
            if (isLong)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_expanded ? 'সংক্ষিপ্ত করুন' : 'আরও দেখুন', style: ts(12, weight: bold, color: AppColors.maroon)),
                ),
              ),
          ]),
        ),
        if (post.mediaUrl != null)
          post.isVideo
              ? Container(
                  height: 180,
                  color: AppColors.grey900,
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.video, color: Colors.white54, size: 40),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: NetImage(post.mediaUrl, width: double.infinity),
                ),
        // ---- counts
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(children: [
            ReactionSummary(types: post.topReactions, total: post.likes),
            const Spacer(),
            GestureDetector(
              onTap: () => showCommentsSheet(context, post, onOpenAuthor: widget.onOpenAuthor),
              child: Text('${toBnDigits(post.commentsCount)} কমেন্ট', style: ts(11, color: AppColors.grey500)),
            ),
          ]),
        ),
        const Divider(indent: 14, endIndent: 14),
        // ---- action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(children: [
            Expanded(child: ReactionButton(current: post.myReaction, onReact: (t) => actions.react(post, t))),
            _action(icon: LucideIcons.messageCircle, label: 'কমেন্ট', onTap: () => showCommentsSheet(context, post, onOpenAuthor: widget.onOpenAuthor)),
            _action(icon: LucideIcons.share2, label: 'শেয়ার', onTap: () => actions.share(post)),
          ]),
        ),
        // ---- first comment preview
        if (comments.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppAvatar(comments.first.authorAvatar, size: 26, ring: false,
                    onTap: () => widget.onOpenAuthor?.call(comments.first.authorName, comments.first.authorId)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => widget.onOpenAuthor?.call(comments.first.authorName, comments.first.authorId),
                      child: Text(comments.first.authorName, style: ts(11.5, weight: bold)),
                    ),
                    Text(comments.first.content, style: ts(12, height: 1.4)),
                  ]),
                ),
              ]),
              if (comments.length > 1)
                GestureDetector(
                  onTap: () => showCommentsSheet(context, post, onOpenAuthor: widget.onOpenAuthor),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 34),
                    child: Text('সব কমেন্ট দেখুন (${toBnDigits(comments.length)}টি)',
                        style: ts(11.5, weight: bold, color: AppColors.maroon)),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }

  PopupMenuItem<String> _menu(String v, IconData icon, String label, {bool danger = false}) => PopupMenuItem(
        value: v,
        height: 40,
        child: Row(children: [
          Icon(icon, size: 16, color: danger ? AppColors.red600 : AppColors.ink),
          const SizedBox(width: 10),
          Text(label, style: ts(13, color: danger ? AppColors.red600 : AppColors.ink)),
        ]),
      );

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool active = false,
  }) =>
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.sandA(0.25) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: active ? AppColors.maroon : AppColors.grey600),
              const SizedBox(width: 6),
              Text(label, style: ts(12, weight: active ? bold : semi, color: active ? AppColors.maroon : AppColors.grey600)),
            ]),
          ),
        ),
      );
}
