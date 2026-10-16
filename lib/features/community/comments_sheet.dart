import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Post detail + comment thread (CommunityTab.tsx "activePost" modal).
/// Re-fetches `GET /posts/:id/comments` on open so comments written on the
/// web appear immediately.
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
      builder: (_) => _CommentsSheet(postId: post.id, onOpenAuthor: onOpenAuthor),
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
  bool _sending = false;

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
    super.dispose();
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final r = await ref.read(apiProvider).addComment(widget.postId, content);
      final data = ref.read(appDataProvider.notifier);
      data.addComment(r.comment);
      data.upsertPost(r.post);
      data.addRewardTx(r.rewardTx);
      _text.clear();
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
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
                for (final c in comments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppAvatar(c.authorAvatar, size: 30, ring: false, onTap: () => _openAuthor(c.authorName, c.authorId)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openAuthor(c.authorName, c.authorId),
                                  child: Text(c.authorName, style: ts(12, weight: bold)),
                                ),
                              ),
                              Text(c.createdAt, style: ts(10, color: AppColors.grey500)),
                            ]),
                            const SizedBox(height: 2),
                            Text(c.content, style: ts(12.5, height: 1.4)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
            ]),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    maxLength: 2000,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'একটি সুন্দর কমেন্ট লিখুন...', counterText: ''),
                  ),
                ),
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
}
