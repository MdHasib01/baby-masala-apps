import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/emoji_picker.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Post detail + comment thread (CommunityTab.tsx "activePost" modal).
/// Re-fetches `GET /posts/:id/comments` on open so comments written on the
/// web appear immediately. Replies are one level deep, like Facebook.
Future<void> showCommentsSheet(
  BuildContext context,
  Post post, {
  void Function(String name, String? id)? onOpenAuthor,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => SheetDragToClose(child: _CommentsSheet(postId: post.id, onOpenAuthor: onOpenAuthor)),
    );

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.postId, this.onOpenAuthor});
  final String postId;
  final void Function(String name, String? id)? onOpenAuthor;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  Comment? _replyTo;

  /// Top-level comment ids whose replies are expanded.
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    ref.read(apiProvider).getComments(widget.postId).then((list) {
      if (mounted) ref.read(appDataProvider.notifier).setCommentsFor(widget.postId, list);
    }).catchError((Object e) => debugPrint('[comments] $e'));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startReply(Comment c) {
    setState(() {
      _replyTo = c;
      _expanded.add(c.parentId ?? c.id);
    });
    _focus.requestFocus();
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final r = await ref.read(apiProvider).addComment(widget.postId, content, parentId: _replyTo?.id);
      final data = ref.read(appDataProvider.notifier);
      data.addComment(r.comment);
      data.upsertPost(r.post);
      data.addRewardTx(r.rewardTx);
      _text.clear();
      setState(() => _replyTo = null);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openAuthor(String name, String? id) {
    if (widget.onOpenAuthor == null) return;
    Navigator.pop(context);
    widget.onOpenAuthor!(name, id);
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final post = d.posts.where((p) => p.id == widget.postId).firstOrNull;
    final comments = d.comments.where((c) => c.postId == widget.postId).toList();
    if (post == null) return const SizedBox(height: 120);

    // Threads: replies whose parent isn't loaded are shown as top-level.
    final ids = {for (final c in comments) c.id};
    final topLevel = comments.where((c) => c.parentId == null || !ids.contains(c.parentId)).toList();
    final replies = <String, List<Comment>>{};
    for (final c in comments) {
      if (c.parentId != null && ids.contains(c.parentId)) (replies[c.parentId!] ??= []).add(c);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 6),
            child: Row(children: [
              Expanded(
                child: Text('${post.authorName}-এর পোস্ট ও কমেন্ট',
                    style: ts(14, weight: bold, color: AppColors.maroon), overflow: TextOverflow.ellipsis),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
            ]),
          ),
          const Divider(),
          Flexible(
            child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
              Row(children: [
                AppAvatar(post.authorAvatar, size: 36),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(post.authorName, style: ts(13, weight: bold)),
                  Text(post.createdAt, style: ts(10.5, color: AppColors.grey500)),
                ]),
              ]),
              const SizedBox(height: 10),
              Text(post.content, style: ts(13, height: 1.6)),
              if (post.mediaUrl != null && !post.isVideo) ...[
                const SizedBox(height: 10),
                NetImage(post.mediaUrl, radius: 12, width: double.infinity, height: 200),
              ],
              const SizedBox(height: 16),
              Text('সকল কমেন্ট', style: ts(13, weight: bold, color: AppColors.maroon)),
              const SizedBox(height: 8),
              if (comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('এখনো কোনো কমেন্ট করা হয়নি। প্রথম কমেন্টটি করুন!',
                      textAlign: TextAlign.center, style: ts(12, color: AppColors.grey500)),
                )
              else
                for (final c in topLevel) ...[
                  _bubble(c, avatar: 32),
                  if ((replies[c.id] ?? const []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: _expanded.contains(c.id) || replies[c.id]!.length == 1
                          ? Column(children: [for (final r in replies[c.id]!) _bubble(r, avatar: 24)])
                          : GestureDetector(
                              onTap: () => setState(() => _expanded.add(c.id)),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  const Icon(LucideIcons.cornerDownRight, size: 15, color: AppColors.grey500),
                                  const SizedBox(width: 6),
                                  Text('${toBnDigits(replies[c.id]!.length)}টি উত্তর দেখুন',
                                      style: ts(12, weight: bold, color: AppColors.grey600)),
                                ]),
                              ),
                            ),
                    ),
                ],
            ]),
          ),
          const Divider(),
          if (_replyTo != null)
            Container(
              color: AppColors.sandA(0.25),
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(children: [
                const Icon(LucideIcons.reply, size: 14, color: AppColors.grey600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${_replyTo!.authorName}-কে উত্তর দিচ্ছেন',
                      style: ts(11.5, weight: semi, color: AppColors.grey600), overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _replyTo = null),
                  icon: const Icon(LucideIcons.x, size: 16),
                ),
              ]),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(children: [
                EmojiButton(controller: _text),
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _replyTo == null ? 'একটি সুন্দর কমেন্ট লিখুন...' : 'উত্তর লিখুন...',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.maroon),
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.send, size: 18, color: Colors.white),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(Comment c, {required double avatar}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppAvatar(c.authorAvatar, size: avatar, ring: false, onTap: () => _openAuthor(c.authorName, c.authorId)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () => _openAuthor(c.authorName, c.authorId),
                    child: Text(c.authorName, style: ts(12, weight: bold)),
                  ),
                  const SizedBox(height: 2),
                  Text(c.content, style: ts(12.5, height: 1.4)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 3),
                child: Row(children: [
                  Text(c.createdAt, style: ts(10.5, color: AppColors.grey500)),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => _startReply(c),
                    child: Text('উত্তর দিন', style: ts(11, weight: bold, color: AppColors.grey600)),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      );
}
