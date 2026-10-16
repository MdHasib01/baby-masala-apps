import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../timeline/user_timeline_screen.dart';
import 'post_card.dart';
import 'post_composer.dart';

/// Home tab — port of frontend/src/tabs/CommunityTab.tsx.
class CommunityTab extends ConsumerStatefulWidget {
  const CommunityTab({super.key});

  @override
  ConsumerState<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<CommunityTab> {
  String _topic = allPostsLabel;
  String _sort = 'newest';
  bool _loadingMore = false;
  bool _exhausted = false;

  void _openAuthor(String name, String? id) {
    final me = ref.read(dataProvider).user;
    final target = (id != null && id == me.id) || name == me.name
        ? const TimelineTarget.me()
        : TimelineTarget.other(authorName: name, authorId: id);
    context.push(Routes.timeline, extra: target);
  }

  Future<void> _refresh() async {
    _exhausted = false;
    try {
      await ref.read(appDataProvider.notifier).refresh();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  /// Bootstrap returns at most 100 posts. Beyond that we page with
  /// `GET /posts?before=<cursor>`.
  Future<void> _loadMore() async {
    if (_loadingMore || _exhausted) return;
    final d = ref.read(dataProvider);
    var cursor = d.postsCursor;
    if (cursor == null && d.posts.length < 100) {
      _exhausted = true;
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final api = ref.read(apiProvider);
      if (cursor == null) {
        final first = await api.listPosts(limit: 100);
        cursor = first.nextCursor;
      }
      if (cursor == null) {
        _exhausted = true;
      } else {
        final page = await api.listPosts(limit: 50, before: cursor);
        ref.read(appDataProvider.notifier).appendPosts(page.posts, page.nextCursor);
        if (page.nextCursor == null) _exhausted = true;
      }
    } catch (e) {
      debugPrint('[posts page] $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    var posts = d.posts.where((p) => _topic == allPostsLabel || p.topic == _topic).toList();
    if (_sort == 'popular') {
      posts.sort((a, b) => (b.likes + b.commentsCount) - (a.likes + a.commentsCount));
    }

    return RefreshIndicator(
      color: AppColors.maroon,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _loadMore();
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            _recipesBanner(),
            const SizedBox(height: 12),
            _composerBox(d.user.avatar, d.user.firstName),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final t in [allPostsLabel, ...postTopics])
                  PillChip(label: t, selected: _topic == t, onTap: () => setState(() => _topic = t)),
              ]),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('সর্ট: ', style: ts(11, color: AppColors.grey500)),
              DropdownButton<String>(
                value: _sort,
                isDense: true,
                underline: const SizedBox(),
                style: ts(12, weight: bold, color: AppColors.maroon),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('নতুন পোস্ট')),
                  DropdownMenuItem(value: 'popular', child: Text('জনপ্রিয়')),
                ],
                onChanged: (v) => setState(() => _sort = v ?? 'newest'),
              ),
            ]),
            const SizedBox(height: 6),
            if (posts.isEmpty)
              AppCard(
                child: Column(children: [
                  const Icon(LucideIcons.circleAlert, color: AppColors.grey400),
                  const SizedBox(height: 8),
                  Text('এই টপিকে বর্তমানে কোনো পোস্ট নেই। প্রথম পোস্টটি আপনি করতে পারেন!',
                      textAlign: TextAlign.center, style: ts(12, color: AppColors.grey500)),
                ]),
              )
            else
              for (final p in posts) PostCard(key: ValueKey(p.id), post: p, onOpenAuthor: _openAuthor),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppColors.maroon, strokeWidth: 2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recipesBanner() => Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.recipes),
          child: Ink(
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.utensils, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('রেসিপি ও পুষ্টি টিপস', style: ts(14, weight: bold, color: Colors.white)),
                  Text('শিশুর বয়স অনুযায়ী স্বাস্থ্যকর খাবার ও রেসিপি দেখুন', style: ts(11, color: AppColors.sand)),
                ]),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white),
            ]),
          ),
        ),
      );

  Widget _composerBox(String avatar, String firstName) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            AppAvatar(avatar, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => showPostComposer(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.sand),
                  ),
                  child: Text('কী শেয়ার করতে চান, $firstName?', style: ts(12.5, color: AppColors.grey500)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => showPostComposer(context, pickImageFirst: true),
                icon: const Icon(LucideIcons.image, size: 16, color: AppColors.olive),
                label: Text('ছবি বা ভিডিও', style: ts(12, weight: semi)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => setState(() => _topic = 'খাবার'),
                icon: const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.gold),
                label: Text('রেসিপি টপিক', style: ts(12, weight: semi)),
              ),
            ),
          ]),
        ]),
      );
}
