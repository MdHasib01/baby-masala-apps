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
import '../notifications/notifications_sheet.dart';
import '../rewards/rewards_tab.dart';
import '../shop/shop_tab.dart';
import '../timeline/user_timeline_screen.dart';
import 'home_tab.dart';
import 'more_sheet.dart';

/// Main app shell: compact top bar + bottom navigation
/// (হোম · মাই বেবি · রিওয়ার্ডস · শপ · আরও).
///
/// Replaces the web's Header.tsx top tabs and ProfileDrawer.tsx — every drawer
/// option lives in the "আরও" sheet (more_sheet.dart).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _titles = {
    HomeTab.home: null, // brand wordmark
    HomeTab.baby: 'মাই বেবি',
    HomeTab.rewards: 'রিওয়ার্ডস',
    HomeTab.shop: 'শপ',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    final cartCount = ref.watch(dataProvider.select((d) => d.cartCount));

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
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _TopBar(title: _titles[tab]),
            Expanded(
              child: IndexedStack(
                index: tab.index,
                children: const [CommunityTab(), MyBabyTab(), RewardsTab(), ShopTab()],
              ),
            ),
          ]),
        ),
        bottomNavigationBar: _BottomBar(
          active: tab,
          cartCount: cartCount,
          onSelect: (t) => ref.read(homeTabProvider.notifier).select(t),
          onMore: () => showMoreSheet(context),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({this.title});
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final user = d.user;
    // Solid background on purpose: on the emulator's Impeller backend, the
    // wordmark/badge next to the clipped avatar vanished over a transparent bar.
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(children: [
        // Avatar → own timeline (was "open drawer" on web).
        GestureDetector(
          onTap: () => context.push(Routes.timeline, extra: const TimelineTarget.me()),
          child: Stack(clipBehavior: Clip.none, children: [
            AppAvatar(user.avatar, size: 42),
            if (user.isMember)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: AppColors.cream, width: 2)),
                  child: const Icon(LucideIcons.shieldCheck, size: 10, color: AppColors.maroon),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        // No AnimatedSwitcher/fade here: opacity layers glitch on the
        // emulator's Impeller backend (same issue as the welcome shadow).
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: title == null
                ? const Wordmark(size: 19)
                : Text(title!, style: ts(20, weight: FontWeight.w800, color: AppColors.maroon)),
          ),
        ),
        TonalIconButton(
          tooltip: 'মেসেঞ্জার',
          icon: LucideIcons.messageCircle,
          badge: d.unreadMessages,
          onPressed: () => context.push(Routes.messenger),
        ),
        const SizedBox(width: 6),
        TonalIconButton(
          tooltip: 'নোটিফিকেশন',
          icon: LucideIcons.bell,
          badge: d.unreadNotifications,
          onPressed: () => showNotificationsSheet(context),
        ),
      ]),
    );
  }
}

/// Custom bottom bar: মাই বেবি · রিওয়ার্ডস · [হোম] · শপ · আরও.
/// Home sits in the middle as a larger raised circle in the brand gradient.
/// (Flat design — no blurred shadows; see the Impeller note in MOBILE_SYNC.md.)
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.active, required this.cartCount, required this.onSelect, required this.onMore});

  final HomeTab active;
  final int cartCount;
  final ValueChanged<HomeTab> onSelect;
  final VoidCallback onMore;

  static const _barHeight = 66.0;
  static const _homeSize = 64.0;
  static const _lift = 26.0; // how far the home circle rises above the bar
  static const _homeBottom = 28.0; // circle bottom, above the "হোম" label

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final homeOn = active == HomeTab.home;

    return SizedBox(
      height: _barHeight + _lift + bottomInset,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        // ---- bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _barHeight + bottomInset,
          child: Container(
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.sandA(0.6))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              _item(LucideIcons.baby, 'মাই বেবি', active == HomeTab.baby, () => onSelect(HomeTab.baby)),
              _item(LucideIcons.gift, 'রিওয়ার্ডস', active == HomeTab.rewards, () => onSelect(HomeTab.rewards)),
              // space under the home circle + its label
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(HomeTab.home),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Text('হোম',
                          style: ts(11.5, weight: homeOn ? bold : FontWeight.w500,
                              color: homeOn ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.6))),
                    ),
                  ),
                ),
              ),
              _item(LucideIcons.shoppingBag, 'শপ', active == HomeTab.shop, () => onSelect(HomeTab.shop), badge: cartCount),
              _item(LucideIcons.layoutGrid, 'আরও', false, onMore),
            ]),
          ),
        ),
        // ---- raised home circle
        Positioned(
          bottom: bottomInset + _homeBottom,
          child: Semantics(
            button: true,
            selected: homeOn,
            label: 'হোম',
            child: GestureDetector(
              onTap: () => onSelect(HomeTab.home),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: _homeSize,
                height: _homeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  // cream ring makes it look "cut into" the bar; gold ring when active
                  border: Border.all(color: homeOn ? AppColors.gold : AppColors.cream, width: 4),
                ),
                child: Icon(LucideIcons.house, size: 27, color: homeOn ? Colors.white : AppColors.sand),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _item(IconData icon, String label, bool on, VoidCallback onTap, {int badge = 0}) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: on ? AppColors.sandA(0.55) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CountBadge(
                count: badge,
                child: Icon(icon, size: 22, color: on ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.55)),
              ),
            ),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(11.5, weight: on ? bold : FontWeight.w500, color: on ? AppColors.maroon : AppColors.ink.withValues(alpha: 0.6))),
          ]),
        ),
      );
}
