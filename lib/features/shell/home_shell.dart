import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../baby/my_baby_tab.dart';
import '../community/community_tab.dart';
import '../friends/friends_tab.dart';
import '../notifications/notifications_sheet.dart';
import '../rewards/rewards_tab.dart';
import '../shop/shop_tab.dart';
import 'app_drawer.dart';
import 'home_tab.dart';

/// Main app: header + five top tabs (Header.tsx) + left drawer.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _scaffold = GlobalKey<ScaffoldState>();

  static const _tabs = [
    (HomeTab.home, 'হোম', LucideIcons.house),
    (HomeTab.baby, 'মাই বেবি', LucideIcons.baby),
    (HomeTab.friends, 'ফ্রেন্ডস', LucideIcons.users),
    (HomeTab.rewards, 'রিওয়ার্ডস', LucideIcons.gift),
    (HomeTab.shop, 'শপ', LucideIcons.shoppingBag),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(homeTabProvider);

    // Leaderboard refresh whenever the Rewards tab opens (App.tsx effect).
    ref.listen(homeTabProvider, (prev, next) {
      if (next == HomeTab.rewards && prev != next) ref.read(appDataProvider.notifier).refreshLeaderboard();
    });

    return PopScope(
      canPop: tab == HomeTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(homeTabProvider.notifier).select(HomeTab.home);
      },
      child: Scaffold(
        key: _scaffold,
        drawer: const AppDrawer(),
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _Header(onOpenDrawer: () => _scaffold.currentState?.openDrawer()),
            _TabBar(tabs: _tabs, active: tab),
            Expanded(
              child: IndexedStack(
                index: tab.index,
                children: const [CommunityTab(), MyBabyTab(), FriendsTab(), RewardsTab(), ShopTab()],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onOpenDrawer});
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final user = d.user;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(children: [
        GestureDetector(
          onTap: onOpenDrawer,
          child: Stack(clipBehavior: Clip.none, children: [
            AppAvatar(user.avatar, size: 40),
            if (user.isMember)
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: const Icon(LucideIcons.shieldCheck, size: 10, color: AppColors.maroon),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: onOpenDrawer, child: const Wordmark(size: 17))),
        // Admin entry — shown only to admins (web shows it to everyone; see MOBILE_SYNC.md §6).
        if (user.isAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: ts(11, weight: bold),
              ),
              onPressed: () => context.push(Routes.admin),
              child: const Text('অ্যাডমিন'),
            ),
          ),
        IconButton(
          tooltip: 'মেসেঞ্জার',
          onPressed: () => context.push(Routes.messenger),
          icon: CountBadge(count: d.unreadMessages, child: const Icon(LucideIcons.messageSquare, color: AppColors.maroon, size: 22)),
        ),
        IconButton(
          tooltip: 'নোটিফিকেশন',
          onPressed: () => showNotificationsSheet(context),
          icon: CountBadge(count: d.unreadNotifications, child: const Icon(LucideIcons.bell, color: AppColors.maroon, size: 22)),
        ),
      ]),
    );
  }
}

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.tabs, required this.active});
  final List<(HomeTab, String, IconData)> tabs;
  final HomeTab active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(dataProvider.select((d) => d.cartCount));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.sand), bottom: BorderSide(color: AppColors.sand)),
      ),
      child: Row(
        children: [
          for (final (t, label, icon) in tabs)
            Expanded(
              child: InkWell(
                onTap: () => ref.read(homeTabProvider.notifier).select(t),
                child: Container(
                  color: t == active ? AppColors.sandA(0.3) : null,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(children: [
                    CountBadge(
                      count: t == HomeTab.shop ? cartCount : 0,
                      child: Icon(icon, size: 20, color: t == active ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                        style: ts(11,
                            weight: t == active ? bold : FontWeight.w500,
                            color: t == active ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: t == active ? 32 : 0,
                      decoration: const BoxDecoration(
                        color: AppColors.maroon,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
